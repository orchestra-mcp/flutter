import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers (API-backed) ─────────────────────────────────────────────

final _badgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.listBadgeDefinitions();
  final list = res['badges'];
  if (list is List) return list.cast<Map<String, dynamic>>();
  return <Map<String, dynamic>>[];
});

// ── Search state ────────────────────────────────────────────────────────────

class _BadgeSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider = NotifierProvider<_BadgeSearchNotifier, String>(
  _BadgeSearchNotifier.new,
);

// ── Shared input decoration ─────────────────────────────────────────────────

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

// ── Category helpers ────────────────────────────────────────────────────────

const _categories = ['achievement', 'streak', 'points', 'special'];

Color _categoryColor(String category) {
  return switch (category) {
    'achievement' => const Color(0xFFFBBF24),
    'streak' => const Color(0xFFF97316),
    'points' => const Color(0xFF3B82F6),
    'special' => const Color(0xFFA855F7),
    _ => const Color(0xFF6B7280),
  };
}

// ── Dialogs ─────────────────────────────────────────────────────────────────

void _showCreateBadgeDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final iconCtrl = TextEditingController();
  final colorCtrl = TextEditingController(text: '#3B82F6');
  final tokens = ThemeTokens.of(context);
  final l10n = AppLocalizations.of(context);
  String category = 'achievement';

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
        title: Text(l10n.adminCreateBadge),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  l10n.adminBadgeDescription,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeCategory),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => category = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeIcon),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: tokens.fgDim)),
          ),
          FilledButton(
            onPressed: () async {
              final api = ref.read(apiClientProvider);
              final slug = nameCtrl.text
                  .toLowerCase()
                  .replaceAll(RegExp('[^a-z0-9]+'), '-')
                  .replaceAll(RegExp('^-|-\$'), '');
              await api.createBadgeDefinition({
                'slug': slug,
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'category': category,
                'icon': iconCtrl.text,
                'color': colorCtrl.text,
              });
              ref.invalidate(_badgesProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.adminBadgeCreated)));
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
            ),
            child: Text(l10n.create),
          ),
        ],
      ),
    ),
  );
}

void _showEditBadgeDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> badge,
) {
  final nameCtrl = TextEditingController(text: badge['name'] as String? ?? '');
  final descCtrl = TextEditingController(
    text: badge['description'] as String? ?? '',
  );
  final iconCtrl = TextEditingController(text: badge['icon'] as String? ?? '');
  final colorCtrl = TextEditingController(
    text: badge['color'] as String? ?? '#3B82F6',
  );
  final tokens = ThemeTokens.of(context);
  final l10n = AppLocalizations.of(context);
  String category = badge['category'] as String? ?? 'achievement';

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
        title: Text(l10n.adminEditBadge),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  l10n.adminBadgeDescription,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeCategory),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => category = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeIcon),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, l10n.adminBadgeColor),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: tokens.fgDim)),
          ),
          FilledButton(
            onPressed: () async {
              final api = ref.read(apiClientProvider);
              await api.updateBadgeDefinition((badge['id'] as num).toInt(), {
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'category': category,
                'icon': iconCtrl.text,
                'color': colorCtrl.text,
              });
              ref.invalidate(_badgesProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.adminBadgeUpdated)));
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteBadgeDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> badge,
) {
  final tokens = ThemeTokens.of(context);
  final l10n = AppLocalizations.of(context);
  final name = badge['name'] as String? ?? 'this badge';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(l10n.adminDeleteBadge),
      content: Text(
        l10n.adminDeleteBadgeConfirm(name),
        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () async {
            final api = ref.read(apiClientProvider);
            await api.deleteBadgeDefinition((badge['id'] as num).toInt());
            ref.invalidate(_badgesProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.adminBadgeDeleted)));
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
}

// ── Badges admin page ───────────────────────────────────────────────────────

/// Admin page for managing badge definitions (CRUD).
///
/// Displays badges in a list with icon, name, description, category,
/// and color. Supports create, edit, and delete via dialogs.
class BadgesAdminPage extends ConsumerWidget {
  const BadgesAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final badgesAsync = ref.watch(_badgesProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  l10n.adminBadges,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showCreateBadgeDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.adminAddBadge),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Search bar ──────────────────────────────────────────
            TextField(
              onChanged: (v) => ref.read(_searchProvider.notifier).update(v),
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.adminSearchBadges,
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
            const SizedBox(height: 16),

            // ── Badge list ──────────────────────────────────────────
            Expanded(
              child: badgesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    l10n.adminFailedToLoad(e.toString()),
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                data: (badges) {
                  final filtered = searchQuery.isEmpty
                      ? badges
                      : badges.where((b) {
                          final name = (b['name'] as String? ?? '')
                              .toLowerCase();
                          final cat = (b['category'] as String? ?? '')
                              .toLowerCase();
                          return name.contains(searchQuery) ||
                              cat.contains(searchQuery);
                        }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        searchQuery.isEmpty
                            ? l10n.adminNoBadgesDefined
                            : l10n.adminNoBadgesMatching(searchQuery),
                        style: TextStyle(color: tokens.fgDim, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _BadgeTile(tokens: tokens, badge: filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge tile ──────────────────────────────────────────────────────────────

class _BadgeTile extends ConsumerWidget {
  const _BadgeTile({required this.tokens, required this.badge});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final name = badge['name'] as String? ?? '';
    final description = badge['description'] as String? ?? '';
    final category = badge['category'] as String? ?? '';
    final icon = badge['icon'] as String? ?? '';
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                icon.isNotEmpty
                    ? icon
                    : name.isNotEmpty
                    ? name[0]
                    : '?',
                style: TextStyle(
                  color: color,
                  fontSize: icon.isNotEmpty ? 20 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name and description
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
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: tokens.fgDim, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () => _showEditBadgeDialog(context, ref, badge),
            visualDensity: VisualDensity.compact,
            tooltip: l10n.edit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () => _showDeleteBadgeDialog(context, ref, badge),
            visualDensity: VisualDensity.compact,
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }
}
