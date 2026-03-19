import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/screens/installer/orchestra_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gates that must pass before the app can show its main content.
enum StartupGate {
  /// Still evaluating prerequisites.
  checking,

  /// Desktop: Orchestra binary not found — show installer.
  needsInstall,

  /// Desktop: No workspace selected — show welcome/picker.
  needsWorkspace,

  /// Desktop: Sandbox has no file access — prompt user to grant.
  needsFileAccess,

  /// Mobile: Desktop web-gate API unreachable — prompt user.
  needsDesktop,

  /// All checks passed — continue to splash/auth.
  ready,
}

/// Evaluates platform-specific prerequisites at app startup.
class StartupGateNotifier extends AsyncNotifier<StartupGate> {
  @override
  Future<StartupGate> build() => _evaluate();

  /// Re-evaluate after the user completes an install or selects a workspace.
  Future<void> recheck() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _evaluate());
  }

  Future<StartupGate> _evaluate() async {
    if (isDesktop) {
      return _evaluateDesktop();
    }
    if (isMobile || isWeb) {
      return _evaluateMobile();
    }
    return StartupGate.ready;
  }

  Future<StartupGate> _evaluateDesktop() async {
    // 1. Check binary
    final result = await OrchestraDetector().check();
    if (result == DetectResult.notFound) return StartupGate.needsInstall;

    // 2. Check file access (macOS sandbox)
    if (!FileAccessService.instance.hasHomeAccess) {
      return StartupGate.needsFileAccess;
    }

    // 3. Check workspace
    final prefs = await SharedPreferences.getInstance();
    final workspace = prefs.getString('workspace_path') ?? '';
    if (workspace.isEmpty) return StartupGate.needsWorkspace;

    return StartupGate.ready;
  }

  Future<StartupGate> _evaluateMobile() async {
    // Mobile/web talks to the web API directly — no desktop dependency.
    // Health, Summary, Settings all work independently.
    return StartupGate.ready;
  }
}

final startupGateProvider =
    AsyncNotifierProvider<StartupGateNotifier, StartupGate>(
      StartupGateNotifier.new,
    );
