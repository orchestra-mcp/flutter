import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminCategories();
  final raw = result['categories'] as List<dynamic>? ?? <dynamic>[];
  return raw.cast<Map<String, dynamic>>();
});

// ── Search state ─────────────────────────────────────────────────────────────

class _CategorySearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _categorySearchProvider =
    NotifierProvider<_CategorySearchNotifier, String>(
        _CategorySearchNotifier.new);

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

void _showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final slugCtrl = TextEditingController();
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
      title: Text(AppLocalizations.of(ctx).addCategory),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(ctx).name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(ctx).slug),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.createAdminCategory({
              'name': nameCtrl.text,
              'slug': slugCtrl.text,
            });
            ref.invalidate(_categoriesProvider);
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

void _showEditCategoryDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> category,
) {
  final nameCtrl =
      TextEditingController(text: category['name'] as String? ?? '');
  final slugCtrl =
      TextEditingController(text: category['slug'] as String? ?? '');
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
      title: Text(AppLocalizations.of(ctx).editCategory),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(ctx).name),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: slugCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(ctx).slug),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.updateAdminCategory(
              (category['id'] as num).toInt(),
              {
                'name': nameCtrl.text,
                'slug': slugCtrl.text,
              },
            );
            ref.invalidate(_categoriesProvider);
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

void _showDeleteCategoryDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> category,
) {
  final tokens = ThemeTokens.of(context);
  final name = category['name'] as String? ?? 'this category';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).deleteCategory),
      content: Text(
        AppLocalizations.of(ctx).areYouSureDelete(name),
        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.deleteAdminCategory(
                (category['id'] as num).toInt());
            ref.invalidate(_categoriesProvider);
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

// ── Categories page ──────────────────────────────────────────────────────────

/// Admin categories management page.
///
/// Fetches categories from [ApiClient.listAdminCategories] and displays them
/// with name, slug, and post count. Includes client-side search, an
/// "Add Category" button, and edit/delete actions per category.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final query = ref.watch(_categorySearchProvider).toLowerCase();
    final categoriesAsync = ref.watch(_categoriesProvider);

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
                  AppLocalizations.of(context).categories,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCreateCategoryDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: Text(AppLocalizations.of(context).addCategory),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.bg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Text(
              AppLocalizations.of(context).nCategories(categories.length),
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            loading: () => Text(
              AppLocalizations.of(context).loading,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            error: (_, _) => Text(
              AppLocalizations.of(context).failedToLoadCategories,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),

          // ── Search ──────────────────────────────────────────────────────
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) =>
                  ref.read(_categorySearchProvider.notifier).update(v),
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchCategories,
                hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: tokens.fgDim),
                filled: true,
                fillColor: tokens.bgAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Category list ───────────────────────────────────────────────
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final filtered = categories.where((c) {
                  if (query.isEmpty) return true;
                  final name =
                      (c['name'] as String? ?? '').toLowerCase();
                  final slug =
                      (c['slug'] as String? ?? '').toLowerCase();
                  return name.contains(query) || slug.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty
                          ? AppLocalizations.of(context).noCategoriesYet
                          : AppLocalizations.of(context).noCategoriesMatch(query),
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _CategoryTile(
                      tokens: tokens,
                      category: filtered[index],
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 32, color: tokens.fgDim),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).failedToLoadCategories,
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$error',
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(_categoriesProvider),
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

// ── Category tile ────────────────────────────────────────────────────────────

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.tokens, required this.category});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = category['name'] as String? ?? 'Untitled';
    final slug = category['slug'] as String? ?? '';
    final postCount = (category['post_count'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.label_outlined, size: 20, color: tokens.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
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
              AppLocalizations.of(context).nItems(postCount),
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon:
                Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () =>
                _showEditCategoryDialog(context, ref, category),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).edit,
          ),
          IconButton(
            icon:
                Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () =>
                _showDeleteCategoryDialog(context, ref, category),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).delete,
          ),
        ],
      ),
    );
  }
}
