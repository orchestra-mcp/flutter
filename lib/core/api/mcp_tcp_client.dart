import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/mcp/mcp_action_logger.dart';
import 'package:orchestra/core/mcp/workspace_initializer.dart';
import 'package:orchestra/core/tray/tray_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// MCP tool descriptor returned by `tools/list`.
class McpTool {
  const McpTool({required this.name, this.description, this.inputSchema});
  final String name;
  final String? description;
  final Map<String, dynamic>? inputSchema;
}

/// Connects to a running `orchestra serve` instance via WebSocket (web-gate).
///
/// Architecture:
/// 1. Try to connect to existing instance at ws://localhost:9201
/// 2. If not running, spawn `orchestra serve` as a detached daemon
/// 3. Communicate via WebSocket JSON-RPC (same protocol as web-gate)
/// 4. All clients (Flutter desktop, Claude Code, mobile) share the same instance
class McpTcpClient implements ApiClient {
  McpTcpClient();

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Process? _serverProcess;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _nextId = 1;
  bool _initialized = false;
  bool _restarting = false;
  bool _stopped = false;
  int _restartAttempts = 0;
  static const _maxRestartAttempts = 5;
  static const _webGatePort = 9201;
  String _workspace = '';

  /// Observable process state for the tray icon and UI.
  final ValueNotifier<TrayIconState> processState = ValueNotifier(
    TrayIconState.stopped,
  );

  /// Available MCP tools fetched after initialization.
  final ValueNotifier<List<McpTool>> availableTools = ValueNotifier([]);

  /// Action logger — logs every tool call for the activity screen.
  McpActionLogger? actionLogger;

  /// Stream controller for server-pushed notifications.
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of MCP notifications (server-pushed, no id).
  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  Future<void> connect({bool resetAttempts = true}) async {
    if (_stopped) return;
    processState.value = TrayIconState.starting;
    if (resetAttempts) _restartAttempts = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      _workspace = prefs.getString('workspace_path') ?? Directory.current.path;

      if (_workspace.isEmpty) {
        processState.value = TrayIconState.stopped;
        return;
      }

      await WorkspaceInitializer.ensureInitialized(_workspace);

      // Step 1: Try connecting to an existing instance.
      if (await _tryConnect()) {
        return; // Connected to existing instance.
      }

      // Step 2: No instance running — spawn one.
      await _spawnServer();

      // Step 3: Wait and connect.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (await _tryConnect()) return;
      }

