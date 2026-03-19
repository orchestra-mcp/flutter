import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:shimmer/shimmer.dart';

String _localizedPhase(AppLocalizations l10n, PomodoroPhase phase) =>
    switch (phase) {
      PomodoroPhase.work => l10n.focus,
      PomodoroPhase.shortBreak => l10n.shortBreak,
      PomodoroPhase.longBreak => l10n.longBreak,
      PomodoroPhase.standAlert => l10n.standUp,
      PomodoroPhase.idle => l10n.ready,
    };

/// Pomodoro tab — timer ring, controls, session stats, insight card,
/// stand-up alerts, and daily streaks.
class PomodoroTab extends ConsumerWidget {
  const PomodoroTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    // --- Loading state: shimmer placeholders ---
    if (state.isLoading) {
      return const _ShimmerLoading();
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // --- Error banner with retry ---
          if (state.error != null)
            _ErrorBanner(
              error: state.error!,
              onRetry: notifier.refresh,
              tokens: tokens,
            ),

          // --- Stand-up alert card (prominent, full-width) ---
          if (state.phase == PomodoroPhase.standAlert)
            _StandAlertCard(state: state, tokens: tokens),

          // --- Timer card ---
          GlassCard(
            child: Column(
              children: [
                _PhaseLabel(phase: state.phase, tokens: tokens),
                const SizedBox(height: 16),
                _TimerRing(state: state, tokens: tokens),
                const SizedBox(height: 24),
                _Controls(
                  state: state,
                  notifier: notifier,
                  tokens: tokens,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Motivational insight card ---
          _InsightCard(state: state, tokens: tokens),
          const SizedBox(height: 16),

          // --- Daily stats ---
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: l10n.pomodoroCompleted,
                  value: state.completedToday.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF4CAF50),
                  tokens: tokens,
                ),
                _Divider(tokens: tokens),
                _Stat(
                  label: l10n.pomodoroTarget,
                  value: state.dailyTarget.toString(),
                  icon: Icons.flag_rounded,
                  color: tokens.accent,
                  tokens: tokens,
                ),
                _Divider(tokens: tokens),
                _Stat(
                  label: l10n.pomodoroCycle,
                  value: '${state.cycleIndex % 4 + 1} / 4',
                  icon: Icons.loop_rounded,
                  color: const Color(0xFF9C27B0),
                  tokens: tokens,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Focus time and streaks row ---
          _FocusStreakRow(state: state, tokens: tokens),
          const SizedBox(height: 16),

          // --- Daily progress bar ---
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.dailyScore,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${state.completedToday} / ${state.dailyTarget}',
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.dailyTarget > 0
                        ? (state.completedToday / state.dailyTarget)
                            .clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: tokens.border.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progressBarColor(state),
                    ),
                    minHeight: 8,
                  ),
                ),
                if (state.completedToday >= state.dailyTarget &&
                    state.dailyTarget > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD600),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.done,
                        style: const TextStyle(
                          color: Color(0xFFFFD600),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _progressBarColor(PomodoroState state) {
    if (state.dailyTarget <= 0) return const Color(0xFF9E9E9E);
    final ratio = state.completedToday / state.dailyTarget;
    if (ratio >= 1.0) return const Color(0xFF4CAF50);
    if (ratio >= 0.75) return const Color(0xFF8BC34A);
    if (ratio >= 0.5) return const Color(0xFFFF9800);
    return const Color(0xFF2196F3);
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Shimmer.fromColors(
      baseColor: tokens.bgAlt,
      highlightColor: tokens.border.withValues(alpha: 0.5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Timer card skeleton
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Insight card skeleton
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Stats card skeleton
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Streak row skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar skeleton
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
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
    required this.onRetry,
    required this.tokens,
  });

  final String error;
  final VoidCallback onRetry;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFF44336);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          border: Border.all(color: errorColor.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: errorColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: errorColor, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stand-up alert card
// ---------------------------------------------------------------------------

class _StandAlertCard extends StatelessWidget {
  const _StandAlertCard({required this.state, required this.tokens});

  final PomodoroState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    const alertColor = Color(0xFFFF9800);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              alertColor.withValues(alpha: 0.2),
              alertColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: alertColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.accessibility_new_rounded,
              color: alertColor,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).phaseStandUp,
              style: const TextStyle(
                color: alertColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).standAlertInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: alertColor.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            // Countdown inside the alert
            Text(
              state.timeDisplay,
              style: const TextStyle(
                color: alertColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase label
// ---------------------------------------------------------------------------

class _PhaseLabel extends StatelessWidget {
  const _PhaseLabel({required this.phase, required this.tokens});

  final PomodoroPhase phase;
  final OrchestraColorTokens tokens;

  String _label(AppLocalizations l10n) {
    switch (phase) {
      case PomodoroPhase.idle:
        return l10n.phaseReady;
      case PomodoroPhase.work:
        return l10n.phaseFocus;
      case PomodoroPhase.standAlert:
        return l10n.phaseStandUp;
      case PomodoroPhase.shortBreak:
        return l10n.phaseShortBreak;
      case PomodoroPhase.longBreak:
        return l10n.phaseLongBreak;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _phaseColor(phase);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label(l10n),
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// Timer ring — color-coded by phase
// ---------------------------------------------------------------------------

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.state, required this.tokens});

  final PomodoroState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final phaseColor = _phaseColor(state.phase);
    final progress = state.phase == PomodoroPhase.idle ? 0.0 : state.progress;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _RingTrackPainter(
                trackColor: tokens.border.withValues(alpha: 0.2),
                strokeWidth: 12,
              ),
            ),
          ),
          // Active progress arc
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _RingProgressPainter(
                progress: progress,
                color: phaseColor,
                trackColor: phaseColor.withValues(alpha: 0.15),
                strokeWidth: 12,
              ),
            ),
          ),
          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.timeDisplay,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (state.phase != PomodoroPhase.idle) ...[
                const SizedBox(height: 4),
                Text(
                  _localizedPhase(AppLocalizations.of(context), state.phase),
                  style: TextStyle(
                    color: phaseColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom ring painters (rounded ends, phase-colored)
// ---------------------------------------------------------------------------

class _RingTrackPainter extends CustomPainter {
  const _RingTrackPainter({
    required this.trackColor,
    required this.strokeWidth,
  });

  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RingTrackPainter oldDelegate) =>
      trackColor != oldDelegate.trackColor;
}

class _RingProgressPainter extends CustomPainter {
  const _RingProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingProgressPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.notifier,
    required this.tokens,
  });

  final PomodoroState state;
  final PomodoroNotifier notifier;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIdle = state.phase == PomodoroPhase.idle;
    final isRunning = state.isRunning;
    final phaseColor = _phaseColor(state.phase);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        IconButton(
          onPressed: notifier.reset,
          icon: Icon(Icons.stop_rounded, color: tokens.fgMuted),
          tooltip: l10n.resetTooltip,
        ),
        const SizedBox(width: 8),

        // Primary play/pause
        FilledButton(
          onPressed: () {
            if (isIdle) {
              notifier.startWork();
            } else if (isRunning) {
              notifier.pauseWork();
            } else {
              notifier.resumeWork();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: phaseColor,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
          ),
          child: Icon(
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 28,
          ),
        ),
        const SizedBox(width: 8),

        // Skip to break
        IconButton(
          onPressed: state.phase == PomodoroPhase.work
              ? notifier.skipToBreak
              : null,
          icon: Icon(Icons.skip_next_rounded,
              color: state.phase == PomodoroPhase.work
                  ? tokens.fgMuted
                  : tokens.fgDim),
          tooltip: l10n.skipToBreak,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Motivational insight card
// ---------------------------------------------------------------------------

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.state, required this.tokens});

  final PomodoroState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insight = _buildInsight(l10n);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _InsightData _buildInsight(AppLocalizations l10n) {
    final completed = state.completedToday;
    final target = state.dailyTarget;
    final remaining = target - completed;

    if (completed >= target) {
      return _InsightData(
        icon: Icons.emoji_events_rounded,
        title: l10n.targetReached,
        message: l10n.targetReachedMsg(completed),
        color: const Color(0xFFFFD600),
      );
    }

    if (completed == 0 && state.phase == PomodoroPhase.idle) {
      return _InsightData(
        icon: Icons.rocket_launch_rounded,
        title: l10n.readyToFocus,
        message: l10n.readyToFocusMsg,
        color: const Color(0xFF2196F3),
      );
    }

    if (remaining == 1) {
      return _InsightData(
        icon: Icons.local_fire_department_rounded,
        title: l10n.almostThere,
        message: l10n.almostThereMsg,
        color: const Color(0xFFFF9800),
      );
    }

    if (remaining <= 3) {
      return _InsightData(
        icon: Icons.trending_up_rounded,
        title: l10n.strongProgress,
        message: l10n.strongProgressMsg(remaining),
        color: const Color(0xFF4CAF50),
      );
    }

    if (state.phase == PomodoroPhase.work) {
      return _InsightData(
        icon: Icons.psychology_rounded,
        title: l10n.deepFocus,
        message: l10n.deepFocusMsg(remaining),
        color: const Color(0xFF7C4DFF),
      );
    }

    if (state.phase == PomodoroPhase.shortBreak ||
        state.phase == PomodoroPhase.longBreak) {
      return _InsightData(
        icon: Icons.self_improvement_rounded,
        title: l10n.recharging,
        message: l10n.rechargingMsg(remaining),
        color: const Color(0xFF4CAF50),
      );
    }

    return _InsightData(
      icon: Icons.lightbulb_outline_rounded,
      title: l10n.stayConsistent,
      message: l10n.stayConsistentMsg(remaining),
      color: tokens.accent,
    );
  }
}

class _InsightData {
  const _InsightData({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
}

// ---------------------------------------------------------------------------
// Focus time and streak row
// ---------------------------------------------------------------------------

class _FocusStreakRow extends StatelessWidget {
  const _FocusStreakRow({required this.state, required this.tokens});

  final PomodoroState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Compute total focus minutes from completed sessions (25 min each).
    final totalFocusMinutes = state.completedToday * 25;
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;
    final focusTimeLabel =
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    // Streak = consecutive completed sessions within the current 4-cycle set.
    final cyclesComplete = state.cycleIndex;

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  focusTimeLabel,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).focus,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF5722),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < cyclesComplete % 4;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? const Color(0xFFFF5722)
                              : tokens.border.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).pomodoros,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat / divider helpers
// ---------------------------------------------------------------------------

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tokens,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: tokens.fgBright,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: tokens.border.withValues(alpha: 0.3),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase color helper (shared across widgets)
// ---------------------------------------------------------------------------

Color _phaseColor(PomodoroPhase phase) {
  switch (phase) {
    case PomodoroPhase.idle:
      return const Color(0xFF9E9E9E);
    case PomodoroPhase.work:
      return const Color(0xFF2196F3);
    case PomodoroPhase.standAlert:
      return const Color(0xFFFF9800);
    case PomodoroPhase.shortBreak:
      return const Color(0xFF4CAF50);
    case PomodoroPhase.longBreak:
      return const Color(0xFF66BB6A);
  }
}
