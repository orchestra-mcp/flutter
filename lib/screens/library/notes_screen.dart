import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/state/selection_state.dart';
import 'package:orchestra/core/storage/repositories/note_repository.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/selection_app_bar.dart';
import 'package:orchestra/widgets/smart_action_dialog.dart';

// -- Provider ----------------------------------------------------------------

/// Reactive provider for the notes list. Uses repository which routes to
/// MCP workspace on desktop or PowerSync on mobile/web.
final _notesListProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAll();
});

// -- Screen ------------------------------------------------------------------

/// List of note cards with title, excerpt, and timestamp. Supports swipe to
/// pin/delete, context menu, and multi-select.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
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
    final asyncNotes = ref.watch(_notesListProvider);
    final selectedIds = ref.watch(notesSelectionProvider);
    final inSelectionMode = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: inSelectionMode
          ? SelectionAppBar(
              selectedCount: selectedIds.length,
              onClear: () =>
                  ref.read(notesSelectionProvider.notifier).clear(),
              onSelectAll: () {
                final notes = asyncNotes.value;
                if (notes != null) {
                  ref.read(notesSelectionProvider.notifier).selectAll(
                      notes.map((Note n) => n.id).toSet());
                }
              },
              onDelete: () async {
                final repo = ref.read(noteRepositoryProvider);
                for (final id in selectedIds) {
                  await repo.delete(id);
                }
                ref.read(notesSelectionProvider.notifier).clear();
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: EntitySearchBar(
                        hintText: l10n.searchNotes,
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
                        backgroundColor: tokens.accent.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => showCreateMenu(
                        context,
                        ref,
                        type: SmartActionType.note,
                        onManualCreate: (title, content) =>
                            context.push('${Routes.notes}/new'),
                        onSmartCreate: (title, content) async {
                          final repo = ref.read(noteRepositoryProvider);
                          await repo.create(title: title, content: content);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: asyncNotes.when(
                loading: () => Center(
                    child:
                        CircularProgressIndicator(color: tokens.accent)),
                error: (e, _) => Center(
                    child: Text(l10n.failedToLoadNotes,
                        style: TextStyle(color: tokens.fgMuted))),
                data: (notes) {
                  if (notes.isEmpty) return _EmptyState(tokens: tokens);
                  final q = _search.toLowerCase();
                  final filtered = q.isEmpty
                      ? notes
                      : notes
                          .where((n) =>
                              n.title.toLowerCase().contains(q) ||
                              n.content.toLowerCase().contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noSearchResults(_search),
                        style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      ),
                    );
                  }
                  // Already sorted by the SQL query (pinned DESC, updated_at DESC)
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = filtered[index];
                      final cust = ref.watch(entityCustomizationProvider)[note.id];
                      return GlassListTile(
                        leadingIcon: cust?.icon ?? Icons.sticky_note_2_rounded,
                        leadingColor: cust?.color ?? const Color(0xFFFBBF24),
                        label: note.title,
                        description: note.content,
                        isPinned: note.pinned,
                        isSelected: selectedIds.contains(note.id),
                        onTap: inSelectionMode
                            ? () => ref
                                .read(
                                    notesSelectionProvider.notifier)
                                .toggle(note.id)
                            : () => context.push(
                                  Routes.note(note.id),
                                ),
                        onSelect: () => ref
                            .read(notesSelectionProvider.notifier)
                            .toggle(note.id),
                        onPin: () async {
                          await ref.read(noteRepositoryProvider).togglePin(note.id);
                        },
                        onDelete: () async {
                          await ref.read(noteRepositoryProvider).delete(note.id);
                        },
                        contextMenuActions:
                            buildEntityContextActions(
                          l10n: AppLocalizations.of(context),
                          onRename: () async {
                            final newName = await showRenameDialog(
                              context,
                              currentName: note.title,
                            );
                            if (newName != null) {
                              await ref
                                  .read(noteRepositoryProvider)
                                  .update(note.id, title: newName);
                            }
                          },
                          onChangeIcon: () => pickAndSaveIcon(
                              context, ref, note.id,
                              currentCodePoint: cust?.iconCodePoint),
                          onChangeColor: () => pickAndSaveColor(
                              context, ref, note.id,
                              currentColor: cust?.color),
                          onSelect: () => ref
                              .read(notesSelectionProvider.notifier)
                              .toggle(note.id),
                          onEdit: () => context.push(
                            Routes.note(note.id),
                          ),
                          onPin: () async {
                            await ref.read(noteRepositoryProvider).togglePin(note.id);
                          },
                          isPinned: note.pinned,
                          onSync: () => openSyncDialog(
                            context,
                            entityType: 'note',
                            entityId: note.id,
                          ),
                          onPublish: () async {
                            final ok = await ref
                                .read(publishServiceProvider)
                                .publishNote(note.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(ok
                                    ? AppLocalizations.of(context).notePublished
                                    : AppLocalizations.of(context).publishFailed),
                              ));
                            }
                          },
                          onExportMarkdown: () => exportAsMarkdown(
                            title: note.title,
                            content: note.content,
                          ),
                          onDelete: () async {
                            await ref.read(noteRepositoryProvider).delete(note.id);
                          },
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
              Icon(Icons.sticky_note_2_rounded,
                  size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                l10n.noNotesYet,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notesWillAppear,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
