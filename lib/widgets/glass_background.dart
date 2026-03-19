import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// Full-screen gradient background with two static accent-coloured blobs.
///
/// Designed to sit behind glass-surface widgets. The blobs are blurred
/// circles using [tokens.accent] at 8 % opacity — they are static and do
/// not animate.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     const GlassBackground(),
///     // … your content …
///   ],
/// )
/// ```
class GlassBackground extends StatelessWidget {
  const GlassBackground({
    super.key,
    this.child,
  });

  /// Optional child layered on top of the background.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    final Widget background = Stack(
      fit: StackFit.expand,
      children: [
        // ── Base gradient ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tokens.bg, tokens.bgAlt],
            ),
          ),
        ),

        // ── Blob 1 — top-right quadrant ───────────────────────────────
        Positioned(
          top: -80,
          right: -60,
          child: _AccentBlob(
            size: 320,
            color: tokens.accent.withValues(alpha: 0.08),
          ),
        ),

        // ── Blob 2 — bottom-left quadrant ─────────────────────────────
        Positioned(
          bottom: -100,
          left: -80,
          child: _AccentBlob(
            size: 360,
            color: tokens.accentAlt.withValues(alpha: 0.08),
          ),
        ),

        ?child,
      ],
    );

    return background;
  }
}

/// A single blurred circular blob used by [GlassBackground].
class _AccentBlob extends StatelessWidget {
  const _AccentBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
