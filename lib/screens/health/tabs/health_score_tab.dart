import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/ai_insight_engine.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Displays the overall health score with wins, concerns and recommendations
/// sourced from [aiInsightProvider].
class HealthScoreTab extends ConsumerWidget {
  const HealthScoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final insightAsync = ref.watch(aiInsightProvider);

    final l10n = AppLocalizations.of(context);

    return insightAsync.when(
      loading: () => const _ShimmerLoading(),
      error: (e, _) => Center(
        child: Text('${l10n.error}: $e',
            style: TextStyle(color: tokens.fgMuted)),
      ),
      data: (state) {
        if (state.isLoading) return const _ShimmerLoading();
        final insights = state.insights ?? AiInsights.placeholder(l10n);
        return _HealthScoreContent(
          tokens: tokens,
          insights: insights,
          onRefresh: () => ref.read(aiInsightProvider.notifier).generateInsights(
                const HealthContext(),
                l10n,
              ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _HealthScoreContent extends StatelessWidget {
  const _HealthScoreContent({
    required this.tokens,
    required this.insights,
    required this.onRefresh,
  });

  final OrchestraColorTokens tokens;
  final AiInsights insights;
  final VoidCallback onRefresh;

  /// Derive a 0–100 score from wins vs concerns count.
  double get _score {
    final wins = insights.top3Wins.length;
    final concerns = insights.top3Concerns.length;
    if (wins + concerns == 0) return 50;
    return (wins / (wins + concerns) * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final score = _score;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Score ring
        Center(
          child: _ScoreRing(score: score, tokens: tokens),
        ),
        const SizedBox(height: 24),

        // Refresh button
        Center(
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, size: 16, color: tokens.accent),
            label: Text(l10n.refreshInsights,
                style: TextStyle(color: tokens.accent, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 24),

        // Wins
        _ChipSection(
          title: l10n.wins,
          items: insights.top3Wins,
          color: const Color(0xFF4CAF50),
          tokens: tokens,
        ),
        const SizedBox(height: 16),

        // Concerns
        _ChipSection(
          title: l10n.concerns,
          items: insights.top3Concerns,
          color: const Color(0xFFFF9800),
          tokens: tokens,
        ),
        const SizedBox(height: 16),

        // Recommendations
        _RecommendationsCard(
          recommendations: insights.recommendations,
          tokens: tokens,
        ),
        const SizedBox(height: 16),

        // Trigger analysis
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.triggerAnalysis,
                  style: TextStyle(
                      color: tokens.fgBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 8),
              Text(insights.triggerAnalysis,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Score ring
// ---------------------------------------------------------------------------

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.tokens});

  final double score;
  final OrchestraColorTokens tokens;

  Color get _ringColor {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RingPainter(
          score: score,
          ringColor: _ringColor,
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
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context).healthScore,
                style: TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    const stroke = 12.0;
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

    // Track
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    // Arc
    canvas.drawArc(
        rect, -math.pi / 2, math.pi * 2 * (score / 100), false, ringPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.score != score || old.ringColor != ringColor;
}

// ---------------------------------------------------------------------------
// Chip section
// ---------------------------------------------------------------------------

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.items,
    required this.color,
    required this.tokens,
  });

  final String title;
  final List<String> items;
  final Color color;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: tokens.fgBright,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item,
                        style: TextStyle(color: color, fontSize: 12)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendations card
// ---------------------------------------------------------------------------

class _RecommendationsCard extends StatefulWidget {
  const _RecommendationsCard({
    required this.recommendations,
    required this.tokens,
  });

  final List<String> recommendations;
  final OrchestraColorTokens tokens;

  @override
  State<_RecommendationsCard> createState() => _RecommendationsCardState();
}

class _RecommendationsCardState extends State<_RecommendationsCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: Text(AppLocalizations.of(context).recommendations,
            style: TextStyle(
                color: widget.tokens.fgBright,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        iconColor: widget.tokens.accent,
        collapsedIconColor: widget.tokens.fgMuted,
        children: widget.recommendations
            .map((rec) => ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle_outline,
                      color: widget.tokens.accent, size: 16),
                  title: Text(rec,
                      style: TextStyle(
                          color: widget.tokens.fgMuted, fontSize: 13)),
                ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading
// ---------------------------------------------------------------------------

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
