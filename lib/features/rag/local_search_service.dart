import 'package:orchestra/core/storage/daos/feature_dao.dart';
import 'package:orchestra/core/storage/daos/note_dao.dart';
import 'package:orchestra/core/storage/daos/project_dao.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Full-text search service across all local SQLite tables.
///
/// Uses the FTS5 virtual tables defined in [LocalDatabase] to provide
/// ranked search results. BM25 scoring ensures the most relevant matches
/// appear first.
class LocalSearchService {
  LocalSearchService({
    required this.db,
    required this.projectDao,
    required this.featureDao,
    required this.noteDao,
  });

  final LocalDatabase db;
  final ProjectDao projectDao;
  final FeatureDao featureDao;
  final NoteDao noteDao;

  /// Search across all entity types (projects, features, notes).
  /// Returns a unified, ranked list of [SearchResult] items.
  Future<List<SearchResult>> search(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];

    // Run all three FTS5 searches in parallel.
    final futures = await Future.wait([
      _searchProjects(query),
      _searchFeatures(query),
      _searchNotes(query),
    ]);

    results.addAll(futures[0]);
    results.addAll(futures[1]);
    results.addAll(futures[2]);

    // Sort by rank (lower = better in BM25).
    results.sort((a, b) => a.rank.compareTo(b.rank));

    // Apply limit.
    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  /// Search only projects.
  Future<List<SearchResult>> searchProjects(String query) async {
    if (query.trim().isEmpty) return [];
    return _searchProjects(query);
  }

  /// Search only features.
  Future<List<SearchResult>> searchFeatures(String query) async {
    if (query.trim().isEmpty) return [];
    return _searchFeatures(query);
  }

  /// Search only notes.
  Future<List<SearchResult>> searchNotes(String query) async {
    if (query.trim().isEmpty) return [];
    return _searchNotes(query);
  }

  // ── Private search implementations ────────────────────────────────────────

  Future<List<SearchResult>> _searchProjects(String query) async {
    final ftsResults = await db.searchProjects(query);
    if (ftsResults.isEmpty) return [];

    final ids = ftsResults.map((r) => r.id).toList();
    final rankMap = {for (final r in ftsResults) r.id: r.rank};

    final projects = await projectDao.search(query);
    final projectMap = {for (final p in projects) p.id: p};

    return ids.where((id) => projectMap.containsKey(id)).map((id) {
      final p = projectMap[id]!;
      return SearchResult(
        id: p.id,
        type: SearchResultType.project,
        title: p.name,
        subtitle: p.description ?? p.slug,
        rank: rankMap[id] ?? 0,
        metadata: {'slug': p.slug, 'mode': p.mode, 'stacks': p.stacks},
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchFeatures(String query) async {
    final ftsResults = await db.searchFeatures(query);
    if (ftsResults.isEmpty) return [];

    final ids = ftsResults.map((r) => r.id).toList();
    final rankMap = {for (final r in ftsResults) r.id: r.rank};

    final features = await featureDao.search(query);
    final featureMap = {for (final f in features) f.id: f};

    return ids.where((id) => featureMap.containsKey(id)).map((id) {
      final f = featureMap[id]!;
      return SearchResult(
        id: f.id,
        type: SearchResultType.feature,
        title: f.title,
        subtitle: f.description ?? '${f.status} | ${f.kind}',
        rank: rankMap[id] ?? 0,
        metadata: {
          'project_id': f.projectId,
          'status': f.status,
          'kind': f.kind,
          'priority': f.priority,
          'labels': f.labels,
        },
      );
    }).toList();
  }

  Future<List<SearchResult>> _searchNotes(String query) async {
    final ftsResults = await db.searchNotes(query);
    if (ftsResults.isEmpty) return [];

    final ids = ftsResults.map((r) => r.id).toList();
    final rankMap = {for (final r in ftsResults) r.id: r.rank};

    final notes = await noteDao.search(query);
    final noteMap = {for (final n in notes) n.id: n};

    return ids.where((id) => noteMap.containsKey(id)).map((id) {
      final n = noteMap[id]!;
      // Use first 120 chars of content as subtitle preview.
      final preview = n.content.length > 120
          ? '${n.content.substring(0, 120)}...'
          : n.content;
      return SearchResult(
        id: n.id,
        type: SearchResultType.note,
        title: n.title,
        subtitle: preview.isNotEmpty ? preview : '(empty note)',
        rank: rankMap[id] ?? 0,
        metadata: {
          if (n.projectId != null) 'project_id': n.projectId!,
          'pinned': n.pinned.toString(),
          'tags': n.tags,
        },
      );
    }).toList();
  }
}

/// Type of entity returned from search.
enum SearchResultType { project, feature, note }

/// A single search result with ranking metadata.
class SearchResult {
  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.rank,
    this.metadata = const {},
  });

  /// Entity ID (e.g., 'orchestra-swift', 'FEAT-HAM', 'note-abc123').
  final String id;

  /// The type of entity this result represents.
  final SearchResultType type;

  /// Display title.
  final String title;

  /// Description or content preview.
  final String subtitle;

  /// BM25 rank — lower (more negative) is better.
  final double rank;

  /// Additional metadata specific to the entity type.
  final Map<String, String> metadata;

  /// Human-readable type label.
  String get typeLabel => switch (type) {
    SearchResultType.project => 'Project',
    SearchResultType.feature => 'Feature',
    SearchResultType.note => 'Note',
  };

  @override
  String toString() => 'SearchResult($typeLabel: $title, rank: $rank)';
}
