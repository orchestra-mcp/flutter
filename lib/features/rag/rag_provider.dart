import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/features/rag/context_builder.dart';
import 'package:orchestra/features/rag/local_search_service.dart';

// ── Search Service ──────────────────────────────────────────────────────────

/// Provider for the local full-text search service.
///
/// Uses FTS5 virtual tables in [LocalDatabase] to search across
/// projects, features, and notes.
final localSearchServiceProvider = Provider<LocalSearchService>((ref) {
  return LocalSearchService(
    db: ref.watch(localDatabaseProvider),
    projectDao: ref.watch(projectDaoProvider),
    featureDao: ref.watch(featureDaoProvider),
    noteDao: ref.watch(noteDaoProvider),
  );
});

// ── Context Builder ─────────────────────────────────────────────────────────

/// Provider for the RAG context builder.
///
/// Builds structured context strings from search results that can be
/// prepended to AI model prompts for project-aware responses.
final contextBuilderProvider = Provider<ContextBuilder>((ref) {
  return ContextBuilder(
    searchService: ref.watch(localSearchServiceProvider),
    featureDao: ref.watch(featureDaoProvider),
    noteDao: ref.watch(noteDaoProvider),
  );
});

// ── Convenience async providers ─────────────────────────────────────────────

/// FutureProvider family for searching across all local data.
/// Usage: `ref.watch(searchResultsProvider('my query'))`
final searchResultsProvider = FutureProvider.family<List<SearchResult>, String>(
  (ref, query) async {
    final service = ref.watch(localSearchServiceProvider);
    return service.search(query);
  },
);

/// FutureProvider family for building AI context from a query.
/// Usage: `ref.watch(ragContextProvider('my query'))`
final ragContextProvider = FutureProvider.family<String, String>((
  ref,
  query,
) async {
  final builder = ref.watch(contextBuilderProvider);
  return builder.buildContext(query);
});

/// FutureProvider family for getting relevant features for a query.
/// Usage: `ref.watch(relevantFeaturesProvider('my query'))`
final relevantFeaturesProvider = FutureProvider.family<String, String>((
  ref,
  query,
) async {
  final builder = ref.watch(contextBuilderProvider);
  return builder.getRelevantFeatures(query);
});

/// FutureProvider family for getting relevant notes for a query.
/// Usage: `ref.watch(relevantNotesProvider('my query'))`
final relevantNotesProvider = FutureProvider.family<String, String>((
  ref,
  query,
) async {
  final builder = ref.watch(contextBuilderProvider);
  return builder.getRelevantNotes(query);
});
