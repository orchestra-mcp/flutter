import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';
import 'package:orchestra/features/devtools/providers/database_browser_provider.dart';
import 'package:orchestra/features/devtools/providers/log_runner_provider.dart';
import 'package:orchestra/features/devtools/providers/prompts_provider.dart';
import 'package:orchestra/features/devtools/providers/secrets_provider.dart';

void main() {
  // ── ApiCollection models ────────────────────────────────────────────────────

  group('ApiCollection', () {
    test('fromJson parses collection with endpoints', () {
      final json = {
        'id': 'col-1',
        'name': 'My API',
        'base_url': 'https://api.example.com',
        'description': 'Test collection',
        'endpoints': [
          {
            'id': 'ep-1',
            'name': 'Get Users',
            'method': 'GET',
            'url': '/users',
            'description': 'Lists all users',
          },
        ],
      };
      final col = ApiCollection.fromJson(json);
      expect(col.id, 'col-1');
      expect(col.name, 'My API');
      expect(col.baseUrl, 'https://api.example.com');
      expect(col.description, 'Test collection');
      expect(col.endpoints.length, 1);
      expect(col.endpoints.first.name, 'Get Users');
    });

    test('fromJson handles missing optional fields', () {
      final col = ApiCollection.fromJson({'id': 'x', 'name': 'Y'});
      expect(col.baseUrl, isNull);
      expect(col.description, isNull);
      expect(col.endpoints, isEmpty);
    });

    test('fromJson handles empty map', () {
      final col = ApiCollection.fromJson({});
      expect(col.id, '');
      expect(col.name, '');
      expect(col.endpoints, isEmpty);
    });
  });

  group('ApiEndpoint', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'ep-1',
        'name': 'Create User',
        'method': 'POST',
        'url': '/users',
        'description': 'Creates a new user',
        'body': '{"name":"test"}',
        'body_type': 'json',
        'headers': {'Content-Type': 'application/json'},
        'folder': 'Users',
      };
      final ep = ApiEndpoint.fromJson(json);
      expect(ep.id, 'ep-1');
      expect(ep.method, 'POST');
      expect(ep.url, '/users');
      expect(ep.bodyType, 'json');
      expect(ep.folder, 'Users');
    });

    test('fromJson defaults method to GET', () {
      final ep = ApiEndpoint.fromJson({'name': 'Test', 'url': '/test'});
      expect(ep.method, 'GET');
    });
  });

  group('ApiResponse', () {
    test('fromJson parses response', () {
      final json = {
        'status_code': 200,
        'headers': {'content-type': 'application/json'},
        'body': '{"ok":true}',
        'duration_ms': 42,
      };
      final resp = ApiResponse.fromJson(json);
      expect(resp.statusCode, 200);
      expect(resp.body, '{"ok":true}');
      expect(resp.durationMs, 42);
    });

    test('fromJson handles missing fields', () {
      final resp = ApiResponse.fromJson({});
      expect(resp.statusCode, 0);
      expect(resp.body, '');
      expect(resp.durationMs, 0);
    });
  });

  group('ApiEnvironment', () {
    test('fromJson parses environment', () {
      final env = ApiEnvironment.fromJson({
        'name': 'production',
        'variables': {'API_KEY': 'sk-123'},
      });
      expect(env.name, 'production');
      expect(env.variables['API_KEY'], 'sk-123');
    });

    test('fromJson handles empty map', () {
      final env = ApiEnvironment.fromJson({});
      expect(env.name, '');
      expect(env.variables, isEmpty);
    });
  });

  // ── Database models ─────────────────────────────────────────────────────────

  group('DbConnection', () {
    test('fromJson parses connection', () {
      final conn = DbConnection.fromJson({
        'id': 'conn-1',
        'driver': 'postgres',
        'dsn': 'postgres://localhost/mydb',
        'status': 'connected',
      });
      expect(conn.id, 'conn-1');
      expect(conn.driver, 'postgres');
      expect(conn.dsn, 'postgres://localhost/mydb');
      expect(conn.status, 'connected');
    });

    test('fromJson uses connection_id fallback', () {
      final conn = DbConnection.fromJson({
        'connection_id': 'conn-2',
        'driver': 'sqlite',
        'dsn': '/tmp/test.db',
      });
      expect(conn.id, 'conn-2');
    });

    test('fromJson handles empty map', () {
      final conn = DbConnection.fromJson({});
      expect(conn.id, '');
      expect(conn.driver, '');
    });
  });

  group('DbTable', () {
    test('fromJson parses table', () {
      final table = DbTable.fromJson({
        'name': 'users',
        'schema': 'public',
        'row_count': 42,
      });
      expect(table.name, 'users');
      expect(table.schema, 'public');
      expect(table.rowCount, 42);
    });

    test('fromJson uses table_name fallback', () {
      final table = DbTable.fromJson({'table_name': 'orders'});
      expect(table.name, 'orders');
    });
  });

  group('DbColumn', () {
    test('fromJson parses column', () {
      final col = DbColumn.fromJson({
        'name': 'id',
        'type': 'uuid',
        'nullable': false,
        'default': 'gen_random_uuid()',
        'primary_key': true,
      });
      expect(col.name, 'id');
      expect(col.type, 'uuid');
      expect(col.nullable, false);
      expect(col.defaultValue, 'gen_random_uuid()');
      expect(col.primaryKey, true);
    });

    test('fromJson uses alternate field names', () {
      final col = DbColumn.fromJson({
        'column_name': 'email',
        'data_type': 'varchar(255)',
        'default_value': "''",
      });
      expect(col.name, 'email');
      expect(col.type, 'varchar(255)');
      expect(col.defaultValue, "''");
    });

    test('fromJson defaults', () {
      final col = DbColumn.fromJson({});
      expect(col.name, '');
      expect(col.type, '');
      expect(col.nullable, true);
      expect(col.primaryKey, false);
    });
  });

  group('DbQueryResult', () {
    test('fromJson parses query result', () {
      final result = DbQueryResult.fromJson({
        'columns': ['id', 'name'],
        'rows': [
          {'id': '1', 'name': 'Alice'},
          {'id': '2', 'name': 'Bob'},
        ],
        'row_count': 2,
        'duration_ms': 15,
      });
      expect(result.columns, ['id', 'name']);
      expect(result.rows.length, 2);
      expect(result.rows[0]['name'], 'Alice');
      expect(result.rowCount, 2);
      expect(result.durationMs, 15);
    });

    test('fromJson infers rowCount from rows', () {
      final result = DbQueryResult.fromJson({
        'columns': ['x'],
        'rows': [
          {'x': 1},
        ],
      });
      expect(result.rowCount, 1);
    });

    test('fromJson handles empty result', () {
      final result = DbQueryResult.fromJson({});
      expect(result.columns, isEmpty);
      expect(result.rows, isEmpty);
      expect(result.rowCount, 0);
    });
  });

  // ── Log Runner models ───────────────────────────────────────────────────────

  group('LogProcess', () {
    test('fromJson parses process', () {
      final proc = LogProcess.fromJson({
        'id': 'proc-1',
        'command': 'make dev',
        'working_directory': '/home/user/app',
        'status': 'running',
        'pid': 12345,
        'uptime': '5m 30s',
        'tail': ['line 1', 'line 2'],
      });
      expect(proc.id, 'proc-1');
      expect(proc.command, 'make dev');
      expect(proc.workingDirectory, '/home/user/app');
      expect(proc.status, 'running');
      expect(proc.pid, 12345);
      expect(proc.uptime, '5m 30s');
      expect(proc.tailLines, ['line 1', 'line 2']);
      expect(proc.isRunning, true);
    });

    test('fromJson uses lines fallback', () {
      final proc = LogProcess.fromJson({
        'id': 'proc-2',
        'command': 'npm start',
        'status': 'finished',
        'lines': ['done'],
      });
      expect(proc.tailLines, ['done']);
      expect(proc.isRunning, false);
    });

    test('fromJson handles empty map', () {
      final proc = LogProcess.fromJson({});
      expect(proc.id, '');
      expect(proc.command, '');
      expect(proc.status, 'unknown');
      expect(proc.tailLines, isEmpty);
      expect(proc.isRunning, false);
    });
  });

  group('LogSearchMatch', () {
    test('fromJson parses match', () {
      final match = LogSearchMatch.fromJson({
        'line_number': 42,
        'line': 'ERROR: connection refused',
        'context': ['previous line', 'ERROR: connection refused', 'next line'],
      });
      expect(match.lineNumber, 42);
      expect(match.line, 'ERROR: connection refused');
      expect(match.context.length, 3);
    });

    test('fromJson handles empty map', () {
      final match = LogSearchMatch.fromJson({});
      expect(match.lineNumber, 0);
      expect(match.line, '');
      expect(match.context, isEmpty);
    });
  });

  // ── Secrets models ──────────────────────────────────────────────────────────

  group('Secret', () {
    test('fromJson parses secret', () {
      final secret = Secret.fromJson({
        'id': 'SEC-ABCD',
        'name': 'ANTHROPIC_API_KEY',
        'value': 'sk-ant-...',
        'masked_value': 'sk-***',
        'category': 'api_key',
        'description': 'Claude API key',
        'scope': 'global',
        'tags': ['production', 'claude'],
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T10:00:00Z',
      });
      expect(secret.id, 'SEC-ABCD');
      expect(secret.name, 'ANTHROPIC_API_KEY');
      expect(secret.value, 'sk-ant-...');
      expect(secret.maskedValue, 'sk-***');
      expect(secret.category, 'api_key');
      expect(secret.scope, 'global');
      expect(secret.tags, ['production', 'claude']);
    });

    test('fromJson defaults', () {
      final secret = Secret.fromJson({'id': 'SEC-X', 'name': 'KEY'});
      expect(secret.category, 'general');
      expect(secret.scope, 'global');
      expect(secret.value, isNull);
      expect(secret.tags, isEmpty);
    });

    test('fromJson handles empty map', () {
      final secret = Secret.fromJson({});
      expect(secret.id, '');
      expect(secret.name, '');
    });
  });

  // ── Prompts models ──────────────────────────────────────────────────────────

  group('Prompt', () {
    test('fromJson parses prompt', () {
      final prompt = Prompt.fromJson({
        'id': 'prompt-a1b2c3',
        'title': 'Daily Standup',
        'prompt': 'Report what you did yesterday...',
        'trigger': 'startup',
        'priority': 1,
        'enabled': true,
        'tags': ['daily', 'standup'],
        'created_at': '2026-03-20T10:00:00Z',
      });
      expect(prompt.id, 'prompt-a1b2c3');
      expect(prompt.title, 'Daily Standup');
      expect(prompt.prompt, 'Report what you did yesterday...');
      expect(prompt.trigger, 'startup');
      expect(prompt.priority, 1);
      expect(prompt.enabled, true);
      expect(prompt.tags, ['daily', 'standup']);
    });

    test('fromJson uses content fallback for prompt field', () {
      final prompt = Prompt.fromJson({
        'id': 'p-1',
        'title': 'Test',
        'content': 'Prompt text via content field',
      });
      expect(prompt.prompt, 'Prompt text via content field');
    });

    test('fromJson defaults', () {
      final prompt = Prompt.fromJson({'id': 'p-x', 'title': 'X'});
      expect(prompt.trigger, 'startup');
      expect(prompt.priority, 0);
      expect(prompt.enabled, true);
      expect(prompt.tags, isEmpty);
      expect(prompt.prompt, '');
    });

    test('fromJson handles empty map', () {
      final prompt = Prompt.fromJson({});
      expect(prompt.id, '');
      expect(prompt.title, '');
    });
  });
}