      throw Exception('Failed to connect to orchestra serve after spawning');
    } catch (e) {
      debugPrint('[MCP] Connect error: $e');
      _initialized = false;
      processState.value = TrayIconState.error;
    }
  }

  /// Attempts to connect to the web-gate WebSocket.
  Future<bool> _tryConnect() async {
    try {
      final uri = Uri.parse('ws://localhost:$_webGatePort/ws');
      final channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: const Duration(seconds: 3),
      );
      await channel.ready;

      _ws = channel;
      _wsSub = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: () {
          if (!_stopped && !_restarting) _scheduleReconnect();
        },
      );

      await _initialize();
      processState.value = TrayIconState.running;
      await _fetchTools();
      debugPrint('[MCP] Connected to web-gate on port $_webGatePort');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Spawns `orchestra serve` as a background child process.
  /// Uses normal mode (not detached) so stdin stays open and the stdio
  /// transport doesn't exit. The process lifecycle is managed by us.
  Future<void> _spawnServer() async {
    debugPrint('[MCP] Spawning orchestra serve for $_workspace');
    _serverProcess = await Process.start('orchestra', [
      'serve',
      '--workspace',
      _workspace,
      '--web-gate',
      ':$_webGatePort',
      '--no-pid',
    ], mode: ProcessStartMode.normal);
    // Drain stdout/stderr to prevent blocking, but don't use them for comms.
    _serverProcess!.stdout.listen((_) {});
    _serverProcess!.stderr.listen((_) {});
    _serverProcess!.exitCode.then((_) {
      _serverProcess = null;
      if (!_stopped && !_restarting) {
        debugPrint('[MCP] Server process exited — reconnecting');
        _scheduleReconnect();
      }
    });
  }

  Future<void> _initialize() async {
    final result = await _send('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, dynamic>{},
      'clientInfo': {'name': 'orchestra-flutter', 'version': '1.0.0'},
    });
    if (result['protocolVersion'] != null) _initialized = true;
  }

  Future<void> _fetchTools() async {
    try {
      final result = await _send('tools/list', {});
      final tools = (result['tools'] as List?)?.map((t) {
        final m = t as Map<String, dynamic>;
        return McpTool(
          name: m['name'] as String,
          description: m['description'] as String?,
          inputSchema: m['inputSchema'] as Map<String, dynamic>?,
        );
      }).toList();
      availableTools.value = tools ?? [];
      debugPrint('[MCP] Loaded ${availableTools.value.length} tools');
    } catch (e) {
      debugPrint('[MCP] Failed to fetch tools: $e');
    }
  }

  Future<List<McpTool>> listTools() async {
    if (availableTools.value.isEmpty && _initialized) {
      await _fetchTools();
    }
    return availableTools.value;
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    _initialized = false;
    availableTools.value = [];
    processState.value = TrayIconState.stopped;
    _restartAttempts++;
    if (_restartAttempts > _maxRestartAttempts) {
      debugPrint('[MCP] Max restart attempts reached');
      processState.value = TrayIconState.error;
      return;
    }
    debugPrint(
      '[MCP] Reconnecting (attempt $_restartAttempts/$_maxRestartAttempts)',
    );
    Future.delayed(
      const Duration(seconds: 2),
      () => connect(resetAttempts: false),
    );
  }

  Future<void> switchWorkspace(String path) async {
    _restarting = true;
    disconnect();
    _restartAttempts = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('workspace_path', path);
    _restarting = false;
    _stopped = false;
    await connect();
  }

  void disconnect() {
    _stopped = true;
    _wsSub?.cancel();
    _wsSub = null;
    _ws?.sink.close();
    _ws = null;
    _serverProcess?.kill();
    _serverProcess = null;
    _initialized = false;
    availableTools.value = [];
    processState.value = TrayIconState.stopped;
  }

  // ── WebSocket messaging ──────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final id = json['id'] as int?;

      // Server-pushed notification (no id).
      if (id == null && json.containsKey('method')) {
        _notificationController.add(json);
        return;
      }

      if (id != null && _pending.containsKey(id)) {
        final c = _pending.remove(id)!;
        final error = json['error'];
        if (error != null) {
          c.completeError(Exception(error.toString()));
        } else {
          c.complete((json['result'] as Map<String, dynamic>?) ?? {});
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _send(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_ws == null) throw StateError('Not connected to MCP server');

    final id = _nextId++;
    final payload = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    _ws!.sink.add(payload);

    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    return c.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('MCP call timed out: $method', timeout);
      },
    );
  }

  // ── Tool call ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await _send('tools/call', {
        'name': name,
        'arguments': arguments,
      }, timeout: timeout);
      sw.stop();
      actionLogger?.log(
        toolName: name,
        arguments: arguments,
        durationMs: sw.elapsedMilliseconds,
        success: true,
      );
      return result;
    } catch (e) {
      sw.stop();
      actionLogger?.log(
        toolName: name,
        arguments: arguments,
        durationMs: sw.elapsedMilliseconds,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ── ApiClient via tools/call ──────────────────────────────────────────

  Future<Map<String, dynamic>> _tool(
    String name,
    Map<String, dynamic> args,
  ) async {
    final raw = await callTool(name, args);

    // Unwrap MCP content envelope.
    final content = raw['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        final text = first['text'] as String? ?? '';
        if (text.isNotEmpty) {
          try {
            final decoded = jsonDecode(text);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {
            return {'text': text};
          }
        }
      }
    }

    return raw;
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> body) =>
      _tool('auth_login', body);

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      _tool('auth_register', body);

  @override
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) =>
      _tool('register_device', body);

  @override
  Future<Map<String, dynamic>> getProfile() => _tool('get_profile', {});

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _tool('update_profile', body);

  @override
  Future<Map<String, dynamic>> updateSettingsProfile(
    Map<String, dynamic> body,
  ) => _tool('update_settings_profile', body);

  @override
  Future<Map<String, dynamic>> uploadAvatar(String filePath) =>
      _tool('upload_avatar', {'file_path': filePath});

  @override
  Future<List<Map<String, dynamic>>> listProjects() async =>
      ((await _tool('list_projects', {}))['projects'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getProject(String id) =>
      _tool('get_project', {'id': id});

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> body) =>
      _tool('create_project', body);

  @override
  Future<Map<String, dynamic>> updateProject(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_project', {'id': id, ...body});

  @override
  Future<void> deleteProject(String id) => _tool('delete_project', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listFeatures({String? projectId}) async =>
      ((await _tool(
                'list_features',
                projectId != null ? {'project_id': projectId} : {},
              ))['features']
              as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getFeature(String id) =>
      _tool('get_feature', {'id': id});

  @override
  Future<Map<String, dynamic>> createFeature(Map<String, dynamic> body) =>
      _tool('create_feature', body);

  @override
  Future<Map<String, dynamic>> updateFeature(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_feature', {'id': id, ...body});

  @override
  Future<void> deleteFeature(String id) => _tool('delete_feature', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listPlans({
    required String projectSlug,
  }) async =>
      ((await _tool('list_plans', {'project_id': projectSlug}))['plans']
              as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<Map<String, dynamic>> getPlan(String projectSlug, String planId) =>
      _tool('get_plan', {'project_id': projectSlug, 'plan_id': planId});

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) =>
      _tool('create_plan', body);

  @override
  Future<Map<String, dynamic>> updatePlan(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_plan', {'id': id, ...body});

  @override
  Future<void> deletePlan(String id) => _tool('delete_plan', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listRequests({
    String? projectSlug,
  }) async =>
      ((await _tool(
                'list_requests',
                projectSlug != null ? {'project_id': projectSlug} : {},
              ))['requests']
              as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<Map<String, dynamic>> getRequest(String id) =>
      _tool('get_request', {'id': id});

  @override
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> body) =>
      _tool('create_request', body);

  @override
  Future<Map<String, dynamic>> updateRequest(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_request', {'id': id, ...body});

  @override
  Future<void> deleteRequest(String id) => _tool('delete_request', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listPersons({String? projectSlug}) async =>
      ((await _tool('list_persons', {
                if (projectSlug != null) 'project_id': projectSlug,
              }))['persons']
              as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<Map<String, dynamic>> getPerson(String id) =>
      _tool('get_person', {'id': id});

  @override
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body) =>
      _tool('create_person', body);

  @override
  Future<Map<String, dynamic>> updatePerson(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_person', {'id': id, ...body});

  @override
  Future<void> deletePerson(String id) => _tool('delete_person', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listNotes() async =>
      ((await _tool('list_notes', {}))['notes'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getNote(String id) =>
      _tool('get_note', {'id': id});

  @override
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> body) =>
      _tool('create_note', body);

  @override
  Future<Map<String, dynamic>> updateNote(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_note', {'id': id, ...body});

  @override
  Future<void> deleteNote(String id) => _tool('delete_note', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listAgents() async =>
      ((await _tool('list_agents', {}))['agents'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getAgent(String id) =>
      _tool('get_agent', {'id': id});

  @override
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> body) =>
      _tool('create_agent', body);

  @override
  Future<Map<String, dynamic>> updateAgent(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_agent', {'id': id, ...body});

  @override
  Future<void> deleteAgent(String id) => _tool('delete_agent', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listSkills() async =>
      ((await _tool('list_skills', {}))['skills'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getSkill(String id) =>
      _tool('get_skill', {'id': id});

  @override
  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> body) =>
      _tool('create_skill', body);

  @override
  Future<Map<String, dynamic>> updateSkill(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_skill', {'id': id, ...body});

  @override
  Future<void> deleteSkill(String id) => _tool('delete_skill', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listWorkflows() async =>
      ((await _tool('list_workflows', {}))['workflows'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getWorkflow(String id) =>
      _tool('get_workflow', {'id': id});

  @override
  Future<Map<String, dynamic>> createWorkflow(Map<String, dynamic> body) =>
      _tool('create_workflow', body);

  @override
  Future<Map<String, dynamic>> updateWorkflow(
    String id,
    Map<String, dynamic> body,
  ) => _tool('update_workflow', {'id': id, ...body});

  @override
  Future<void> deleteWorkflow(String id) =>
      _tool('delete_workflow', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listDocs() async =>
      ((await _tool('list_docs', {}))['docs'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<Map<String, dynamic>> getDoc(String id) =>
      _tool('doc_get', {'id': id});

  @override
  Future<Map<String, dynamic>> createDoc(Map<String, dynamic> body) =>
      _tool('doc_create', body);

  @override
  Future<Map<String, dynamic>> updateDoc(
    String id,
    Map<String, dynamic> body,
  ) => _tool('doc_update', {'id': id, ...body});

  @override
  Future<void> deleteDoc(String id) => _tool('doc_delete', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listSessions() async =>
      ((await _tool('list_sessions', {}))['sessions'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<List<Map<String, dynamic>>> listDelegations() async =>
      ((await _tool('list_delegations', {}))['delegations'] as List)
          .cast<Map<String, dynamic>>();

  @override
  Future<List<Map<String, dynamic>>> listTeams() async {
    final r = await _tool('list_team_members', {});
    final teams = r['teams'];
    if (teams is List) return teams.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Future<Map<String, dynamic>> getMyTeam() => _tool('get_team', {});

  @override
  Future<List<Map<String, dynamic>>> listTeamMembers(String teamId) async {
    final r = await _tool('list_team_members', {'team_id': teamId});
    final members = r['members'];
    if (members is List) return members.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Future<Map<String, dynamic>> createTeam(String name) =>
      _tool('create_team', {'name': name});

  @override
  Future<Map<String, dynamic>> updateTeam(Map<String, dynamic> body) =>
      _tool('update_team', body);

  @override
  Future<void> deleteTeam(String teamId) async =>
      _tool('delete_team', {'team_id': teamId});

  @override
  Future<Map<String, dynamic>> inviteTeamMember(
    String teamId,
    String email, {
    String role = 'member',
  }) => _tool('invite_team_member', {
    'team_id': teamId,
    'email': email,
    'role': role,
  });

  @override
  Future<void> removeTeamMember(String memberId) async =>
      _tool('remove_team_member', {'member_id': memberId});

  @override
  Future<Map<String, dynamic>> updateMemberRole(String memberId, String role) =>
      _tool('update_member_role', {'member_id': memberId, 'role': role});

  @override
  Future<Map<String, dynamic>> getPreferences() => _tool('get_preferences', {});

  @override
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) =>
      _tool('update_preferences', body);

  @override
  Future<List<Map<String, dynamic>>> listSettingsSessions() async =>
      ((await _tool('list_settings_sessions', {}))['sessions'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<void> revokeSession(String id) => _tool('revoke_session', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listApiKeys() async =>
      ((await _tool('list_api_keys', {}))['api_keys'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body) =>
      _tool('create_api_key', body);

  @override
  Future<void> revokeApiKey(String id) => _tool('revoke_api_key', {'id': id});

  @override
  Future<List<Map<String, dynamic>>> listConnectedAccounts() async =>
      ((await _tool('list_connected_accounts', {}))['accounts'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      [];

  @override
  Future<void> unlinkAccount(String provider) =>
      _tool('unlink_account', {'provider': provider});

  @override
  Future<void> changePassword(Map<String, dynamic> body) =>
      _tool('change_password', body);

  // ── Admin ───────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getAdminStats() => _tool('admin_stats', {});
  @override
  Future<Map<String, dynamic>> listAdminUsers({
    String? search,
    String? role,
    String? status,
    int? limit,
    int? offset,
  }) => _tool('list_admin_users', {
    if (search != null) 'search': search,
    if (role != null) 'role': role,
    if (status != null) 'status': status,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> getAdminUser(int id) =>
      _tool('get_admin_user', {'id': id});
  @override
  Future<Map<String, dynamic>> updateAdminUser(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_user', {'id': id, ...body});
  @override
  Future<void> deleteAdminUser(int id) =>
      _tool('delete_admin_user', {'id': id});
  @override
  Future<Map<String, dynamic>> updateAdminUserRole(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_user_role', {'id': id, ...body});
  @override
  Future<Map<String, dynamic>> updateAdminUserStatus(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_user_status', {'id': id, ...body});
  @override
  Future<Map<String, dynamic>> listAdminUserProjects(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminUserNotes(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminUserSessions(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminUserTeams(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminUserIssues(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminUserMemberships(int id) =>
      throw UnimplementedError();
  @override
  Future<void> removeAdminUserMembership(int userId, int teamId) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> changeAdminUserPassword(
    int id,
    Map<String, dynamic> body,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> sendAdminUserNotification(
    int id,
    Map<String, dynamic> body,
  ) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> impersonateAdminUser(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> suspendAdminUser(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> unsuspendAdminUser(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> verifyAdminUser(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> unverifyAdminUser(int id) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> listAdminTeams({
    String? search,
    int? limit,
    int? offset,
  }) => _tool('list_admin_teams', {
    if (search != null) 'search': search,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> getAdminTeam(int id) =>
      _tool('get_admin_team', {'id': id});
  @override
  Future<Map<String, dynamic>> createAdminTeam(Map<String, dynamic> body) =>
      _tool('create_admin_team', body);
  @override
  Future<Map<String, dynamic>> updateAdminTeam(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_team', {'id': id, ...body});
  @override
  Future<void> deleteAdminTeam(int id) =>
      _tool('delete_admin_team', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminTeamMembers(int teamId) =>
      _tool('list_admin_team_members', {'team_id': teamId});
  @override
  Future<Map<String, dynamic>> addAdminTeamMember(
    int teamId,
    Map<String, dynamic> body,
  ) => _tool('add_admin_team_member', {'team_id': teamId, ...body});
  @override
  Future<void> removeAdminTeamMember(int teamId, int userId) =>
      _tool('remove_admin_team_member', {'team_id': teamId, 'user_id': userId});
  @override
  Future<Map<String, dynamic>> listAdminSettings({
    String? search,
    String? category,
    int? limit,
    int? offset,
  }) => _tool('list_admin_settings', {
    if (search != null) 'search': search,
    if (category != null) 'category': category,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> upsertAdminSetting(Map<String, dynamic> body) =>
      _tool('upsert_admin_setting', body);
  @override
  Future<Map<String, dynamic>> getAdminSetting(String key) =>
      _tool('get_admin_setting', {'key': key});
  @override
  Future<Map<String, dynamic>> patchAdminSetting(
    String key,
    Map<String, dynamic> body,
  ) => _tool('patch_admin_setting', {'key': key, ...body});
  @override
  Future<Map<String, dynamic>> updateAdminSetting(
    String key,
    Map<String, dynamic> value,
  ) => patchAdminSetting(key, value);
  @override
  Future<void> deleteAdminSetting(String key) =>
      _tool('delete_admin_setting', {'key': key});
  @override
  Future<Map<String, dynamic>> testEmail() => _tool('test_email', {});
  @override
  Future<Map<String, dynamic>> listAdminPages({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _tool('list_admin_pages', {
    if (search != null) 'search': search,
    if (status != null) 'status': status,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> getAdminPage(int id) =>
      _tool('get_admin_page', {'id': id});
  @override
  Future<Map<String, dynamic>> createAdminPage(Map<String, dynamic> body) =>
      _tool('create_admin_page', body);
  @override
  Future<Map<String, dynamic>> updateAdminPage(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_page', {'id': id, ...body});
  @override
  Future<void> deleteAdminPage(int id) =>
      _tool('delete_admin_page', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminCategories({
    String? search,
    int? limit,
    int? offset,
  }) => _tool('list_admin_categories', {
    if (search != null) 'search': search,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> body) =>
      _tool('create_admin_category', body);
  @override
  Future<Map<String, dynamic>> updateAdminCategory(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_category', {'id': id, ...body});
  @override
  Future<void> deleteAdminCategory(int id) =>
      _tool('delete_admin_category', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminContact({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _tool('list_admin_contact', {
    if (search != null) 'search': search,
    if (status != null) 'status': status,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> updateAdminContactStatus(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_contact_status', {'id': id, ...body});
  @override
  Future<void> deleteAdminContactMessage(int id) =>
      _tool('delete_admin_contact', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminIssues({
    String? search,
    String? status,
    String? priority,
    int? limit,
    int? offset,
  }) => _tool('list_admin_issues', {
    if (search != null) 'search': search,
    if (status != null) 'status': status,
    if (priority != null) 'priority': priority,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> updateAdminIssueStatus(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_issue_status', {'id': id, ...body});
  @override
  Future<Map<String, dynamic>> listAdminNotifications({
    int? limit,
    int? offset,
  }) => _tool('list_admin_notifications', {
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> createAdminNotification(
    Map<String, dynamic> body,
  ) => _tool('create_admin_notification', body);
  @override
  Future<Map<String, dynamic>> listAdminSponsors({
    String? search,
    String? tier,
    String? status,
    int? limit,
    int? offset,
  }) => _tool('list_admin_sponsors', {
    if (search != null) 'search': search,
    if (tier != null) 'tier': tier,
    if (status != null) 'status': status,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> createAdminSponsor(Map<String, dynamic> body) =>
      _tool('create_admin_sponsor', body);
  @override
  Future<Map<String, dynamic>> updateAdminSponsor(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_sponsor', {'id': id, ...body});
  @override
  Future<void> deleteAdminSponsor(int id) =>
      _tool('delete_admin_sponsor', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminCommunityPosts({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _tool('list_admin_community_posts', {
    if (search != null) 'search': search,
    if (status != null) 'status': status,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> updateAdminCommunityPost(
    int id,
    Map<String, dynamic> body,
  ) => _tool('update_admin_community_post', {'id': id, ...body});
  @override
  Future<void> deleteAdminCommunityPost(int id) =>
      _tool('delete_admin_community_post', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminGitHubIssues({
    String? repo,
    String? state,
    String? type,
    int? limit,
    int? offset,
  }) => _tool('list_admin_github_issues', {
    if (repo != null) 'repo': repo,
    if (state != null) 'state': state,
    if (type != null) 'type': type,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  });
  @override
  Future<Map<String, dynamic>> syncAdminGitHub({String? repo}) =>
      _tool('sync_admin_github', {if (repo != null) 'repo': repo});
  @override
  Future<void> deleteAdminGitHubIssue(int id) =>
      _tool('delete_admin_github_issue', {'id': id});
  @override
  Future<Map<String, dynamic>> listAdminGitHubRepos() =>
      _tool('list_admin_github_repos', {});

  // ── Health ──────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getHealthProfile() =>
      _tool('get_health_profile', {});
  @override
  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> body) =>
      _tool('update_health_profile', body);
  @override
  Future<Map<String, dynamic>> logWater(Map<String, dynamic> body) =>
      _tool('log_water', body);
  @override
  Future<List<Map<String, dynamic>>> listWaterLogs({String? date}) async =>
      (((await _tool('list_water_logs', {
                    if (date != null) 'date': date,
                  }))['items']
                  as List?) ??
              [])
          .cast<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getHydrationStatus() =>
      _tool('get_hydration_status', {});
  @override
  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> body) =>
      _tool('log_meal', body);
  @override
  Future<List<Map<String, dynamic>>> listMealLogs({String? date}) async =>
      (((await _tool('list_meal_logs', {
                    if (date != null) 'date': date,
                  }))['items']
                  as List?) ??
              [])
          .cast<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> logCaffeine(Map<String, dynamic> body) =>
      _tool('log_caffeine', body);
  @override
  Future<List<Map<String, dynamic>>> listCaffeineLogs({String? date}) async =>
      (((await _tool('list_caffeine_logs', {
                    if (date != null) 'date': date,
                  }))['items']
                  as List?) ??
              [])
          .cast<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getCaffeineScore() =>
      _tool('get_caffeine_score', {});
  @override
  Future<Map<String, dynamic>> startPomodoro() => _tool('start_pomodoro', {});
  @override
  Future<Map<String, dynamic>> endPomodoro(String id) =>
      _tool('end_pomodoro', {'id': id});
  @override
  Future<List<Map<String, dynamic>>> listPomodoroSessions({
    String? date,
  }) async =>
      (((await _tool('list_pomodoro_sessions', {
                    if (date != null) 'date': date,
                  }))['items']
                  as List?) ??
              [])
          .cast<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getShutdownStatus() =>
      _tool('get_shutdown_status', {});
  @override
  Future<Map<String, dynamic>> startShutdown() => _tool('start_shutdown', {});
  @override
  Future<Map<String, dynamic>> upsertSnapshot(Map<String, dynamic> body) =>
      _tool('upsert_snapshot', body);
  @override
  Future<List<Map<String, dynamic>>> listSnapshots({
    String? from,
    String? to,
  }) async =>
      (((await _tool('list_snapshots', {
                    if (from != null) 'from': from,
                    if (to != null) 'to': to,
                  }))['items']
                  as List?) ??
              [])
          .cast<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getHealthSummary() =>
      _tool('get_health_summary', {});

  // ── Search / Sync ──────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> search(String query, {String? scope}) =>
      _tool('search', {'query': query, if (scope != null) 'scope': scope});
  @override
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> body) =>
      _tool('push_sync', body);
  @override
  Future<Map<String, dynamic>> pullSync({String? since}) =>
      _tool('pull_sync', {if (since != null) 'since': since});
}
