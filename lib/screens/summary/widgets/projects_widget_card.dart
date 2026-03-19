import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

final _projectsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(powersyncDatabaseProvider);
  return db.watch('SELECT * FROM projects ORDER BY updated_at DESC');
});

class ProjectsWidgetCard extends ConsumerWidget {
  const ProjectsWidgetCard({super.key});

  static const _color = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(_projectsProvider);

    return GlassCard(
      onTap: () => context.go(Routes.projects),
      padding: const EdgeInsets.all(14),
      child: async.when(
        loading: () => _body(tokens, l10n, total: null, active: null),
        error: (_, _) => _body(tokens, l10n, total: 0, active: 0),
        data: (projects) {
          final active = projects.where((p) => p['mode'] == 'active').length;
          return _body(tokens, l10n, total: projects.length, active: active);
        },
      ),
    );
  }

  Widget _body(
    OrchestraColorTokens tokens,
    AppLocalizations l10n, {
    required int? total,
    required int? active,
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
              child: const Icon(Icons.folder_rounded, color: _color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.projects,
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
          active != null ? '$active ${l10n.active}' : l10n.loading,
          style: TextStyle(color: tokens.fgDim, fontSize: 11),
        ),
      ],
    );
  }
}
