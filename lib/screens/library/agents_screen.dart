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
import 'package:orchestra/widgets/smart_action_dialog.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/widgets/selection_app_bar.dart';

// -- Helpers -----------------------------------------------------------------

/// Generates a deterministic colour from a string hash so each agent gets a
/// consistent accent colour without needing one from the API.
Color _colorFromName(String name) {
  const palette = [
    Color(0xFFA78BFA), // violet
    Color(0xFF38BDF8), // sky
    Color(0xFFF97316), // orange
    Color(0xFF4ADE80), // green
    Color(0xFFEC4899), // pink
    Color(0xFFFBBF24), // amber
    Color(0xFF60A5FA), // blue
    Color(0xFF34D399), // emerald
  ];
  final index = name.hashCode.abs() % palette.length;
  return palette[index];
}

// -- Screen ------------------------------------------------------------------

/// List of agents showing name, description, and scope. Uses [GlassListTile]
/// for consistent list styling across the app.
class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
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
    final asyncAgents = ref.watch(agentsProvider);
    final Set<String> selectedIds = ref.watch(agentsSelectionProvider);
    final Set<String> pinnedIds = ref.watch(agentsPinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(agentsSelectionProvider.notifier).clear(),
              onDelete: () {
                showComingSoon(context, 'Delete Agents');
                ref.read(agentsSelectionProvider.notifier).clear();
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
                        hintText: l10n.searchAgents,
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v),
                        tokens: tokens,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.add_rounded,
                          color: tokens.accent, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            tokens.accent.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => showCreateMenu(
                        context,
                        ref,
                        type: SmartActionType.agent,
                        onManualCreate: (title, content) =>
                            context.push('/library/agents/new'),
                        onSmartCreate: (title, content) async {
                          final api = ref.read(apiClientProvider);
                          await api.createAgent({'name': title, 'content': content});
                          ref.invalidate(agentsProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Body
            Expanded(
              child: asyncAgents.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadAgents,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (agents) {
                  if (agents.isEmpty) {
                    return MobileEmptyState(
                      icon: Icons.smart_toy_rounded,
                      title: l10n.noAgentsFound,
                      subtitle: l10n.agentsWillAppear,
                    );
                  }
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? agents
                      : agents
                          .where((a) =>
                              ((a['name'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((a['description'] as String?) ?? '')
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
                  // Sort pinned first
                  final sorted = List<Map<String, dynamic>>.from(filtered)
                    ..sort((a, b) {
                      final bool aPin =
                          pinnedIds.contains(a['name'] ?? '');
                      final bool bPin =
                          pinnedIds.contains(b['name'] ?? '');
                      if (aPin && !bPin) return -1;
                      if (!aPin && bPin) return 1;
                      return 0;
                    });
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final agent = sorted[index];
                      final name =
                          (agent['name'] as String?) ?? 'Unknown';
                      final description =
                          (agent['description'] as String?) ?? '';
                      final id = name;
                      final bool isPinned = pinnedIds.contains(id);
                      final cust = ref.watch(entityCustomizationProvider)[id];
                      final color =
                          cust?.color ?? _colorFromName(name);
                      return GlassListTile(
                        leadingIcon:
                            cust?.icon ?? Icons.smart_toy_rounded,
                        leadingColor: color,
                        label: name,
                        description: description,
                        isPinned: isPinned,
                        isSelected: selectedIds.contains(id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(agentsSelectionProvider.notifier)
                                .toggle(id)
                            : () => context.push(Routes.agent(id)),
                        onSelect: () => ref
                            .read(agentsSelectionProvider.notifier)
                            .toggle(id),
                        onPin: () => ref
                            .read(agentsPinProvider.notifier)
                            .toggle(id),
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onSelect: () => ref
                              .read(agentsSelectionProvider.notifier)
                              .toggle(id),
                          onPin: () => ref
                              .read(agentsPinProvider.notifier)
                              .toggle(id),
                          isPinned: isPinned,
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'agent',
                            entityId: id,
                            ref: ref,
                            entityData: Map<String, dynamic>.from(agent),
                          ),
                          onPublish: () async {
                            final ok = await ref
                                .read(publishServiceProvider)
                                .publishAgent(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(ok
                                    ? AppLocalizations.of(context).agentPublished
                                    : AppLocalizations.of(context).publishFailed),
                              ));
                            }
                          },
                          onExportMarkdown: () {
                            exportAsMarkdown(
                              title: name,
                              content: description,
                            );
                          },
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
