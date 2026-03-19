import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _postsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminPages();
  final raw = result['pages'] as List<dynamic>? ?? <dynamic>[];
  return raw.cast<Map<String, dynamic>>();
});

// ── Search state ─────────────────────────────────────────────────────────────

class _PostSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _postSearchProvider = NotifierProvider<_PostSearchNotifier, String>(
  _PostSearchNotifier.new,
);

// ── Dialogs ──────────────────────────────────────────────────────────────────

void _showCreatePostDialog(BuildContext context, WidgetRef ref) {
  final titleCtrl = TextEditingController();
  final slugCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final tokens = ThemeTokens.of(context);
  String status = 'draft';

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        titleTextStyle: TextStyle(
          color: tokens.fgBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        title: Text(AppLocalizations.of(ctx).newPost),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).status,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'draft',
                    child: Text(AppLocalizations.of(ctx).draft),
                  ),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text(AppLocalizations.of(ctx).published),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => status = v);
                },
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
                'status': status,
              });
              ref.invalidate(_postsProvider);
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
    ),
  );
}

void _showEditPostDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> post,
) {
  final titleCtrl = TextEditingController(text: post['title'] as String? ?? '');
  final slugCtrl = TextEditingController(text: post['slug'] as String? ?? '');
  final contentCtrl = TextEditingController(
    text: post['content'] as String? ?? '',
  );
  final tokens = ThemeTokens.of(context);
  String status = post['status'] as String? ?? 'draft';

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        titleTextStyle: TextStyle(
          color: tokens.fgBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        title: Text(AppLocalizations.of(ctx).editPost),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).status,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'draft',
                    child: Text(AppLocalizations.of(ctx).draft),
                  ),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text(AppLocalizations.of(ctx).published),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => status = v);
                },
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
              await api.updateAdminPage((post['id'] as num).toInt(), {
                'title': titleCtrl.text,
                'slug': slugCtrl.text,
                'content': contentCtrl.text,
                'status': status,
              });
              ref.invalidate(_postsProvider);
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
    ),
  );
}

void _showDeletePostDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> post,
) {
  final tokens = ThemeTokens.of(context);
  final title = post['title'] as String? ?? 'this post';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).deletePost),
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
            await api.deleteAdminPage((post['id'] as num).toInt());
            ref.invalidate(_postsProvider);
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

// ── Posts page ───────────────────────────────────────────────────────────────

/// Admin blog posts management page.
///
/// Fetches pages from [ApiClient.listAdminPages] and displays them with
/// title, slug, date, and status (draft/published). Includes client-side
/// search filtering and a "New Post" button.
class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final query = ref.watch(_postSearchProvider).toLowerCase();
    final postsAsync = ref.watch(_postsProvider);

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
                  AppLocalizations.of(context).postsLabel,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreatePostDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context).newPost),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            postsAsync.when(
              data: (posts) => Text(
                AppLocalizations.of(context).nPostsTotal(posts.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              loading: () => Text(
                AppLocalizations.of(context).loading,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              error: (_, _) => Text(
                AppLocalizations.of(context).failedToLoadPosts,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search ──────────────────────────────────────────────────────
            SizedBox(
              width: 320,
              child: TextField(
                onChanged: (v) =>
                    ref.read(_postSearchProvider.notifier).update(v),
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchPosts,
                  hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18, color: tokens.fgDim),
                  filled: true,
                  fillColor: tokens.bgAlt,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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

            // ── Post list ───────────────────────────────────────────────────
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  final filtered = posts.where((p) {
                    if (query.isEmpty) return true;
                    final title = (p['title'] as String? ?? '').toLowerCase();
                    final slug = (p['slug'] as String? ?? '').toLowerCase();
                    return title.contains(query) || slug.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? AppLocalizations.of(context).noPostsYet
                            : AppLocalizations.of(context).noPostsMatch(query),
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _PostTile(tokens: tokens, post: filtered[index]);
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
                        AppLocalizations.of(context).failedToLoadPosts,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(_postsProvider),
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

// ── Post tile ────────────────────────────────────────────────────────────────

class _PostTile extends ConsumerWidget {
  const _PostTile({required this.tokens, required this.post});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = post['title'] as String? ?? 'Untitled';
    final slug = post['slug'] as String? ?? '';
    final status = post['status'] as String? ?? 'draft';
    final updatedAt =
        post['updated_at'] as String? ?? post['created_at'] as String? ?? '';

    final statusColor = status == 'published'
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFBBF24);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, size: 20, color: tokens.fgDim),
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
                    Text(
                      slug,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      updatedAt.length >= 10
                          ? updatedAt.substring(0, 10)
                          : updatedAt,
                      style: TextStyle(color: tokens.fgDim, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () => _showEditPostDialog(context, ref, post),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).edit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () => _showDeletePostDialog(context, ref, post),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).delete,
          ),
        ],
      ),
    );
  }
}
