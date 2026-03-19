import 'package:drift/drift.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Data Access Object for [LocalFeatures] table.
///
/// Provides CRUD operations, status/label filtering, and FTS5-backed
/// search for feature entities in the local SQLite database.
class FeatureDao {
  FeatureDao(this._db);

  final LocalDatabase _db;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all features ordered by most recently updated first.
  Future<List<LocalFeature>> listAll() {
    return (_db.select(_db.localFeatures)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Watch all features as a reactive stream.
  Stream<List<LocalFeature>> watchAll() {
    return (_db.select(_db.localFeatures)
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Returns a single feature by [id], or `null` if not found.
  Future<LocalFeature?> getById(String id) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch a single feature by [id].
  Stream<LocalFeature?> watchById(String id) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Returns all features belonging to [projectId].
  Future<List<LocalFeature>> listByProject(String projectId) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Watch features for a specific project.
  Stream<List<LocalFeature>> watchByProject(String projectId) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Returns features matching a given [status] ('todo', 'in-progress', etc.).
  Future<List<LocalFeature>> listByStatus(String status) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Returns features matching a given [kind] ('feature', 'bug', 'hotfix', 'chore').
  Future<List<LocalFeature>> listByKind(String kind) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.kind.equals(kind))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Returns features that contain [label] in their JSON labels array.
  /// Uses a LIKE query against the serialised JSON text.
  Future<List<LocalFeature>> listByLabel(String label) {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.labels.like('%"$label"%'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Full-text search across feature title, description, body, and labels.
  /// Returns features ranked by FTS5 BM25 relevance.
  Future<List<LocalFeature>> search(String query) async {
    if (query.trim().isEmpty) return listAll();
    final ftsResults = await _db.searchFeatures(query);
    if (ftsResults.isEmpty) return [];
    final ids = ftsResults.map((r) => r.id).toList();
    final features = await (_db.select(_db.localFeatures)
          ..where((t) => t.id.isIn(ids)))
        .get();
    // Preserve FTS ranking order.
    final idOrder = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    features.sort(
        (a, b) => (idOrder[a.id] ?? 999).compareTo(idOrder[b.id] ?? 999));
    return features;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new feature. Returns the inserted row.
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
    String labels = '[]',
    String? evidence,
    String? body,
    bool synced = false,
  }) async {
    final now = DateTime.now();
    final companion = LocalFeaturesCompanion.insert(
      id: id,
      projectId: projectId,
      title: title,
      description: Value(description),
      status: Value(status),
      kind: Value(kind),
      priority: Value(priority),
      estimate: Value(estimate),
      assigneeId: Value(assigneeId),
      labels: Value(labels),
      evidence: Value(evidence),
      body: Value(body),
      synced: Value(synced),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.localFeatures).insert(companion);
    return (await getById(id))!;
  }

  /// Upserts a feature — inserts or updates on conflict.
  Future<void> upsert(LocalFeaturesCompanion companion) {
    return _db.into(_db.localFeatures).insertOnConflictUpdate(companion);
  }

  /// Updates an existing feature by [id].
  Future<int> update(String id, LocalFeaturesCompanion companion) {
    return (_db.update(_db.localFeatures)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Deletes a feature by [id]. Returns the number of deleted rows.
  Future<int> deleteById(String id) {
    return (_db.delete(_db.localFeatures)..where((t) => t.id.equals(id))).go();
  }

  /// Marks a feature as synced.
  Future<void> markSynced(String id) {
    return update(id, const LocalFeaturesCompanion(synced: Value(true)));
  }

  /// Returns features that have not been synced to the server.
  Future<List<LocalFeature>> listUnsynced() {
    return (_db.select(_db.localFeatures)
          ..where((t) => t.synced.equals(false)))
        .get();
  }

  /// Returns the feature count, optionally filtered by [projectId].
  Future<int> count({String? projectId}) async {
    final countExp = _db.localFeatures.id.count();
    final query = _db.selectOnly(_db.localFeatures)..addColumns([countExp]);
    if (projectId != null) {
      query.where(_db.localFeatures.projectId.equals(projectId));
    }
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Returns feature count grouped by status for a given project.
  Future<Map<String, int>> countByStatus({String? projectId}) async {
    final countExp = _db.localFeatures.id.count();
    final statusCol = _db.localFeatures.status;
    final query = _db.selectOnly(_db.localFeatures)
      ..addColumns([statusCol, countExp])
      ..groupBy([statusCol]);
    if (projectId != null) {
      query.where(_db.localFeatures.projectId.equals(projectId));
    }
    final rows = await query.get();
    return {
      for (final row in rows)
        (row.read(statusCol) ?? 'unknown'): row.read(countExp) ?? 0,
    };
  }
}
