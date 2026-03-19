import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

String _localizedPhase(AppLocalizations l10n, PomodoroPhase phase) =>
    switch (phase) {
      PomodoroPhase.work => l10n.focus,
      PomodoroPhase.shortBreak => l10n.shortBreak,
      PomodoroPhase.longBreak => l10n.longBreak,
      PomodoroPhase.standAlert => l10n.standUp,
      PomodoroPhase.idle => l10n.ready,
    };

class PomodoroWidgetCard extends ConsumerWidget {
  const PomodoroWidgetCard({super.key});

  static const _color = Color(0xFFF97316);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pomodoroProvider);

    final phaseColor = state.phase == PomodoroPhase.work
        ? _color
        : state.phase.isActive
            ? const Color(0xFF4CAF50)
            : tokens.fgMuted;

    return GlassCard(
      onTap: () => context.go(Routes.healthPomodoro),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: _color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pomodoro,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _localizedPhase(l10n, state.phase),
                  style: TextStyle(color: phaseColor, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.timeDisplay,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final notifier = ref.read(pomodoroProvider.notifier);
                  if (state.isRunning) {
                    notifier.cancelTimer();
                  } else {
                    notifier.startWork();
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    state.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: phaseColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 4,
                    backgroundColor: tokens.border.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(phaseColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.completedToday}/${state.dailyTarget}',
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
