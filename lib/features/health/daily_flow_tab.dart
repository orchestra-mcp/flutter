import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/health/health_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ─── Component row model ──────────────────────────────────────────────────────

class _Component {
  const _Component({
    required this.label,
    required this.weight,
    required this.score,
    required this.color,
  });
  final String label;
  final double weight; // 0–1
  final double score;  // 0–100
  final Color color;
}

// ─── Daily Flow Tab ───────────────────────────────────────────────────────────

/// Shows the daily composite score ring, per-component breakdown, and a
/// 7-bar weekly history chart.
class DailyFlowTab extends ConsumerWidget {
  const DailyFlowTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(healthProvider);
    final ctx = data.healthContext;

    final dailyScore = data.healthScore;

    final components = [
      _Component(
        label: l10n.pomodoros,
        weight: 0.40,
        score: ctx?.pomodoroScore ?? 0,
        color: tokens.accent,
      ),
      _Component(
        label: l10n.hydration,
        weight: 0.25,
        score: ctx?.hydrationScore ?? 0,
        color: const Color(0xFF29B6F6),
      ),
      _Component(
        label: l10n.nutrition,
        weight: 0.20,
        score: ctx?.nutritionScore ?? 0,
        color: const Color(0xFF66BB6A),
      ),
      _Component(
        label: l10n.shutdown,
        weight: 0.15,
        score: ctx?.shutdownScore ?? 0,
        color: const Color(0xFFAB47BC),
      ),
    ];

    // Placeholder 7-day bar data (today = last bar, index 6).
    final weekScores = [72.0, 58.0, 81.0, 64.0, 77.0, 55.0, dailyScore];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score ring
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (dailyScore / 100).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: tokens.border,
                    color: tokens.accent,
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dailyScore.toStringAsFixed(0),
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        l10n.dailyScore,
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Hydration: ${data.hydrationMl} / ${data.hydrationGoal} ml',
              style: TextStyle(color: tokens.fgMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 28),

          // Component breakdown
          Text(
            l10n.componentBreakdown,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...components.map((c) => _ComponentRow(c: c, tokens: tokens)),
          const SizedBox(height: 28),

          // Weekly bar chart
          Text(
            l10n.weekSummary,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: tokens.border,
                    strokeWidth: 0.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          days[idx],
                          style: TextStyle(
                            color: idx == 6
                                ? tokens.accent
                                : tokens.fgMuted,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: weekScores.asMap().entries.map((e) {
                  final isToday = e.key == 6;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: isToday
                            ? tokens.accent
                            : tokens.accent.withValues(alpha: 0.4),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Component row ────────────────────────────────────────────────────────────

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.c, required this.tokens});
  final _Component c;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.label,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
              ),
              Text(
                '${(c.weight * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Text(
                c.score.toStringAsFixed(0),
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (c.score / 100).clamp(0.0, 1.0),
            backgroundColor: tokens.border,
            color: c.color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
