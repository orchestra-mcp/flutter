import 'package:flutter/foundation.dart';

/// State of the system tray icon.
enum TrayIconState { running, starting, stopped, error }

/// Stub tray manager service for platforms without tray_manager support.
///
/// On desktop platforms (macOS, Windows, Linux) this would delegate to the
/// tray_manager package. Here we provide a no-op implementation so that the
/// rest of the codebase can reference [TrayManagerService] unconditionally.
class TrayManagerService {
  TrayManagerService._();

  static final TrayManagerService instance = TrayManagerService._();

  TrayIconState _state = TrayIconState.stopped;
  TrayIconState get state => _state;

  Future<void> init() async {
    if (kIsWeb) return;
    debugPrint('[Tray] init');
  }

  Future<void> updateIcon(TrayIconState newState) async {
    _state = newState;
    debugPrint('[Tray] updateIcon: $newState');
  }

  Future<void> buildMenu({
    required List<String> workspaceNames,
    required String? activeWorkspaceId,
    required void Function() onShowHide,
    required void Function() onQuit,
  }) async {
    debugPrint('[Tray] buildMenu workspaces=${workspaceNames.length}');
  }

  Future<void> dispose() async {
    debugPrint('[Tray] dispose');
  }
}
