import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

final _notesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch('SELECT * FROM notes ORDER BY updated_at DESC');
});

class NotesWidgetCard extends ConsumerWidget {
  const NotesWidgetCard({super.key});

  static const _color = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(_notesProvider);

    return GlassCard(
      onTap: () => context.go(Routes.notes),
      padding: const EdgeInsets.all(14),
      child: async.when(
        loading: () => _body(tokens, l10n, total: null, pinned: null),
        error: (_, _) => _body(tokens, l10n, total: 0, pinned: 0),
        data: (notes) {
          final pinned = notes.where((n) => (n['pinned'] as int?) == 1).length;
          return _body(tokens, l10n, total: notes.length, pinned: pinned);
        },
      ),
    );
  }

  Widget _body(
    OrchestraColorTokens tokens,
    AppLocalizations l10n, {
    required int? total,
    required int? pinned,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                color: _color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.notes,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          total != null ? '$total' : '—',
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          pinned != null ? '$pinned ${l10n.pinnedCount}' : l10n.loading,
          style: TextStyle(color: tokens.fgDim, fontSize: 11),
        ),
      ],
    );
  }
}
