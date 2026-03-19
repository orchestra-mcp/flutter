import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/db/app_database.dart';

AppDatabase _makeTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _makeTestDb());
  tearDown(() => db.close());

  group('AppDatabase schema', () {
    test('opens without error', () async {
      await db.customStatement('SELECT 1');
    });

    test('all 12 tables exist', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      for (final table in [
        'users_table',
        'features_table',
        'projects_table',
        'notes_table',
        'health_logs_table',
        'notifications_table',
        'sessions_table',
        'sync_queue_table',
        'agents_table',
        'workflows_table',
        'settings_table',
        'delegations_table',
      ]) {
        expect(names, contains(table), reason: '\$table should exist');
      }
    });

    test('sync_queue_table has primary key id', () async {
      final cols = await db
          .customSelect("PRAGMA table_info('sync_queue_table')")
          .get();
      final idCol = cols.firstWhere((r) => r.read<String>('name') == 'id');
      expect(idCol.read<int>('pk'), 1);
    });

    test('settings_table can store and retrieve a value', () async {
      final now = DateTime.now();
      await db
          .into(db.settingsTable)
          .insert(
            SettingsTableCompanion.insert(
              key: 'theme',
              value: 'dracula',
              updatedAt: now,
            ),
          );
      final row = await (db.select(
        db.settingsTable,
      )..where((t) => t.key.equals('theme'))).getSingle();
      expect(row.value, 'dracula');
    });

    test('users_table insert and select', () async {
      final now = DateTime.now();
      await db
          .into(db.usersTable)
          .insert(
            UsersTableCompanion.insert(
              id: 'user-1',
              email: 'test@example.com',
              displayName: 'Test User',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final users = await db.select(db.usersTable).get();
      expect(users.length, 1);
      expect(users.first.email, 'test@example.com');
    });
  });
}
