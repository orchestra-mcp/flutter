import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Resolves a widget label key to its localized string.
String _resolveLabel(AppLocalizations l10n, String key) =>
    switch (key.toLowerCase()) {
      'agents' => l10n.agents,
      'skills' => l10n.skills,
      'workflows' => l10n.workflows,
      'docs' => l10n.docs,
      'delegations' => l10n.delegations,
      'sessions' => l10n.sessions,
      'active' => l10n.active,
      'pending' => l10n.pending,
      'total' => l10n.total,
      _ => key,
    };

/// Generic analytics widget card for API-backed data (agents, skills,
/// workflows, docs, sessions, delegations).
///
/// Uses a callback [asyncDataBuilder] to obtain the data from any provider
/// type (FutureProvider or StreamProvider).
class ApiWidgetCard extends ConsumerWidget {
  const ApiWidgetCard({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    required this.asyncDataBuilder,
    this.secondaryLabel,
    this.secondaryFilter,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;

  /// Callback that watches the provider and returns AsyncValue.
  final AsyncValue<List<Map<String, dynamic>>> Function(WidgetRef ref) asyncDataBuilder;

  final String? secondaryLabel;
  final bool Function(Map<String, dynamic>)? secondaryFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final resolvedLabel = _resolveLabel(l10n, label);
    final resolvedSecondary =
        secondaryLabel != null ? _resolveLabel(l10n, secondaryLabel!) : null;
    final async = asyncDataBuilder(ref);

    return GlassCard(
      onTap: () => context.go(route),
      padding: const EdgeInsets.all(14),
      child: async.when(
        loading: () => _body(tokens, l10n, resolvedLabel, resolvedSecondary,
            total: null, secondary: null),
        error: (_, _) => _body(tokens, l10n, resolvedLabel, resolvedSecondary,
            total: 0, secondary: 0),
        data: (items) {
          final secondary = secondaryFilter != null
              ? items.where(secondaryFilter!).length
              : null;
          return _body(tokens, l10n, resolvedLabel, resolvedSecondary,
              total: items.length, secondary: secondary);
        },
      ),
    );
  }

  Widget _body(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    String displayLabel,
    String? displaySecondary, {
    required int? total,
    required int? secondary,
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              displayLabel,
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
          total == null
              ? l10n.loading
              : secondary != null && displaySecondary != null
                  ? '$secondary $displaySecondary'
                  : '$total ${l10n.total}',
          style: TextStyle(color: tokens.fgDim, fontSize: 11),
        ),
      ],
    );
  }
}
