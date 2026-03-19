import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/storage/daos/feature_dao.dart';
import 'package:orchestra/core/storage/daos/note_dao.dart';
import 'package:orchestra/core/storage/daos/project_dao.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:orchestra/core/mcp/publish_service.dart';
import 'package:orchestra/core/storage/migration/markdown_importer.dart';
import 'package:orchestra/core/storage/repositories/feature_repository.dart';
import 'package:orchestra/core/storage/repositories/note_repository.dart';
import 'package:orchestra/core/storage/repositories/project_repository.dart';
import 'package:orchestra/core/utils/platform_utils.dart';

// ── Database ─────────────────────────────────────────────────────────────────

/// Workspace-scoped provider for the local SQLite database.
///
/// Watches [workspacePathProvider] so the entire database (and all downstream
/// DAOs / repositories) is automatically recreated when the user switches
/// workspaces. Each workspace gets its own Drift SQLite file.
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final workspace = ref.watch(workspacePathProvider);
  final db = LocalDatabase(workspacePath: workspace);
  ref.onDispose(db.close);
  return db;
});

// ── DAOs ─────────────────────────────────────────────────────────────────────

/// Provider for the projects Data Access Object.
final projectDaoProvider = Provider<ProjectDao>((ref) {
  return ProjectDao(ref.watch(localDatabaseProvider));
});

/// Provider for the features Data Access Object.
final featureDaoProvider = Provider<FeatureDao>((ref) {
  return FeatureDao(ref.watch(localDatabaseProvider));
});

/// Provider for the notes Data Access Object.
final noteDaoProvider = Provider<NoteDao>((ref) {
  return NoteDao(ref.watch(localDatabaseProvider));
});

// ── Repositories (offline-first) ─────────────────────────────────────────────

/// Provider for the project repository.
///
/// - **Desktop**: Uses Drift + MCP (reads from local workspace via Orchestra MCP)
/// - **Mobile/Web**: Uses PowerSync (syncs from PostgreSQL)
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  if (isDesktop) {
    return ProjectRepository.fromDrift(
      dao: ref.watch(projectDaoProvider),
      client: ref.watch(apiClientProvider),
      db: ref.watch(localDatabaseProvider),
    );
  }
  return ProjectRepository(db: ref.watch(powersyncDatabaseProvider));
});

/// Provider for the offline-first feature repository.
final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  return FeatureRepository(
    dao: ref.watch(featureDaoProvider),
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

/// Provider for the note repository.
///
/// - **Desktop**: Uses Drift + MCP (reads from local workspace via Orchestra MCP)
/// - **Mobile/Web**: Uses PowerSync (syncs from PostgreSQL)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  if (isDesktop) {
    return NoteRepository.fromDrift(
      dao: ref.watch(noteDaoProvider),
      client: ref.watch(apiClientProvider),
      db: ref.watch(localDatabaseProvider),
    );
  }
  return NoteRepository(db: ref.watch(powersyncDatabaseProvider));
});

/// Increment to force any provider watching this to refresh (e.g. sidebar notes).
class _RefreshCounter extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final notesRefreshProvider = NotifierProvider<_RefreshCounter, int>(
  _RefreshCounter.new,
);

// ── Publish Service ──────────────────────────────────────────────────────────

/// Per-item publish service for manually syncing local items to the backend.
final publishServiceProvider = Provider<PublishService>((ref) {
  return PublishService(
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
    workspacePath: ref.watch(workspacePathProvider),
  );
});

// ── Migration ────────────────────────────────────────────────────────────────

/// Provider for the markdown importer service.
/// Use this to bulk-import data from the REST API into local SQLite.
final markdownImporterProvider = Provider<MarkdownImporter>((ref) {
  return MarkdownImporter(
    db: ref.watch(localDatabaseProvider),
    client: ref.watch(apiClientProvider),
  );
});
