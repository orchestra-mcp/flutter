import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Bidirectional sync bridge between workspace files and SQLite.
///
/// Architecture:
/// - **Files** (`.projects/`, `.claude/`) = source of truth for agent access
/// - **SQLite** (`~/.orchestra/db/<hash>.db`) = indexed cache for UI + PowerSync sync
/// - **Every write** updates BOTH SQLite AND files simultaneously
/// - **On workspace open** scans files → populates SQLite
/// - **File watcher** detects external changes → updates SQLite
class WorkspaceBridge {
  WorkspaceBridge({required this.workspacePath});

  final String workspacePath;
  Database? _db;
  StreamSubscription<FileSystemEvent>? _watcher;
  Timer? _debounce;

  /// Resolve the real home directory (escaping macOS sandbox).
  static String get _realHome {
    final env = Platform.environment['HOME'] ?? '/tmp';
    final match = RegExp(
      r'^(/Users/[^/]+)/Library/Containers/.+/Data$',
    ).firstMatch(env);
    return match?.group(1) ?? env;
  }

  /// Get (or create) the workspace SQLite database with read-write access.
  Database get db {
    if (_db != null) return _db!;

    final absPath = Directory(
      workspacePath,
    ).absolute.path.replaceAll(RegExp(r'/$'), '');
    final hash = sha256
        .convert(utf8.encode(absPath))
        .toString()
        .substring(0, 16);
    final home = _realHome;
    final dbDir = Directory('$home/.orchestra/db');
    if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
    final dbPath = '${dbDir.path}/$hash.db';

    debugPrint('[WorkspaceBridge] Opening DB at $dbPath (read-write)');
    _db = sqlite3.open(dbPath);

    // Ensure schema exists.
    _ensureSchema(_db!);
    return _db!;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Initialize: scan all workspace files → upsert into SQLite.
  /// Call this once on workspace open.
  Future<void> init() async {
    debugPrint('[WorkspaceBridge] Initializing for $workspacePath');
    final sw = Stopwatch()..start();

    int count = 0;
    count += await _syncProjectEntities();
    count += await _syncAgents();
    count += await _syncSkills();
    count += await _syncDocs();

    sw.stop();
    debugPrint(
      '[WorkspaceBridge] Synced $count entities from files → SQLite in ${sw.elapsedMilliseconds}ms',
    );

    // Start watching for external file changes.
    _startWatcher();
  }

  /// Dispose resources.
  void dispose() {
    _watcher?.cancel();
    _debounce?.cancel();
    _db?.dispose();
    _db = null;
  }

  // ── Write-through: update BOTH SQLite AND file ─────────────────────────

  /// Upsert a feature in SQLite and write the corresponding .md file.
  void upsertFeature(String projectSlug, Map<String, dynamic> data) {
    final id = data['id'] as String;
    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      INSERT INTO features (id, project_id, title, description, status, priority, kind, assignee, estimate, labels, depends_on, body, version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title=excluded.title, description=excluded.description, status=excluded.status,
        priority=excluded.priority, kind=excluded.kind, assignee=excluded.assignee,
        estimate=excluded.estimate, labels=excluded.labels, depends_on=excluded.depends_on,
        body=excluded.body, version=excluded.version, updated_at=excluded.updated_at
    ''',
      [
        id,
        projectSlug,
        data['title'] ?? '',
        data['description'] ?? '',
        data['status'] ?? 'backlog',
        data['priority'] ?? 'P2',
        data['kind'] ?? 'feature',
        data['assignee'] ?? '',
        data['estimate'] ?? '',
        jsonEncode(data['labels'] ?? []),
        jsonEncode(data['depends_on'] ?? []),
        data['body'] ?? '',
        data['version'] ?? 1,
        data['created_at'] ?? now,
        now,
      ],
    );

    _writeEntityFile(projectSlug, 'features', id, data);
    _logChange('feature', id, 'upsert', data['version'] as int? ?? 1);
  }

  /// Upsert a plan in SQLite and write the corresponding .md file.
  void upsertPlan(String projectSlug, Map<String, dynamic> data) {
    final id = data['id'] as String;
    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      INSERT INTO plans (id, project_id, title, description, status, features, body, version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        title=excluded.title, description=excluded.description, status=excluded.status,
        features=excluded.features, body=excluded.body, version=excluded.version, updated_at=excluded.updated_at
    ''',
      [
        id,
        projectSlug,
        data['title'] ?? '',
        data['description'] ?? '',
        data['status'] ?? 'draft',
        jsonEncode(data['features'] ?? []),
        data['body'] ?? '',
        data['version'] ?? 1,
        data['created_at'] ?? now,
        now,
      ],
    );

    _writeEntityFile(projectSlug, 'plans', id, data);
    _logChange('plan', id, 'upsert', data['version'] as int? ?? 1);
  }

  /// Upsert an agent in SQLite and write the .claude/agents/<slug>.md file.
  void upsertAgent(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? data['slug'] as String;
    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      INSERT INTO agents (id, name, slug, description, content, scope, icon, color, version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name, slug=excluded.slug, description=excluded.description,
        content=excluded.content, scope=excluded.scope, icon=excluded.icon,
        color=excluded.color, version=excluded.version, updated_at=excluded.updated_at
    ''',
      [
        id,
        data['name'] ?? '',
        data['slug'] ?? id,
        data['description'] ?? '',
        data['content'] ?? '',
        data['scope'] ?? 'personal',
        data['icon'] ?? '',
        data['color'] ?? '',
        data['version'] ?? 1,
        data['created_at'] ?? now,
        now,
      ],
    );

    // Write .claude/agents/<slug>.md
    final slug = data['slug'] as String? ?? id;
    final agentFile = File('$workspacePath/.claude/agents/$slug.md');
    agentFile.parent.createSync(recursive: true);
    agentFile.writeAsStringSync(data['content'] as String? ?? '');
    _logChange('agent', id, 'upsert', data['version'] as int? ?? 1);
  }

  /// Upsert a skill in SQLite and write .claude/skills/<slug>/SKILL.md.
  void upsertSkill(Map<String, dynamic> data) {
    final id = data['id'] as String? ?? data['slug'] as String;
    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      INSERT INTO skills (id, name, slug, description, content, scope, icon, color, stacks, version, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name=excluded.name, slug=excluded.slug, description=excluded.description,
        content=excluded.content, scope=excluded.scope, icon=excluded.icon,
        color=excluded.color, stacks=excluded.stacks, version=excluded.version, updated_at=excluded.updated_at
    ''',
      [
        id,
        data['name'] ?? '',
        data['slug'] ?? id,
        data['description'] ?? '',
        data['content'] ?? '',
        data['scope'] ?? 'personal',
        data['icon'] ?? '',
        data['color'] ?? '',
        jsonEncode(data['stacks'] ?? []),
        data['version'] ?? 1,
        data['created_at'] ?? now,
        now,
      ],
    );

    // Write .claude/skills/<slug>/SKILL.md
    final slug = data['slug'] as String? ?? id;
    final skillDir = Directory('$workspacePath/.claude/skills/$slug');
    skillDir.createSync(recursive: true);
    File(
      '${skillDir.path}/SKILL.md',
    ).writeAsStringSync(data['content'] as String? ?? '');
    _logChange('skill', id, 'upsert', data['version'] as int? ?? 1);
  }

  // ── File → SQLite sync (startup + file watcher) ───────────────────────

  /// Scan .projects/ and sync all entity files to SQLite.
  Future<int> _syncProjectEntities() async {
    int count = 0;
    final projectsDir = Directory('$workspacePath/.projects');
    if (!projectsDir.existsSync()) return 0;

    for (final projectDir in projectsDir.listSync().whereType<Directory>()) {
      final slug = p.basename(projectDir.path);
      if (slug.startsWith('.')) continue;

      // Ensure project exists in DB.
      db.execute(
        '''
        INSERT INTO projects (slug, name) VALUES (?, ?)
        ON CONFLICT(slug) DO NOTHING
      ''',
        [slug, slug],
      );

      // Sync features, plans, requests, persons.
      for (final entityType in ['features', 'plans', 'requests', 'persons']) {
        final entityDir = Directory('${projectDir.path}/$entityType');
        if (!entityDir.existsSync()) continue;

        for (final file in entityDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.md')) continue;
          final data = _parseFile(file);
          if (data == null) continue;
          data['project_id'] = slug;
          _upsertEntityFromFile(entityType, data);
          count++;
        }
      }
    }
    return count;
  }

  /// Scan .claude/agents/ and sync to SQLite.
  Future<int> _syncAgents() async {
    int count = 0;
    final dir = Directory('$workspacePath/.claude/agents');
    if (!dir.existsSync()) return 0;

    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;
      final basename = p.basenameWithoutExtension(file.path);
      final content = file.readAsStringSync();
      final now = file.lastModifiedSync().toIso8601String();

      db.execute(
        '''
        INSERT INTO agents (id, name, slug, content, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET content=excluded.content, updated_at=excluded.updated_at
      ''',
        [basename, basename.replaceAll('-', ' '), basename, content, now, now],
      );
      count++;
    }
    return count;
  }

