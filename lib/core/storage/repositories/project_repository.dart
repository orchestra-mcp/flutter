import 'dart:convert';

import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/storage/daos/project_dao.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// A plain Dart model representing a project row.
class Project {
  Project({
    required this.id,
    required this.name,
    this.slug,
    this.userId,
    this.description,
    this.mode = 'active',
    this.stacks = '[]',
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromRow(Map<String, dynamic> row) {
    return Project(
      id: row['id'] as String,
      userId: row['user_id'] as int?,
      name: (row['name'] as String?) ?? '',
      slug: row['slug'] as String?,
      description: row['description'] as String?,
      mode: (row['mode'] as String?) ?? 'active',
      stacks: (row['stacks'] as String?) ?? '[]',
      createdAt: row['created_at'] as String?,
      updatedAt: row['updated_at'] as String?,
    );
  }

  final String id;
  final int? userId;
  final String name;
  final String? slug;
  final String? description;
  final String mode;
  final String stacks;
  final String? createdAt;
  final String? updatedAt;
}

/// Repository for projects — supports two backends:
///
/// - **PowerSync** (mobile/web): reads/writes via PowerSync local SQLite.
/// - **Drift + MCP** (desktop): reads from MCP workspace via API client.
class ProjectRepository {
  /// PowerSync-backed constructor (mobile/web).
  ProjectRepository({required PowerSyncDatabase db})
      : _db = db,
        _dao = null,
        _client = null,
        _localDb = null;

  /// Drift + MCP-backed constructor (desktop).
  ProjectRepository.fromDrift({
    required ProjectDao dao,
    required ApiClient client,
    required LocalDatabase db,
  })  : _db = null,
        _dao = dao,
        _client = client,
        _localDb = db;

  final PowerSyncDatabase? _db;
  final ProjectDao? _dao;
  final ApiClient? _client;
  final LocalDatabase? _localDb;

  static const _uuid = Uuid();

  bool get _usePowerSync => _db != null;

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<Project>> listAll() async {
    if (_usePowerSync) {
      final rows = await _db!.getAll(
        'SELECT * FROM projects ORDER BY updated_at DESC',
      );
      return rows.map(Project.fromRow).toList();
    }
    final projects = await _client!.listProjects();
    return projects.map(Project.fromRow).toList();
  }

  Stream<List<Project>> watchAll() {
    if (_usePowerSync) {
      return _db!
          .watch('SELECT * FROM projects ORDER BY updated_at DESC')
          .map((rows) => rows.map(Project.fromRow).toList());
    }
    return Stream.fromFuture(listAll()).asBroadcastStream();
  }

  Future<Project?> getById(String id) async {
    if (_usePowerSync) {
      final rows = await _db!.getAll(
        'SELECT * FROM projects WHERE id = ?',
        [id],
      );
      if (rows.isEmpty) return null;
      return Project.fromRow(rows.first);
    }
    final data = await _client!.getProject(id);
    return Project.fromRow(data);
  }

  Stream<Project?> watchById(String id) {
    if (_usePowerSync) {
      return _db!.watch(
        'SELECT * FROM projects WHERE id = ?',
        parameters: [id],
      ).map((rows) => rows.isEmpty ? null : Project.fromRow(rows.first));
    }
    return Stream.fromFuture(getById(id)).asBroadcastStream();
  }

  Future<List<Project>> search(String query) async {
    if (query.trim().isEmpty) return listAll();
    if (_usePowerSync) {
      final pattern = '%${query.trim()}%';
      final rows = await _db!.getAll(
        'SELECT * FROM projects WHERE name LIKE ? OR description LIKE ? ORDER BY updated_at DESC',
        [pattern, pattern],
      );
      return rows.map(Project.fromRow).toList();
    }
    final all = await listAll();
    final q = query.trim().toLowerCase();
    return all.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false)).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Project> create({
    String? id,
    required String name,
    String? description,
    String mode = 'active',
    List<String> stacks = const [],
    int userId = 0,
  }) async {
    final projectId = id ?? _uuid.v4();

    if (_usePowerSync) {
      final now = DateTime.now().toUtc().toIso8601String();
      final stacksJson = jsonEncode(stacks);
      await _db!.execute(
        'INSERT INTO projects(id, user_id, name, description, mode, stacks, created_at, updated_at) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [projectId, userId, name, description, mode, stacksJson, now, now],
      );
      return Project(id: projectId, userId: userId, name: name,
          description: description, mode: mode, stacks: stacksJson,
          createdAt: now, updatedAt: now);
    }

    final data = await _client!.createProject({
      'id': projectId,
      'name': name,
      'description': description ?? '',
      'mode': mode,
    });
    return Project.fromRow(data);
  }

  Future<void> update(
    String id, {
    String? name,
    String? description,
    String? mode,
    List<String>? stacks,
  }) async {
    if (_usePowerSync) {
      final sets = <String>[];
      final params = <dynamic>[];
      if (name != null) { sets.add('name = ?'); params.add(name); }
      if (description != null) { sets.add('description = ?'); params.add(description); }
      if (mode != null) { sets.add('mode = ?'); params.add(mode); }
      if (stacks != null) { sets.add('stacks = ?'); params.add(jsonEncode(stacks)); }
      if (sets.isEmpty) return;
      sets.add('updated_at = ?');
      params.add(DateTime.now().toUtc().toIso8601String());
      params.add(id);
      await _db!.execute('UPDATE projects SET ${sets.join(', ')} WHERE id = ?', params);
      return;
    }

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    await _client!.updateProject(id, body);
  }

  Future<void> delete(String id) async {
    if (_usePowerSync) {
      await _db!.execute('DELETE FROM projects WHERE id = ?', [id]);
      return;
    }
    await _client!.deleteProject(id);
  }
}
