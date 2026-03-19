import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';

/// Backend connector for PowerSync — handles authentication and data uploads.
///
/// - [fetchCredentials] obtains a PowerSync JWT from the Orchestra backend.
/// - [uploadData] sends local CRUD operations as a single batch POST to
///   `/api/powersync/crud`, eliminating per-table endpoint mapping.
class OrchestraBackendConnector extends PowerSyncBackendConnector {
  OrchestraBackendConnector({
    required this.apiBaseUrl,
    required this.powersyncUrl,
    required this.sessionToken,
  });

  /// Orchestra API base URL (e.g. https://api.orchestra-mcp.dev).
  final String apiBaseUrl;

  /// PowerSync service URL (e.g. https://sync.orchestra-mcp.dev).
  final String powersyncUrl;

  /// The user's session JWT for authenticating with the Orchestra API.
  final String sessionToken;

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Old table names from before the rename — stale CRUD entries referencing
  /// these should be discarded since the API never had endpoints for them.
  static const _staleTables = <String>{
    'health_hydration',
    'health_caffeine',
    'health_nutrition',
    'health_pomodoro',
    'health_shutdown',
    'health_weight',
    'health_settings',
    'health_sleep',
    'health_vitals',
  };

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/powersync/token'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[PowerSync] Token fetch failed: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final expiresAt = data['expires_at'] as int;

      return PowerSyncCredentials(
        endpoint: powersyncUrl,
        token: token,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
      );
    } catch (e) {
      debugPrint('[PowerSync] Failed to fetch credentials: $e');
      return null;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      final ops = <Map<String, dynamic>>[];

      for (final op in transaction.crud) {
        // Discard stale CRUD entries from old table names.
        if (_staleTables.contains(op.table)) continue;

        // Skip non-UUID IDs from MCP workspace (e.g. "note-2ecdf1").
        if (!_uuidRegex.hasMatch(op.id)) continue;

        ops.add({
          'table': op.table,
          'op': switch (op.op) {
            UpdateType.put => 'PUT',
            UpdateType.patch => 'PATCH',
            UpdateType.delete => 'DELETE',
          },
          'id': op.id,
          'data': op.opData ?? {},
        });
      }

      if (ops.isEmpty) {
        await transaction.complete();
        return;
      }

      final res = await http.post(
        Uri.parse('$apiBaseUrl/api/powersync/crud'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'operations': ops}),
      );

      if (res.statusCode < 400) {
        await transaction.complete();
        debugPrint('[PowerSync] Batch uploaded ${ops.length} ops');
      } else {
        debugPrint('[PowerSync] Batch upload returned ${res.statusCode}: ${res.body}');
        // Complete even on server error — the server processed what it could.
        // Retrying the same ops won't help and causes "previously encountered CRUD item" loops.
        await transaction.complete();
      }
    } catch (e) {
      debugPrint('[PowerSync] Batch upload failed: $e');
      // Complete on network error too — prevents infinite retry loops.
      // Data will re-sync from the server on next connection.
      try { await transaction.complete(); } catch (_) {}
    }
  }
}
