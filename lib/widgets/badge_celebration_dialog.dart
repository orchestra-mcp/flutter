import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a celebration dialog when a user earns a badge.
///
/// Displays the badge icon, name, description with a confetti-like animation.
class BadgeCelebrationDialog extends StatefulWidget {
  const BadgeCelebrationDialog({
    super.key,
    required this.badgeName,
    required this.badgeDescription,
    required this.badgeIcon,
    required this.badgeColor,
  });

  final String badgeName;
  final String badgeDescription;
  final IconData badgeIcon;
  final Color badgeColor;

  /// Show the celebration dialog.
  static Future<void> show(
    BuildContext context, {
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge Celebration',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, secondaryAnim) => BadgeCelebrationDialog(
        badgeName: name,
        badgeDescription: description,
        badgeIcon: icon,
        badgeColor: color,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<BadgeCelebrationDialog> createState() => _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<BadgeCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _particles = List.generate(
      30,
      (_) => _Particle(
        x: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        color: [
          const Color(0xFF00E5FF),
          const Color(0xFFA900FF),
          const Color(0xFF22C55E),
          const Color(0xFFF59E0B),
          const Color(0xFFEF4444),
        ][_random.nextInt(5)],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.badgeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon with glow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: widget.badgeColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: widget.badgeColor.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.badgeColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.badgeIcon,
                  size: 42,
                  color: widget.badgeColor,
                ),
              ),
              const SizedBox(height: 24),

              // Badge name
              Text(
                widget.badgeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.badgeDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.badgeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

class _Particle {
  _Particle({required this.x, required this.speed, required this.color});
  final double x;
  final double speed;
  final Color color;
}
