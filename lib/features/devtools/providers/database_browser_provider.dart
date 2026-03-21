import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class DbConnection {
  final String id;
  final String driver;
  final String dsn;
  final String? status;

  const DbConnection({
    required this.id,
    required this.driver,
    required this.dsn,
    this.status,
  });

  factory DbConnection.fromJson(Map<String, dynamic> json) {
    return DbConnection(
      id: json['id'] as String? ?? json['connection_id'] as String? ?? '',
      driver: json['driver'] as String? ?? '',
      dsn: json['dsn'] as String? ?? '',
      status: json['status'] as String?,
    );
  }
}

class DbTable {
  final String name;
  final String? schema;
  final int? rowCount;

  const DbTable({required this.name, this.schema, this.rowCount});

  factory DbTable.fromJson(Map<String, dynamic> json) {
    return DbTable(
      name: json['name'] as String? ?? json['table_name'] as String? ?? '',
      schema: json['schema'] as String?,
      rowCount: json['row_count'] as int?,
    );
  }
}

class DbColumn {
  final String name;
  final String type;
  final bool nullable;
  final String? defaultValue;
  final bool primaryKey;

  const DbColumn({
    required this.name,
    required this.type,
    this.nullable = true,
    this.defaultValue,
    this.primaryKey = false,
  });

  factory DbColumn.fromJson(Map<String, dynamic> json) {
    return DbColumn(
      name: json['name'] as String? ?? json['column_name'] as String? ?? '',
      type: json['type'] as String? ?? json['data_type'] as String? ?? '',
      nullable: json['nullable'] as bool? ?? true,
      defaultValue:
          json['default'] as String? ?? json['default_value'] as String?,
      primaryKey: json['primary_key'] as bool? ?? false,
    );
  }
}

class DbQueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final int rowCount;
  final int? durationMs;

  const DbQueryResult({
    required this.columns,
    required this.rows,
    required this.rowCount,
    this.durationMs,
  });

  factory DbQueryResult.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DbQueryResult(
      columns: (json['columns'] as List<dynamic>? ?? []).cast<String>(),
      rows: rows,
      rowCount: json['row_count'] as int? ?? rows.length,
      durationMs: json['duration_ms'] as int?,
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Typed Riverpod wrapper around MCP Database tools.
///
/// Calls MCP tools: db_connect, db_disconnect, db_list_connections,
/// db_list_tables, db_describe_table, db_query.
class DatabaseBrowserNotifier extends AsyncNotifier<List<DbConnection>> {
  @override
  Future<List<DbConnection>> build() => listConnections();

  Future<List<DbConnection>> listConnections() async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('db_list_connections', {});
    final list = result['connections'] as List<dynamic>? ?? [];
    return list
        .map((e) => DbConnection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DbConnection> connect({
    required String driver,
    required String dsn,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('db_connect', {
      'driver': driver,
      'dsn': dsn,
    });
    ref.invalidateSelf();
    return DbConnection.fromJson(result);
  }

  Future<void> disconnect(String connectionId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('db_disconnect', {'connection_id': connectionId});
    ref.invalidateSelf();
  }

  Future<List<DbTable>> listTables(
    String connectionId, {
    String? schema,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('db_list_tables', {
      'connection_id': connectionId,
      if (schema != null) 'schema': schema,
    });
    final list = result['tables'] as List<dynamic>? ?? [];
    return list
        .map((e) => DbTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DbColumn>> describeTable(
    String connectionId,
    String table,
  ) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('db_describe_table', {
      'connection_id': connectionId,
      'table': table,
    });
    final list = result['columns'] as List<dynamic>? ?? [];
    return list
        .map((e) => DbColumn.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DbQueryResult> query(String connectionId, String sql) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('db_query', {
      'connection_id': connectionId,
      'query': sql,
    });
    return DbQueryResult.fromJson(result);
  }
}

final databaseBrowserProvider =
    AsyncNotifierProvider<DatabaseBrowserNotifier, List<DbConnection>>(
      DatabaseBrowserNotifier.new,
    );

/// Lists tables for a given connection ID.
final dbTablesProvider = FutureProvider.family<List<DbTable>, String>((
  ref,
  connectionId,
) async {
  final notifier = ref.watch(databaseBrowserProvider.notifier);
  return notifier.listTables(connectionId);
});

/// Describes columns for a (connectionId, tableName) pair.
final dbColumnsProvider =
    FutureProvider.family<
      List<DbColumn>,
      ({String connectionId, String table})
    >((ref, params) async {
      final notifier = ref.watch(databaseBrowserProvider.notifier);
      return notifier.describeTable(params.connectionId, params.table);
    });
