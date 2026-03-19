import 'dart:convert';

import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/storage/daos/note_dao.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// Plain Dart model for a note, replacing the Drift-generated [LocalNote].
///
/// Fields map 1:1 to the PowerSync `notes` table columns.
class Note {
  Note({
    required this.id,
    required this.userId,
    required this.title,
    this.content = '',
    this.pinned = false,
    this.tags = '[]',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String title;
  final String content;
  final bool pinned;

  /// JSON-encoded list of tag strings, e.g. `'["dart","flutter"]'`.
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Construct a [Note] from a row map.
  /// Handles both PowerSync format (content) and MCP format (body).
  factory Note.fromRow(Map<String, dynamic> row) {
    // MCP uses 'body', PowerSync/REST uses 'content'.
    final content = row['content']?.toString() ??
        row['body']?.toString() ?? '';

    // MCP may return pinned as bool, PowerSync as int.
    final pinnedRaw = row['pinned'];
    final pinned = pinnedRaw is bool ? pinnedRaw : (pinnedRaw as num?)?.toInt() == 1;

    // MCP may return tags as List, PowerSync as JSON string.
    final tagsRaw = row['tags'];
    final tags = tagsRaw is List ? jsonEncode(tagsRaw) : tagsRaw?.toString() ?? '[]';

    return Note(
      id: row['id']?.toString() ?? '',
      userId: (row['user_id'] as num?)?.toInt() ?? 0,
      title: row['title']?.toString() ?? '',
      content: content,
      pinned: pinned,
      tags: tags,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

const _uuid = Uuid();

/// Repository for notes — supports two backends:
///
/// - **PowerSync** (mobile/web): reads/writes via PowerSync local SQLite,
///   auto-syncs to/from PostgreSQL.
/// - **Drift + MCP** (desktop): reads from MCP workspace via the API client,
///   writes to local Drift DB + pushes to MCP.
class NoteRepository {
  /// PowerSync-backed constructor (mobile/web).
  NoteRepository({required PowerSyncDatabase db})
      : _db = db,
        _dao = null,
        _client = null,
        _localDb = null;

  /// Drift + MCP-backed constructor (desktop).
  NoteRepository.fromDrift({
    required NoteDao dao,
    required ApiClient client,
    required LocalDatabase db,
  })  : _db = null,
        _dao = dao,
        _client = client,
        _localDb = db;

  final PowerSyncDatabase? _db;
  final NoteDao? _dao;
  final ApiClient? _client;
  final LocalDatabase? _localDb;

  bool get _usePowerSync => _db != null;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all notes ordered by most recently updated.
  Future<List<Note>> listAll({bool forceRefresh = false}) async {
    if (_usePowerSync) {
      final results = await _db!.getAll(
        'SELECT * FROM notes ORDER BY pinned DESC, updated_at DESC',
      );
      return results.map(Note.fromRow).toList();
    }
    // Desktop: read from MCP workspace via API client.
    final notes = await _client!.listNotes();
    return notes.map(Note.fromRow).toList();
  }

  /// Watch all notes as a reactive stream.
  /// On mobile: PowerSync auto-updates.
  /// On desktop: returns single-shot (use ref.invalidate to refresh).
  Stream<List<Note>> watchAll() {
    if (_usePowerSync) {
      return _db!
          .watch('SELECT * FROM notes ORDER BY pinned DESC, updated_at DESC')
          .map((rows) => rows.map(Note.fromRow).toList());
    }
    return Stream.fromFuture(listAll());
  }

  /// Returns a single note by [id], or `null` if not found.
  Future<Note?> getById(String id) async {
    if (_usePowerSync) {
      final results = await _db!.getAll(
        'SELECT * FROM notes WHERE id = ?',
        [id],
      );
      if (results.isEmpty) return null;
      return Note.fromRow(results.first);
    }
    // Desktop: read from MCP workspace via API client.
    final data = await _client!.getNote(id);
    return Note.fromRow(data);
  }

  /// Watch a single note by [id].
  Stream<Note?> watchById(String id) {
    if (_usePowerSync) {
      return _db!
          .watch('SELECT * FROM notes WHERE id = ?', parameters: [id])
          .map((rows) => rows.isEmpty ? null : Note.fromRow(rows.first));
    }
    return Stream.fromFuture(getById(id)).asBroadcastStream();
  }

  /// Filter notes by tag (LIKE match against JSON-encoded tags column).
  Future<List<Note>> listByTag(String tag) async {
    if (_usePowerSync) {
      final results = await _db!.getAll(
        'SELECT * FROM notes WHERE tags LIKE ? ORDER BY pinned DESC, updated_at DESC',
        ['%"$tag"%'],
      );
      return results.map(Note.fromRow).toList();
    }
    final all = await listAll();
    return all.where((n) => n.tags.contains('"$tag"')).toList();
  }

  /// Get only pinned notes.
  Future<List<Note>> listPinned() async {
    if (_usePowerSync) {
      final results = await _db!.getAll(
        'SELECT * FROM notes WHERE pinned = 1 ORDER BY updated_at DESC',
      );
      return results.map(Note.fromRow).toList();
    }
    final all = await listAll();
    return all.where((n) => n.pinned).toList();
  }

  /// Search notes by title or content (simple LIKE search).
  Future<List<Note>> search(String query) async {
    if (query.trim().isEmpty) return listAll();
    if (_usePowerSync) {
      final pattern = '%${query.trim()}%';
      final results = await _db!.getAll(
        'SELECT * FROM notes WHERE title LIKE ? OR content LIKE ? '
        'ORDER BY pinned DESC, updated_at DESC',
        [pattern, pattern],
      );
      return results.map(Note.fromRow).toList();
    }
    final all = await listAll();
    final q = query.trim().toLowerCase();
    return all.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.content.toLowerCase().contains(q)).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Creates a new note.
  /// - Mobile: writes to PowerSync local SQLite → CRUD uploads to API.
  /// - Desktop: writes via API client (MCP) to workspace.
  Future<Note> create({
    String? id,
    required String title,
    String content = '',
    bool pinned = false,
    List<String> tags = const [],
    int userId = 0,
  }) async {
    final noteId = id ?? _uuid.v4();

    if (_usePowerSync) {
      final now = DateTime.now().toIso8601String();
      final tagsJson = jsonEncode(tags);
      await _db!.execute(
        'INSERT INTO notes(id, user_id, title, content, pinned, tags, created_at, updated_at) '
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?)',
        [noteId, userId, title, content, pinned ? 1 : 0, tagsJson, now, now],
      );
      return (await getById(noteId))!;
    }

    // Desktop: create via API client (MCP workspace).
    final data = await _client!.createNote({
      'id': noteId,
      'title': title,
      'content': content,
      'pinned': pinned,
    });
    return Note.fromRow(data);
  }

  /// Updates an existing note.
  Future<void> update(
    String id, {
    String? title,
    String? content,
    bool? pinned,
    List<String>? tags,
  }) async {
    if (_usePowerSync) {
      final sets = <String>[];
      final params = <dynamic>[];
      if (title != null) { sets.add('title = ?'); params.add(title); }
      if (content != null) { sets.add('content = ?'); params.add(content); }
      if (pinned != null) { sets.add('pinned = ?'); params.add(pinned ? 1 : 0); }
      if (tags != null) { sets.add('tags = ?'); params.add(jsonEncode(tags)); }
      if (sets.isEmpty) return;
      sets.add('updated_at = ?');
      params.add(DateTime.now().toIso8601String());
      params.add(id);
      await _db!.execute('UPDATE notes SET ${sets.join(', ')} WHERE id = ?', params);
      return;
    }

    // Desktop: update via API client (MCP workspace).
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (pinned != null) body['pinned'] = pinned;
    if (tags != null) body['tags'] = jsonEncode(tags);
    await _client!.updateNote(id, body);
  }

  /// Deletes a note by [id].
  Future<void> delete(String id) async {
    if (_usePowerSync) {
      await _db!.execute('DELETE FROM notes WHERE id = ?', [id]);
      return;
    }
    await _client!.deleteNote(id);
  }

  /// Toggles the pinned state of a note.
  Future<void> togglePin(String id) async {
    final note = await getById(id);
    if (note == null) return;
    await update(id, pinned: !note.pinned);
  }
}
