import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/orchestra_theme.dart';

/// Builds a [ThemeData] from an [OrchestraTheme].
abstract final class AppThemeBuilder {
  static ThemeData build(OrchestraTheme t) {
    final brightness = t.isLight ? Brightness.light : Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: brightness,
      surface: t.bgAlt,
      onSurface: t.fgBright,
    ).copyWith(
      primary: t.accent,
      secondary: t.accentAlt,
      onPrimary: t.isLight ? Colors.white : Colors.black,
      outline: t.border,
    );

    const ibmFont = 'IBM Plex Sans';
    const ibmFallback = ['IBM Plex Sans Arabic', 'sans-serif'];

    return ThemeData(
      useMaterial3: true,
      fontFamily: ibmFont,
      fontFamilyFallback: ibmFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      cardColor: t.bgAlt,
      dividerColor: t.border.withValues(alpha: 0.3),
      splashFactory: NoSplash.splashFactory,
      highlightColor: t.accent.withValues(alpha: 0.08),
      textTheme: _buildTextTheme(t, brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.fgBright,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.bgAlt,
        indicatorColor: t.accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: t.fgMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.bgAlt,
        selectedItemColor: t.accent,
        unselectedItemColor: t.fgDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: t.bgAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: t.border.withValues(alpha: 0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.bgAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: t.fgDim),
        labelStyle: TextStyle(color: t.fgMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.bgAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.border.withValues(alpha: 0.3)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.bgAlt,
        selectedColor: t.accent.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: t.fgMuted, fontSize: 12),
        side: BorderSide(color: t.border.withValues(alpha: 0.4)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return t.accent;
          return t.fgDim;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return t.accent.withValues(alpha: 0.3);
          }
          return t.bgAlt;
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.accent),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: t.isLight ? Colors.white : Colors.black,
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(OrchestraTheme t, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base
        .apply(
          bodyColor: t.fgMuted,
          displayColor: t.fgBright,
          fontFamily: 'IBM Plex Sans',
          fontFamilyFallback: const ['IBM Plex Sans Arabic', 'sans-serif'],
        );
  }
}
