import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/workspace/workspace_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached workspace scan results, refreshed on app startup.
///
/// On desktop, scans `.projects/` for all entity files and provides
/// them as a fallback data source when the SQLite DB is unavailable
/// or stale.
final workspaceScanProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
      if (!isDesktop || kIsWeb) return {};

      final prefs = await SharedPreferences.getInstance();
      final workspacePath = prefs.getString('workspace_path');
      if (workspacePath == null || workspacePath.isEmpty) return {};

      // Verify workspace exists.
      if (!Directory(workspacePath).existsSync()) return {};

      final scanner = WorkspaceScanner(workspacePath: workspacePath);
      final results = await scanner.scanAll();

      debugPrint(
        '[WorkspaceScanProvider] Loaded: '
        '${results['features']?.length ?? 0} features, '
        '${results['plans']?.length ?? 0} plans, '
        '${results['agents']?.length ?? 0} agents, '
        '${results['skills']?.length ?? 0} skills',
      );

      return results;
    });

/// Convenience accessors for specific entity types.

final scannedFeaturesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['features'] ??
      [];
});

final scannedPlansProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['plans'] ??
      [];
});

final scannedAgentsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['agents'] ??
      [];
});

final scannedSkillsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['skills'] ??
      [];
});

final scannedDocsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['docs'] ??
      [];
});

final scannedHooksProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['hooks'] ??
      [];
});

final scannedConfigProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final scan = ref.watch(workspaceScanProvider);
  return scan.when(
        data: (d) => d,
        error: (_, __) => null,
        loading: () => null,
      )?['config'] ??
      [];
});
