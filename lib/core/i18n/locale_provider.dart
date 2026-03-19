import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/config/user_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'locale_lang';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSaved();
    _watchSyncedLocale();
    return const Locale('en');
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kLocaleKey);
    if (lang != null) state = Locale(lang);
  }

  void _watchSyncedLocale() {
    ref.listen(userSettingProvider('locale_lang'), (prev, next) {
      if (next != null && next != state.languageCode) {
        state = Locale(next);
      }
    });
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    try {
      await ref.read(userSettingsProvider.notifier).set('locale_lang', locale.languageCode);
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Supported locales for Orchestra.
const kSupportedLocales = [Locale('en'), Locale('ar')];
