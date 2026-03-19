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

// -- Screen ------------------------------------------------------------------

/// List of skills showing name, trigger command, and source path.
/// Fetches real data from [skillsProvider].
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
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
    final asyncSkills = ref.watch(skillsProvider);
    final Set<String> selectedIds = ref.watch(skillsSelectionProvider);
    final Set<String> pinnedIds = ref.watch(skillsPinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(skillsSelectionProvider.notifier).clear(),
              onDelete: () {
                showComingSoon(context, 'Delete Skills');
                ref.read(skillsSelectionProvider.notifier).clear();
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
                        hintText: l10n.searchSkills,
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
                        type: SmartActionType.skill,
                        onManualCreate: (title, content) =>
                            context.push('/library/skills/new'),
                        onSmartCreate: (title, content) async {
                          final api = ref.read(apiClientProvider);
                          await api.createSkill({'name': title, 'content': content});
                          ref.invalidate(skillsProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: asyncSkills.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadSkills,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (skills) {
                  if (skills.isEmpty) {
                    return MobileEmptyState(
                      icon: Icons.bolt_rounded,
                      title: l10n.noSkillsFound,
                      subtitle: l10n.skillsWillAppear,
                    );
                  }
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? skills
                      : skills
                          .where((s) =>
                              ((s['name'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((s['command'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((s['source'] as String?) ?? '')
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
                      final bool aPin = pinnedIds.contains(a['name'] ?? '');
                      final bool bPin = pinnedIds.contains(b['name'] ?? '');
                      if (aPin && !bPin) return -1;
                      if (!aPin && bPin) return 1;
                      return 0;
                    });
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final skill = sorted[index];
                      final name = (skill['name'] as String?) ?? 'Unknown';
                      final command = (skill['command'] as String?) ?? '';
                      final source = (skill['source'] as String?) ?? '';
                      final id = name;
                      final bool isPinned = pinnedIds.contains(id);
                      final cust = ref.watch(entityCustomizationProvider)[id];
                      return GlassListTile(
                        leadingIcon: cust?.icon ?? Icons.bolt_rounded,
                        leadingColor: cust?.color ?? const Color(0xFFF97316),
                        label: name,
                        description: '$command -- $source',
                        isPinned: isPinned,
                        isSelected: selectedIds.contains(id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(skillsSelectionProvider.notifier)
                                .toggle(id)
                            : () => context.push(Routes.skill(id)),
                        onSelect: () => ref
                            .read(skillsSelectionProvider.notifier)
                            .toggle(id),
                        onPin: () =>
                            ref.read(skillsPinProvider.notifier).toggle(id),
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onSelect: () => ref
                              .read(skillsSelectionProvider.notifier)
                              .toggle(id),
                          onPin: () => ref
                              .read(skillsPinProvider.notifier)
                              .toggle(id),
                          isPinned: isPinned,
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'skill',
                            entityId: id,
                          ),
                          onPublish: () async {
                            final ok = await ref
                                .read(publishServiceProvider)
                                .publishSkill(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(ok
                                    ? AppLocalizations.of(context).skillPublished
                                    : AppLocalizations.of(context).publishFailed),
                              ));
                            }
                          },
                          onExportMarkdown: () => exportAsMarkdown(
                            title: name,
                            content:
                                'Command: $command\nSource: $source',
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
