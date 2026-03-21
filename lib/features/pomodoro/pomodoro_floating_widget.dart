import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

// ── Floating Pomodoro Widget ────────────────────────────────────────────────
//
// A draggable overlay widget for desktop that shows the pomodoro timer as
// either an expanded card (timer + controls) or a minimized pill (time only).
//
// Usage:
//   PomodoroFloatingController.show(context);
//   PomodoroFloatingController.hide();

class PomodoroFloatingController {
  PomodoroFloatingController._();

  static OverlayEntry? _entry;
  static bool get isVisible => _entry != null;

  /// Show the floating pomodoro widget as an overlay.
  static void show(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => const _PomodoroOverlay(),
    );
    Overlay.of(context).insert(_entry!);
  }

  /// Remove the floating widget.
  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  /// Toggle visibility.
  static void toggle(BuildContext context) {
    if (isVisible) {
      hide();
    } else {
      show(context);
    }
  }
}

// ── Overlay wrapper (positioned + draggable) ────────────────────────────────

class _PomodoroOverlay extends StatefulWidget {
  const _PomodoroOverlay();

  @override
  State<_PomodoroOverlay> createState() => _PomodoroOverlayState();
}

class _PomodoroOverlayState extends State<_PomodoroOverlay> {
  // Default position: bottom-right corner.
  Offset _position = const Offset(-1, -1); // sentinel — set in first build
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Initialize position to bottom-right with padding.
    if (_position.dx < 0) {
      _position = Offset(size.width - 220, size.height - 200);
    }

    // Clamp to screen bounds.
    final dx = _position.dx.clamp(0.0, size.width - 60);
    final dy = _position.dy.clamp(0.0, size.height - 40);

    return Positioned(
      left: dx,
      top: dy,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _position = Offset(_position.dx + d.delta.dx, _position.dy + d.delta.dy);
          });
        },
        child: _minimized
            ? _PomodoroMinPill(
                onExpand: () => setState(() => _minimized = false),
              )
            : _PomodoroCard(
                onMinimize: () => setState(() => _minimized = true),
                onClose: PomodoroFloatingController.hide,
              ),
      ),
    );
  }
}

// ── Minimized pill ──────────────────────────────────────────────────────────

class _PomodoroMinPill extends ConsumerWidget {
  const _PomodoroMinPill({required this.onExpand});
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final color = _phaseColor(state.phase);

    return GestureDetector(
      onTap: onExpand,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isRunning ? color : const Color(0xFF6B7280),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  state.timeDisplay,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.unfold_more_rounded,
                  color: const Color(0xFF9CA3AF),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Expanded card ───────────────────────────────────────────────────────────

class _PomodoroCard extends ConsumerWidget {
  const _PomodoroCard({required this.onMinimize, required this.onClose});
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final color = _phaseColor(state.phase);
    final tokens = ThemeTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header (drag handle + minimize/close) ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isRunning ? color : const Color(0xFF6B7280),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.phase.label,
                        style: TextStyle(
                          color: tokens.fgMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.unfold_less_rounded,
                      onTap: onMinimize,
                    ),
                    _HeaderButton(
                      icon: Icons.close_rounded,
                      onTap: onClose,
                    ),
                  ],
                ),
              ),

              // ── Timer display ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  state.timeDisplay,
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),

              // ── Progress bar ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: const Color(0xFF2A2A3E),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ),

              // ── Controls ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.phase == PomodoroPhase.idle) ...[
                      _ControlButton(
                        icon: Icons.play_arrow_rounded,
                        color: const Color(0xFF4ADE80),
                        onTap: notifier.startWork,
                        tooltip: 'Start',
                      ),
                    ] else ...[
                      if (state.isRunning)
                        _ControlButton(
                          icon: Icons.pause_rounded,
                          color: const Color(0xFFFBBF24),
                          onTap: notifier.pauseWork,
                          tooltip: 'Pause',
                        )
                      else
                        _ControlButton(
                          icon: Icons.play_arrow_rounded,
                          color: const Color(0xFF4ADE80),
                          onTap: notifier.resumeWork,
                          tooltip: 'Resume',
                        ),
                      const SizedBox(width: 8),
                      if (state.phase == PomodoroPhase.work)
                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          color: const Color(0xFF60A5FA),
                          onTap: notifier.skipToBreak,
                          tooltip: 'Skip',
                        ),
                      const SizedBox(width: 8),
                      _ControlButton(
                        icon: Icons.stop_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: notifier.reset,
                        tooltip: 'Reset',
                      ),
                    ],
                  ],
                ),
              ),

              // ── Session counter ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${state.completedToday} / ${state.dailyTarget} sessions',
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

Color _phaseColor(PomodoroPhase phase) {
  switch (phase) {
    case PomodoroPhase.work:
      return const Color(0xFFEF4444);
    case PomodoroPhase.shortBreak:
      return const Color(0xFF4ADE80);
    case PomodoroPhase.longBreak:
      return const Color(0xFF60A5FA);
    case PomodoroPhase.standAlert:
      return const Color(0xFFFBBF24);
    case PomodoroPhase.idle:
      return const Color(0xFF9CA3AF);
  }
}
