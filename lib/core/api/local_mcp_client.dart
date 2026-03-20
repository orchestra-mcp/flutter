import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:sqlite3/sqlite3.dart';

/// Desktop [ApiClient] that reads directly from the Orchestra SQLite databases.
///
/// Two databases are used:
/// - **Workspace DB** at `~/.orchestra/db/<sha256(workspace)[:16]>.db` — project
///   data (features, plans, notes, persons, etc.) scoped to the open workspace.
/// - **Global DB** at `~/.orchestra/db/global.db` — cross-workspace config
///   (workflows, accounts, secrets, workspaces).
///
/// Records include a `db_source` field: `"workspace"` or `"global"` so the UI
/// can show a badge indicating where the data lives.
///
/// The optional [restClient] is used **only** for write operations that require
/// the web-gate API (settings, admin, profile updates, auth, health).
class LocalMcpClient implements ApiClient {
  LocalMcpClient({required this.workspacePath, this.restClient});

  final String workspacePath;

  /// REST client for operations that require the web-gate API.
  /// Used only for settings, admin, profile updates, auth, and health —
  /// **never** for workspace data reads.
  final ApiClient? restClient;

  // ── Workspace DB ─────────────────────────────────────────────────────────
  Database? _db;

  /// Whether we already tried and failed to open the workspace DB.
  bool _dbFailed = false;

  // ── Global DB ─────────────────────────────────────────────────────────────
  Database? _globalDb;

  /// Whether we already tried and failed to open the global DB.
  bool _globalDbFailed = false;

  /// Resolve the real user home directory.
  ///
  /// On macOS sandboxed apps, `$HOME` points to the container
  /// (`~/Library/Containers/<bundle>/Data`). The Orchestra DB lives at the
  /// real `~/.orchestra/`, so we strip the container suffix when detected.
  static String get _realHome {
    final env = Platform.environment['HOME'] ?? '/tmp';
    // Sandboxed macOS: /Users/<user>/Library/Containers/<id>/Data
    final containerMatch = RegExp(
      r'^(/Users/[^/]+)/Library/Containers/.+/Data$',
    );
    final match = containerMatch.firstMatch(env);
    if (match != null) return match.group(1)!;
    return env;
  }

  // ── Database lifecycle ──────────────────────────────────────────────────

  Database get _database {
    if (_db != null) return _db!;
    if (_dbFailed) throw StateError('DB previously failed to open');

    final absPath = Directory(
      workspacePath,
    ).absolute.path.replaceAll(RegExp(r'/$'), '');
    final hash = sha256
        .convert(utf8.encode(absPath))
        .toString()
        .substring(0, 16);
    final home = _realHome;
    final dbPath = '$home/.orchestra/db/$hash.db';

    debugPrint(
      '[LocalMcpClient] DB path: $dbPath (home=$home, workspace=$absPath)',
    );

    if (!File(dbPath).existsSync()) {
      _dbFailed = true;
      throw StateError(
        'Orchestra DB not found at $dbPath — run `orchestra init` first',
      );
    }

    try {
      _db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    } catch (e) {
      _dbFailed = true;
      debugPrint('[LocalMcpClient] Failed to open DB: $e');
      rethrow;
    }
    return _db!;
  }

  Database get _globalDatabase {
    if (_globalDb != null) return _globalDb!;
    if (_globalDbFailed)
      throw StateError('Global DB previously failed to open');

    final home = _realHome;
    final dbPath = '$home/.orchestra/db/global.db';

    debugPrint('[LocalMcpClient] Global DB path: $dbPath');

    if (!File(dbPath).existsSync()) {
      _globalDbFailed = true;
      throw StateError(
        'Orchestra global DB not found at $dbPath — run `orchestra init` first',
      );
    }

    try {
      _globalDb = sqlite3.open(dbPath, mode: OpenMode.readOnly);
    } catch (e) {
      _globalDbFailed = true;
      debugPrint('[LocalMcpClient] Failed to open global DB: $e');
      rethrow;
    }
    return _globalDb!;
  }

