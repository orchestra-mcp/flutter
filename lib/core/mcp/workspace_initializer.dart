import 'dart:io';

import 'package:flutter/foundation.dart';

/// Ensures a workspace directory has Orchestra initialized.
///
/// Checks for the `.orchestra/` directory and runs `orchestra init` if missing.
class WorkspaceInitializer {
  WorkspaceInitializer._();

  /// Returns true if the workspace already has Orchestra initialized.
  static bool isInitialized(String workspacePath) {
    return Directory('$workspacePath/.orchestra').existsSync();
  }

  /// Ensures the workspace is initialized. Runs `orchestra init` if needed.
  /// Returns true if init was run, false if already initialized.
  static Future<bool> ensureInitialized(String workspacePath) async {
    if (isInitialized(workspacePath)) return false;

    debugPrint('[WorkspaceInit] Running orchestra init in $workspacePath');
    try {
      final result = await Process.run('orchestra', [
        'init',
      ], workingDirectory: workspacePath);
      if (result.exitCode == 0) {
        debugPrint('[WorkspaceInit] Init completed successfully');
        return true;
      } else {
        debugPrint('[WorkspaceInit] Init failed: ${result.stderr}');
        return false;
      }
    } on ProcessException catch (e) {
      debugPrint('[WorkspaceInit] Process error: $e');
      return false;
    }
  }
}
