import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/health/health_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class HealthScoreWidgetCard extends ConsumerWidget {
  const HealthScoreWidgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final healthData = ref.watch(healthProvider);
    final healthCtx = healthData.healthContext;
    final score = healthData.healthScore;

    final dimensions = [
      _Dim(l10n.hydration, healthCtx?.hydrationScore ?? 0),
      _Dim(l10n.focus, healthCtx?.pomodoroScore ?? 0),
      _Dim(l10n.nutrition, healthCtx?.nutritionScore ?? 0),
      _Dim(l10n.sleep, healthCtx?.sleepScore ?? 0),
      _Dim(l10n.shutdown, healthCtx?.shutdownScore ?? 0),
    ];

    return GlassCard(
      onTap: () => context.go(Routes.healthScore),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(
                score: score,
                ringColor: _scoreColor(score),
                trackColor: tokens.border.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toInt().toString(),
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.health,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Dimension bars
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: dimensions
                  .map((d) => _DimensionBar(dim: d, tokens: tokens))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Map<String, dynamic> toWidgetData() => {};
}

// ---------------------------------------------------------------------------
// Dimension model + bar
// ---------------------------------------------------------------------------

class _Dim {
  const _Dim(this.label, this.score);
  final String label;
  final double score;
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.dim, required this.tokens});

  final _Dim dim;
  final OrchestraColorTokens tokens;

  Color get _barColor {
    if (dim.score >= 70) return const Color(0xFF4CAF50);
    if (dim.score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              dim.label,
              style: TextStyle(color: tokens.fgMuted, fontSize: 10),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (dim.score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: tokens.border.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            child: Text(
              '${dim.score.toInt()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tokens.fgDim,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter (copied from health_score_tab.dart — private, can't import)
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.score,
    required this.ringColor,
    required this.trackColor,
  });

  final double score;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ringPaint = Paint()
      ..color = ringColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    canvas.drawArc(
        rect, -math.pi / 2, math.pi * 2 * (score / 100), false, ringPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.score != score || old.ringColor != ringColor;
}
