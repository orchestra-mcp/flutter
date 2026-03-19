import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Service that reads REST API responses (originally backed by markdown
/// files in `.projects/`) and bulk-inserts them into the local SQLite
/// [LocalDatabase].
///
/// Handles deduplication via primary-key conflict resolution
/// (insertOnConflictUpdate). Call [importAll] for a full sync, or use
/// individual methods for incremental imports.
class MarkdownImporter {
  MarkdownImporter({required this.db, required this.client});

  final LocalDatabase db;
  final ApiClient client;

  /// Import everything: projects, features, and notes.
  /// Returns a summary of how many rows were imported per entity type.
  Future<ImportSummary> importAll() async {
    final projects = await importProjects();
    final features = await importFeatures();
    final notes = await importNotes();
    // Rebuild FTS5 indexes after bulk import.
    await db.rebuildFtsIndexes();
    return ImportSummary(projects: projects, features: features, notes: notes);
  }

  // ── Projects ─────────────────────────────────────────────────────────────

  /// Fetches all projects from the REST API and upserts into SQLite.
  /// Returns the number of projects imported.
  Future<int> importProjects() async {
    final items = await client.listProjects();
    for (final p in items) {
      final id = p['id'] as String;
      final slug = (p['slug'] as String?) ?? id;
      final stacks = p['stacks'];
      final stacksJson = stacks is List
          ? jsonEncode(stacks)
          : (stacks as String?) ?? '[]';

      await db
          .into(db.localProjects)
          .insertOnConflictUpdate(
            LocalProjectsCompanion.insert(
              id: id,
              slug: slug,
              name: (p['name'] as String?) ?? slug,
              description: Value(p['description'] as String?),
              mode: Value((p['mode'] as String?) ?? 'active'),
              stacks: Value(stacksJson),
              synced: const Value(true),
              createdAt: _parseDate(p['created_at']),
              updatedAt: _parseDate(p['updated_at']),
            ),
          );
    }
    return items.length;
  }

  // ── Features ─────────────────────────────────────────────────────────────

  /// Fetches all features from the REST API and upserts into SQLite.
  /// Returns the number of features imported.
  Future<int> importFeatures() async {
    final items = await client.listFeatures();
    for (final f in items) {
      final labels = f['labels'];
      final labelsJson = labels is List
          ? jsonEncode(labels)
          : (labels as String?) ?? '[]';

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
    return items.length;
  }

  // ── Notes ────────────────────────────────────────────────────────────────

  /// Fetches all notes from the REST API and upserts into SQLite.
  /// Returns the number of notes imported.
  Future<int> importNotes() async {
    final items = await client.listNotes();
    for (final n in items) {
      final tags = n['tags'];
      final tagsJson = tags is List
          ? jsonEncode(tags)
          : (tags as String?) ?? '[]';

      await db
          .into(db.localNotes)
          .insertOnConflictUpdate(
            LocalNotesCompanion.insert(
              id: n['id'] as String,
              projectId: Value(n['project_id'] as String?),
              title: (n['title'] as String?) ?? '',
              content: Value((n['content'] as String?) ?? ''),
              pinned: Value(n['is_pinned'] as bool? ?? false),
              tags: Value(tagsJson),
              synced: const Value(true),
              createdAt: _parseDate(n['created_at']),
              updatedAt: _parseDate(n['updated_at']),
            ),
          );
    }
    return items.length;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Parses an ISO-8601 date string, falling back to [DateTime.now].
  DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Summary of a bulk import operation.
class ImportSummary {
  const ImportSummary({
    required this.projects,
    required this.features,
    required this.notes,
  });

  final int projects;
  final int features;
  final int notes;

  int get total => projects + features + notes;

  @override
  String toString() =>
      'ImportSummary(projects: $projects, features: $features, notes: $notes, total: $total)';
}
