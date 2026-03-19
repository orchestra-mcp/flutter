import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/state/selection_state.dart';
import 'package:orchestra/core/storage/pin_store.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/selection_app_bar.dart';

// -- Screen ------------------------------------------------------------------

/// List of delegations with assignee, feature, and status.
/// Fetches real data from [delegationsProvider].
class DelegationsScreen extends ConsumerStatefulWidget {
  const DelegationsScreen({super.key});

  @override
  ConsumerState<DelegationsScreen> createState() => _DelegationsScreenState();
}

class _DelegationsScreenState extends ConsumerState<DelegationsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final asyncDelegations = ref.watch(delegationsProvider);
    final Set<String> selectedIds = ref.watch(delegationsSelectionProvider);
    final Set<String> pinnedIds = ref.watch(delegationsPinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () => ref
                  .read(delegationsSelectionProvider.notifier)
                  .clear(),
              onDelete: () {
                showComingSoon(context, 'Delete Delegations');
                ref.read(delegationsSelectionProvider.notifier).clear();
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: tokens.fgBright, size: 20),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go(Routes.summary);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.delegations,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    asyncDelegations.whenOrNull(
                          data: (items) => Text(
                            l10n.delegationsCount(items.length),
                            style:
                                TextStyle(color: tokens.fgDim, fontSize: 13),
                          ),
                        ) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: EntitySearchBar(
                  hintText: l10n.searchDelegations,
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  tokens: tokens,
                ),
              ),
            Expanded(
              child: asyncDelegations.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadDelegations,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (delegations) {
                  if (delegations.isEmpty) {
                    return _EmptyState(tokens: tokens);
                  }
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? delegations
                      : delegations
                          .where((d) =>
                              ((d['feature_id'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((d['feature_title'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((d['assignee'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noSearchResults(_search),
                        style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      ),
                    );
                  }
                  final sorted =
                      List<Map<String, dynamic>>.from(filtered)
                        ..sort((a, b) {
                          final aId =
                              '${a['feature_id'] ?? ''}:${a['feature_title'] ?? ''}';
                          final bId =
                              '${b['feature_id'] ?? ''}:${b['feature_title'] ?? ''}';
                          final aPin = pinnedIds.contains(aId);
                          final bPin = pinnedIds.contains(bId);
                          if (aPin && !bPin) return -1;
                          if (!aPin && bPin) return 1;
                          return 0;
                        });
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final d = sorted[index];
                      final assignee =
                          (d['assignee'] as String?) ?? l10n.unknown;
                      final featureId =
                          (d['feature_id'] as String?) ?? '';
                      final featureTitle =
                          (d['feature_title'] as String?) ?? '';
                      final status =
                          (d['status'] as String?) ?? l10n.unknown;
                      final id = '$featureId:$featureTitle';
                      final isPinned = pinnedIds.contains(id);
                      return GlassListTile(
                        leadingIcon: _iconForStatus(status),
                        leadingColor:
                            _colorForStatus(status, tokens),
                        label: '$featureId: $featureTitle',
                        description:
                            l10n.assignedTo(assignee, status),
                        isPinned: isPinned,
                        isSelected: selectedIds.contains(id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(delegationsSelectionProvider
                                    .notifier)
                                .toggle(id)
                            : () => context.go(
                                '/library/delegations/${d['id'] ?? ''}'),
                        onSelect: () => ref
                            .read(
                                delegationsSelectionProvider.notifier)
                            .toggle(id),
                        onPin: () => ref
                            .read(delegationsPinProvider.notifier)
                            .toggle(id),
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onSelect: () => ref
                              .read(delegationsSelectionProvider
                                  .notifier)
                              .toggle(id),
                          onPin: () => ref
                              .read(delegationsPinProvider.notifier)
                              .toggle(id),
                          isPinned: isPinned,
                          onExportMarkdown: () => exportAsMarkdown(
                            title: '$featureId: $featureTitle',
                            content:
                                'Assignee: $assignee\nStatus: $status',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForStatus(String status) {
    return switch (status) {
      'completed' => Icons.check_circle_rounded,
      'accepted' => Icons.play_circle_rounded,
      'pending' => Icons.hourglass_top_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.radio_button_unchecked_rounded,
    };
  }

  static Color _colorForStatus(String status, OrchestraColorTokens tokens) {
    return switch (status) {
      'completed' => const Color(0xFF4ADE80),
      'accepted' => tokens.accent,
      'pending' => const Color(0xFFFBBF24),
      'rejected' => const Color(0xFFDC2626),
      _ => tokens.fgDim,
    };
  }
}

// -- Empty state -------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt_rounded,
                  size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                l10n.noDelegationsFound,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.delegatedTasksWillAppear,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
