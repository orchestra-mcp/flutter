import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/config/user_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal test-only notifier that bypasses PowerSync by providing
/// direct state injection. Only tests pure logic on the in-memory map.
class _TestUserSettingsNotifier extends UserSettingsNotifier {
  @override
  Map<String, String> build() => {};

  void inject(Map<String, String> data) => state = data;
}

final _testProvider =
    NotifierProvider<_TestUserSettingsNotifier, Map<String, String>>(
      _TestUserSettingsNotifier.new,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSettingsNotifier — pure getters', () {
    late ProviderContainer container;
    late _TestUserSettingsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(_testProvider.notifier);
    });

    test('get returns null for missing key', () {
      expect(notifier.get('missing'), isNull);
    });

    test('get returns stored value', () {
      notifier.inject({'foo': 'bar'});
      expect(notifier.get('foo'), 'bar');
    });

    test('getBool returns defaultValue when key absent', () {
      expect(notifier.getBool('b', defaultValue: true), isTrue);
      expect(notifier.getBool('b'), isFalse);
    });

    test('getBool parses "true" as true', () {
      notifier.inject({'flag': 'true'});
      expect(notifier.getBool('flag'), isTrue);
    });

    test('getBool parses "1" as true', () {
      notifier.inject({'flag': '1'});
      expect(notifier.getBool('flag'), isTrue);
    });

    test('getBool parses "false" as false', () {
      notifier.inject({'flag': 'false'});
      expect(notifier.getBool('flag'), isFalse);
    });

    test('getInt returns null when absent', () {
      expect(notifier.getInt('n'), isNull);
    });

    test('getInt parses numeric string', () {
      notifier.inject({'count': '42'});
      expect(notifier.getInt('count'), 42);
    });

    test('getInt returns null for non-numeric', () {
      notifier.inject({'count': 'abc'});
      expect(notifier.getInt('count'), isNull);
    });

    test('getJson returns null when absent', () {
      expect(notifier.getJson('j'), isNull);
    });

    test('getJson parses valid JSON map', () {
      notifier.inject({
        'cfg': jsonEncode({'theme': 'dark', 'size': 14}),
      });
      final j = notifier.getJson('cfg');
      expect(j, isNotNull);
      expect(j!['theme'], 'dark');
      expect(j['size'], 14);
    });

    test('getJson returns null for invalid JSON', () {
      notifier.inject({'cfg': '{broken'});
      expect(notifier.getJson('cfg'), isNull);
    });
  });

  group('UserSettingsNotifier — type setters (state only)', () {
    late ProviderContainer container;
    late _TestUserSettingsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(_testProvider.notifier);
      // Seed state so setBool/setInt/setJson can update it
      notifier.inject({});
    });

    test('initial state is empty map', () {
      expect(container.read(_testProvider), isEmpty);
    });

    test('inject updates state map', () {
      notifier.inject({'k': 'v'});
      expect(container.read(_testProvider), {'k': 'v'});
    });
  });

  group('userSettingProvider family', () {
    test('returns null for absent key (via test notifier)', () {
      final container = ProviderContainer(
        overrides: [
          // Override base provider so family doesn't try to read PowerSync.
          userSettingsProvider.overrideWith(_TestUserSettingsNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(userSettingProvider('missing')), isNull);
    });

    test('returns value for present key (via test notifier)', () {
      final container = ProviderContainer(
        overrides: [
          userSettingsProvider.overrideWith(_TestUserSettingsNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      (container.read(userSettingsProvider.notifier)
              as _TestUserSettingsNotifier)
          .inject({'theme': 'dark'});
      expect(container.read(userSettingProvider('theme')), 'dark');
    });
  });
}
