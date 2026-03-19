import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class HydrationWidgetCard extends ConsumerWidget {
  const HydrationWidgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hydrationProvider);

    final statusColor = _statusColor(state.status);

    return GlassCard(
      onTap: () => context.go(Routes.healthHydration),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.hydration,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusDot(color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${state.totalMl} / ${state.goalMl} ml',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.progressFraction,
              minHeight: 5,
              backgroundColor: tokens.border.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: FilledButton(
              onPressed: () =>
                  ref.read(hydrationProvider.notifier).addWater(250),
              style: FilledButton.styleFrom(
                backgroundColor: statusColor.withValues(alpha: 0.15),
                foregroundColor: statusColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                l10n.addWaterMl,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(HydrationStatus status) {
    switch (status) {
      case HydrationStatus.goalReached:
        return const Color(0xFF4CAF50);
      case HydrationStatus.onTrack:
        return const Color(0xFF4CAF50);
      case HydrationStatus.slightlyBehind:
        return const Color(0xFFFF9800);
      case HydrationStatus.dehydrated:
        return const Color(0xFFF44336);
    }
  }

  Map<String, dynamic> toWidgetData() => {};
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
