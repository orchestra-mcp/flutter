import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _communityPostsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final result = await api.listAdminCommunityPosts();
      final raw = result['posts'] as List<dynamic>? ?? <dynamic>[];
      return raw.cast<Map<String, dynamic>>();
    });

// ── Search state ─────────────────────────────────────────────────────────────

class _CommunitySearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _communitySearchProvider =
    NotifierProvider<_CommunitySearchNotifier, String>(
      _CommunitySearchNotifier.new,
    );

// ── Community page ───────────────────────────────────────────────────────────

/// Admin community posts management page.
///
/// Fetches community posts from [ApiClient.listAdminCommunityPosts] and
/// displays them with title/content, author, date, and status. Includes
/// client-side search and moderation actions.
class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final query = ref.watch(_communitySearchProvider).toLowerCase();
    final postsAsync = ref.watch(_communityPostsProvider);

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text(
              AppLocalizations.of(context).community,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            postsAsync.when(
              data: (posts) => Text(
                AppLocalizations.of(context).nCommunityPosts(posts.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              loading: () => Text(
                AppLocalizations.of(context).loading,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              error: (_, _) => Text(
                AppLocalizations.of(context).failedToLoadCommunityPosts,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search ──────────────────────────────────────────────────────
            SizedBox(
              width: 320,
              child: TextField(
                onChanged: (v) =>
                    ref.read(_communitySearchProvider.notifier).update(v),
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchCommunityPosts,
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

            // ── Posts list ───────────────────────────────────────────────────
            Expanded(
              child: postsAsync.when(
                data: (posts) {
                  final filtered = posts.where((p) {
                    if (query.isEmpty) return true;
                    final title = (p['title'] as String? ?? '').toLowerCase();
                    final content = (p['content'] as String? ?? '')
                        .toLowerCase();
                    final author = (p['author'] as String? ?? '').toLowerCase();
                    return title.contains(query) ||
                        content.contains(query) ||
                        author.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? AppLocalizations.of(context).noCommunityPostsYet
                            : AppLocalizations.of(context).noPostsMatch(query),
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final post = filtered[index];
                      return _CommunityPostTile(
                        tokens: tokens,
                        post: post,
                        onEdit: () => _showEditDialog(context, ref, post),
                        onDelete: () => _showDeleteDialog(context, ref, post),
                      );
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
                        AppLocalizations.of(context).failedToLoadCommunityPosts,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(_communityPostsProvider),
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

// ── Dialogs ─────────────────────────────────────────────────────────────────

void _showEditDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> post,
) {
  final tokens = ThemeTokens.of(context);
  final currentStatus = post['status'] as String? ?? 'pending';
  String selected = currentStatus;

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: tokens.bgAlt,
            titleTextStyle: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            title: Text(AppLocalizations.of(ctx).updatePostStatus),
            content: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              dropdownColor: tokens.bgAlt,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              underline: Container(height: 1, color: tokens.border),
              items: [
                DropdownMenuItem(
                  value: 'published',
                  child: Text(AppLocalizations.of(ctx).published),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child: Text(AppLocalizations.of(ctx).approved),
                ),
                DropdownMenuItem(
                  value: 'rejected',
                  child: Text(AppLocalizations.of(ctx).rejected),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text(AppLocalizations.of(ctx).pending),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => selected = v);
              },
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
                  Navigator.of(ctx).pop();
                  final api = ref.read(apiClientProvider);
                  await api.updateAdminCommunityPost(
                    (post['id'] as num).toInt(),
                    {'status': selected},
                  );
                  ref.invalidate(_communityPostsProvider);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.bg,
                ),
                child: Text(AppLocalizations.of(ctx).save),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> post,
) {
  final tokens = ThemeTokens.of(context);
  final title = post['title'] as String? ?? 'this post';

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
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
              Navigator.of(ctx).pop();
              final api = ref.read(apiClientProvider);
              await api.deleteAdminCommunityPost((post['id'] as num).toInt());
              ref.invalidate(_communityPostsProvider);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(ctx).delete),
          ),
        ],
      );
    },
  );
}

// ── Community post tile ──────────────────────────────────────────────────────

class _CommunityPostTile extends StatelessWidget {
  const _CommunityPostTile({
    required this.tokens,
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title =
        post['title'] as String? ?? post['content'] as String? ?? 'Untitled';
    final author =
        post['author'] as String? ??
        post['user_name'] as String? ??
        AppLocalizations.of(context).unknown;
    final status = post['status'] as String? ?? 'pending';
    final createdAt = post['created_at'] as String? ?? '';

    final statusColor = switch (status) {
      'approved' || 'published' => const Color(0xFF4ADE80),
      'pending' => const Color(0xFFFBBF24),
      'flagged' || 'rejected' => const Color(0xFFF87171),
      _ => tokens.fgDim,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.forum_outlined, size: 20, color: tokens.fgDim),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      author,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        createdAt.length >= 10
                            ? createdAt.substring(0, 10)
                            : createdAt,
                        style: TextStyle(color: tokens.fgDim, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).edit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).delete,
          ),
        ],
      ),
    );
  }
}
