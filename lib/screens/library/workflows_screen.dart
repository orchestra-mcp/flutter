import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/state/selection_state.dart';
import 'package:orchestra/core/storage/pin_store.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/mobile_empty_state.dart';
import 'package:orchestra/widgets/selection_app_bar.dart';

// -- Screen ------------------------------------------------------------------

/// List of workflows with name, step count, and last updated time.
/// Fetches real data from [workflowsProvider].
class WorkflowsScreen extends ConsumerStatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  ConsumerState<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends ConsumerState<WorkflowsScreen> {
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
    final asyncWorkflows = ref.watch(workflowsProvider);
    final Set<String> selectedIds = ref.watch(workflowsSelectionProvider);
    final Set<String> pinnedIds = ref.watch(workflowsPinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(workflowsSelectionProvider.notifier).clear(),
              onDelete: () {
                showComingSoon(context, 'Delete Workflows');
                ref.read(workflowsSelectionProvider.notifier).clear();
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // -- Header: Search + Add button --
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: EntitySearchBar(
                        hintText: l10n.searchWorkflows,
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        tokens: tokens,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        icon: Icon(Icons.add_rounded,
                            color: tokens.accent, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              tokens.accent.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            context.push('/library/workflows/new'),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: asyncWorkflows.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadWorkflows,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (workflows) {
                  if (workflows.isEmpty) {
                    return MobileEmptyState(
                      icon: Icons.account_tree_rounded,
                      title: l10n.noWorkflowsFound,
                      subtitle: l10n.workflowsWillAppear,
                    );
                  }
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? workflows
                      : workflows
                          .where((w) =>
                              ((w['name'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((w['description'] as String?) ?? '')
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
                          final bool aPin =
                              pinnedIds.contains(a['id'] ?? a['name'] ?? '');
                          final bool bPin =
                              pinnedIds.contains(b['id'] ?? b['name'] ?? '');
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
                      final wf = sorted[index];
                      final title =
                          (wf['description'] as String?)?.isNotEmpty == true
                              ? wf['description'] as String
                              : (wf['name'] as String?) ?? 'Unknown';
                      final projectName =
                          (wf['name'] as String?) ?? '';
                      final states = wf['states'];
                      final stateCount = states is Map
                          ? states.length
                          : 0;
                      final transitions = wf['transitions'];
                      final transitionCount = transitions is List
                          ? transitions.length
                          : 0;
                      final gates = wf['gates'];
                      final gateCount = gates is Map
                          ? gates.length
                          : 0;
                      final initialState =
                          (wf['initial_state'] as String?) ?? 'todo';
                      final isDefault = wf['is_default'] == true;
                      final id = (wf['id'] as String?) ?? title;
                      final bool isPinned = pinnedIds.contains(id);
                      final cust = ref.watch(entityCustomizationProvider)[id];
                      return GlassListTile(
                        leadingIcon: cust?.icon ?? Icons.account_tree_rounded,
                        leadingColor: cust?.color ?? const Color(0xFFEC4899),
                        label: title,
                        description: projectName.isNotEmpty
                            ? '$projectName · $stateCount states · $transitionCount transitions'
                            : '$stateCount states · $transitionCount transitions · $gateCount gates',
                        isPinned: isPinned,
                        isSelected: selectedIds.contains(id),
                        trailing: isDefault
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.defaultBadge,
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                        onTap: inSelectionMode
                            ? () => ref
                                .read(workflowsSelectionProvider.notifier)
                                .toggle(id)
                            : () => context.push(Routes.workflow(id)),
                        onSelect: () => ref
                            .read(workflowsSelectionProvider.notifier)
                            .toggle(id),
                        onPin: () => ref
                            .read(workflowsPinProvider.notifier)
                            .toggle(id),
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onSelect: () => ref
                              .read(workflowsSelectionProvider.notifier)
                              .toggle(id),
                          onPin: () => ref
                              .read(workflowsPinProvider.notifier)
                              .toggle(id),
                          isPinned: isPinned,
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'workflow',
                            entityId: id,
                          ),
                          onPublish: () async {
                            final ok = await ref
                                .read(publishServiceProvider)
                                .publishWorkflow(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(ok
                                    ? AppLocalizations.of(context).workflowPublished
                                    : AppLocalizations.of(context).publishFailed),
                              ));
                            }
                          },
                          onExportMarkdown: () => exportAsMarkdown(
                            title: title,
                            content:
                                'States: $stateCount\nTransitions: $transitionCount\nGates: $gateCount\nInitial: $initialState\nDefault: $isDefault',
                          ),
                          onChangeIcon: () => pickAndSaveIcon(
                              context, ref, id,
                              currentCodePoint: cust?.iconCodePoint),
                          onChangeColor: () => pickAndSaveColor(
                              context, ref, id,
                              currentColor: cust?.color),
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
}
