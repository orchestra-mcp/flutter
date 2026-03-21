import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/workspace/workspace_bridge.dart';

/// The workspace bridge instance — created synchronously, init'd async.
WorkspaceBridge? _bridgeInstance;

/// Provides the [WorkspaceBridge] after initialization completes.
///
/// On desktop: scans workspace files → SQLite, starts file watcher.
/// On mobile/web: completes immediately with null.
///
/// Downstream providers should `await ref.watch(workspaceBridgeReadyProvider.future)`
/// before reading from the workspace SQLite DB.
final workspaceBridgeReadyProvider = FutureProvider<WorkspaceBridge?>((
  ref,
) async {
  if (!isDesktop || kIsWeb) return null;

  final workspace = ref.watch(workspacePathProvider);
  if (workspace.isEmpty) return null;

  // Reuse existing instance if workspace hasn't changed.
  if (_bridgeInstance != null && _bridgeInstance!.workspacePath == workspace) {
    return _bridgeInstance;
  }

  // Dispose old bridge if workspace changed.
  _bridgeInstance?.dispose();

  final bridge = WorkspaceBridge(workspacePath: workspace);
  await bridge.init();
  debugPrint('[WorkspaceBridge] Ready');

  _bridgeInstance = bridge;

  ref.onDispose(() {
    bridge.dispose();
    if (_bridgeInstance == bridge) _bridgeInstance = null;
  });

  return bridge;
});

/// Synchronous access to the bridge (may be null if not yet initialized).
final workspaceBridgeProvider = Provider<WorkspaceBridge?>((ref) {
  final async = ref.watch(workspaceBridgeReadyProvider);
  return async.when(
    data: (b) => b,
    error: (_, __) => null,
    loading: () => _bridgeInstance,
  );
});

/// Eagerly initialize the workspace bridge on app startup.
final workspaceBridgeInitProvider = Provider<void>((ref) {
  ref.watch(workspaceBridgeReadyProvider);
});
