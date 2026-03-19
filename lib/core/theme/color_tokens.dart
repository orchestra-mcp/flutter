import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/orchestra_theme.dart';

/// Resolved color tokens for a given [OrchestraTheme].
/// Use via [ThemeTokens.of(context)] once theme provider is wired.
@immutable
class OrchestraColorTokens {
  const OrchestraColorTokens({
    required this.bg,
    required this.bgAlt,
    required this.fgBright,
    required this.fgMuted,
    required this.fgDim,
    required this.border,
    required this.accent,
    required this.accentAlt,
    required this.glass,
    required this.isLight,
  });

  final Color bg;
  final Color bgAlt;
  final Color fgBright;
  final Color fgMuted;
  final Color fgDim;
  final Color border;
  final Color accent;
  final Color accentAlt;

  /// Pre-computed glass tint (bg at 12% or 15% opacity).
  final Color glass;
  final bool isLight;

  factory OrchestraColorTokens.fromTheme(OrchestraTheme t) =>
      OrchestraColorTokens(
        bg: t.bg,
        bgAlt: t.bgAlt,
        fgBright: t.fgBright,
        fgMuted: t.fgMuted,
        fgDim: t.fgDim,
        border: t.border,
        accent: t.accent,
        accentAlt: t.accentAlt,
        glass: t.glassColor,
        isLight: t.isLight,
      );

  /// Convenience border with low opacity for dividers / glass edges.
  Color get borderFaint => border.withValues(alpha: 0.3);

  /// Accent with slight opacity for hover states.
  Color get accentSurface => accent.withValues(alpha: 0.15);
}

/// InheritedWidget that exposes [OrchestraColorTokens] to the subtree.
/// Placed at the root of the app by [OrchestraApp].
class ThemeTokens extends InheritedWidget {
  const ThemeTokens({
    super.key,
    required this.tokens,
    required super.child,
  });

  final OrchestraColorTokens tokens;

  static OrchestraColorTokens of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<ThemeTokens>();
    assert(result != null, 'No ThemeTokens found in context');
    return result!.tokens;
  }

  static OrchestraColorTokens? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeTokens>()?.tokens;

  @override
  bool updateShouldNotify(ThemeTokens oldWidget) =>
      tokens != oldWidget.tokens;
}
