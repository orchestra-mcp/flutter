import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Daily Flow tab — composite score ring, component breakdown, insight text
/// and weekly bar chart.
class DailyFlowTab extends ConsumerWidget {
  const DailyFlowTab({super.key});

  // Weights for the composite score.
  static const _wPomodoro = 0.40;
  static const _wHydration = 0.25;
  static const _wNutrition = 0.20;
  static const _wShutdown = 0.15;

  // Placeholder weekly scores (Mon–Sat). Today is computed live.
  static const _weekHistoryScores = [62.0, 74.0, 55.0, 80.0, 68.0, 71.0];

  /// Derive pomodoro score from provider state.
  static double _pomodoroScore(PomodoroState s) {
    if (s.dailyTarget <= 0) return 0;
    return (s.completedToday / s.dailyTarget * 100).clamp(0, 100).toDouble();
  }

  /// Derive hydration score from provider state.
  static double _hydrationScore(HydrationState s) {
    return (s.progressFraction * 100).clamp(0, 100).toDouble();
  }

  /// Derive nutrition score from provider state.
  static double _nutritionScore(NutritionState s) {
    return s.safetyScore.clamp(0, 100).toDouble();
  }

  /// Derive shutdown score from provider state.
  static double _shutdownScore(ShutdownState s) {
    switch (s.phase) {
      case ShutdownPhase.active:
        return 100;
      case ShutdownPhase.violated:
        return 50;
      case ShutdownPhase.inactive:
        return 0;
    }
  }

  /// Compute the weighted daily composite score.
  static double _dailyScore({
    required double pomodoro,
    required double hydration,
    required double nutrition,
    required double shutdown,
  }) {
    return pomodoro * _wPomodoro +
        hydration * _wHydration +
        nutrition * _wNutrition +
        shutdown * _wShutdown;
  }

  /// Return insight text describing the weakest component.
  static String _insightText({
    required double pomodoro,
    required double hydration,
    required double nutrition,
    required double shutdown,
    required AppLocalizations l10n,
  }) {
    final scores = {0: pomodoro, 1: hydration, 2: nutrition, 3: shutdown};

    final lowest = scores.entries.reduce((a, b) => a.value <= b.value ? a : b);

    return switch (lowest.key) {
      0 => l10n.insightLowFocus,
      1 => l10n.insightLowHydration,
      2 => l10n.insightTriggerFoods,
      3 => l10n.insightShutdownNotActive,
      _ => l10n.insightKeepGoing,
    };
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(pomodoroProvider.notifier).refresh(),
      ref.read(hydrationProvider.notifier).refresh(),
      ref.read(nutritionProvider.notifier).refresh(),
      ref.read(shutdownProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    // Read live state from each provider.
    final pomState = ref.watch(pomodoroProvider);
    final hydState = ref.watch(hydrationProvider);
    final nutState = ref.watch(nutritionProvider);
    final shdState = ref.watch(shutdownProvider);

    final pomodoro = _pomodoroScore(pomState);
    final hydration = _hydrationScore(hydState);
    final nutrition = _nutritionScore(nutState);
    final shutdown = _shutdownScore(shdState);

    final score = _dailyScore(
      pomodoro: pomodoro,
      hydration: hydration,
      nutrition: nutrition,
      shutdown: shutdown,
    );

    final weekScores = [..._weekHistoryScores, score];
    final insight = _insightText(
      pomodoro: pomodoro,
      hydration: hydration,
      nutrition: nutrition,
      shutdown: shutdown,
      l10n: l10n,
    );

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Overall score ring
          Center(
            child: _FlowRing(score: score, tokens: tokens),
          ),
          const SizedBox(height: 24),

          // Insight text
          GlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: tokens.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Component breakdown
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.componentBreakdown,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _ComponentRow(
                  label: l10n.pomodoro,
                  weight: '40%',
                  score: pomodoro,
                  tokens: tokens,
                ),
                const SizedBox(height: 10),
                _ComponentRow(
                  label: l10n.hydration,
                  weight: '25%',
                  score: hydration,
                  tokens: tokens,
                ),
                const SizedBox(height: 10),
                _ComponentRow(
                  label: l10n.nutrition,
                  weight: '20%',
                  score: nutrition,
                  tokens: tokens,
                ),
                const SizedBox(height: 10),
                _ComponentRow(
                  label: l10n.shutdown,
                  weight: '15%',
                  score: shutdown,
                  tokens: tokens,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly bar chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.thisWeek,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: _WeeklyBarChart(scores: weekScores, tokens: tokens),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      [
                            l10n.mon,
                            l10n.tue,
                            l10n.wed,
                            l10n.thu,
                            l10n.fri,
                            l10n.sat,
                            l10n.sun,
                          ]
                          .map(
                            (d) => Text(
                              d,
                              style: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 10,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flow ring
// ---------------------------------------------------------------------------

class _FlowRing extends StatelessWidget {
  const _FlowRing({required this.score, required this.tokens});

  final double score;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: tokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toInt().toString(),
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context).dailyFlow,
                style: TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Component row
// ---------------------------------------------------------------------------

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.label,
    required this.weight,
    required this.score,
    required this.tokens,
  });

  final String label;
  final String weight;
  final double score;
  final OrchestraColorTokens tokens;

  Color get _barColor {
    if (score >= 75) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            weight,
            style: TextStyle(color: tokens.fgDim, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: tokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            score.toInt().toString(),
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly bar chart
// ---------------------------------------------------------------------------

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.scores, required this.tokens});

  final List<double> scores;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final todayIndex = scores.length - 1;
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        barGroups: List.generate(scores.length, (i) {
          final isToday = i == todayIndex;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: scores[i],
                color: isToday
                    ? tokens.accent
                    : tokens.accent.withValues(alpha: 0.4),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
