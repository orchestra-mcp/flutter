import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Cross-device user settings via PowerSync.
///
/// Each setting is a key-value row in the `user_settings` table.
/// Writes go to local SQLite → CRUD batch upload → PostgreSQL → syncs to all
/// devices. On desktop, also mirrors to SharedPreferences as fallback for
/// settings needed before PowerSync connects.
class UserSettingsNotifier extends Notifier<Map<String, String>> {
  static const _uuid = Uuid();

  @override
  Map<String, String> build() {
    _load();
    return {};
  }

  /// Load all user settings from local SQLite into memory.
  Future<void> _load() async {
    try {
      final db = ref.read(powersyncDatabaseProvider);
      final rows = await db.getAll('SELECT key, value FROM user_settings');
      final map = <String, String>{};
      for (final row in rows) {
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key != null && value != null) {
          map[key] = value;
        }
      }
      state = map;
    } catch (e) {
      debugPrint('[UserSettings] Failed to load: $e');
    }
  }

  /// Get a setting value by key.
  String? get(String key) => state[key];

  /// Get a setting as a boolean (stored as "true"/"false").
  bool getBool(String key, {bool defaultValue = false}) {
    final value = state[key];
    if (value == null) return defaultValue;
    return value == 'true' || value == '1';
  }

  /// Get a setting as an int.
  int? getInt(String key) {
    final value = state[key];
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Get a setting as a JSON map.
  Map<String, dynamic>? getJson(String key) {
    final value = state[key];
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Set a setting value. Writes to local SQLite (triggers CRUD sync).
  Future<void> set(String key, String value) async {
    try {
      final db = ref.read(powersyncDatabaseProvider);

      // Check if key already exists.
      final existing = await db.getOptional(
        'SELECT id FROM user_settings WHERE key = ?',
        [key],
      );

      final now = DateTime.now().toUtc().toIso8601String();
      if (existing != null) {
        await db.execute(
          'UPDATE user_settings SET value = ?, updated_at = ? WHERE key = ?',
          [value, now, key],
        );
      } else {
        await db.execute(
          'INSERT INTO user_settings (id, key, value, updated_at) VALUES (?, ?, ?, ?)',
          [_uuid.v4(), key, value, now],
        );
      }

      state = {...state, key: value};

      // Mirror to SharedPreferences for desktop fallback.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_setting_$key', value);
    } catch (e) {
      debugPrint('[UserSettings] Failed to set $key: $e');
    }
  }

  /// Set a boolean value.
  Future<void> setBool(String key, bool value) => set(key, value.toString());

  /// Set an int value.
  Future<void> setInt(String key, int value) => set(key, value.toString());

  /// Set a JSON map value.
  Future<void> setJson(String key, Map<String, dynamic> value) =>
      set(key, jsonEncode(value));

  /// Remove a setting.
  Future<void> remove(String key) async {
    try {
      final db = ref.read(powersyncDatabaseProvider);
      await db.execute('DELETE FROM user_settings WHERE key = ?', [key]);
      final newState = {...state};
      newState.remove(key);
      state = newState;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_setting_$key');
    } catch (e) {
      debugPrint('[UserSettings] Failed to remove $key: $e');
    }
  }

  /// Reload from database (e.g. after sync).
  Future<void> refresh() => _load();
}

/// Provides the user settings notifier backed by PowerSync.
final userSettingsProvider =
    NotifierProvider<UserSettingsNotifier, Map<String, String>>(
      UserSettingsNotifier.new,
    );

/// Convenience provider for a single setting key.
final userSettingProvider = Provider.family<String?, String>((ref, key) {
  final settings = ref.watch(userSettingsProvider);
  return settings[key];
});
