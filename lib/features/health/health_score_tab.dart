import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/health/ai_insight_engine.dart';
import 'package:orchestra/features/health/health_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

// ─── Score ring painter ───────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 12;
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * (score / 100).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.score != score || old.color != color;
}

// ─── Helper: score colour ─────────────────────────────────────────────────────

Color _scoreColor(double score) {
  if (score >= 70) return const Color(0xFF4CAF50);
  if (score >= 40) return const Color(0xFFFF9800);
  return const Color(0xFFF44336);
}

// ─── Health Score Tab ─────────────────────────────────────────────────────────

/// Displays the composite health score ring, wins, concerns, recommendations,
/// trigger analysis, and an AI-refresh button with cooldown countdown.
class HealthScoreTab extends ConsumerStatefulWidget {
  const HealthScoreTab({super.key});

  @override
  ConsumerState<HealthScoreTab> createState() => _HealthScoreTabState();
}

class _HealthScoreTabState extends ConsumerState<HealthScoreTab> {
  AiInsights? _insights;
  bool _loading = false;
  int _cooldownRemaining = 0;

  Future<void> _refresh() async {
    if (_loading || _cooldownRemaining > 0) return;
    setState(() => _loading = true);
    final notifier = ref.read(healthProvider.notifier);
    final ctx = notifier.buildHealthContext();
    try {
      final insights = await notifier.aiInsightEngine.generateInsights(ctx);
      if (mounted) setState(() => _insights = insights);
    } on CooldownException catch (e) {
      if (mounted) {
        setState(() => _cooldownRemaining = e.remainingSeconds);
        _startCountdown();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _cooldownRemaining = (_cooldownRemaining - 1).clamp(0, 999);
      });
      return _cooldownRemaining > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(healthProvider);
    final score = data.healthScore;
    final ringColor = _scoreColor(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score ring
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _ScoreRingPainter(score: score, color: ringColor),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          color: ringColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        l10n.healthScore,
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hydration progress snippet
          Text(
            'Hydration: ${data.hydrationMl} / ${data.hydrationGoal} ml',
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // AI insights section
          if (_loading) _buildShimmer(tokens),
          if (!_loading && _insights != null) ...[
            _buildChipRow(l10n.wins, _insights!.top3Wins,
                const Color(0xFF4CAF50), tokens),
            const SizedBox(height: 12),
            _buildChipRow(l10n.concerns, _insights!.top3Concerns,
                const Color(0xFFFF9800), tokens),
            const SizedBox(height: 12),
            _buildRecommendations(_insights!.recommendations, tokens, l10n),
            const SizedBox(height: 12),
            _buildTriggerBar(_insights!.triggerAnalysis, tokens),
            const SizedBox(height: 16),
          ],

          // Refresh button
          Center(
            child: FilledButton.icon(
              onPressed: _cooldownRemaining > 0 || _loading ? null : _refresh,
              icon: const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text(
                _cooldownRemaining > 0
                    ? '${_cooldownRemaining ~/ 60}m ${_cooldownRemaining % 60}s'
                    : l10n.generateAiInsights,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow(
      String label, List<String> items, Color color, OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t,
                        style: TextStyle(color: color, fontSize: 12)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendations(
      List<String> recs, OrchestraColorTokens tokens, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recommendations,
            style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...recs.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_right, color: tokens.accent, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(r,
                          style: TextStyle(
                              color: tokens.fgBright, fontSize: 13))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTriggerBar(String analysis, OrchestraColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined,
              color: tokens.fgMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(analysis,
                  style: TextStyle(color: tokens.fgBright, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildShimmer(OrchestraColorTokens tokens) {
    return Shimmer.fromColors(
      baseColor: tokens.bgAlt,
      highlightColor: tokens.border,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 40,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
