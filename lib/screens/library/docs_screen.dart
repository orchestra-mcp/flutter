import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/library_provider.dart';
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

/// List of documentation files with title, file path, and last updated time.
/// Fetches real data from [docsProvider].
class DocsScreen extends ConsumerStatefulWidget {
  const DocsScreen({super.key});

  @override
  ConsumerState<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends ConsumerState<DocsScreen> {
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
    final asyncDocs = ref.watch(docsProvider);
    final Set<String> selectedIds = ref.watch(docsSelectionProvider);
    final Set<String> pinnedIds = ref.watch(docsPinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(docsSelectionProvider.notifier).clear(),
              onDelete: () {
                showComingSoon(context, 'Delete Docs');
                ref.read(docsSelectionProvider.notifier).clear();
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
                        hintText: l10n.searchDocs,
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
                      onPressed: () => context.push('/library/docs/new'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: asyncDocs.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadDocs,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (docs) {
                  if (docs.isEmpty) {
                    return MobileEmptyState(
                      icon: Icons.description_rounded,
                      title: l10n.noDocsFound,
                      subtitle: l10n.docsWillAppear,
                    );
                  }
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? docs
                      : docs
                          .where((d) =>
                              ((d['title'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((d['path'] as String?) ?? '')
                                  .toLowerCase()
                                  .contains(q) ||
                              ((d['content'] as String?) ?? (d['body'] as String?) ?? '')
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
                  final sorted = List<Map<String, dynamic>>.from(filtered)
                    ..sort((a, b) {
                      final aId = (a['id'] as String?) ??
                          (a['slug'] as String?) ??
                          (a['title'] ?? '');
                      final bId = (b['id'] as String?) ??
                          (b['slug'] as String?) ??
                          (b['title'] ?? '');
                      final bool aPin = pinnedIds.contains(aId);
                      final bool bPin = pinnedIds.contains(bId);
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
                      final doc = sorted[index];
                      final title =
                          (doc['title'] as String?) ?? 'Untitled';
                      final path = (doc['path'] as String?) ?? '';
                      final updatedAt =
                          (doc['updated_at'] as String?) ?? '';
                      final content =
                          (doc['content'] as String?) ?? '';
                      final id = (doc['id'] as String?) ??
                          (doc['slug'] as String?) ??
                          title;
                      final bool isPinned = pinnedIds.contains(id);
                      final cust = ref.watch(entityCustomizationProvider)[id];
                      return GlassListTile(
                        leadingIcon: cust?.icon ?? Icons.description_rounded,
                        leadingColor: cust?.color ?? const Color(0xFF60A5FA),
                        label: title,
                        description: '$path -- $updatedAt',
                        isPinned: isPinned,
                        isSelected: selectedIds.contains(id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(docsSelectionProvider.notifier)
                                .toggle(id)
                            : () => context.push(Routes.doc(id)),
                        onSelect: () => ref
                            .read(docsSelectionProvider.notifier)
                            .toggle(id),
                        onPin: () =>
                            ref.read(docsPinProvider.notifier).toggle(id),
                        contextMenuActions: buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onSelect: () => ref
                              .read(docsSelectionProvider.notifier)
                              .toggle(id),
                          onPin: () => ref
                              .read(docsPinProvider.notifier)
                              .toggle(id),
                          isPinned: isPinned,
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'doc',
                            entityId: id,
                            ref: ref,
                            entityData: Map<String, dynamic>.from(doc),
                          ),
                          onExportMarkdown: () => exportAsMarkdown(
                            title: title,
                            content: content.isNotEmpty
                                ? content
                                : 'Path: $path',
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
