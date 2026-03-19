import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:shimmer/shimmer.dart';

/// Shutdown tab — evening routine checklist with completion progress,
/// loading/error states, pull-to-refresh, and phase-aware UI.
class ShutdownTab extends ConsumerStatefulWidget {
  const ShutdownTab({super.key});

  @override
  ConsumerState<ShutdownTab> createState() => _ShutdownTabState();
}

class _ShutdownTabState extends ConsumerState<ShutdownTab> {
  static List<_RoutineItem> _buildRoutine(AppLocalizations l10n) => [
    _RoutineItem(
      title: l10n.routineStopScreens,
      subtitle: l10n.routineStopScreensSub,
      icon: Icons.phone_android_rounded,
    ),
    _RoutineItem(
      title: l10n.routineJournal,
      subtitle: l10n.routineJournalSub,
      icon: Icons.edit_note_rounded,
    ),
    _RoutineItem(
      title: l10n.routineStretch,
      subtitle: l10n.routineStretchSub,
      icon: Icons.self_improvement_rounded,
    ),
    _RoutineItem(
      title: l10n.routinePrepareClothes,
      subtitle: l10n.routinePrepareClotheseSub,
      icon: Icons.checkroom_rounded,
    ),
    _RoutineItem(
      title: l10n.routineDimLights,
      subtitle: l10n.routineDimLightsSub,
      icon: Icons.lightbulb_outline_rounded,
    ),
    _RoutineItem(
      title: l10n.routineBrushTeeth,
      subtitle: l10n.routineBrushTeethSub,
      icon: Icons.clean_hands_rounded,
    ),
    _RoutineItem(
      title: l10n.routineHerbalTea,
      subtitle: l10n.routineHerbalTeaSub,
      icon: Icons.local_cafe_rounded,
    ),
    _RoutineItem(
      title: l10n.routineRead,
      subtitle: l10n.routineReadSub,
      icon: Icons.menu_book_rounded,
    ),
  ];

  late final Set<int> _completedIndices;

  @override
  void initState() {
    super.initState();
    _completedIndices = {};
  }

