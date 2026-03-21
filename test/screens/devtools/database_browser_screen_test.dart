import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/database_browser_provider.dart';

void main() {
  // ── DbConnection ────────────────────────────────────────────────────────

  group('DbConnection for sidebar', () {
    test('parses postgres connection', () {
      final conn = DbConnection.fromJson({
        'id': 'conn-1',
        'driver': 'postgres',
        'dsn': 'postgres://user:pass@localhost:5432/mydb',
        'status': 'connected',
      });
      expect(conn.id, 'conn-1');
      expect(conn.driver, 'postgres');
      expect(conn.status, 'connected');
    });

    test('parses sqlite connection', () {
      final conn = DbConnection.fromJson({
        'id': 'conn-2',
        'driver': 'sqlite',
        'dsn': '/tmp/test.db',
      });
      expect(conn.driver, 'sqlite');
      expect(conn.dsn, '/tmp/test.db');
      expect(conn.status, isNull);
    });

    test('parses mysql connection', () {
      final conn = DbConnection.fromJson({
        'connection_id': 'conn-3',
        'driver': 'mysql',
        'dsn': 'mysql://root@localhost/db',
      });
      expect(conn.id, 'conn-3');
      expect(conn.driver, 'mysql');
    });
  });

  // ── DbTable ─────────────────────────────────────────────────────────────

  group('DbTable for table list', () {
    test('parses table with row count', () {
      final table = DbTable.fromJson({
        'name': 'users',
        'schema': 'public',
        'row_count': 1234,
      });
      expect(table.name, 'users');
      expect(table.schema, 'public');
      expect(table.rowCount, 1234);
    });

    test('parses table without optional fields', () {
      final table = DbTable.fromJson({'table_name': 'orders'});
      expect(table.name, 'orders');
      expect(table.schema, isNull);
      expect(table.rowCount, isNull);
    });
  });

  // ── DbColumn ────────────────────────────────────────────────────────────

  group('DbColumn for schema viewer', () {
    test('parses primary key column', () {
      final col = DbColumn.fromJson({
        'name': 'id',
        'type': 'uuid',
        'nullable': false,
        'primary_key': true,
        'default': 'gen_random_uuid()',
      });
      expect(col.name, 'id');
      expect(col.type, 'uuid');
      expect(col.nullable, false);
      expect(col.primaryKey, true);
      expect(col.defaultValue, 'gen_random_uuid()');
    });

    test('parses nullable text column', () {
      final col = DbColumn.fromJson({
        'column_name': 'bio',
        'data_type': 'text',
        'nullable': true,
        'primary_key': false,
      });
      expect(col.name, 'bio');
      expect(col.type, 'text');
      expect(col.nullable, true);
      expect(col.primaryKey, false);
    });

    test('parses integer column with default', () {
      final col = DbColumn.fromJson({
        'name': 'version',
        'type': 'integer',
        'default_value': '1',
      });
      expect(col.name, 'version');
      expect(col.type, 'integer');
      expect(col.defaultValue, '1');
    });
  });

  // ── DbQueryResult ───────────────────────────────────────────────────────

  group('DbQueryResult for results table', () {
    test('parses query with rows', () {
      final result = DbQueryResult.fromJson({
        'columns': ['id', 'name', 'email'],
        'rows': [
          {'id': '1', 'name': 'Alice', 'email': 'alice@example.com'},
          {'id': '2', 'name': 'Bob', 'email': 'bob@example.com'},
        ],
        'row_count': 2,
        'duration_ms': 12,
      });
      expect(result.columns, ['id', 'name', 'email']);
      expect(result.rows.length, 2);
      expect(result.rows[0]['name'], 'Alice');
      expect(result.rowCount, 2);
      expect(result.durationMs, 12);
    });

    test('parses empty result set', () {
      final result = DbQueryResult.fromJson({
        'columns': ['id'],
        'rows': <Map<String, dynamic>>[],
        'row_count': 0,
        'duration_ms': 3,
      });
      expect(result.columns, ['id']);
      expect(result.rows, isEmpty);
      expect(result.rowCount, 0);
    });

    test('handles large row count', () {
      final result = DbQueryResult.fromJson({
        'columns': ['count'],
        'rows': [
          {'count': 999999},
        ],
        'row_count': 1,
        'duration_ms': 150,
      });
      expect(result.durationMs, 150);
      expect(result.rows[0]['count'], 999999);
    });

    test('supports various SQL data types in rows', () {
      final result = DbQueryResult.fromJson({
        'columns': ['bool_col', 'int_col', 'null_col', 'json_col'],
        'rows': [
          {
            'bool_col': true,
            'int_col': 42,
            'null_col': null,
            'json_col': '{"key":"value"}',
          },
        ],
        'row_count': 1,
      });
      expect(result.rows[0]['bool_col'], true);
      expect(result.rows[0]['int_col'], 42);
      expect(result.rows[0]['null_col'], isNull);
      expect(result.rows[0]['json_col'], '{"key":"value"}');
    });
  });

  // ── Driver helpers ────────────────────────────────────────────────────

  group('Supported drivers', () {
    test('all drivers recognized', () {
      const drivers = ['postgres', 'sqlite', 'mysql', 'mongodb', 'redis'];
      for (final d in drivers) {
        final conn = DbConnection.fromJson({'driver': d, 'dsn': 'test'});
        expect(conn.driver, d);
      }
    });
  });
}
