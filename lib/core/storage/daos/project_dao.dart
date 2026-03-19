import 'package:drift/drift.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Data Access Object for [LocalProjects] table.
///
/// Provides CRUD operations and queries for project entities stored
/// in the local SQLite database.
class ProjectDao {
  ProjectDao(this._db);

  final LocalDatabase _db;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all projects ordered by most recently updated first.
  Future<List<LocalProject>> listAll() {
    return (_db.select(
      _db.localProjects,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  /// Watch all projects as a reactive stream.
  Stream<List<LocalProject>> watchAll() {
    return (_db.select(
      _db.localProjects,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();
  }

  /// Returns a single project by [id], or `null` if not found.
  Future<LocalProject?> getById(String id) {
    return (_db.select(
      _db.localProjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Watch a single project by [id].
  Stream<LocalProject?> watchById(String id) {
    return (_db.select(
      _db.localProjects,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Returns projects matching the given [mode] ('active', 'planned', 'archived').
  Future<List<LocalProject>> listByMode(String mode) {
    return (_db.select(_db.localProjects)
          ..where((t) => t.mode.equals(mode))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Full-text search across project name, description, slug, and stacks.
  /// Returns projects ranked by FTS5 BM25 relevance.
  Future<List<LocalProject>> search(String query) async {
    if (query.trim().isEmpty) return listAll();
    final ftsResults = await _db.searchProjects(query);
    if (ftsResults.isEmpty) return [];
    final ids = ftsResults.map((r) => r.id).toList();
    final projects = await (_db.select(
      _db.localProjects,
    )..where((t) => t.id.isIn(ids))).get();
    // Preserve FTS ranking order.
    final idOrder = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    projects.sort(
      (a, b) => (idOrder[a.id] ?? 999).compareTo(idOrder[b.id] ?? 999),
    );
    return projects;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new project. Returns the inserted row.
  Future<LocalProject> create({
    required String id,
    required String slug,
    required String name,
    String? description,
    String mode = 'active',
    String stacks = '[]',
    bool synced = false,
  }) async {
    final now = DateTime.now();
    final companion = LocalProjectsCompanion.insert(
      id: id,
      slug: slug,
      name: name,
      description: Value(description),
      mode: Value(mode),
      stacks: Value(stacks),
      synced: Value(synced),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.localProjects).insert(companion);
    return (await getById(id))!;
  }

  /// Upserts a project — inserts or updates on conflict.
  Future<void> upsert(LocalProjectsCompanion companion) {
    return _db.into(_db.localProjects).insertOnConflictUpdate(companion);
  }

  /// Updates an existing project by [id].
  Future<int> update(String id, LocalProjectsCompanion companion) {
    return (_db.update(
      _db.localProjects,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// Deletes a project by [id]. Returns the number of deleted rows.
  Future<int> deleteById(String id) {
    return (_db.delete(_db.localProjects)..where((t) => t.id.equals(id))).go();
  }

  /// Marks a project as synced.
  Future<void> markSynced(String id) {
    return update(id, const LocalProjectsCompanion(synced: Value(true)));
  }

  /// Returns projects that have not been synced to the server.
  Future<List<LocalProject>> listUnsynced() {
    return (_db.select(
      _db.localProjects,
    )..where((t) => t.synced.equals(false))).get();
  }

  /// Returns the total project count.
  Future<int> count() async {
    final countExp = _db.localProjects.id.count();
    final query = _db.selectOnly(_db.localProjects)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }
}