  void _toggle(int index) {
    setState(() {
      if (_completedIndices.contains(index)) {
        _completedIndices.remove(index);
      } else {
        _completedIndices.add(index);
      }
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(shutdownProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final shutdownState = ref.watch(shutdownProvider);

    // ------ Loading shimmer ------
    if (shutdownState.isLoading) {
      return _ShimmerSkeleton(tokens: tokens);
    }

    final routine = _buildRoutine(l10n);
    final completedCount = _completedIndices.length;
    final totalCount = routine.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ------ Error banner ------
          if (shutdownState.error != null)
            _ErrorBanner(
              error: shutdownState.error!,
              tokens: tokens,
              onRetry: _onRefresh,
            ),

          // ------ Inactive empty state ------
          if (shutdownState.phase == ShutdownPhase.inactive)
            _InactiveEmptyState(
              tokens: tokens,
              onStart: () =>
                  ref.read(shutdownProvider.notifier).startShutdown(),
            ),

          // ------ Violated insight banner ------
          if (shutdownState.phase == ShutdownPhase.violated)
            _ViolatedBanner(tokens: tokens),

          // ------ Progress overview card ------
          GlassCard(
            child: Column(
              children: [
                _CompletionRing(
                  progress: progress,
                  completedCount: completedCount,
                  totalCount: totalCount,
                  tokens: tokens,
                ),
                const SizedBox(height: 12),
                Text(
                  progress >= 1.0
                      ? l10n.done
                      : '$completedCount / $totalCount',
                  style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _PhaseBadge(phase: shutdownState.phase, tokens: tokens),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ------ Countdown / bedtime card ------
          if (shutdownState.targetSleepTime != null) ...[
            _CountdownCard(
              shutdownState: shutdownState,
              tokens: tokens,
            ),
            const SizedBox(height: 16),
          ],

          // ------ Flare risk banner ------
          if (shutdownState.flareRisk != FlareRisk.none)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _flareColor(shutdownState.flareRisk)
                    .withValues(alpha: 0.15),
                border: Border.all(
                  color: _flareColor(shutdownState.flareRisk)
                      .withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _flareColor(shutdownState.flareRisk),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shutdownState.flareRisk == FlareRisk.high
                          ? l10n.highFlareRisk
                          : l10n.moderateFlareRisk,
                      style: TextStyle(
                        color: _flareColor(shutdownState.flareRisk),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ------ Checklist ------
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.checklist_rounded,
                        color: tokens.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.shutdown,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate(routine.length, (i) {
                  final item = routine[i];
                  final done = _completedIndices.contains(i);
                  return _ChecklistTile(
                    item: item,
                    done: done,
                    tokens: tokens,
                    onToggle: () => _toggle(i),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ------ Allowed during shutdown ------
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shutdownWindow,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [l10n.drinkWater, l10n.drinkChamomileTea, l10n.drinkAniseTea]
                      .map((item) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.15),
                              border: Border.all(
                                color: const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _flareColor(FlareRisk risk) {
    switch (risk) {
      case FlareRisk.high:
        return const Color(0xFFF44336);
      case FlareRisk.moderate:
        return const Color(0xFFFF9800);
      case FlareRisk.none:
        return const Color(0xFF4CAF50);
    }
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------

class _ShimmerSkeleton extends StatelessWidget {
  const _ShimmerSkeleton({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final baseColor = tokens.bgAlt;
    final highlightColor = tokens.border.withValues(alpha: 0.3);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Ring placeholder
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Bedtime card placeholder
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Checklist placeholders
          ...List.generate(6, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner with retry
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFF44336).withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF44336),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).failedToLoad,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).retry,
                style: const TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inactive empty state with "Start Shutdown" button
// ---------------------------------------------------------------------------

class _InactiveEmptyState extends StatelessWidget {
  const _InactiveEmptyState({
    required this.tokens,
    required this.onStart,
  });

  final OrchestraColorTokens tokens;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(
              Icons.nights_stay_rounded,
              color: tokens.accent.withValues(alpha: 0.6),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).shutdown,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).shutdownEmptyState,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onStart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bedtime_rounded,
                        color: tokens.bg,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).shutdown,
                        style: TextStyle(
                          color: tokens.bg,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Violated state insight banner
// ---------------------------------------------------------------------------

class _ViolatedBanner extends StatelessWidget {
  const _ViolatedBanner({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withValues(alpha: 0.10),
        border: Border.all(
          color: const Color(0xFFF44336).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.schedule_rounded,
              color: Color(0xFFF44336),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).shutdownViolated,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).shutdownViolatedDescription,
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
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
// Countdown card — prominent minutes display when active
// ---------------------------------------------------------------------------

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.shutdownState,
    required this.tokens,
  });

  final ShutdownState shutdownState;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isActive = shutdownState.phase == ShutdownPhase.active;
    final timeLeft = shutdownState.timeUntilSleep;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.bedtime_rounded, color: tokens.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).bedtime,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(shutdownState.targetSleepTime!),
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (timeLeft != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context).remaining,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(timeLeft),
                      style: TextStyle(
                        color: tokens.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Prominent countdown when active
          if (isActive && timeLeft != null) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: tokens.border.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            _ProminentCountdown(
              timeLeft: timeLeft,
              tokens: tokens,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ---------------------------------------------------------------------------
// Prominent countdown — large minute display
// ---------------------------------------------------------------------------

class _ProminentCountdown extends StatelessWidget {
  const _ProminentCountdown({
    required this.timeLeft,
    required this.tokens,
  });

  final Duration timeLeft;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = timeLeft.inMinutes;
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes.remainder(60);
    final isUrgent = totalMinutes <= 30;
    final displayColor = isUrgent ? const Color(0xFFFF9800) : tokens.accent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (hours > 0) ...[
          Text(
            hours.toString(),
            style: TextStyle(
              color: displayColor,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 8),
            child: Text(
              'hr',
              style: TextStyle(
                color: displayColor.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        Text(
          minutes.toString().padLeft(hours > 0 ? 2 : 1, '0'),
          style: TextStyle(
            color: displayColor,
            fontSize: 44,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'min',
            style: TextStyle(
              color: displayColor.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Routine item model
// ---------------------------------------------------------------------------

class _RoutineItem {
  const _RoutineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

// ---------------------------------------------------------------------------
// Completion ring
// ---------------------------------------------------------------------------

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.tokens,
  });

  final double progress;
  final int completedCount;
  final int totalCount;
  final OrchestraColorTokens tokens;

  Color get _ringColor {
    if (progress >= 1.0) return const Color(0xFF4CAF50);
    if (progress >= 0.5) return tokens.accent;
    return const Color(0xFFFF9800);
  }

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
              valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
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
              Icon(
                Icons.nights_stay_rounded,
                color: tokens.accent,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase badge
// ---------------------------------------------------------------------------

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase, required this.tokens});

  final ShutdownPhase phase;
  final OrchestraColorTokens tokens;

  String _label(AppLocalizations l10n) {
    switch (phase) {
      case ShutdownPhase.inactive:
        return l10n.shutdownNotActive;
      case ShutdownPhase.active:
        return l10n.shutdownActiveLabel;
      case ShutdownPhase.violated:
        return l10n.shutdownViolatedLabel;
    }
  }

  Color get _color {
    switch (phase) {
      case ShutdownPhase.inactive:
        return const Color(0xFF9E9E9E);
      case ShutdownPhase.active:
        return const Color(0xFF4CAF50);
      case ShutdownPhase.violated:
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
      child: Text(_label(AppLocalizations.of(context)), style: TextStyle(color: _color, fontSize: 12)),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist tile
// ---------------------------------------------------------------------------

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.done,
    required this.tokens,
    required this.onToggle,
  });

  final _RoutineItem item;
  final bool done;
  final OrchestraColorTokens tokens;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: done
                      ? const Color(0xFF4CAF50)
                      : tokens.border.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF4CAF50), size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              item.icon,
              color: done ? tokens.fgDim : tokens.accent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: done ? tokens.fgDim : tokens.fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: tokens.fgDim,
                      fontSize: 11,
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
