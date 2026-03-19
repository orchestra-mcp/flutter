import 'dart:math';

import 'package:orchestra/core/storage/daos/feature_dao.dart';
import 'package:orchestra/core/storage/daos/note_dao.dart';
import 'package:orchestra/features/rag/local_search_service.dart';

/// Builds context strings from search results for AI prompts.
///
/// Uses [LocalSearchService] to find relevant local data, then formats
/// it into structured text that can be prepended to AI model prompts
/// to provide project-aware context.
class ContextBuilder {
  ContextBuilder({
    required this.searchService,
    required this.featureDao,
    required this.noteDao,
  });

  final LocalSearchService searchService;
  final FeatureDao featureDao;
  final NoteDao noteDao;

  /// Rough estimate: 1 token ~= 4 characters for English text.
  static const int _charsPerToken = 4;

  /// Builds a context string from search results for a given [query].
  ///
  /// [maxTokens] controls the approximate maximum token budget for the
  /// returned context. The builder fills the budget greedily from the
  /// highest-ranked results first.
  Future<String> buildContext(String query, {int maxTokens = 2000}) async {
    if (query.trim().isEmpty) return '';

    final maxChars = maxTokens * _charsPerToken;
    final results = await searchService.search(query, limit: 30);
    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Relevant Context');
    buffer.writeln();

    var remainingChars = maxChars - buffer.length;

    for (final result in results) {
      if (remainingChars <= 0) break;

      final section = _formatResult(result);
      if (section.length > remainingChars) {
        // Truncate to fit the budget.
        buffer.write(section.substring(0, remainingChars));
        break;
      }

      buffer.write(section);
      remainingChars -= section.length;
    }

    return buffer.toString().trimRight();
  }

  /// Returns features relevant to the given [query], formatted as context.
  ///
  /// Useful when you specifically want feature context (e.g., for status
  /// updates, code reviews, or sprint planning prompts).
  Future<String> getRelevantFeatures(String query,
      {int maxTokens = 1500}) async {
    if (query.trim().isEmpty) return '';

    final maxChars = maxTokens * _charsPerToken;
    final features = await featureDao.search(query);
    if (features.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Related Features');
    buffer.writeln();

    var remainingChars = maxChars - buffer.length;

    for (final f in features) {
      if (remainingChars <= 0) break;

      final section = StringBuffer();
      section.writeln('### ${f.id}: ${f.title}');
      section.writeln('- Status: ${f.status}');
      section.writeln('- Kind: ${f.kind}');
      section.writeln('- Priority: ${f.priority}');
      if (f.description != null && f.description!.isNotEmpty) {
        section.writeln('- Description: ${f.description}');
      }
      if (f.body != null && f.body!.isNotEmpty) {
        // Truncate body to avoid blowing the budget on one feature.
        final bodyPreview = f.body!.substring(0, min(500, f.body!.length));
        section.writeln('- Body: $bodyPreview');
      }
      section.writeln();

      final sectionStr = section.toString();
      if (sectionStr.length > remainingChars) {
        buffer.write(sectionStr.substring(0, remainingChars));
        break;
      }

      buffer.write(sectionStr);
      remainingChars -= sectionStr.length;
    }

    return buffer.toString().trimRight();
  }

  /// Returns notes relevant to the given [query], formatted as context.
  ///
  /// Useful for providing documentation or knowledge-base context to
  /// AI prompts.
  Future<String> getRelevantNotes(String query,
      {int maxTokens = 1500}) async {
    if (query.trim().isEmpty) return '';

    final maxChars = maxTokens * _charsPerToken;
    final notes = await noteDao.search(query);
    if (notes.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## Related Notes');
    buffer.writeln();

    var remainingChars = maxChars - buffer.length;

    for (final n in notes) {
      if (remainingChars <= 0) break;

      final section = StringBuffer();
      section.writeln('### ${n.title}');
      if (n.content.isNotEmpty) {
        // Truncate content to avoid blowing the budget on one note.
        final contentPreview =
            n.content.substring(0, min(800, n.content.length));
        section.writeln(contentPreview);
      }
      if (n.tags != '[]') {
        section.writeln('Tags: ${n.tags}');
      }
      section.writeln();

      final sectionStr = section.toString();
      if (sectionStr.length > remainingChars) {
        buffer.write(sectionStr.substring(0, remainingChars));
        break;
      }

      buffer.write(sectionStr);
      remainingChars -= sectionStr.length;
    }

    return buffer.toString().trimRight();
  }

  // ── Formatting helpers ────────────────────────────────────────────────────

  String _formatResult(SearchResult result) {
    final buffer = StringBuffer();

    switch (result.type) {
      case SearchResultType.project:
        buffer.writeln('### Project: ${result.title}');
        buffer.writeln('- ID: ${result.id}');
        if (result.subtitle.isNotEmpty) {
          buffer.writeln('- Description: ${result.subtitle}');
        }
        final mode = result.metadata['mode'];
        if (mode != null) buffer.writeln('- Mode: $mode');
        final stacks = result.metadata['stacks'];
        if (stacks != null && stacks != '[]') {
          buffer.writeln('- Stacks: $stacks');
        }

      case SearchResultType.feature:
        buffer.writeln('### Feature: ${result.title}');
        buffer.writeln('- ID: ${result.id}');
        final status = result.metadata['status'];
        if (status != null) buffer.writeln('- Status: $status');
        final kind = result.metadata['kind'];
        if (kind != null) buffer.writeln('- Kind: $kind');
        final priority = result.metadata['priority'];
        if (priority != null) buffer.writeln('- Priority: $priority');
        if (result.subtitle.isNotEmpty) {
          buffer.writeln('- Description: ${result.subtitle}');
        }

      case SearchResultType.note:
        buffer.writeln('### Note: ${result.title}');
        buffer.writeln('- ID: ${result.id}');
        if (result.subtitle.isNotEmpty && result.subtitle != '(empty note)') {
          buffer.writeln('- Preview: ${result.subtitle}');
        }
        final tags = result.metadata['tags'];
        if (tags != null && tags != '[]') {
          buffer.writeln('- Tags: $tags');
        }
    }

    buffer.writeln();
    return buffer.toString();
  }
}
