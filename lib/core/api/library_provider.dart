import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';

/// Library providers — platform-aware routing:
///
/// - **Desktop**: reads from API client (MCP workspace files on disk)
/// - **Mobile/Web**: reads from PowerSync (synced from PostgreSQL)

final agentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listAgents());
  }
  final db = ref.watch(powersyncDatabaseProvider);
  return db
      .watch('SELECT * FROM agents ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final skillsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listSkills());
  }
  final db = ref.watch(powersyncDatabaseProvider);
  return db
      .watch('SELECT * FROM skills ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final workflowsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listWorkflows());
  }
  final db = ref.watch(powersyncDatabaseProvider);
  // Deduplicate by name+project_slug, keeping the row with the latest updated_at.
  return db
      .watch(
        'SELECT w.* FROM workflows w '
        'INNER JOIN ('
        '  SELECT name, COALESCE(project_slug, \'\') AS ps, MAX(updated_at) AS max_updated '
        '  FROM workflows GROUP BY name, COALESCE(project_slug, \'\')'
        ') latest ON w.name = latest.name '
        'AND COALESCE(w.project_slug, \'\') = latest.ps '
        'AND w.updated_at = latest.max_updated '
        'ORDER BY w.updated_at DESC',
      )
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final docsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listDocs());
  }
  final db = ref.watch(powersyncDatabaseProvider);
  return db
      .watch('SELECT * FROM docs ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final delegationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listDelegations());
  }
  final db = ref.watch(powersyncDatabaseProvider);
  return db
      .watch('SELECT * FROM delegations ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final plansProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((
  ref,
  projectSlug,
) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    if (projectSlug != null && projectSlug.isNotEmpty) {
      return Stream.fromFuture(api.listPlans(projectSlug: projectSlug));
    }
    return Stream.fromFuture(api.listPlans(projectSlug: ''));
  }
  final db = ref.watch(powersyncDatabaseProvider);
  if (projectSlug != null && projectSlug.isNotEmpty) {
    return db
        .watch(
          'SELECT * FROM plans WHERE project_slug = ? ORDER BY updated_at DESC',
          parameters: [projectSlug],
        )
        .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
  }
  return db
      .watch('SELECT * FROM plans ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});

final requestsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String?>((
      ref,
      projectSlug,
    ) {
      if (isDesktop) {
        final api = ref.watch(apiClientProvider);
        return Stream.fromFuture(api.listRequests(projectSlug: projectSlug));
      }
      final db = ref.watch(powersyncDatabaseProvider);
      if (projectSlug != null && projectSlug.isNotEmpty) {
        return db
            .watch(
              'SELECT * FROM requests WHERE project_slug = ? ORDER BY updated_at DESC',
              parameters: [projectSlug],
            )
            .map(
              (r) => r.map((row) => Map<String, dynamic>.from(row)).toList(),
            );
      }
      return db
          .watch('SELECT * FROM requests ORDER BY updated_at DESC')
          .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
    });

final personsProvider = StreamProvider.family<List<Map<String, dynamic>>, String?>((
  ref,
  projectSlug,
) {
  if (isDesktop) {
    final api = ref.watch(apiClientProvider);
    return Stream.fromFuture(api.listPersons(projectSlug: projectSlug));
  }
  final db = ref.watch(powersyncDatabaseProvider);
  if (projectSlug != null && projectSlug.isNotEmpty) {
    return db
        .watch(
          'SELECT * FROM persons WHERE project_slug = ? ORDER BY updated_at DESC',
          parameters: [projectSlug],
        )
        .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
  }
  return db
      .watch('SELECT * FROM persons ORDER BY updated_at DESC')
      .map((r) => r.map((row) => Map<String, dynamic>.from(row)).toList());
});
