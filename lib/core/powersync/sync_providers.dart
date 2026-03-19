import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';

/// PowerSync-backed reactive providers for all synced entities.
///
/// These replace the API-only FutureProviders with watched queries that
/// auto-update when data changes locally or via sync from other devices.

// ── Notes ──────────────────────────────────────────────────────────────────

final syncedNotesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM notes ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Projects ───────────────────────────────────────────────────────────────

final syncedProjectsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM projects ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Features ───────────────────────────────────────────────────────────────

final syncedFeaturesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM features WHERE project_id = ? ORDER BY updated_at DESC',
    parameters: [projectId],
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Agents ─────────────────────────────────────────────────────────────────

final syncedAgentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM agents ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Skills ─────────────────────────────────────────────────────────────────

final syncedSkillsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM skills ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Workflows ──────────────────────────────────────────────────────────────

final syncedWorkflowsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  // Deduplicate by name+project_slug, keeping the row with the latest updated_at.
  return db.watch(
    'SELECT w.* FROM workflows w '
    'INNER JOIN ('
    '  SELECT name, COALESCE(project_slug, \'\') AS ps, MAX(updated_at) AS max_updated '
    '  FROM workflows GROUP BY name, COALESCE(project_slug, \'\')'
    ') latest ON w.name = latest.name '
    'AND COALESCE(w.project_slug, \'\') = latest.ps '
    'AND w.updated_at = latest.max_updated '
    'ORDER BY w.updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Docs ───────────────────────────────────────────────────────────────────

final syncedDocsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM docs ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Delegations ────────────────────────────────────────────────────────────

final syncedDelegationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM delegations ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Sessions ───────────────────────────────────────────────────────────────

final syncedSessionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM sessions ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Plans ─────────────────────────────────────────────────────────────────

final syncedPlansProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, projectSlug) {
  final db = ref.watch(powersyncDatabaseProvider);
  if (projectSlug != null && projectSlug.isNotEmpty) {
    return db.watch(
      'SELECT * FROM plans WHERE project_slug = ? ORDER BY updated_at DESC',
      parameters: [projectSlug],
    ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
  }
  return db.watch(
    'SELECT * FROM plans ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Requests ──────────────────────────────────────────────────────────────

final syncedRequestsProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, projectSlug) {
  final db = ref.watch(powersyncDatabaseProvider);
  if (projectSlug != null && projectSlug.isNotEmpty) {
    return db.watch(
      'SELECT * FROM requests WHERE project_slug = ? ORDER BY updated_at DESC',
      parameters: [projectSlug],
    ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
  }
  return db.watch(
    'SELECT * FROM requests ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── Persons ───────────────────────────────────────────────────────────────

final syncedPersonsProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((ref, projectSlug) {
  final db = ref.watch(powersyncDatabaseProvider);
  if (projectSlug != null && projectSlug.isNotEmpty) {
    return db.watch(
      'SELECT * FROM persons WHERE project_slug = ? ORDER BY updated_at DESC',
      parameters: [projectSlug],
    ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
  }
  return db.watch(
    'SELECT * FROM persons ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});

// ── User Settings ──────────────────────────────────────────────────────────

final syncedUserSettingsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch(
    'SELECT * FROM user_settings ORDER BY updated_at DESC',
  ).map((results) => results.map((r) => Map<String, dynamic>.from(r)).toList());
});