  /// Scan .claude/skills/ and sync to SQLite.
  Future<int> _syncSkills() async {
    int count = 0;
    final dir = Directory('$workspacePath/.claude/skills');
    if (!dir.existsSync()) return 0;

    for (final subdir in dir.listSync().whereType<Directory>()) {
      final slug = p.basename(subdir.path);
      final skillFile = File('${subdir.path}/SKILL.md');
      final content = skillFile.existsSync()
          ? skillFile.readAsStringSync()
          : '';
      final now =
          (skillFile.existsSync()
                  ? skillFile.lastModifiedSync()
                  : subdir.statSync().modified)
              .toIso8601String();

      db.execute(
        '''
        INSERT INTO skills (id, name, slug, content, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET content=excluded.content, updated_at=excluded.updated_at
      ''',
        [slug, slug.replaceAll('-', ' '), slug, content, now, now],
      );
      count++;
    }
    return count;
  }

  /// Scan docs/ recursively and sync to SQLite.
  Future<int> _syncDocs() async {
    int count = 0;
    final docsDir = Directory('$workspacePath/docs');
    if (!docsDir.existsSync()) return 0;

    // Ensure docs table exists (might not in older DBs).
    try {
      db.execute('SELECT 1 FROM docs LIMIT 0');
    } catch (_) {
      db.execute('''
        CREATE TABLE IF NOT EXISTS docs (
          id TEXT PRIMARY KEY, project_id TEXT NOT NULL DEFAULT '',
          title TEXT NOT NULL, slug TEXT NOT NULL, body TEXT DEFAULT '',
          parent_id TEXT DEFAULT '', position INTEGER DEFAULT 0,
          tags TEXT DEFAULT '[]', version INTEGER DEFAULT 1,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
    }

    for (final file in docsDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;
      try {
        final content = file.readAsStringSync();
        final relativePath = file.path.substring(docsDir.path.length + 1);
        final slug = p.basenameWithoutExtension(file.path);
        final title = slug.replaceAll('-', ' ');
        final now = file.lastModifiedSync().toIso8601String();

        // Use relative path as ID to handle subdirectories.
        final id = relativePath.replaceAll('.md', '').replaceAll('/', '-');

        db.execute(
          '''
          INSERT INTO docs (id, project_id, title, slug, body, created_at, updated_at)
          VALUES (?, '', ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET title=excluded.title, body=excluded.body, updated_at=excluded.updated_at
        ''',
          [id, title, slug, content, now, now],
        );
        count++;
      } catch (e) {
        debugPrint('[WorkspaceBridge] Failed to sync doc ${file.path}: $e');
      }
    }
    return count;
  }

  // ── File watcher ──────────────────────────────────────────────────────

  void _startWatcher() {
    // Watch .projects/, .claude/, and docs/ for changes.
    for (final dirPath in [
      '$workspacePath/.projects',
      '$workspacePath/.claude',
      '$workspacePath/docs',
    ]) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      _watcher = dir.watch(recursive: true).listen((event) {
        if (!event.path.endsWith('.md')) return;

        // Debounce rapid changes (editors save multiple times).
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          _handleFileChange(event.path);
        });
      });
    }
  }

  void _handleFileChange(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return; // Deletion — skip for now.

    debugPrint('[WorkspaceBridge] File changed: $filePath');

    // Determine what type of entity changed.
    if (filePath.contains('.claude/agents/')) {
      final basename = p.basenameWithoutExtension(filePath);
      final content = file.readAsStringSync();
      final now = file.lastModifiedSync().toIso8601String();
      db.execute(
        '''
        INSERT INTO agents (id, name, slug, content, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET content=excluded.content, updated_at=excluded.updated_at
      ''',
        [basename, basename.replaceAll('-', ' '), basename, content, now, now],
      );
    } else if (filePath.contains('.claude/skills/')) {
      // Re-sync all skills (simpler than parsing path).
      _syncSkills();
    } else if (filePath.contains('.projects/')) {
      final data = _parseFile(file);
      if (data == null) return;

      // Extract project slug and entity type from path.
      final relative = filePath.substring('$workspacePath/.projects/'.length);
      final parts = relative.split('/');
      if (parts.length >= 3) {
        final projectSlug = parts[0];
        final entityType = parts[1];
        data['project_id'] = projectSlug;
        _upsertEntityFromFile(entityType, data);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Parse a markdown file with YAML frontmatter into a map.
  Map<String, dynamic>? _parseFile(File file) {
    try {
      final content = file.readAsStringSync();
      final id = p.basenameWithoutExtension(file.path);
      final fileStat = file.statSync();

      if (!content.startsWith('---')) {
        return {
          'id': id,
          'body': content,
          'updated_at': fileStat.modified.toIso8601String(),
        };
      }

      final endIdx = content.indexOf('---', 3);
      if (endIdx == -1) {
        return {
          'id': id,
          'body': content,
          'updated_at': fileStat.modified.toIso8601String(),
        };
      }

      final frontmatter = content.substring(3, endIdx).trim();
      final body = content.substring(endIdx + 3).trim();
      final data = <String, dynamic>{'id': id, 'body': body};

      for (final line in frontmatter.split('\n')) {
        final colonIdx = line.indexOf(':');
        if (colonIdx == -1) continue;
        final key = line.substring(0, colonIdx).trim();
        var value = line.substring(colonIdx + 1).trim();
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
        if (key == 'labels' ||
            key == 'depends_on' ||
            key == 'features' ||
            key == 'stacks') {
          data[key] = value;
        } else if (key == 'version') {
          data[key] = int.tryParse(value) ?? 1;
        } else {
          data[key] = value;
        }
      }

      data['updated_at'] ??= fileStat.modified.toIso8601String();
      data['created_at'] ??= fileStat.modified.toIso8601String();
      return data;
    } catch (e) {
      debugPrint('[WorkspaceBridge] Parse error ${file.path}: $e');
      return null;
    }
  }

  /// Upsert a parsed entity into the correct SQLite table.
  void _upsertEntityFromFile(String entityType, Map<String, dynamic> data) {
    final id = data['id'] as String;
    final projectId = data['project_id'] as String? ?? '';
    final now =
        data['updated_at'] as String? ?? DateTime.now().toIso8601String();

    switch (entityType) {
      case 'features':
        db.execute(
          '''
          INSERT INTO features (id, project_id, title, description, status, priority, kind, assignee, estimate, labels, depends_on, body, version, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title=excluded.title, description=excluded.description, status=excluded.status,
            priority=excluded.priority, kind=excluded.kind, assignee=excluded.assignee,
            estimate=excluded.estimate, labels=excluded.labels, depends_on=excluded.depends_on,
            body=excluded.body, version=excluded.version, updated_at=excluded.updated_at
        ''',
          [
            id,
            projectId,
            data['title'] ?? id,
            data['description'] ?? '',
            data['status'] ?? 'backlog',
            data['priority'] ?? 'P2',
            data['kind'] ?? 'feature',
            data['assignee'] ?? '',
            data['estimate'] ?? '',
            data['labels'] ?? '[]',
            data['depends_on'] ?? '[]',
            data['body'] ?? '',
            data['version'] ?? 1,
            data['created_at'] ?? now,
            now,
          ],
        );
      case 'plans':
        db.execute(
          '''
          INSERT INTO plans (id, project_id, title, description, status, body, version, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title=excluded.title, description=excluded.description, status=excluded.status,
            body=excluded.body, version=excluded.version, updated_at=excluded.updated_at
        ''',
          [
            id,
            projectId,
            data['title'] ?? id,
            data['description'] ?? '',
            data['status'] ?? 'draft',
            data['body'] ?? '',
            data['version'] ?? 1,
            data['created_at'] ?? now,
            now,
          ],
        );
      case 'requests':
        db.execute(
          '''
          INSERT INTO requests (id, project_id, title, description, kind, status, priority, body, version, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            title=excluded.title, description=excluded.description, kind=excluded.kind,
            status=excluded.status, priority=excluded.priority, body=excluded.body,
            version=excluded.version, updated_at=excluded.updated_at
        ''',
          [
            id,
            projectId,
            data['title'] ?? id,
            data['description'] ?? '',
            data['kind'] ?? 'feature',
            data['status'] ?? 'pending',
            data['priority'] ?? 'P2',
            data['body'] ?? '',
            data['version'] ?? 1,
            data['created_at'] ?? now,
            now,
          ],
        );
      case 'persons':
        db.execute(
          '''
          INSERT INTO persons (id, project_id, name, email, role, status, bio, body, version, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name=excluded.name, email=excluded.email, role=excluded.role,
            status=excluded.status, bio=excluded.bio, body=excluded.body,
            version=excluded.version, updated_at=excluded.updated_at
        ''',
          [
            id,
            projectId,
            data['name'] ?? id,
            data['email'] ?? '',
            data['role'] ?? 'developer',
            data['status'] ?? 'active',
            data['bio'] ?? '',
            data['body'] ?? '',
            data['version'] ?? 1,
            data['created_at'] ?? now,
            now,
          ],
        );
    }
  }

  /// Write a .projects/ entity file from data.
  void _writeEntityFile(
    String projectSlug,
    String entityType,
    String id,
    Map<String, dynamic> data,
  ) {
    final dir = Directory('$workspacePath/.projects/$projectSlug/$entityType');
    dir.createSync(recursive: true);
    final file = File('${dir.path}/$id.md');

    final frontmatter = StringBuffer('---\n');
    for (final key in [
      'title',
      'description',
      'status',
      'priority',
      'kind',
      'assignee',
      'estimate',
    ]) {
      if (data.containsKey(key) && data[key] != null && data[key] != '') {
        frontmatter.writeln('$key: ${data[key]}');
      }
    }
    if (data['labels'] is List && (data['labels'] as List).isNotEmpty) {
      frontmatter.writeln('labels: ${jsonEncode(data['labels'])}');
    }
    if (data['version'] != null) {
      frontmatter.writeln('version: ${data['version']}');
    }
    frontmatter.writeln('---');

    final body = data['body'] as String? ?? '';
    file.writeAsStringSync('${frontmatter.toString()}\n$body\n');
  }

  /// Log a change for sync tracking.
  void _logChange(
    String entityType,
    String entityId,
    String action,
    int version,
  ) {
    try {
      db.execute(
        '''
        INSERT INTO change_log (entity_type, entity_id, action, version)
        VALUES (?, ?, ?, ?)
      ''',
        [entityType, entityId, action, version],
      );
    } catch (_) {
      // change_log table might not exist in older DBs — non-fatal.
    }
  }

  /// Ensure the SQLite schema exists (create tables if missing).
  void _ensureSchema(Database db) {
    // Check if features table exists; if not, create the full schema.
    try {
      db.execute("SELECT 1 FROM features LIMIT 0");
    } catch (_) {
      debugPrint('[WorkspaceBridge] Creating schema...');
      db.execute(_schema);
    }
  }

  static const _schema = '''
CREATE TABLE IF NOT EXISTS projects (
    slug TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT DEFAULT '',
    metadata TEXT DEFAULT '{}', body TEXT DEFAULT '', version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS features (
    id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
    description TEXT DEFAULT '', status TEXT DEFAULT 'backlog', priority TEXT DEFAULT 'P2',
    kind TEXT DEFAULT 'feature', assignee TEXT DEFAULT '', estimate TEXT DEFAULT '',
    labels TEXT DEFAULT '[]', depends_on TEXT DEFAULT '[]', body TEXT DEFAULT '',
    version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS plans (
    id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
    description TEXT DEFAULT '', status TEXT DEFAULT 'draft', features TEXT DEFAULT '[]',
    body TEXT DEFAULT '', version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS requests (
    id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL,
    description TEXT DEFAULT '', kind TEXT NOT NULL DEFAULT 'feature',
    status TEXT DEFAULT 'pending', priority TEXT DEFAULT 'P2', body TEXT DEFAULT '',
    version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS persons (
    id TEXT PRIMARY KEY, project_id TEXT NOT NULL, name TEXT NOT NULL,
    email TEXT DEFAULT '', role TEXT DEFAULT 'developer', status TEXT DEFAULT 'active',
    bio TEXT DEFAULT '', github_email TEXT DEFAULT '', body TEXT DEFAULT '',
    version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS agents (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, slug TEXT NOT NULL,
    description TEXT DEFAULT '', content TEXT DEFAULT '', scope TEXT DEFAULT 'personal',
    icon TEXT DEFAULT '', color TEXT DEFAULT '', version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS skills (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, slug TEXT NOT NULL,
    description TEXT DEFAULT '', content TEXT DEFAULT '', scope TEXT DEFAULT 'personal',
    icon TEXT DEFAULT '', color TEXT DEFAULT '', stacks TEXT DEFAULT '[]',
    version INTEGER DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS change_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL, action TEXT NOT NULL, version INTEGER NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (datetime('now')), synced INTEGER DEFAULT 0
);
''';
}
