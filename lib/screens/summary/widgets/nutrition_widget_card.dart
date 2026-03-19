import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class NutritionWidgetCard extends ConsumerWidget {
  const NutritionWidgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(nutritionProvider);
    final score = state.safetyScore;
    final mealCount = state.todayEntries.length;
    final statusColor = _statusColor(state.status);

    return GlassCard(
      onTap: () => context.go(Routes.healthNutrition),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_rounded, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(
                l10n.nutrition,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(state.status, l10n),
                  style: TextStyle(color: statusColor, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/100',
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                '$mealCount ${l10n.meals}',
                style: TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: tokens.border.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(NutritionStatus status) {
    switch (status) {
      case NutritionStatus.allSafe:
        return const Color(0xFF4CAF50);
      case NutritionStatus.warning:
        return const Color(0xFFFF9800);
      case NutritionStatus.critical:
        return const Color(0xFFF44336);
    }
  }

  static String _statusLabel(NutritionStatus status, AppLocalizations l10n) {
    switch (status) {
      case NutritionStatus.allSafe:
        return l10n.safe;
      case NutritionStatus.warning:
        return l10n.warning;
      case NutritionStatus.critical:
        return l10n.critical;
    }
  }

  Map<String, dynamic> toWidgetData() => {};
}
