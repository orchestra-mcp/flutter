import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class CaffeineWidgetCard extends ConsumerWidget {
  const CaffeineWidgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(caffeineProvider);
    final statusColor = _statusColor(state.status);
    final cleanPct = state.cleanTransitionPercent;

    return GlassCard(
      onTap: () => context.go(Routes.healthCaffeine),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon + total
          Icon(Icons.coffee_rounded, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.caffeine,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (state.overDailyLimit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF44336,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.overLimit,
                          style: const TextStyle(
                            color: Color(0xFFF44336),
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.totalMg} ${l10n.mgToday}',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Clean transition %
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${cleanPct.toInt()}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.cleanLabel,
                style: TextStyle(color: tokens.fgMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(CaffeineStatus status) {
    switch (status) {
      case CaffeineStatus.noIntake:
        return const Color(0xFF9E9E9E);
      case CaffeineStatus.clean:
        return const Color(0xFF4CAF50);
      case CaffeineStatus.transitioning:
        return const Color(0xFFFF9800);
      case CaffeineStatus.redBullDependent:
        return const Color(0xFFF44336);
    }
  }

  Map<String, dynamic> toWidgetData() => {};
}
