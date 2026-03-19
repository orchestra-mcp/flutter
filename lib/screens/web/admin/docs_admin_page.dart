import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _docsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  return api.listDocs();
});

// ── Docs admin page ──────────────────────────────────────────────────────────

/// Admin documentation management page.
///
/// Fetches documentation entries from [ApiClient.listDocs] and displays them
/// with title, path, last updated date, and article count. Includes a
/// "New Doc" button.
class DocsAdminPage extends ConsumerWidget {
  const DocsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final docsAsync = ref.watch(_docsProvider);

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).documentation,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context).newDocLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            docsAsync.when(
              data: (docs) {
                final totalArticles = docs.fold<int>(
                  0,
                  (sum, d) =>
                      sum + ((d['article_count'] as num?)?.toInt() ?? 1),
                );
                return Text(
                  AppLocalizations.of(
                    context,
                  ).nSectionsNArticles(docs.length, totalArticles),
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                );
              },
              loading: () => Text(
                AppLocalizations.of(context).loading,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              error: (_, _) => Text(
                AppLocalizations.of(context).failedToLoadDocs,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // ── Doc sections list ───────────────────────────────────────────
            Expanded(
              child: docsAsync.when(
                data: (docs) {
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context).noDocumentationYet,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _DocTile(tokens: tokens, doc: docs[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 32, color: tokens.fgDim),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).failedToLoadDocs,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(_docsProvider),
                        child: Text(AppLocalizations.of(context).retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Doc tile ─────────────────────────────────────────────────────────────────

class _DocTile extends StatelessWidget {
  const _DocTile({required this.tokens, required this.doc});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> doc;

  @override
  Widget build(BuildContext context) {
    final title =
        doc['title'] as String? ?? doc['name'] as String? ?? 'Untitled';
    final path = doc['path'] as String? ?? doc['slug'] as String? ?? '';
    final updatedAt =
        doc['updated_at'] as String? ?? doc['created_at'] as String? ?? '';
    final articleCount = (doc['article_count'] as num?)?.toInt() ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 20, color: tokens.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (path.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.fgDim.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          path,
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (path.isNotEmpty) const SizedBox(width: 12),
                    if (updatedAt.isNotEmpty)
                      Text(
                        AppLocalizations.of(context).updatedDate(
                          updatedAt.length >= 10
                              ? updatedAt.substring(0, 10)
                              : updatedAt,
                        ),
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.fgDim.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context).nArticles(articleCount),
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 14, color: tokens.fgDim),
            onPressed: () {},
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).viewSection,
          ),
        ],
      ),
    );
  }
}
