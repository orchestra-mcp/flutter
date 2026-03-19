import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/storage/repositories/note_repository.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// -- Screen ------------------------------------------------------------------

/// Full detail screen for a single note. Shows the title, pin indicator,
/// tags as colored chips, relative timestamp, and renders markdown content.
class NoteDetailScreen extends ConsumerStatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  Note? _note;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void didUpdateWidget(covariant NoteDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) {
      setState(() {
        _loading = true;
        _error = null;
        _note = null;
      });
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    try {
      final note = await ref
          .read(noteRepositoryProvider)
          .getById(widget.noteId);
      if (mounted) {
        setState(() {
          _note = note;
          _loading = false;
          if (note == null) _error = 'NOT_FOUND';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteNote() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNoteConfirm),
        content: Text(l10n.deleteItemMessage(_note?.title ?? l10n.note)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(noteRepositoryProvider).delete(widget.noteId);
      if (mounted) context.go(Routes.notes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToDelete}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: tokens.accent))
            : (_error != null || _note == null)
            ? _ErrorState(
                tokens: tokens,
                message: _error == 'NOT_FOUND'
                    ? AppLocalizations.of(context).noteNotFound
                    : (_error ?? AppLocalizations.of(context).failedToLoadNote),
              )
            : _NoteContent(
                note: _note!,
                tokens: tokens,
                onDelete: () => _deleteNote(),
              ),
      ),
    );
  }
}

// -- Content -----------------------------------------------------------------

class _NoteContent extends StatelessWidget {
  const _NoteContent({
    required this.note,
    required this.tokens,
    required this.onDelete,
  });

  final Note note;
  final OrchestraColorTokens tokens;
  final VoidCallback onDelete;

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  List<String> _parseTags(String tagsJson) {
    if (tagsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = _parseTags(note.tags);

    return CustomScrollView(
      slivers: [
        // -- Header -----------------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + updated time
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go(Routes.notes);
                        }
                      },
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: tokens.fgBright,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.note,
                        style: TextStyle(
                          color: tokens.fgMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/library/notes/${note.id}/edit'),
                      child: Icon(
                        Icons.edit_rounded,
                        color: tokens.fgMuted,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatRelativeTime(note.updatedAt),
                      style: TextStyle(color: tokens.fgDim, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title + pin indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.pinned) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.push_pin_rounded,
                          color: Color(0xFFFBBF24),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                // Tags
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((tag) {
                      final color = _tagColor(tag);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // -- Content card -----------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: note.content.isNotEmpty
                  ? MarkdownRendererWidget(content: note.content)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              color: tokens.fgDim,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noContent,
                              style: TextStyle(
                                color: tokens.fgMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  /// Deterministic color from tag string so the same tag always gets the same
  /// color, without needing a mapping table.
  Color _tagColor(String tag) {
    const palette = [
      Color(0xFF38BDF8), // sky
      Color(0xFF4ADE80), // green
      Color(0xFFFBBF24), // amber
      Color(0xFFF472B6), // pink
      Color(0xFF818CF8), // indigo
      Color(0xFF2DD4BF), // teal
      Color(0xFFFB923C), // orange
      Color(0xFFA78BFA), // violet
    ];
    final index =
        tag.codeUnits.fold<int>(0, (sum, c) => sum + c) % palette.length;
    return palette[index];
  }
}

// -- Error state -------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadNote,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
