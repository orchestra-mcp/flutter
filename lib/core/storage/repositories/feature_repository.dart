import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/storage/daos/feature_dao.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Offline-first repository for features.
///
/// Read path: SQLite first, falls back to REST API, caches API responses
/// locally. Write path: writes to SQLite immediately, then pushes to the
/// REST API in the background.
class FeatureRepository {
  FeatureRepository({
    required this.dao,
    required this.client,
    required this.db,
  });

  final FeatureDao dao;
  final ApiClient client;
  final LocalDatabase db;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all features. Tries local SQLite first. If empty, fetches
  /// from the REST API and caches the results.
  Future<List<LocalFeature>> listAll({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final local = await dao.listAll();
      if (local.isNotEmpty) return local;
    }
    return _fetchAndCacheAll();
  }

  /// Returns features for a specific project.
  Future<List<LocalFeature>> listByProject(
    String projectId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final local = await dao.listByProject(projectId);
      if (local.isNotEmpty) return local;
    }
    return _fetchAndCacheByProject(projectId);
  }

  /// Watch all features as a reactive stream from SQLite.
  Stream<List<LocalFeature>> watchAll() => dao.watchAll();

  /// Watch features for a specific project.
  Stream<List<LocalFeature>> watchByProject(String projectId) =>
      dao.watchByProject(projectId);

  /// Returns a single feature by [id]. Tries local first, falls back
  /// to the REST API.
  Future<LocalFeature?> getById(String id) async {
    final local = await dao.getById(id);
    if (local != null) return local;
    return _fetchAndCacheOne(id);
  }

  /// Watch a single feature by [id].
  Stream<LocalFeature?> watchById(String id) => dao.watchById(id);

  /// Filter features by status.
  Future<List<LocalFeature>> listByStatus(String status) =>
      dao.listByStatus(status);

  /// Filter features by label.
  Future<List<LocalFeature>> listByLabel(String label) =>
      dao.listByLabel(label);

  /// Search features using FTS5.
  Future<List<LocalFeature>> search(String query) => dao.search(query);

  /// Get feature count by status for a project.
  Future<Map<String, int>> countByStatus({String? projectId}) =>
      dao.countByStatus(projectId: projectId);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new feature locally and pushes to the API.
  Future<LocalFeature> create({
    required String id,
    required String projectId,
    required String title,
    String? description,
    String status = 'todo',
    String kind = 'feature',
    String priority = 'P2',
    String? estimate,
    String? assigneeId,
    List<String> labels = const [],
  }) async {
    final feature = await dao.create(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: status,
      kind: kind,
      priority: priority,
      estimate: estimate,
      assigneeId: assigneeId,
      labels: jsonEncode(labels),
      synced: false,
    );
    _pushCreate(feature);
    return feature;
  }

  /// Updates an existing feature locally and pushes to the API.
  Future<void> update(
    String id, {
    String? title,
    String? description,
    String? status,
    String? kind,
    String? priority,
    String? estimate,
    String? assigneeId,
    List<String>? labels,
    String? evidence,
    String? body,
  }) async {
    final companion = LocalFeaturesCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      description: description != null
          ? Value(description)
          : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      kind: kind != null ? Value(kind) : const Value.absent(),
      priority: priority != null ? Value(priority) : const Value.absent(),
      estimate: estimate != null ? Value(estimate) : const Value.absent(),
      assigneeId: assigneeId != null ? Value(assigneeId) : const Value.absent(),
      labels: labels != null ? Value(jsonEncode(labels)) : const Value.absent(),
      evidence: evidence != null ? Value(evidence) : const Value.absent(),
      body: body != null ? Value(body) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      synced: const Value(false),
    );
    await dao.update(id, companion);
    _pushUpdate(id);
  }

  /// Deletes a feature locally. Features are not deleted from the API
  /// (they follow the MCP workflow lifecycle).
  Future<void> delete(String id) async {
    await dao.deleteById(id);
  }

  // ── Background sync helpers ───────────────────────────────────────────────

  Future<List<LocalFeature>> _fetchAndCacheAll() async {
    try {
      final items = await client.listFeatures();
      await _cacheFeatures(items);
      return dao.listAll();
    } catch (_) {
      return dao.listAll();
    }
  }

  Future<List<LocalFeature>> _fetchAndCacheByProject(String projectId) async {
    try {
      final items = await client.listFeatures(projectId: projectId);
      await _cacheFeatures(items);
      return dao.listByProject(projectId);
    } catch (_) {
      return dao.listByProject(projectId);
    }
  }

  Future<LocalFeature?> _fetchAndCacheOne(String id) async {
    try {
      final f = await client.getFeature(id);
      await _cacheFeature(f);
      return dao.getById(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheFeatures(List<Map<String, dynamic>> items) async {
    for (final f in items) {
      await _cacheFeature(f);
    }
  }

  Future<void> _cacheFeature(Map<String, dynamic> f) async {
    final labelsRaw = f['labels'];
    final labelsJson = labelsRaw is List
        ? jsonEncode(labelsRaw)
        : (labelsRaw as String?) ?? '[]';

    await db
        .into(db.localFeatures)
        .insertOnConflictUpdate(
          LocalFeaturesCompanion.insert(
            id: f['id'] as String,
            projectId: (f['project_id'] as String?) ?? '',
            title: (f['title'] as String?) ?? '',
            description: Value(f['description'] as String?),
            status: Value((f['status'] as String?) ?? 'todo'),
            kind: Value((f['kind'] as String?) ?? 'feature'),
            priority: Value((f['priority'] as String?) ?? 'P2'),
            estimate: Value(f['estimate'] as String?),
            assigneeId: Value(f['assignee_id'] as String?),
            labels: Value(labelsJson),
            evidence: Value(f['evidence'] as String?),
            body: Value(f['body'] as String?),
            synced: const Value(true),
            createdAt: _parseDate(f['created_at']),
            updatedAt: _parseDate(f['updated_at']),
          ),
        );
  }

  Future<void> _pushCreate(LocalFeature feature) async {
    try {
      await client.createFeature({
        'id': feature.id,
        'project_id': feature.projectId,
        'title': feature.title,
        if (feature.description != null) 'description': feature.description,
        'status': feature.status,
        'kind': feature.kind,
        'priority': feature.priority,
        if (feature.estimate != null) 'estimate': feature.estimate,
        if (feature.assigneeId != null) 'assignee_id': feature.assigneeId,
        'labels': feature.labels,
      });
      await dao.markSynced(feature.id);
    } catch (_) {
      // Will be retried by the sync engine.
    }
  }

  Future<void> _pushUpdate(String id) async {
    try {
      final feature = await dao.getById(id);
      if (feature == null) return;
      await client.updateFeature(id, {
        'title': feature.title,
        if (feature.description != null) 'description': feature.description,
        'status': feature.status,
        'kind': feature.kind,
        'priority': feature.priority,
        if (feature.estimate != null) 'estimate': feature.estimate,
        if (feature.assigneeId != null) 'assignee_id': feature.assigneeId,
        'labels': feature.labels,
      });
      await dao.markSynced(id);
    } catch (_) {
      // Will be retried by the sync engine.
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
