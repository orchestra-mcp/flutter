import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/powersync/connector.dart';
import 'package:orchestra/core/powersync/schema.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global PowerSync database instance, set during app startup.
PowerSyncDatabase? _db;

/// Bump this when the PowerSync schema changes (table renames, column changes).
/// Forces a full re-sync from server on app restart.
const _schemaVersion = 11;

/// Must be called once during app startup (before runApp or in main).
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await initPowerSync();
///   runApp(const ProviderScope(child: OrchestraApp()));
/// }
/// ```
Future<void> initPowerSync() async {
  if (_db != null) return;

  String dbPath;
  if (kIsWeb) {
    dbPath = 'orchestra-sync.db';
  } else {
    final dir = await getApplicationSupportDirectory();
    dbPath = p.join(dir.path, 'orchestra-sync.db');

    // Check if schema version changed — if so, delete stale local DB so
    // PowerSync re-creates it with the new table names and re-syncs from server.
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('powersync_schema_version') ?? 0;
    if (storedVersion < _schemaVersion) {
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        debugPrint(
          '[PowerSync] Schema version changed ($storedVersion → $_schemaVersion), deleting stale DB',
        );
        dbFile.deleteSync();
        // Also delete WAL/SHM files if they exist.
        final wal = File('$dbPath-wal');
        final shm = File('$dbPath-shm');
        if (wal.existsSync()) wal.deleteSync();
        if (shm.existsSync()) shm.deleteSync();
      }
      await prefs.setInt('powersync_schema_version', _schemaVersion);
    }
  }

  _db = PowerSyncDatabase(schema: powersyncSchema, path: dbPath);
  await _db!.initialize();
  debugPrint(
    '[PowerSync] Database initialized at $dbPath (schema v$_schemaVersion)',
  );

  // One-time cleanup: remove duplicate workflows (keep latest updated_at per name+project_slug).
  await _deduplicateWorkflows(_db!);
}

/// Deletes duplicate workflow rows, keeping only the one with the latest
/// updated_at for each (name, project_slug) combination.
Future<void> _deduplicateWorkflows(PowerSyncDatabase db) async {
  try {
    final deleted = await db.execute(
      'DELETE FROM workflows WHERE id NOT IN ('
      '  SELECT id FROM ('
      '    SELECT id, ROW_NUMBER() OVER ('
      '      PARTITION BY name, COALESCE(project_slug, \'\') '
      '      ORDER BY updated_at DESC'
      '    ) AS rn FROM workflows'
      '  ) ranked WHERE rn = 1'
      ')',
    );
    debugPrint(
      '[PowerSync] Workflow dedup cleanup: removed $deleted duplicate rows',
    );
  } catch (e) {
    debugPrint('[PowerSync] Workflow dedup cleanup failed (non-fatal): $e');
  }
}

/// Provides the [PowerSyncDatabase] singleton.
///
/// Requires [initPowerSync] to have been called first (in main).
final powersyncDatabaseProvider = Provider<PowerSyncDatabase>((ref) {
  final db = _db;
  if (db == null) {
    throw StateError(
      'PowerSync not initialized. Call initPowerSync() in main() before runApp().',
    );
  }

  // Watch auth state to connect/disconnect.
  ref.listen(authProvider, (prev, next) async {
    final value = next.value;
    if (value is AuthAuthenticated) {
      final storage = const TokenStorage();
      final token = await storage.getAccessToken();
      if (token != null) {
        _connectDatabase(db, token);
      }
    } else {
      await db.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(() {
    db.disconnect();
  });

  return db;
});

void _connectDatabase(PowerSyncDatabase db, String sessionToken) {
  final connector = OrchestraBackendConnector(
    apiBaseUrl: Env.apiBaseUrl,
    powersyncUrl: Env.powersyncUrl,
    sessionToken: sessionToken,
  );

  db.connect(connector: connector);
  debugPrint('[PowerSync] Connected to ${Env.powersyncUrl}');
}
