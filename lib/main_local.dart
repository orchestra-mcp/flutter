import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:orchestra/app.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/config/flavor_config.dart';
import 'package:orchestra/core/team/team_provider.dart';
import 'package:orchestra/core/firebase/firebase_service.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/tray/tray_service.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/features/health/health_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  initFlavor();
  await initPowerSync();
  // Firebase init can fail on macOS when the app is unsigned (Keychain
  // access denied). Wrap so it never blocks runApp().
  try {
    await FirebaseService.init(); // no-op when ENABLE_FIREBASE=false
  } catch (e) {
    debugPrint('[main] Firebase init failed (non-fatal): $e');
  }
  if (isDesktop) {
    await TrayService.instance.init();
    // Restore saved security-scoped bookmarks for file access.
    // If no home bookmark exists, the app will prompt on first workspace load.
    await FileAccessService.instance.restoreSavedAccess();
  }
  await initWorkspacePath(); // Prime workspace path for LocalMcpClient
  await initActiveTeam();
  await HealthNotificationService.instance.initialize();
  runApp(const ProviderScope(child: OrchestraApp()));
}
