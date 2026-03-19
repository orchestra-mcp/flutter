import 'package:drift/drift.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Data Access Object for [LocalNotes] table.
///
/// Provides CRUD operations, tag filtering, pin ordering, and FTS5-backed
/// search for note entities in the local SQLite database.
class NoteDao {
  NoteDao(this._db);

  final LocalDatabase _db;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all notes ordered by pinned first, then most recently updated.
  Future<List<LocalNote>> listAll() {
    return (_db.select(_db.localNotes)
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Watch all notes as a reactive stream.
  Stream<List<LocalNote>> watchAll() {
    return (_db.select(_db.localNotes)
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Returns a single note by [id], or `null` if not found.
  Future<LocalNote?> getById(String id) {
    return (_db.select(_db.localNotes)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch a single note by [id].
  Stream<LocalNote?> watchById(String id) {
    return (_db.select(_db.localNotes)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Returns all notes belonging to [projectId].
  Future<List<LocalNote>> listByProject(String projectId) {
    return (_db.select(_db.localNotes)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Watch notes for a specific project.
  Stream<List<LocalNote>> watchByProject(String projectId) {
    return (_db.select(_db.localNotes)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  /// Returns notes that contain [tag] in their JSON tags array.
  /// Uses a LIKE query against the serialised JSON text.
  Future<List<LocalNote>> listByTag(String tag) {
    return (_db.select(_db.localNotes)
          ..where((t) => t.tags.like('%"$tag"%'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.pinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Returns only pinned notes.
  Future<List<LocalNote>> listPinned() {
    return (_db.select(_db.localNotes)
          ..where((t) => t.pinned.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
  }

  /// Full-text search across note title, content, and tags.
  /// Returns notes ranked by FTS5 BM25 relevance.
  Future<List<LocalNote>> search(String query) async {
    if (query.trim().isEmpty) return listAll();
    final ftsResults = await _db.searchNotes(query);
    if (ftsResults.isEmpty) return [];
    final ids = ftsResults.map((r) => r.id).toList();
    final notes = await (_db.select(_db.localNotes)
          ..where((t) => t.id.isIn(ids)))
        .get();
    // Preserve FTS ranking order.
    final idOrder = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    notes
        .sort((a, b) => (idOrder[a.id] ?? 999).compareTo(idOrder[b.id] ?? 999));
    return notes;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new note. Returns the inserted row.
  Future<LocalNote> create({
    required String id,
    required String title,
    String? projectId,
    String content = '',
    bool pinned = false,
    String tags = '[]',
    bool synced = false,
  }) async {
    final now = DateTime.now();
    final companion = LocalNotesCompanion.insert(
      id: id,
      projectId: Value(projectId),
      title: title,
      content: Value(content),
      pinned: Value(pinned),
      tags: Value(tags),
      synced: Value(synced),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.localNotes).insert(companion);
    return (await getById(id))!;
  }

  /// Upserts a note — inserts or updates on conflict.
  Future<void> upsert(LocalNotesCompanion companion) {
    return _db.into(_db.localNotes).insertOnConflictUpdate(companion);
  }

  /// Updates an existing note by [id].
  Future<int> update(String id, LocalNotesCompanion companion) {
    return (_db.update(_db.localNotes)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  /// Deletes a note by [id]. Returns the number of deleted rows.
  Future<int> deleteById(String id) {
    return (_db.delete(_db.localNotes)..where((t) => t.id.equals(id))).go();
  }

  /// Toggles the pinned state of a note.
  Future<void> togglePin(String id) async {
    final note = await getById(id);
    if (note == null) return;
    await update(
      id,
      LocalNotesCompanion(
        pinned: Value(!note.pinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks a note as synced.
  Future<void> markSynced(String id) {
    return update(id, const LocalNotesCompanion(synced: Value(true)));
  }

  /// Returns notes that have not been synced to the server.
  Future<List<LocalNote>> listUnsynced() {
    return (_db.select(_db.localNotes)
          ..where((t) => t.synced.equals(false)))
        .get();
  }

  /// Returns the total note count, optionally filtered by [projectId].
  Future<int> count({String? projectId}) async {
    final countExp = _db.localNotes.id.count();
    final query = _db.selectOnly(_db.localNotes)..addColumns([countExp]);
    if (projectId != null) {
      query.where(_db.localNotes.projectId.equals(projectId));
    }
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }
}
