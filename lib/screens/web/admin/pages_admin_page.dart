import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _pagesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminPages();
  final raw = result['pages'] as List<dynamic>? ?? <dynamic>[];
  return raw.cast<Map<String, dynamic>>();
});

// ── Shared input decoration ──────────────────────────────────────────────────

InputDecoration _inputDecoration(OrchestraColorTokens tokens, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
    filled: true,
    fillColor: tokens.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: tokens.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: tokens.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: tokens.accent),
    ),
  );
}

// ── Dialogs ──────────────────────────────────────────────────────────────────

void _showCreatePageDialog(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final slugCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final tokens = ThemeTokens.of(context);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).newPage),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).title,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).slug,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              maxLines: 5,
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).contentLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            AppLocalizations.of(ctx).cancel,
            style: TextStyle(color: tokens.fgDim),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.createAdminPage({
              'title': titleCtrl.text,
              'slug': slugCtrl.text,
              'content': contentCtrl.text,
              'status': 'draft',
            });
            ref.invalidate(_pagesProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.bg,
          ),
          child: Text(AppLocalizations.of(ctx).create),
        ),
      ],
    ),
  );
}

void _showEditPageDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> page,
) {
  final titleCtrl = TextEditingController(text: page['title'] as String? ?? '');
  final slugCtrl = TextEditingController(text: page['slug'] as String? ?? '');
  final contentCtrl = TextEditingController(
    text: page['content'] as String? ?? '',
  );
  final tokens = ThemeTokens.of(context);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).editPage),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).title,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).slug,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              maxLines: 5,
              decoration: _inputDecoration(
                tokens,
                AppLocalizations.of(ctx).contentLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            AppLocalizations.of(ctx).cancel,
            style: TextStyle(color: tokens.fgDim),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.updateAdminPage((page['id'] as num).toInt(), {
              'title': titleCtrl.text,
              'slug': slugCtrl.text,
              'content': contentCtrl.text,
            });
            ref.invalidate(_pagesProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: tokens.bg,
          ),
          child: Text(AppLocalizations.of(ctx).save),
        ),
      ],
    ),
  );
}

void _showDeletePageDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> page,
) {
  final tokens = ThemeTokens.of(context);
  final title = page['title'] as String? ?? 'this page';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).deletePage),
      content: Text(
        AppLocalizations.of(ctx).areYouSureDelete(title),
        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            AppLocalizations.of(ctx).cancel,
            style: TextStyle(color: tokens.fgDim),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.deleteAdminPage((page['id'] as num).toInt());
            ref.invalidate(_pagesProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(ctx).delete),
        ),
      ],
    ),
  );
}

// ── Pages admin page ─────────────────────────────────────────────────────────

/// Admin static pages management page.
///
/// Fetches pages from [ApiClient.listAdminPages] and displays them with
/// title, slug, status, and last updated date. Includes a "New Page" button.
class PagesAdminPage extends ConsumerWidget {
  const PagesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final pagesAsync = ref.watch(_pagesProvider);

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
                  AppLocalizations.of(context).pages,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showCreatePageDialog(context, ref),
                  icon: Icon(Icons.add, size: 16, color: tokens.accent),
                  label: Text(
                    AppLocalizations.of(context).newPage,
                    style: TextStyle(color: tokens.accent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            pagesAsync.when(
              data: (pages) => Text(
                AppLocalizations.of(context).nStaticPages(pages.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              loading: () => Text(
                AppLocalizations.of(context).loading,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              error: (_, _) => Text(
                AppLocalizations.of(context).failedToLoadPages,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // ── Page list ───────────────────────────────────────────────────
            Expanded(
              child: pagesAsync.when(
                data: (pages) {
                  if (pages.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context).noPagesYet,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: pages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _PageTile(tokens: tokens, page: pages[index]);
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
                        AppLocalizations.of(context).failedToLoadPages,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(_pagesProvider),
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

// ── Page tile ────────────────────────────────────────────────────────────────

class _PageTile extends ConsumerWidget {
  const _PageTile({required this.tokens, required this.page});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = page['title'] as String? ?? 'Untitled';
    final slug = page['slug'] as String? ?? '';
    final updatedAt =
        page['updated_at'] as String? ?? page['created_at'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.web_outlined, size: 20, color: tokens.fgDim),
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
                        slug,
                        style: TextStyle(
                          color: tokens.fgDim,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      updatedAt.isNotEmpty
                          ? AppLocalizations.of(context).updatedDate(
                              updatedAt.length >= 10
                                  ? updatedAt.substring(0, 10)
                                  : updatedAt,
                            )
                          : '',
                      style: TextStyle(color: tokens.fgDim, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () => _showEditPageDialog(context, ref, page),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).editPageTooltip,
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () => _showDeletePageDialog(context, ref, page),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).deletePageTooltip,
          ),
        ],
      ),
    );
  }
}
