import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/config/user_settings_provider.dart';
import 'package:orchestra/core/firebase/analytics_service.dart';
import 'package:orchestra/core/theme/orchestra_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_id';

class ThemeNotifier extends Notifier<OrchestraTheme> {
  @override
  OrchestraTheme build() {
    // Load persisted theme asynchronously; default to orchestra.
    _loadSaved();
    // Watch user_settings for cross-device theme changes.
    _watchSyncedTheme();
    return OrchestraTheme.orchestra;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kThemeKey);
    if (id != null && id != state.id) {
      state = OrchestraTheme.byId(id);
    }
  }

  /// Watch the PowerSync user_settings for theme changes from other devices.
  void _watchSyncedTheme() {
    ref.listen(userSettingProvider('theme_id'), (prev, next) {
      if (next != null && next != state.id) {
        state = OrchestraTheme.byId(next);
      }
    });
  }

  Future<void> setTheme(String themeId) async {
    final theme = OrchestraTheme.byId(themeId);
    state = theme;
    // Save locally for fast startup.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, themeId);
    // Sync to PowerSync for cross-device.
    try {
      await ref.read(userSettingsProvider.notifier).set('theme_id', themeId);
    } catch (_) {
      // PowerSync might not be connected yet — local prefs is the fallback.
    }
    await AnalyticsService.logThemeChanged(themeName: themeId);
  }
}

/// Current [OrchestraTheme] — read anywhere with ref.watch(themeProvider).
final themeProvider = NotifierProvider<ThemeNotifier, OrchestraTheme>(
  ThemeNotifier.new,
);

/// Convenience provider for the current theme ID.
final themeIdProvider = Provider<String>((ref) {
  return ref.watch(themeProvider).id;
});

/// Themes grouped for the settings picker.
final groupedThemesProvider =
    Provider<Map<ThemeGroup, List<OrchestraTheme>>>((ref) {
  final grouped = <ThemeGroup, List<OrchestraTheme>>{};
  for (final t in OrchestraTheme.allThemes) {
    grouped.putIfAbsent(t.group, () => []).add(t);
  }
  return grouped;
});
