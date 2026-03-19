import 'package:flutter/material.dart';

enum ThemeGroup { orchestra, material, popular, classic }

/// A single Orchestra color theme.
@immutable
class OrchestraTheme {
  const OrchestraTheme({
    required this.id,
    required this.name,
    required this.group,
    required this.bg,
    required this.bgAlt,
    required this.fgBright,
    required this.fgMuted,
    required this.fgDim,
    required this.border,
    required this.accent,
    required this.accentAlt,
    this.isLight = false,
  });

  final String id;
  final String name;
  final ThemeGroup group;
  final Color bg;
  final Color bgAlt;
  final Color fgBright;
  final Color fgMuted;
  final Color fgDim;
  final Color border;
  final Color accent;
  final Color accentAlt;
  final bool isLight;

  /// Glass background opacity — 0.15 for light, 0.12 for dark.
  Color get glassColor =>
      bg.withValues(alpha: isLight ? 0.15 : 0.12);

  // ─── All 25 themes ────────────────────────────────────────────────────────

  static const OrchestraTheme orchestra = OrchestraTheme(
    id: 'orchestra',
    name: 'Orchestra',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF0F0F1A),
    bgAlt: Color(0xFF1A1A2E),
    fgBright: Color(0xFFFFFFFF),
    fgMuted: Color(0xFFB0B0C8),
    fgDim: Color(0xFF6B6B8A),
    border: Color(0xFF2A2A45),
    accent: Color(0xFFA900FF),
    accentAlt: Color(0xFF00E5FF),
  );

  static const OrchestraTheme midnight = OrchestraTheme(
    id: 'midnight',
    name: 'Midnight',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF080812),
    bgAlt: Color(0xFF12121F),
    fgBright: Color(0xFFFFFFFF),
    fgMuted: Color(0xFFAAAAAC),
    fgDim: Color(0xFF555566),
    border: Color(0xFF1E1E35),
    accent: Color(0xFF6366F1),
    accentAlt: Color(0xFF818CF8),
  );

  static const OrchestraTheme aurora = OrchestraTheme(
    id: 'aurora',
    name: 'Aurora',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF0D1117),
    bgAlt: Color(0xFF161B22),
    fgBright: Color(0xFFE6EDF3),
    fgMuted: Color(0xFF8D96A0),
    fgDim: Color(0xFF484F58),
    border: Color(0xFF21262D),
    accent: Color(0xFFA78BFA),
    accentAlt: Color(0xFFC4B5FD),
  );

  static const OrchestraTheme ocean = OrchestraTheme(
    id: 'ocean',
    name: 'Ocean',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF0A1628),
    bgAlt: Color(0xFF0F2042),
    fgBright: Color(0xFFE0F0FF),
    fgMuted: Color(0xFF7AABCC),
    fgDim: Color(0xFF3D6680),
    border: Color(0xFF163050),
    accent: Color(0xFF38BDF8),
    accentAlt: Color(0xFF7DD3FC),
  );

  static const OrchestraTheme forest = OrchestraTheme(
    id: 'forest',
    name: 'Forest',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF0A1A0F),
    bgAlt: Color(0xFF0F2518),
    fgBright: Color(0xFFE0FFE8),
    fgMuted: Color(0xFF7AAA88),
    fgDim: Color(0xFF3D6647),
    border: Color(0xFF163020),
    accent: Color(0xFF4ADE80),
    accentAlt: Color(0xFF86EFAC),
  );

  static const OrchestraTheme sunset = OrchestraTheme(
    id: 'sunset',
    name: 'Sunset',
    group: ThemeGroup.orchestra,
    bg: Color(0xFF1A0A0F),
    bgAlt: Color(0xFF2A1015),
    fgBright: Color(0xFFFFEEE0),
    fgMuted: Color(0xFFCC9977),
    fgDim: Color(0xFF7A4433),
    border: Color(0xFF3A1A20),
    accent: Color(0xFFF97316),
    accentAlt: Color(0xFFFB923C),
  );

  // ─── Material ─────────────────────────────────────────────────────────────

  static const OrchestraTheme materialDeepPurple = OrchestraTheme(
    id: 'material-deep-purple',
    name: 'Material Deep Purple',
    group: ThemeGroup.material,
    bg: Color(0xFF1C1B1F),
    bgAlt: Color(0xFF2B2930),
    fgBright: Color(0xFFE6E1E5),
    fgMuted: Color(0xFF9E9AA7),
    fgDim: Color(0xFF4A4458),
    border: Color(0xFF3A3544),
    accent: Color(0xFFD0BCFF),
    accentAlt: Color(0xFFE8DEF8),
  );

  static const OrchestraTheme materialTeal = OrchestraTheme(
    id: 'material-teal',
    name: 'Material Teal',
    group: ThemeGroup.material,
    bg: Color(0xFF1C1B1F),
    bgAlt: Color(0xFF2B2930),
    fgBright: Color(0xFFE6E1E5),
    fgMuted: Color(0xFF9E9AA7),
    fgDim: Color(0xFF4A4458),
    border: Color(0xFF3A3544),
    accent: Color(0xFF80CBC4),
    accentAlt: Color(0xFFB2DFDB),
  );

  static const OrchestraTheme materialBlue = OrchestraTheme(
    id: 'material-blue',
    name: 'Material Blue',
    group: ThemeGroup.material,
    bg: Color(0xFF1C1B1F),
    bgAlt: Color(0xFF2B2930),
    fgBright: Color(0xFFE6E1E5),
    fgMuted: Color(0xFF9E9AA7),
    fgDim: Color(0xFF4A4458),
    border: Color(0xFF3A3544),
    accent: Color(0xFF90CAF9),
    accentAlt: Color(0xFFBBDEFB),
  );

  static const OrchestraTheme materialGreen = OrchestraTheme(
    id: 'material-green',
    name: 'Material Green',
    group: ThemeGroup.material,
    bg: Color(0xFF1C1B1F),
    bgAlt: Color(0xFF2B2930),
    fgBright: Color(0xFFE6E1E5),
    fgMuted: Color(0xFF9E9AA7),
    fgDim: Color(0xFF4A4458),
    border: Color(0xFF3A3544),
    accent: Color(0xFFA5D6A7),
    accentAlt: Color(0xFFC8E6C9),
  );

  // ─── Popular ──────────────────────────────────────────────────────────────

  static const OrchestraTheme githubDark = OrchestraTheme(
    id: 'github-dark',
    name: 'GitHub Dark',
    group: ThemeGroup.popular,
    bg: Color(0xFF0D1117),
    bgAlt: Color(0xFF161B22),
    fgBright: Color(0xFFE6EDF3),
    fgMuted: Color(0xFF8D96A0),
    fgDim: Color(0xFF484F58),
    border: Color(0xFF30363D),
    accent: Color(0xFF58A6FF),
    accentAlt: Color(0xFF79C0FF),
  );

  static const OrchestraTheme githubLight = OrchestraTheme(
    id: 'github-light',
    name: 'GitHub Light',
    group: ThemeGroup.popular,
    bg: Color(0xFFFFFFFF),
    bgAlt: Color(0xFFF6F8FA),
    fgBright: Color(0xFF1F2328),
    fgMuted: Color(0xFF59636E),
    fgDim: Color(0xFF818B98),
    border: Color(0xFFD1D9E0),
    accent: Color(0xFF0969DA),
    accentAlt: Color(0xFF218BFF),
    isLight: true,
  );

  static const OrchestraTheme dracula = OrchestraTheme(
    id: 'dracula',
    name: 'Dracula',
    group: ThemeGroup.popular,
    bg: Color(0xFF282A36),
    bgAlt: Color(0xFF343746),
    fgBright: Color(0xFFF8F8F2),
    fgMuted: Color(0xFF6272A4),
    fgDim: Color(0xFF44475A),
    border: Color(0xFF44475A),
    accent: Color(0xFFBD93F9),
    accentAlt: Color(0xFFFF79C6),
  );

  static const OrchestraTheme nord = OrchestraTheme(
    id: 'nord',
    name: 'Nord',
    group: ThemeGroup.popular,
    bg: Color(0xFF2E3440),
    bgAlt: Color(0xFF3B4252),
    fgBright: Color(0xFFECEFF4),
    fgMuted: Color(0xFF8892A2),
    fgDim: Color(0xFF4C566A),
    border: Color(0xFF434C5E),
    accent: Color(0xFF88C0D0),
    accentAlt: Color(0xFF81A1C1),
  );

  static const OrchestraTheme solarizedDark = OrchestraTheme(
    id: 'solarized-dark',
    name: 'Solarized Dark',
    group: ThemeGroup.popular,
    bg: Color(0xFF002B36),
    bgAlt: Color(0xFF073642),
    fgBright: Color(0xFFFDF6E3),
    fgMuted: Color(0xFF657B83),
    fgDim: Color(0xFF586E75),
    border: Color(0xFF073642),
    accent: Color(0xFF268BD2),
    accentAlt: Color(0xFF2AA198),
  );

  static const OrchestraTheme solarizedLight = OrchestraTheme(
    id: 'solarized-light',
    name: 'Solarized Light',
    group: ThemeGroup.popular,
    bg: Color(0xFFFDF6E3),
    bgAlt: Color(0xFFEEE8D5),
    fgBright: Color(0xFF073642),
    fgMuted: Color(0xFF93A1A1),
    fgDim: Color(0xFF839496),
    border: Color(0xFFDDD6C1),
    accent: Color(0xFF268BD2),
    accentAlt: Color(0xFF2AA198),
    isLight: true,
  );

  static const OrchestraTheme catppuccinMocha = OrchestraTheme(
    id: 'catppuccin-mocha',
    name: 'Catppuccin Mocha',
    group: ThemeGroup.popular,
    bg: Color(0xFF1E1E2E),
    bgAlt: Color(0xFF313244),
    fgBright: Color(0xFFCDD6F4),
    fgMuted: Color(0xFF6C7086),
    fgDim: Color(0xFF45475A),
    border: Color(0xFF313244),
    accent: Color(0xFFCBA6F7),
    accentAlt: Color(0xFFF5C2E7),
  );

  static const OrchestraTheme catppuccinLatte = OrchestraTheme(
    id: 'catppuccin-latte',
    name: 'Catppuccin Latte',
    group: ThemeGroup.popular,
    bg: Color(0xFFEFF1F5),
    bgAlt: Color(0xFFE6E9EF),
    fgBright: Color(0xFF4C4F69),
    fgMuted: Color(0xFF9CA0B0),
    fgDim: Color(0xFFACB0BE),
    border: Color(0xFFCCD0DA),
    accent: Color(0xFF8839EF),
    accentAlt: Color(0xFFDC8A78),
    isLight: true,
  );

  // ─── Classic ──────────────────────────────────────────────────────────────

  static const OrchestraTheme classicDark = OrchestraTheme(
    id: 'classic-dark',
    name: 'Classic Dark',
    group: ThemeGroup.classic,
    bg: Color(0xFF1E1E1E),
    bgAlt: Color(0xFF252526),
    fgBright: Color(0xFFD4D4D4),
    fgMuted: Color(0xFF808080),
    fgDim: Color(0xFF4E4E4E),
    border: Color(0xFF3E3E42),
    accent: Color(0xFF007ACC),
    accentAlt: Color(0xFF0098FF),
  );

  static const OrchestraTheme classicLight = OrchestraTheme(
    id: 'classic-light',
    name: 'Classic Light',
    group: ThemeGroup.classic,
    bg: Color(0xFFFFFFFF),
    bgAlt: Color(0xFFF3F3F3),
    fgBright: Color(0xFF000000),
    fgMuted: Color(0xFF616161),
    fgDim: Color(0xFF9E9E9E),
    border: Color(0xFFE0E0E0),
    accent: Color(0xFF007ACC),
    accentAlt: Color(0xFF005F9E),
    isLight: true,
  );

  static const OrchestraTheme highContrast = OrchestraTheme(
    id: 'high-contrast',
    name: 'High Contrast',
    group: ThemeGroup.classic,
    bg: Color(0xFF000000),
    bgAlt: Color(0xFF0A0A0A),
    fgBright: Color(0xFFFFFFFF),
    fgMuted: Color(0xFFCCCCCC),
    fgDim: Color(0xFF888888),
    border: Color(0xFFFFFFFF),
    accent: Color(0xFFFFFF00),
    accentAlt: Color(0xFF00FF00),
  );

  static const OrchestraTheme gruvboxDark = OrchestraTheme(
    id: 'gruvbox-dark',
    name: 'Gruvbox Dark',
    group: ThemeGroup.classic,
    bg: Color(0xFF282828),
    bgAlt: Color(0xFF3C3836),
    fgBright: Color(0xFFEBDBB2),
    fgMuted: Color(0xFFA89984),
    fgDim: Color(0xFF665C54),
    border: Color(0xFF504945),
    accent: Color(0xFFFABD2F),
    accentAlt: Color(0xFFB8BB26),
  );

  static const OrchestraTheme gruvboxLight = OrchestraTheme(
    id: 'gruvbox-light',
    name: 'Gruvbox Light',
    group: ThemeGroup.classic,
    bg: Color(0xFFFBF1C7),
    bgAlt: Color(0xFFEBDBB2),
    fgBright: Color(0xFF3C3836),
    fgMuted: Color(0xFF7C6F64),
    fgDim: Color(0xFF9D8374),
    border: Color(0xFFD5C4A1),
    accent: Color(0xFFD65D0E),
    accentAlt: Color(0xFF98971A),
    isLight: true,
  );

  static const OrchestraTheme tokyoNight = OrchestraTheme(
    id: 'tokyo-night',
    name: 'Tokyo Night',
    group: ThemeGroup.classic,
    bg: Color(0xFF1A1B26),
    bgAlt: Color(0xFF24283B),
    fgBright: Color(0xFFC0CAF5),
    fgMuted: Color(0xFF565F89),
    fgDim: Color(0xFF3B4261),
    border: Color(0xFF292E42),
    accent: Color(0xFF7AA2F7),
    accentAlt: Color(0xFFBB9AF7),
  );

  static const OrchestraTheme oneDark = OrchestraTheme(
    id: 'one-dark',
    name: 'One Dark',
    group: ThemeGroup.classic,
    bg: Color(0xFF282C34),
    bgAlt: Color(0xFF2C313C),
    fgBright: Color(0xFFABB2BF),
    fgMuted: Color(0xFF636D83),
    fgDim: Color(0xFF4B5263),
    border: Color(0xFF3E4451),
    accent: Color(0xFF61AFEF),
    accentAlt: Color(0xFFC678DD),
  );

  // ─── All themes list ──────────────────────────────────────────────────────

  static const List<OrchestraTheme> allThemes = [
    // Orchestra (6)
    orchestra,
    midnight,
    aurora,
    ocean,
    forest,
    sunset,
    // Material (4)
    materialDeepPurple,
    materialTeal,
    materialBlue,
    materialGreen,
    // Popular (8)
    githubDark,
    githubLight,
    dracula,
    nord,
    solarizedDark,
    solarizedLight,
    catppuccinMocha,
    catppuccinLatte,
    // Classic (7)
    classicDark,
    classicLight,
    highContrast,
    gruvboxDark,
    gruvboxLight,
    tokyoNight,
    oneDark,
  ];

  static OrchestraTheme byId(String id) =>
      allThemes.firstWhere((t) => t.id == id, orElse: () => orchestra);
}
