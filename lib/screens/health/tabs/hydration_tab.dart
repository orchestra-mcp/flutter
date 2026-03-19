import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

String _localizedHydrationStatus(
  AppLocalizations l10n,
  HydrationStatus status,
) => switch (status) {
  HydrationStatus.goalReached => l10n.goalReached,
  HydrationStatus.onTrack => l10n.onTrack,
  HydrationStatus.slightlyBehind => l10n.slightlyBehindMsg,
  HydrationStatus.dehydrated => l10n.dehydratedMsg,
};

/// Hydration tab — log water intake, view today's total and progress.
///
/// Supports loading/error states, pull-to-refresh, gout flush recommendations,
/// status messages, and a time-since-last-drink indicator.
class HydrationTab extends ConsumerWidget {
  const HydrationTab({super.key});

  static const _quickAmounts = [150, 250, 350, 500];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(hydrationProvider);
    final notifier = ref.read(hydrationProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Loading indicator
          if (state.isLoading) _LoadingShimmer(tokens: tokens),

          // Error banner
          if (state.error != null)
            _ErrorBanner(
              error: state.error!,
              tokens: tokens,
              onRetry: notifier.refresh,
            ),

          // Gout flush recommendation
          if (state.goutFlushRecommendation && !state.isLoading)
            _GoutFlushCard(tokens: tokens),

          // Progress ring card
          GlassCard(
            child: Column(
              children: [
                _HydrationRing(
                  progress: state.progressFraction,
                  totalMl: state.totalMl,
                  goalMl: state.goalMl,
                  tokens: tokens,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.mlUnit(state.totalMl, state.goalMl),
                  style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                // Status message
                Text(
                  _localizedHydrationStatus(l10n, state.status),
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _StatusChip(status: state.status, tokens: tokens),
                // Time since last drink
                if (state.lastLoggedAt != null) ...[
                  const SizedBox(height: 10),
                  _TimeSinceLastDrink(
                    lastLoggedAt: state.lastLoggedAt!,
                    tokens: tokens,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick-add buttons
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addWater,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickAmounts
                      .map(
                        (ml) => _QuickAddButton(
                          ml: ml,
                          tokens: tokens,
                          onTap: () => notifier.addWater(ml),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log or empty state
          if (state.entries.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.today,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.entries.reversed
                      .take(8)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                color: tokens.accent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.plusMl(e.ml),
                                style: TextStyle(
                                  color: tokens.fgBright,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _fmt(e.timestamp),
                                style: TextStyle(
                                  color: tokens.fgDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            )
          else if (!state.isLoading)
            _EmptyState(tokens: tokens),

          const SizedBox(height: 16),

          // Reset
          Center(
            child: TextButton(
              onPressed: notifier.reset,
              child: Text(
                l10n.resetToday,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Loading shimmer
// ---------------------------------------------------------------------------

class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shimmerOpacity =
              0.3 +
              0.4 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi));
          return Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: widget.tokens.accent.withValues(alpha: shimmerOpacity),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.error,
    required this.tokens,
    required this.onRetry,
  });

  final String error;
  final OrchestraColorTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFF44336);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          border: Border.all(color: errorColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: errorColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: errorColor, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: AppLocalizations.of(context).retryLoadingHydration,
              child: GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context).retry,
                    style: const TextStyle(
                      color: errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gout flush recommendation card
// ---------------------------------------------------------------------------

class _GoutFlushCard extends StatelessWidget {
  const _GoutFlushCard({required this.tokens});

  final OrchestraColorTokens tokens;

  static const _warningColor = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _warningColor.withValues(alpha: 0.1),
          border: Border.all(color: _warningColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.warning_amber_rounded,
                color: _warningColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).flareRisk,
                    style: const TextStyle(
                      color: _warningColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context).goutFlushDescription,
                    style: TextStyle(
                      color: _warningColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Icon(Icons.water_drop_outlined, color: tokens.fgDim, size: 36),
          const SizedBox(height: 10),
          Text(
            l10n.noResults,
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addWater,
            style: TextStyle(color: tokens.fgDim, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time since last drink
// ---------------------------------------------------------------------------

class _TimeSinceLastDrink extends StatelessWidget {
  const _TimeSinceLastDrink({required this.lastLoggedAt, required this.tokens});

  final DateTime lastLoggedAt;
  final OrchestraColorTokens tokens;

  String _formatDuration(Duration d, AppLocalizations l10n) {
    if (d.inMinutes < 1) return l10n.justNow;
    if (d.inMinutes < 60) return l10n.minutesAgo(d.inMinutes);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (m == 0) return l10n.hoursAgo(h);
    return l10n.hoursMinutesAgo(h, m);
  }

  Color _urgencyColor(Duration d) {
    if (d.inMinutes < 60) return const Color(0xFF4CAF50);
    if (d.inMinutes < 120) return const Color(0xFF2196F3);
    if (d.inMinutes < 180) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final elapsed = DateTime.now().difference(lastLoggedAt);
    final color = _urgencyColor(elapsed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          l10n.lastDrink(_formatDuration(elapsed, l10n)),
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ring
// ---------------------------------------------------------------------------

class _HydrationRing extends StatelessWidget {
  const _HydrationRing({
    required this.progress,
    required this.totalMl,
    required this.goalMl,
    required this.tokens,
  });

  final double progress;
  final int totalMl;
  final int goalMl;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: tokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? const Color(0xFF4CAF50) : tokens.accent,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.tokens});

  final HydrationStatus status;
  final OrchestraColorTokens tokens;

  String _label(AppLocalizations l10n) {
    switch (status) {
      case HydrationStatus.goalReached:
        return l10n.goalReachedChip;
      case HydrationStatus.onTrack:
        return l10n.onTrackChip;
      case HydrationStatus.slightlyBehind:
        return l10n.slightlyBehindChip;
      case HydrationStatus.dehydrated:
        return l10n.dehydratedChip;
    }
  }

  Color get _color {
    switch (status) {
      case HydrationStatus.goalReached:
        return const Color(0xFF4CAF50);
      case HydrationStatus.onTrack:
        return const Color(0xFF2196F3);
      case HydrationStatus.slightlyBehind:
        return const Color(0xFFFF9800);
      case HydrationStatus.dehydrated:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(AppLocalizations.of(context)),
        style: TextStyle(color: _color, fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-add button
// ---------------------------------------------------------------------------

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.ml,
    required this.tokens,
    required this.onTap,
  });

  final int ml;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).addMlWater(ml),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.15),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.water_drop_rounded, color: tokens.accent, size: 18),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).mlLabel(ml),
                style: TextStyle(
                  color: tokens.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
