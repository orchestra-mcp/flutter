import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/state/selection_state.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/storage/repositories/project_repository.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/mobile_empty_state.dart';
import 'package:orchestra/widgets/selection_app_bar.dart';

// -- Providers ----------------------------------------------------------------

/// Watches all projects reactively from PowerSync.
final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAll();
});

// -- Helpers ------------------------------------------------------------------

/// Generates a deterministic color from a project ID.
Color _projectColor(String id) {
  const colors = [
    Color(0xFF38BDF8),
    Color(0xFFA78BFA),
    Color(0xFF4ADE80),
    Color(0xFFFBBF24),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
  ];
  return colors[id.hashCode.abs() % colors.length];
}

// -- Screen -------------------------------------------------------------------

/// List of projects with name, description, and status. Uses [GlassListTile]
/// for consistent list styling across the app.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
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
    final asyncProjects = ref.watch(projectsProvider);
    final Set<String> selectedIds = ref.watch(projectsSelectionProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(projectsSelectionProvider.notifier).clear(),
              onSelectAll: () {
                final projects = asyncProjects.value;
                if (projects != null) {
                  ref.read(projectsSelectionProvider.notifier).selectAll(
                      projects.map((p) => p.id).toSet());
                }
              },
              onDelete: () async {
                for (final id in selectedIds) {
                  await ref.read(projectRepositoryProvider).delete(id);
                }
                ref.read(projectsSelectionProvider.notifier).clear();
                ref.invalidate(projectsProvider);
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
                        hintText: l10n.searchProjects,
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
                      onPressed: () {
                        // TODO(projects): Show create project dialog.
                      },
                    ),
                  ],
                ),
              ),
            // -- Body --
            Expanded(
              child: asyncProjects.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: tokens.accent),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: tokens.fgDim, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          l10n.failedToLoadProjects,
                          style: TextStyle(
                            color: tokens.fgMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.invalidate(projectsProvider),
                          child: Text(
                            l10n.retry,
                            style: TextStyle(color: tokens.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return MobileEmptyState(
                      icon: Icons.folder_off_rounded,
                      title: l10n.noProjects,
                      subtitle: '',
                    );
                  }

                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? projects
                      : projects
                          .where((p) =>
                              p.name.toLowerCase().contains(q) ||
                              (p.description ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              p.mode.toLowerCase().contains(q))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noSearchResults(_search),
                        style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = filtered[index];
                      final id = project.id;
                      final cust = ref.watch(entityCustomizationProvider)[id];
                      final color =
                          cust?.color ?? _projectColor(project.id);
                      return GlassListTile(
                        leadingIcon:
                            cust?.icon ?? Icons.folder_rounded,
                        leadingColor: color,
                        label: project.name,
                        description: project.description ?? project.mode,
                        isSelected: selectedIds.contains(id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(projectsSelectionProvider.notifier)
                                .toggle(id)
                            : () =>
                                context.push(Routes.project(project.id)),
                        onSelect: () => ref
                            .read(projectsSelectionProvider.notifier)
                            .toggle(id),
                        onDelete: () async {
                          await ref
                              .read(projectRepositoryProvider)
                              .delete(id);
                          ref.invalidate(projectsProvider);
                        },
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onRename: () async {
                            final newName = await showRenameDialog(
                              context,
                              currentName: project.name,
                            );
                            if (newName != null) {
                              await ref
                                  .read(projectRepositoryProvider)
                                  .update(id, name: newName);
                              ref.invalidate(projectsProvider);
                            }
                          },
                          onSelect: () => ref
                              .read(projectsSelectionProvider.notifier)
                              .toggle(id),
                          onEdit: () =>
                              context.push(Routes.project(project.id)),
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'project',
                            entityId: id,
                            ref: ref,
                            entityData: {
                              'id': project.id,
                              'name': project.name,
                              'description': project.description ?? '',
                              'mode': project.mode,
                            },
                          ),
                          onDelete: () async {
                            await ref
                                .read(projectRepositoryProvider)
                                .delete(id);
                            ref.invalidate(projectsProvider);
                          },
                          onExportMarkdown: () => exportAsMarkdown(
                            title: project.name,
                            content: project.description ?? '',
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

