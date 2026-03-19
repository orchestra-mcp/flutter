import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/terminal/claude_terminal_backend.dart';
import 'package:orchestra/features/terminal/mcp_terminal_backend.dart';
import 'package:orchestra/features/terminal/pty_terminal_backend.dart';
import 'package:orchestra/features/terminal/remote_terminal_backend.dart';
import 'package:orchestra/features/terminal/ssh_terminal_backend.dart';
import 'package:orchestra/features/terminal/terminal_backend.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:xterm/xterm.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Manages the list of active terminal sessions (local, SSH, Claude).
final terminalSessionsProvider =
    NotifierProvider<TerminalSessionsNotifier, List<TerminalSessionModel>>(
      TerminalSessionsNotifier.new,
    );

/// The ID of the currently visible / active terminal tab.
final activeTerminalIdProvider = NotifierProvider<_ActiveTerminalId, String?>(
  _ActiveTerminalId.new,
);

class _ActiveTerminalId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Riverpod notifier that creates, removes, and manages terminal sessions.
///
/// Uses native backends: flutter_pty for local shells, dartssh2 for SSH,
/// and MCP for Claude AI chat.
class TerminalSessionsNotifier extends Notifier<List<TerminalSessionModel>> {
  int _counter = 0;
  final Map<String, TerminalBackend> _backends = {};
  final Map<String, TerminalController> _controllers = {};
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  List<TerminalSessionModel> build() => [];

  /// Backend registry — used by content widget to get the xterm Terminal.
  Map<String, TerminalBackend> get backends => _backends;

  /// Controller registry — used for selection, search highlights, etc.
  Map<String, TerminalController> get controllers => _controllers;

  /// Scroll controller registry — used for search navigation.
  Map<String, ScrollController> get scrollControllers => _scrollControllers;

  String _nextId(String prefix) {
    _counter++;
    return '$prefix-$_counter';
  }

  void _createControllers(String id) {
    _controllers[id] = TerminalController();
    _scrollControllers[id] = ScrollController();
  }

  void _disposeControllers(String id) {
    _controllers.remove(id)?.dispose();
    _scrollControllers.remove(id)?.dispose();
  }

  /// Wire terminal events (title change) to update session metadata.
  void _wireTerminalEvents(String id, Terminal terminal) {
    terminal.onTitleChange = (title) {
      if (title.isNotEmpty) renameSession(id, title);
    };
  }

  // ── Local terminal ───────────────────────────────────────────────────────

  /// Creates a new local terminal session via flutter_pty.
  /// Desktop only — mobile uses [createRemoteSession] via tunnel.
  Future<TerminalSessionModel> createTerminalSession({String? shell}) async {
    if (!isDesktop) {
      throw StateError('Local terminal is only available on desktop');
    }

    final id = _nextId('term');
    final workspacePath = ref.read(workspacePathProvider);
    final session = TerminalSessionModel(
      id: id,
      type: TerminalSessionType.terminal,
      status: TerminalSessionStatus.connecting,
      label: shell ?? 'Terminal',
      createdAt: DateTime.now(),
    );
    state = [...state, session];

    _createControllers(id);
    try {
      final backend = PtyTerminalBackend(
        shell: shell,
        workingDirectory: workspacePath,
      );
      _backends[id] = backend;
      await backend.start();
      _wireTerminalEvents(id, backend.terminal);

      final connected = session.copyWith(
        status: TerminalSessionStatus.connected,
      );
      _replaceSession(id, connected);
      return connected;
    } catch (e) {
      debugPrint('[TerminalSessions] createTerminalSession error: $e');
      final errored = session.copyWith(status: TerminalSessionStatus.error);
      _replaceSession(id, errored);
      return errored;
    }
  }

  // ── MCP terminal (shared across devices) ─────────────────────────────────

