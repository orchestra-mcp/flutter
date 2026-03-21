import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/powersync/schema.dart';

void main() {
  group('PowerSync schema — health table names', () {
    final tableNames = powersyncSchema.tables.map((t) => t.name).toSet();

    test('contains water_logs (not health_hydration)', () {
      expect(tableNames, contains('water_logs'));
      expect(tableNames, isNot(contains('health_hydration')));
    });

    test('contains caffeine_logs (not health_caffeine)', () {
      expect(tableNames, contains('caffeine_logs'));
      expect(tableNames, isNot(contains('health_caffeine')));
    });

    test('contains meal_logs (not health_nutrition)', () {
      expect(tableNames, contains('meal_logs'));
      expect(tableNames, isNot(contains('health_nutrition')));
    });

    test('contains pomodoro_sessions (not health_pomodoro)', () {
      expect(tableNames, contains('pomodoro_sessions'));
      expect(tableNames, isNot(contains('health_pomodoro')));
    });

    test('contains sleep_configs (not health_shutdown)', () {
      expect(tableNames, contains('sleep_configs'));
      expect(tableNames, isNot(contains('health_shutdown')));
    });

    test('contains health_snapshots (not health_weight)', () {
      expect(tableNames, contains('health_snapshots'));
      expect(tableNames, isNot(contains('health_weight')));
    });

    test('contains health_profiles (not health_settings)', () {
      expect(tableNames, contains('health_profiles'));
      expect(tableNames, isNot(contains('health_settings')));
    });

    test('contains sleep_logs (not health_sleep)', () {
      expect(tableNames, contains('sleep_logs'));
      expect(tableNames, isNot(contains('health_sleep')));
    });
  });

  group('PowerSync schema — app data tables', () {
    final tableNames = powersyncSchema.tables.map((t) => t.name).toSet();

    test('contains notes table', () {
      expect(tableNames, contains('notes'));
    });

    test('contains projects table', () {
      expect(tableNames, contains('projects'));
    });

    test('contains features table', () {
      expect(tableNames, contains('features'));
    });

    test('contains delegations table', () {
      expect(tableNames, contains('delegations'));
    });

    test('contains workspaces table', () {
      expect(tableNames, contains('workspaces'));
    });
  });

  group('PowerSync schema — column types', () {
    Map<String, String> columnsOf(String tableName) {
      final table = powersyncSchema.tables.firstWhere((t) => t.name == tableName);
      return {for (final c in table.columns) c.name: c.type.name};
    }

    test('caffeine_logs.sugar_g is real (not integer)', () {
      final cols = columnsOf('caffeine_logs');
      expect(cols['sugar_g'], 'real');
    });

    test('health_snapshots.weight_kg is real', () {
      final cols = columnsOf('health_snapshots');
      expect(cols['weight_kg'], 'real');
    });

    test('health_snapshots.body_fat_pct is real', () {
      final cols = columnsOf('health_snapshots');
      expect(cols['body_fat_pct'], 'real');
    });

    test('sleep_logs.duration_hours is real', () {
      final cols = columnsOf('sleep_logs');
      expect(cols['duration_hours'], 'real');
    });

    test('water_logs.amount_ml is integer', () {
      final cols = columnsOf('water_logs');
      expect(cols['amount_ml'], 'integer');
    });
  });

  group('PowerSync schema — no legacy table names', () {
    final tableNames = powersyncSchema.tables.map((t) => t.name).toSet();

    final legacyNames = [
      'health_hydration',
      'health_caffeine',
      'health_nutrition',
      'health_pomodoro',
      'health_shutdown',
      'health_weight',
      'health_sleep',
      'health_vitals',
      'health_settings',
    ];

    for (final name in legacyNames) {
      test('does not contain legacy table "$name"', () {
        expect(tableNames, isNot(contains(name)));
      });
    }
  });
}