  void close() {
    _db?.dispose();
    _db = null;
    _globalDb?.dispose();
    _globalDb = null;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _query(
    String sql, [
    List<Object?> params = const [],
  ]) {
    final stmt = _database.prepare(sql);
    try {
      final rows = stmt.select(params);
      return rows.map((row) {
        final map = <String, dynamic>{};
        for (final col in row.keys) {
          map[col] = row[col];
        }
        return map;
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  List<Map<String, dynamic>> _queryGlobal(
    String sql, [
    List<Object?> params = const [],
  ]) {
    final stmt = _globalDatabase.prepare(sql);
    try {
      final rows = stmt.select(params);
      return rows.map((row) {
        final map = <String, dynamic>{};
        for (final col in row.keys) {
          map[col] = row[col];
        }
        return map;
      }).toList();
    } finally {
      stmt.dispose();
    }
  }

  Map<String, dynamic>? _queryOne(
    String sql, [
    List<Object?> params = const [],
  ]) {
    final rows = _query(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  Map<String, dynamic>? _queryGlobalOne(
    String sql, [
    List<Object?> params = const [],
  ]) {
    final rows = _queryGlobal(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  List<String> _parseJsonArray(dynamic raw) {
    if (raw == null || raw == '' || raw == 'null') return [];
    try {
      final list = jsonDecode(raw as String);
      if (list is List) return list.cast<String>();
    } catch (_) {}
    return [];
  }

  // ── Auth (not applicable for local DB — stubs) ─────────────────────────

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> body) =>
      throw UnsupportedError('Auth is not available via local MCP client');

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      throw UnsupportedError('Auth is not available via local MCP client');

  @override
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) =>
      throw UnsupportedError('Auth is not available via local MCP client');

  // ── Profile ─────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getProfile() async {
    // Read from ~/.orchestra/me.json (person profile)
    final home = _realHome;
    final file = File('$home/.orchestra/me.json');
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _rest.updateProfile(body);

  @override
  Future<Map<String, dynamic>> updateSettingsProfile(
    Map<String, dynamic> body,
  ) => _rest.updateSettingsProfile(body);

  @override
  Future<Map<String, dynamic>> uploadAvatar(String filePath) =>
      _rest.uploadAvatar(filePath);

  // ── Projects ────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listProjects() async {
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT slug AS id, slug, name, description, metadata, version, '
        'created_at, updated_at FROM projects ORDER BY name',
      );
    } catch (e) {
      debugPrint('[LocalMcpClient] listProjects error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getProject(String id) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT slug AS id, slug, name, description, metadata, version, '
        'created_at, updated_at FROM projects WHERE slug = ?',
        [id],
      );
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getProject error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> body) =>
      _rest.createProject(body);

  @override
  Future<Map<String, dynamic>> updateProject(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateProject(id, body);

  @override
  Future<void> deleteProject(String id) => _rest.deleteProject(id);

  // ── Features ────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listFeatures({String? projectId}) async {
    if (projectId == null) return [];
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT id, project_id, title, description, status, priority, kind, '
        'assignee, estimate, labels, depends_on, body, version, '
        'created_at, updated_at '
        'FROM features WHERE project_id = ? ORDER BY updated_at DESC',
        [projectId],
      ).map((row) {
        row['labels'] = _parseJsonArray(row['labels']);
        row['depends_on'] = _parseJsonArray(row['depends_on']);
        return row;
      }).toList();
    } catch (e) {
      debugPrint('[LocalMcpClient] listFeatures error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getFeature(String id) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT id, project_id, title, description, status, priority, kind, '
        'assignee, estimate, labels, depends_on, body, version, '
        'created_at, updated_at '
        'FROM features WHERE id = ?',
        [id],
      );
      if (row != null) {
        row['labels'] = _parseJsonArray(row['labels']);
        row['depends_on'] = _parseJsonArray(row['depends_on']);
      }
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getFeature error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createFeature(Map<String, dynamic> body) =>
      _rest.createFeature(body);

  @override
  Future<Map<String, dynamic>> updateFeature(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateFeature(id, body);

  @override
  Future<void> deleteFeature(String id) => _rest.deleteFeature(id);

  // ── Plans ───────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listPlans({
    required String projectSlug,
  }) async {
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT id, project_id, title, description, status, '
        'created_at, updated_at '
        'FROM plans WHERE project_id = ? ORDER BY updated_at DESC',
        [projectSlug],
      );
    } catch (e) {
      debugPrint('[LocalMcpClient] listPlans error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPlan(
    String projectSlug,
    String planId,
  ) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT id, project_id, title, description, status, body, '
        'created_at, updated_at '
        'FROM plans WHERE id = ?',
        [planId],
      );
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getPlan error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) =>
      _rest.createPlan(body);

  @override
  Future<Map<String, dynamic>> updatePlan(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updatePlan(id, body);

  @override
  Future<void> deletePlan(String id) => _rest.deletePlan(id);

  // ── Requests ────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listRequests({String? projectSlug}) async {
    if (_dbFailed) return [];
    try {
      final where = projectSlug != null ? 'WHERE project_id = ?' : '';
      final params = projectSlug != null ? [projectSlug] : <Object>[];
      return _query(
        'SELECT id, project_id, title, kind, priority, status, '
        'created_at, updated_at '
        'FROM requests $where ORDER BY created_at DESC',
        params,
      );
    } catch (e) {
      debugPrint('[LocalMcpClient] listRequests error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getRequest(String id) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT id, project_id, title, kind, priority, status, body, '
        'created_at, updated_at '
        'FROM requests WHERE id = ?',
        [id],
      );
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getRequest error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> body) =>
      _rest.createRequest(body);

  @override
  Future<Map<String, dynamic>> updateRequest(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateRequest(id, body);

  @override
  Future<void> deleteRequest(String id) => _rest.deleteRequest(id);

  // ── Persons ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listPersons({String? projectSlug}) async {
    if (_dbFailed) return [];
    try {
      if (projectSlug != null) {
        return _query(
          'SELECT id, name, role, email, github_email, bio, '
          'created_at, updated_at '
          'FROM persons WHERE project_id = ? ORDER BY name',
          [projectSlug],
        );
      }
      return _query(
        'SELECT id, name, role, email, github_email, bio, '
        'created_at, updated_at '
        'FROM persons ORDER BY name',
      );
    } catch (e) {
      debugPrint('[LocalMcpClient] listPersons error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPerson(String id) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT id, name, role, email, github_email, bio, '
        'created_at, updated_at '
        'FROM persons WHERE id = ?',
        [id],
      );
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getPerson error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body) =>
      _rest.createPerson(body);

  @override
  Future<Map<String, dynamic>> updatePerson(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updatePerson(id, body);

  @override
  Future<void> deletePerson(String id) => _rest.deletePerson(id);

  // ── Notes ───────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listNotes() async {
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT id, project_id, title, body, pinned, tags, icon, color, '
        'version, created_at, updated_at '
        'FROM notes WHERE deleted = 0 ORDER BY pinned DESC, updated_at DESC',
      ).map((row) {
        row['pinned'] = (row['pinned'] as int?) == 1;
        row['tags'] = _parseJsonArray(row['tags']);
        row['db_source'] = 'workspace';
        return row;
      }).toList();
    } catch (e) {
      debugPrint('[LocalMcpClient] listNotes error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getNote(String id) async {
    if (_dbFailed) return {};
    try {
      final row = _queryOne(
        'SELECT id, project_id, title, body, pinned, tags, icon, color, '
        'version, created_at, updated_at '
        'FROM notes WHERE id = ? AND deleted = 0',
        [id],
      );
      if (row != null) {
        row['pinned'] = (row['pinned'] as int?) == 1;
        row['tags'] = _parseJsonArray(row['tags']);
        row['db_source'] = 'workspace';
      }
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getNote error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> body) =>
      _rest.createNote(body);

  @override
  Future<Map<String, dynamic>> updateNote(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateNote(id, body);

  @override
  Future<void> deleteNote(String id) => _rest.deleteNote(id);

  // ── Library (reads from workspace filesystem) ──────────────────────────

  /// Extracts YAML frontmatter fields from a markdown file.
  /// Returns a map of key→value for single-line `key: value` entries.
  static Map<String, String> _parseFrontmatter(String content) {
    final fm = <String, String>{};
    if (!content.startsWith('---')) return fm;
    final endIdx = content.indexOf('---', 3);
    if (endIdx < 0) return fm;
    final block = content.substring(3, endIdx);
    final buf = StringBuffer();
    String? currentKey;
    for (final line in block.split('\n')) {
      final trimmed = line.trimRight();
      // Multi-line continuation (indented)
      if (currentKey != null && trimmed.startsWith('  ')) {
        buf.write(' ${trimmed.trim()}');
        continue;
      }
      // Flush previous key
      if (currentKey != null) {
        fm[currentKey] = buf.toString().trim();
        buf.clear();
        currentKey = null;
      }
      final sep = trimmed.indexOf(':');
      if (sep < 0) continue;
      final key = trimmed.substring(0, sep).trim();
      var val = trimmed.substring(sep + 1).trim();
      if (val == '>-' || val == '|') {
        // Block scalar — collect following indented lines
        currentKey = key;
        continue;
      }
      // Strip optional quotes
      if (val.startsWith('"') && val.endsWith('"'))
        val = val.substring(1, val.length - 1);
      if (val.startsWith("'") && val.endsWith("'"))
        val = val.substring(1, val.length - 1);
      fm[key] = val;
    }
    if (currentKey != null) fm[currentKey] = buf.toString().trim();
    return fm;
  }

  static String _titleFromSlug(String slug) {
    final words = slug.split('-');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns the body content after the YAML frontmatter block.
  static String _bodyAfterFrontmatter(String content) {
    if (!content.startsWith('---')) return content;
    final endIdx = content.indexOf('---', 3);
    if (endIdx < 0) return content;
    return content.substring(endIdx + 3).trim();
  }

  @override
  Future<Map<String, dynamic>> getAgent(String id) async {
    final agents = await listAgents();
    return agents.firstWhere(
      (a) => a['id'] == id || a['slug'] == id,
      orElse: () => {},
    );
  }

  @override
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> body) =>
      _rest.createAgent(body);

  @override
  Future<Map<String, dynamic>> updateAgent(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateAgent(id, body);

  @override
  Future<void> deleteAgent(String id) =>
      throw UnimplementedError('Requires MCP connection');

  @override
  Future<Map<String, dynamic>> getSkill(String id) async {
    final skills = await listSkills();
    return skills.firstWhere(
      (s) => s['id'] == id || s['slug'] == id,
      orElse: () => {},
    );
  }

  @override
  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> body) =>
      _rest.createSkill(body);

  @override
  Future<Map<String, dynamic>> updateSkill(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateSkill(id, body);

  @override
  Future<void> deleteSkill(String id) =>
      throw UnimplementedError('Requires MCP connection');

  @override
  Future<Map<String, dynamic>> getWorkflow(String id) async {
    if (_globalDbFailed) return {};
    try {
      final row = _queryGlobalOne(
        'SELECT id, project_id, name, description, initial_state, '
        'states, transitions, gates, is_default, '
        'created_at, updated_at '
        'FROM workflows WHERE id = ?',
        [id],
      );
      if (row != null) {
        for (final key in ['states', 'transitions', 'gates']) {
          final raw = row[key];
          if (raw is String && raw.isNotEmpty) {
            try {
              row[key] = jsonDecode(raw);
            } catch (_) {}
          }
        }
        row['is_default'] = (row['is_default'] as int?) == 1;
        row['db_source'] = 'global';
      }
      return row ?? {};
    } catch (e) {
      debugPrint('[LocalMcpClient] getWorkflow error: $e');
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> createWorkflow(Map<String, dynamic> body) =>
      throw UnimplementedError(
        'Workflow creation requires MCP tool call — use McpTcpClient',
      );

  @override
  Future<Map<String, dynamic>> updateWorkflow(
    String id,
    Map<String, dynamic> body,
  ) => throw UnimplementedError(
    'Workflow update requires MCP tool call — use McpTcpClient',
  );

  @override
  Future<void> deleteWorkflow(String id) => throw UnimplementedError(
    'Workflow deletion requires MCP tool call — use McpTcpClient',
  );

  @override
  Future<Map<String, dynamic>> getDoc(String id) async {
    final docs = await listDocs();
    return docs.firstWhere(
      (d) => d['id'] == id || d['slug'] == id,
      orElse: () => {},
    );
  }

  @override
  Future<Map<String, dynamic>> createDoc(Map<String, dynamic> body) =>
      _rest.createDoc(body);

  @override
  Future<Map<String, dynamic>> updateDoc(
    String id,
    Map<String, dynamic> body,
  ) => _rest.updateDoc(id, body);

  @override
  Future<void> deleteDoc(String id) =>
      throw UnimplementedError('Requires MCP connection');

  @override
  Future<List<Map<String, dynamic>>> listAgents() async {
    try {
      final dir = Directory('$workspacePath/.claude/agents');
      if (!dir.existsSync()) return [];
      final items = <Map<String, dynamic>>[];
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.md')) continue;
        final filename = f.uri.pathSegments.last;
        final slug = filename.replaceAll('.md', '');
        final content = f.readAsStringSync();
        final fm = _parseFrontmatter(content);
        final name = fm['name'] ?? _titleFromSlug(slug);
        final body = _bodyAfterFrontmatter(content);
        items.add({
          'id': slug,
          'name': _titleFromSlug(name),
          'slug': slug,
          'description': fm['description'] ?? '',
          'system_prompt': body,
          'path': f.path,
          'db_source': 'workspace',
        });
      }
      items.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
      return items;
    } catch (e) {
      debugPrint('[LocalMcpClient] listAgents error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listSkills() async {
    try {
      final dir = Directory('$workspacePath/.claude/skills');
      if (!dir.existsSync()) return [];
      final items = <Map<String, dynamic>>[];
      for (final d in dir.listSync().whereType<Directory>()) {
        final slug = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
        // Try reading SKILL.md for metadata
        final skillFile = File('${d.path}/SKILL.md');
        String description = '';
        String name = _titleFromSlug(slug);
        String body = '';
        if (skillFile.existsSync()) {
          final content = skillFile.readAsStringSync();
          final fm = _parseFrontmatter(content);
          if (fm['name'] != null) name = _titleFromSlug(fm['name']!);
          description = fm['description'] ?? '';
          body = _bodyAfterFrontmatter(content);
        }
        items.add({
          'id': slug,
          'name': name,
          'slug': slug,
          'description': body.isNotEmpty ? body : description,
          'command': '/$slug',
          'source': '.claude/skills/$slug/',
          'path': d.path,
          'db_source': 'workspace',
        });
      }
      items.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
      return items;
    } catch (e) {
      debugPrint('[LocalMcpClient] listSkills error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listWorkflows() async {
    if (_globalDbFailed) return [];
    try {
      return _queryGlobal(
        'SELECT id, project_id, name, description, initial_state, '
        'states, transitions, gates, is_default, '
        'created_at, updated_at '
        'FROM workflows ORDER BY updated_at DESC',
      ).map((row) {
        // Parse JSON string fields into actual objects
        for (final key in ['states', 'transitions', 'gates']) {
          final raw = row[key];
          if (raw is String && raw.isNotEmpty) {
            try {
              row[key] = jsonDecode(raw);
            } catch (_) {}
          }
        }
        // Convert SQLite integer to bool
        row['is_default'] = (row['is_default'] as int?) == 1;
        // Tag with source so UI can show a badge
        row['db_source'] = 'global';
        return row;
      }).toList();
    } catch (e) {
      debugPrint('[LocalMcpClient] listWorkflows error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listDocs() async {
    try {
      final dir = Directory('$workspacePath/docs');
      if (!dir.existsSync()) return [];
      final items = <Map<String, dynamic>>[];
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.md')) continue;
        final filename = f.uri.pathSegments.last;
        final slug = filename.replaceAll('.md', '');
        final content = f.readAsStringSync();
        // Try to get title from first # heading or frontmatter
        final fm = _parseFrontmatter(content);
        String title = fm['title'] ?? '';
        if (title.isEmpty) {
          // Look for first markdown heading
          final headingMatch = RegExp(
            r'^#\s+(.+)$',
            multiLine: true,
          ).firstMatch(content);
          if (headingMatch != null) {
            title = headingMatch.group(1)!.trim();
          } else {
            final stripped = slug.replaceAll(
              RegExp(r'^\d{4}-\d{2}-\d{2}-'),
              '',
            );
            title = _titleFromSlug(stripped);
          }
        }
        // First non-heading, non-empty line as description
        String description = '';
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty ||
              trimmed.startsWith('#') ||
              trimmed.startsWith('---'))
            continue;
          if (trimmed.startsWith('**') || trimmed.startsWith('*')) {
            description = trimmed.replaceAll(RegExp(r'\*+'), '').trim();
            break;
          }
          description = trimmed;
          break;
        }
        items.add({
          'id': slug,
          'title': title,
          'slug': slug,
          'description': description,
          'content': content,
          'path': f.path,
        });
      }
      items.sort(
        (a, b) => (a['title'] as String).compareTo(b['title'] as String),
      );
      return items;
    } catch (e) {
      debugPrint('[LocalMcpClient] listDocs error: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listSessions() async {
    // Sessions require the orchestrator process — return empty when offline.
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT id, account_id, name, workspace, model, status, '
        'message_count, total_tokens_in, total_tokens_out, total_cost_usd, '
        'last_message_at, created_at '
        'FROM sessions ORDER BY created_at DESC',
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listDelegations() async {
    // Delegations require the orchestrator process — return empty when offline.
    if (_dbFailed) return [];
    try {
      return _query(
        'SELECT id, project_id, feature_id, from_person, to_person, '
        'question, context, response, status, responded_at, version, '
        'created_at, updated_at '
        'FROM delegations ORDER BY created_at DESC',
      );
    } catch (_) {
      return [];
    }
  }

  // ── Teams (delegated to REST API) ──────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listTeams() => _rest.listTeams();

  @override
  Future<Map<String, dynamic>> getMyTeam() => _rest.getMyTeam();

  @override
  Future<List<Map<String, dynamic>>> listTeamMembers(String teamId) =>
      _rest.listTeamMembers(teamId);

  @override
  Future<Map<String, dynamic>> createTeam(String name) =>
      _rest.createTeam(name);

  @override
  Future<Map<String, dynamic>> updateTeam(Map<String, dynamic> body) =>
      _rest.updateTeam(body);

  @override
  Future<void> deleteTeam(String teamId) => _rest.deleteTeam(teamId);

  @override
  Future<Map<String, dynamic>> inviteTeamMember(
    String teamId,
    String email, {
    String role = 'member',
  }) => _rest.inviteTeamMember(teamId, email, role: role);

  @override
  Future<void> removeTeamMember(String memberId) =>
      _rest.removeTeamMember(memberId);

  @override
  Future<Map<String, dynamic>> updateMemberRole(String memberId, String role) =>
      _rest.updateMemberRole(memberId, role);

  // ── Settings (delegated to REST API) ────────────────────────────────

  ApiClient get _rest {
    if (restClient == null) {
      throw StateError(
        'REST client not configured — settings require web-gate API',
      );
    }
    return restClient!;
  }

  @override
  Future<Map<String, dynamic>> getPreferences() => _rest.getPreferences();

  @override
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) =>
      _rest.updatePreferences(body);

  @override
  Future<List<Map<String, dynamic>>> listSettingsSessions() =>
      _rest.listSettingsSessions();

  @override
  Future<void> revokeSession(String id) => _rest.revokeSession(id);

  @override
  Future<List<Map<String, dynamic>>> listApiKeys() => _rest.listApiKeys();

  @override
  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body) =>
      _rest.createApiKey(body);

  @override
  Future<void> revokeApiKey(String id) => _rest.revokeApiKey(id);

  @override
  Future<List<Map<String, dynamic>>> listConnectedAccounts() =>
      _rest.listConnectedAccounts();

  @override
  Future<void> unlinkAccount(String provider) => _rest.unlinkAccount(provider);

  @override
  Future<void> changePassword(Map<String, dynamic> body) =>
      _rest.changePassword(body);

  // ── Admin (delegated to REST API) ──────────────────────────────────

  @override
  Future<Map<String, dynamic>> getAdminStats() => _rest.getAdminStats();

  @override
  Future<Map<String, dynamic>> listAdminUsers({
    String? search,
    String? role,
    String? status,
    int? limit,
    int? offset,
  }) => _rest.listAdminUsers(
    search: search,
    role: role,
    status: status,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> getAdminUser(int id) => _rest.getAdminUser(id);

  @override
  Future<Map<String, dynamic>> updateAdminUser(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminUser(id, body);

  @override
  Future<void> deleteAdminUser(int id) => _rest.deleteAdminUser(id);

  @override
  Future<Map<String, dynamic>> updateAdminUserRole(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminUserRole(id, body);

  @override
  Future<Map<String, dynamic>> updateAdminUserStatus(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminUserStatus(id, body);

  @override
  Future<Map<String, dynamic>> listAdminUserProjects(int id) =>
      _rest.listAdminUserProjects(id);

  @override
  Future<Map<String, dynamic>> listAdminUserNotes(int id) =>
      _rest.listAdminUserNotes(id);

  @override
  Future<Map<String, dynamic>> listAdminUserSessions(int id) =>
      _rest.listAdminUserSessions(id);

  @override
  Future<Map<String, dynamic>> listAdminUserTeams(int id) =>
      _rest.listAdminUserTeams(id);

  @override
  Future<Map<String, dynamic>> listAdminUserIssues(int id) =>
      _rest.listAdminUserIssues(id);

  @override
  Future<Map<String, dynamic>> listAdminUserMemberships(int id) =>
      _rest.listAdminUserMemberships(id);

  @override
  Future<void> removeAdminUserMembership(int userId, int teamId) =>
      _rest.removeAdminUserMembership(userId, teamId);

  @override
  Future<Map<String, dynamic>> changeAdminUserPassword(
    int id,
    Map<String, dynamic> body,
  ) => _rest.changeAdminUserPassword(id, body);

  @override
  Future<Map<String, dynamic>> sendAdminUserNotification(
    int id,
    Map<String, dynamic> body,
  ) => _rest.sendAdminUserNotification(id, body);

  @override
  Future<Map<String, dynamic>> impersonateAdminUser(int id) =>
      _rest.impersonateAdminUser(id);

  @override
  Future<Map<String, dynamic>> suspendAdminUser(int id) =>
      _rest.suspendAdminUser(id);

  @override
  Future<Map<String, dynamic>> unsuspendAdminUser(int id) =>
      _rest.unsuspendAdminUser(id);

  @override
  Future<Map<String, dynamic>> verifyAdminUser(int id) =>
      _rest.verifyAdminUser(id);

  @override
  Future<Map<String, dynamic>> unverifyAdminUser(int id) =>
      _rest.unverifyAdminUser(id);

  @override
  Future<Map<String, dynamic>> listAdminTeams({
    String? search,
    int? limit,
    int? offset,
  }) => _rest.listAdminTeams(search: search, limit: limit, offset: offset);

  @override
  Future<Map<String, dynamic>> getAdminTeam(int id) => _rest.getAdminTeam(id);

  @override
  Future<Map<String, dynamic>> createAdminTeam(Map<String, dynamic> body) =>
      _rest.createAdminTeam(body);

  @override
  Future<Map<String, dynamic>> updateAdminTeam(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminTeam(id, body);

  @override
  Future<void> deleteAdminTeam(int id) => _rest.deleteAdminTeam(id);

  @override
  Future<Map<String, dynamic>> listAdminTeamMembers(int teamId) =>
      _rest.listAdminTeamMembers(teamId);

  @override
  Future<Map<String, dynamic>> addAdminTeamMember(
    int teamId,
    Map<String, dynamic> body,
  ) => _rest.addAdminTeamMember(teamId, body);

  @override
  Future<void> removeAdminTeamMember(int teamId, int userId) =>
      _rest.removeAdminTeamMember(teamId, userId);

  @override
  Future<Map<String, dynamic>> listAdminSettings({
    String? search,
    String? category,
    int? limit,
    int? offset,
  }) => _rest.listAdminSettings(
    search: search,
    category: category,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> upsertAdminSetting(Map<String, dynamic> body) =>
      _rest.upsertAdminSetting(body);

  @override
  Future<Map<String, dynamic>> getAdminSetting(String key) =>
      _rest.getAdminSetting(key);

  @override
  Future<Map<String, dynamic>> patchAdminSetting(
    String key,
    Map<String, dynamic> body,
  ) => _rest.patchAdminSetting(key, body);

  @override
  Future<Map<String, dynamic>> updateAdminSetting(
    String key,
    Map<String, dynamic> value,
  ) => _rest.updateAdminSetting(key, value);

  @override
  Future<void> deleteAdminSetting(String key) => _rest.deleteAdminSetting(key);

  @override
  Future<Map<String, dynamic>> testEmail() => _rest.testEmail();

  @override
  Future<Map<String, dynamic>> listAdminPages({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _rest.listAdminPages(
    search: search,
    status: status,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> getAdminPage(int id) => _rest.getAdminPage(id);

  @override
  Future<Map<String, dynamic>> createAdminPage(Map<String, dynamic> body) =>
      _rest.createAdminPage(body);

  @override
  Future<Map<String, dynamic>> updateAdminPage(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminPage(id, body);

  @override
  Future<void> deleteAdminPage(int id) => _rest.deleteAdminPage(id);

  @override
  Future<Map<String, dynamic>> listAdminCategories({
    String? search,
    int? limit,
    int? offset,
  }) => _rest.listAdminCategories(search: search, limit: limit, offset: offset);

  @override
  Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> body) =>
      _rest.createAdminCategory(body);

  @override
  Future<Map<String, dynamic>> updateAdminCategory(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminCategory(id, body);

  @override
  Future<void> deleteAdminCategory(int id) => _rest.deleteAdminCategory(id);

  @override
  Future<Map<String, dynamic>> listAdminContact({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _rest.listAdminContact(
    search: search,
    status: status,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> updateAdminContactStatus(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminContactStatus(id, body);

  @override
  Future<void> deleteAdminContactMessage(int id) =>
      _rest.deleteAdminContactMessage(id);

  @override
  Future<Map<String, dynamic>> listAdminIssues({
    String? search,
    String? status,
    String? priority,
    int? limit,
    int? offset,
  }) => _rest.listAdminIssues(
    search: search,
    status: status,
    priority: priority,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> updateAdminIssueStatus(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminIssueStatus(id, body);

  @override
  Future<Map<String, dynamic>> listAdminNotifications({
    int? limit,
    int? offset,
  }) => _rest.listAdminNotifications(limit: limit, offset: offset);

  @override
  Future<Map<String, dynamic>> createAdminNotification(
    Map<String, dynamic> body,
  ) => _rest.createAdminNotification(body);

  @override
  Future<Map<String, dynamic>> listAdminSponsors({
    String? search,
    String? tier,
    String? status,
    int? limit,
    int? offset,
  }) => _rest.listAdminSponsors(
    search: search,
    tier: tier,
    status: status,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> createAdminSponsor(Map<String, dynamic> body) =>
      _rest.createAdminSponsor(body);

  @override
  Future<Map<String, dynamic>> updateAdminSponsor(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminSponsor(id, body);

  @override
  Future<void> deleteAdminSponsor(int id) => _rest.deleteAdminSponsor(id);

  @override
  Future<Map<String, dynamic>> listAdminCommunityPosts({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _rest.listAdminCommunityPosts(
    search: search,
    status: status,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> updateAdminCommunityPost(
    int id,
    Map<String, dynamic> body,
  ) => _rest.updateAdminCommunityPost(id, body);

  @override
  Future<void> deleteAdminCommunityPost(int id) =>
      _rest.deleteAdminCommunityPost(id);

  @override
  Future<Map<String, dynamic>> listAdminGitHubIssues({
    String? repo,
    String? state,
    String? type,
    int? limit,
    int? offset,
  }) => _rest.listAdminGitHubIssues(
    repo: repo,
    state: state,
    type: type,
    limit: limit,
    offset: offset,
  );

  @override
  Future<Map<String, dynamic>> syncAdminGitHub({String? repo}) =>
      _rest.syncAdminGitHub(repo: repo);

  @override
  Future<void> deleteAdminGitHubIssue(int id) =>
      _rest.deleteAdminGitHubIssue(id);

  @override
  Future<Map<String, dynamic>> listAdminGitHubRepos() =>
      _rest.listAdminGitHubRepos();

  // ── Health (delegated to REST API) ──────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getHealthProfile() => _rest.getHealthProfile();

  @override
  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> body) =>
      _rest.updateHealthProfile(body);

  @override
  Future<Map<String, dynamic>> logWater(Map<String, dynamic> body) =>
      _rest.logWater(body);

  @override
  Future<List<Map<String, dynamic>>> listWaterLogs({String? date}) =>
      _rest.listWaterLogs(date: date);

  @override
  Future<Map<String, dynamic>> getHydrationStatus() =>
      _rest.getHydrationStatus();

  @override
  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> body) =>
      _rest.logMeal(body);

  @override
  Future<List<Map<String, dynamic>>> listMealLogs({String? date}) =>
      _rest.listMealLogs(date: date);

  @override
  Future<Map<String, dynamic>> logCaffeine(Map<String, dynamic> body) =>
      _rest.logCaffeine(body);

  @override
  Future<List<Map<String, dynamic>>> listCaffeineLogs({String? date}) =>
      _rest.listCaffeineLogs(date: date);

  @override
  Future<Map<String, dynamic>> getCaffeineScore() => _rest.getCaffeineScore();

  @override
  Future<Map<String, dynamic>> startPomodoro() => _rest.startPomodoro();

  @override
  Future<Map<String, dynamic>> endPomodoro(String id) => _rest.endPomodoro(id);

  @override
  Future<List<Map<String, dynamic>>> listPomodoroSessions({String? date}) =>
      _rest.listPomodoroSessions(date: date);

  @override
  Future<Map<String, dynamic>> getShutdownStatus() => _rest.getShutdownStatus();

  @override
  Future<Map<String, dynamic>> startShutdown() => _rest.startShutdown();

  @override
  Future<Map<String, dynamic>> upsertSnapshot(Map<String, dynamic> body) =>
      _rest.upsertSnapshot(body);

  @override
  Future<List<Map<String, dynamic>>> listSnapshots({
    String? from,
    String? to,
  }) => _rest.listSnapshots(from: from, to: to);

  @override
  Future<Map<String, dynamic>> getHealthSummary() => _rest.getHealthSummary();

  // ── Search ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> search(String query, {String? scope}) async {
    try {
      return _searchLocal(query, scope: scope);
    } catch (e) {
      debugPrint('[LocalMcpClient] search error: $e');
      return {'results': <Map<String, dynamic>>[]};
    }
  }

  Map<String, dynamic> _searchLocal(String query, {String? scope}) {
    final like = '%${query.toLowerCase()}%';
    final results = <Map<String, dynamic>>[];

    if (scope == null || scope == 'projects') {
      results.addAll(
        _query(
          'SELECT slug AS id, name AS title, description AS subtitle, '
          '\'project\' AS type FROM projects '
          'WHERE LOWER(name) LIKE ? OR LOWER(description) LIKE ? LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'features') {
      results.addAll(
        _query(
          'SELECT id, title, description AS subtitle, '
          '\'feature\' AS type FROM features '
          'WHERE LOWER(title) LIKE ? OR LOWER(body) LIKE ? LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'notes') {
      results.addAll(
        _query(
          'SELECT id, title, \'\' AS subtitle, '
          '\'note\' AS type FROM notes '
          'WHERE (LOWER(title) LIKE ? OR LOWER(body) LIKE ?) AND deleted = 0 LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'agents') {
      results.addAll(
        _query(
          'SELECT id, name AS title, description AS subtitle, '
          '\'agent\' AS type FROM agents '
          'WHERE LOWER(name) LIKE ? OR LOWER(description) LIKE ? LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'skills') {
      results.addAll(
        _query(
          'SELECT id, name AS title, description AS subtitle, '
          '\'skill\' AS type FROM skills '
          'WHERE LOWER(name) LIKE ? OR LOWER(description) LIKE ? LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'docs') {
      results.addAll(
        _query(
          'SELECT id, title, \'\' AS subtitle, '
          '\'doc\' AS type FROM docs '
          'WHERE LOWER(title) LIKE ? OR LOWER(body) LIKE ? LIMIT 10',
          [like, like],
        ),
      );
    }
    if (scope == null || scope == 'sessions') {
      results.addAll(
        _query(
          'SELECT id, name AS title, model AS subtitle, '
          '\'session\' AS type FROM sessions '
          'WHERE LOWER(name) LIKE ? LIMIT 10',
          [like],
        ),
      );
    }
    if (scope == null || scope == 'delegations') {
      results.addAll(
        _query(
          'SELECT id, question AS title, from_person AS subtitle, '
          '\'delegation\' AS type FROM delegations '
          'WHERE LOWER(question) LIKE ? LIMIT 10',
          [like],
        ),
      );
    }

    return {'results': results};
  }

  // ── Sync (stubs — desktop syncs via MCP) ────────────────────────────────

  @override
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> body) async => {};

  @override
  Future<Map<String, dynamic>> pullSync({String? since}) async => {};

  // ── Marketplace Admin (delegate to restClient if available) ──────────────

  @override
  Future<Map<String, dynamic>> listPendingMarketplace() async {
    if (restClient != null) return restClient!.listPendingMarketplace();
    return {'submissions': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> approveMarketplaceItem(int id) async {
    if (restClient != null) return restClient!.approveMarketplaceItem(id);
    throw UnsupportedError(
      'approveMarketplaceItem requires restClient on LocalMcpClient',
    );
  }

  @override
  Future<Map<String, dynamic>> rejectMarketplaceItem(
    int id, {
    String reason = '',
  }) async {
    if (restClient != null) {
      return restClient!.rejectMarketplaceItem(id, reason: reason);
    }
    throw UnsupportedError(
      'rejectMarketplaceItem requires restClient on LocalMcpClient',
    );
  }

  // ── Verification Admin (delegate to restClient) ─────────────────────────

  @override
  Future<Map<String, dynamic>> listVerificationTypes() async {
    if (restClient != null) return restClient!.listVerificationTypes();
    return {'types': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> createVerificationType(
    Map<String, dynamic> body,
  ) async {
    if (restClient != null) return restClient!.createVerificationType(body);
    throw UnsupportedError(
      'createVerificationType requires restClient on LocalMcpClient',
    );
  }

  @override
  Future<Map<String, dynamic>> updateVerificationType(
    int id,
    Map<String, dynamic> body,
  ) async {
    if (restClient != null) return restClient!.updateVerificationType(id, body);
    throw UnsupportedError(
      'updateVerificationType requires restClient on LocalMcpClient',
    );
  }

  @override
  Future<void> deleteVerificationType(int id) async {
    if (restClient != null) return restClient!.deleteVerificationType(id);
    throw UnsupportedError(
      'deleteVerificationType requires restClient on LocalMcpClient',
    );
  }

  // ── Badge Admin (delegate to restClient) ────────────────────────────────

  @override
  Future<Map<String, dynamic>> listBadgeDefinitions() async {
    if (restClient != null) return restClient!.listBadgeDefinitions();
    return {'badges': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> createBadgeDefinition(
    Map<String, dynamic> body,
  ) async {
    if (restClient != null) return restClient!.createBadgeDefinition(body);
    throw UnsupportedError(
      'createBadgeDefinition requires restClient on LocalMcpClient',
    );
  }

  @override
  Future<Map<String, dynamic>> updateBadgeDefinition(
    int id,
    Map<String, dynamic> body,
  ) async {
    if (restClient != null) {
      return restClient!.updateBadgeDefinition(id, body);
    }
    throw UnsupportedError(
      'updateBadgeDefinition requires restClient on LocalMcpClient',
    );
  }

  @override
  Future<void> deleteBadgeDefinition(int id) async {
    if (restClient != null) return restClient!.deleteBadgeDefinition(id);
    throw UnsupportedError(
      'deleteBadgeDefinition requires restClient on LocalMcpClient',
    );
  }

  // ── Tools (delegate to McpTcpClient) ────────────────────────────────────

  @override
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  }) => throw UnsupportedError(
    'callTool not available on LocalMcpClient — use mcpClientProvider',
  );

  // ── Badges & Points (admin API — delegate to REST) ─────────────────────

  @override
  Future<Map<String, dynamic>> listUserBadges(int userId) async =>
      restClient?.listUserBadges(userId) ?? {'badges': []};

  @override
  Future<Map<String, dynamic>> awardUserBadge(
    int userId,
    Map<String, dynamic> body,
  ) async => restClient?.awardUserBadge(userId, body) ?? {};

  @override
  Future<void> revokeUserBadge(int userId, String badgeId) async =>
      restClient?.revokeUserBadge(userId, badgeId);

  @override
  Future<Map<String, dynamic>> getUserPoints(int userId) async =>
      restClient?.getUserPoints(userId) ?? {'points': 0};

  @override
  Future<Map<String, dynamic>> addUserPoints(
    int userId,
    Map<String, dynamic> body,
  ) async => restClient?.addUserPoints(userId, body) ?? {};
}