  /// Creates a terminal session through the Go PTY manager via MCP.
  /// These sessions are visible from both desktop and mobile.
  Future<TerminalSessionModel> _createMcpTerminalSession(
    dynamic mcp, {
    String? shell,
  }) async {
    final id = _nextId('term');
    final session = TerminalSessionModel(
      id: id,
      type: TerminalSessionType.terminal,
      status: TerminalSessionStatus.connecting,
      label: shell ?? 'Terminal',
      createdAt: DateTime.now(),
    );
    state = [...state, session];

    _createControllers(id);
    try {
      final backend = McpTerminalBackend(
        callTool: (name, args) async {
          final raw = await mcp.callTool(name, args);
          // Unwrap MCP content envelope:
          // {"content": [{"type": "text", "text": "{\"terminal_id\":\"...\"}"}]}
          if (raw is Map<String, dynamic>) {
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
          return <String, dynamic>{};
        },
        shell: shell,
      );
      _backends[id] = backend;
      await backend.start();
      _wireTerminalEvents(id, backend.terminal);

      final connected = session.copyWith(
        status: TerminalSessionStatus.connected,
      );
      _replaceSession(id, connected);
      return connected;
    } catch (e) {
      debugPrint('[TerminalSessions] createMcpTerminalSession error: $e');
      final errored = session.copyWith(status: TerminalSessionStatus.error);
      _replaceSession(id, errored);
      return errored;
    }
  }

  // ── SSH session ──────────────────────────────────────────────────────────

  /// Creates an SSH session via dartssh2.
  Future<TerminalSessionModel> createSshSession({
    required String host,
    required String user,
    int port = 22,
    String? password,
    String? keyFile,
  }) async {
    final id = _nextId('ssh');
    final session = TerminalSessionModel(
      id: id,
      type: TerminalSessionType.ssh,
      status: TerminalSessionStatus.connecting,
      label: '$user@$host',
      createdAt: DateTime.now(),
      sshHost: host,
      sshUser: user,
      sshPort: port,
      sshPassword: password,
      sshKeyFile: keyFile,
    );
    state = [...state, session];

    _createControllers(id);
    try {
      final backend = SshTerminalBackend(
        host: host,
        username: user,
        port: port,
        password: password,
        keyFile: keyFile,
      );
      _backends[id] = backend;
      await backend.start();
      _wireTerminalEvents(id, backend.terminal);

      final connected = session.copyWith(
        status: TerminalSessionStatus.connected,
      );
      _replaceSession(id, connected);
      return connected;
    } catch (e) {
      debugPrint('[TerminalSessions] createSshSession error: $e');
      final errored = session.copyWith(status: TerminalSessionStatus.error);
      _replaceSession(id, errored);
      return errored;
    }
  }

  // ── Claude session ───────────────────────────────────────────────────────

  /// Creates a Claude Code session — launches `claude` CLI as a native PTY.
  /// Desktop only.
  Future<TerminalSessionModel> createClaudeSession({
    String model = 'claude-sonnet-4-6',
  }) async {
    if (!isDesktop) {
      throw StateError('Claude Code terminal is only available on desktop');
    }

    final id = _nextId('claude');
    final workspacePath = ref.read(workspacePathProvider);
    final session = TerminalSessionModel(
      id: id,
      type: TerminalSessionType.claude,
      status: TerminalSessionStatus.connecting,
      label: 'Claude Code',
      createdAt: DateTime.now(),
      claudeModel: model,
    );
    state = [...state, session];

    _createControllers(id);
    try {
      final backend = ClaudeTerminalBackend(
        model: model,
        workingDirectory: workspacePath,
      );
      _backends[id] = backend;
      await backend.start();
      _wireTerminalEvents(id, backend.terminal);

      final connected = session.copyWith(
        status: TerminalSessionStatus.connected,
      );
      _replaceSession(id, connected);
      return connected;
    } catch (e) {
      debugPrint('[TerminalSessions] createClaudeSession error: $e');
      final errored = session.copyWith(status: TerminalSessionStatus.error);
      _replaceSession(id, errored);
      return errored;
    }
  }

  // ── Remote terminal ────────────────────────────────────────────────────

  /// Creates a remote terminal session via WebSocket.
  ///
  /// Connects to the desktop's orchestra serve web-gate directly (local dev)
  /// or via the tunnel proxy (cloud). The Go PTY manager spawns the shell.
  Future<TerminalSessionModel> createRemoteSession({
    required String tunnelId,
    required String baseUrl,
    required String authToken,
    String? shell,
  }) async {
    final id = _nextId('remote');
    final session = TerminalSessionModel(
      id: id,
      type: TerminalSessionType.remote,
      status: TerminalSessionStatus.connecting,
      label: 'Remote Terminal',
      createdAt: DateTime.now(),
      remoteTunnelId: tunnelId,
    );
    state = [...state, session];

    _createControllers(id);
    try {
      // baseUrl is now the full WebSocket URL.
      final backend = RemoteTerminalBackend(wsUrl: baseUrl, shell: shell);
      _backends[id] = backend;
      await backend.start();
      _wireTerminalEvents(id, backend.terminal);

      final connected = session.copyWith(
        status: TerminalSessionStatus.connected,
      );
      _replaceSession(id, connected);
      return connected;
    } catch (e) {
      debugPrint('[TerminalSessions] createRemoteSession error: $e');
      final errored = session.copyWith(status: TerminalSessionStatus.error);
      _replaceSession(id, errored);
      return errored;
    }
  }

  // ── Remove ───────────────────────────────────────────────────────────────

  /// Disposes the backend, controllers, and removes the session from state.
  Future<void> removeSession(String id) async {
    final backend = _backends.remove(id);
    if (backend != null) {
      try {
        await backend.dispose();
      } catch (e) {
        debugPrint('[TerminalSessions] removeSession cleanup error: $e');
      }
    }
    _disposeControllers(id);

    state = state.where((s) => s.id != id).toList();

    final activeId = ref.read(activeTerminalIdProvider);
    if (activeId == id) {
      ref
          .read(activeTerminalIdProvider.notifier)
          .set(state.isNotEmpty ? state.last.id : null);
    }
  }

  // ── Status updates ───────────────────────────────────────────────────────

  void updateSessionStatus(String id, TerminalSessionStatus status) {
    _replaceSession(
      id,
      state.where((s) => s.id == id).firstOrNull?.copyWith(status: status),
    );
  }

  // ── Rename ─────────────────────────────────────────────────────────────

  void renameSession(String id, String newLabel) {
    _replaceSession(
      id,
      state.where((s) => s.id == id).firstOrNull?.copyWith(label: newLabel),
    );
  }

  // ── Pin / Unpin ────────────────────────────────────────────────────────

  void togglePin(String id) {
    final session = state.where((s) => s.id == id).firstOrNull;
    if (session == null) return;
    _replaceSession(id, session.copyWith(pinned: !session.pinned));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _replaceSession(String id, TerminalSessionModel? replacement) {
    final updated = <TerminalSessionModel>[];
    for (final s in state) {
      if (s.id == id) {
        if (replacement != null) updated.add(replacement);
      } else {
        updated.add(s);
      }
    }
    state = updated;
  }
}
