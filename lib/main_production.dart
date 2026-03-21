import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:orchestra/app.dart';
import 'package:orchestra/core/config/flavor_config.dart';
import 'package:orchestra/core/firebase/firebase_service.dart';
import 'package:orchestra/core/firebase/messaging_service.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/team/team_provider.dart';
import 'package:orchestra/core/tray/tray_service.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/features/health/health_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage msg) =>
    firebaseMessagingBackgroundHandler(msg);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();
  FirebaseMessaging.onBackgroundMessage(_bgHandler);
  initFlavor();
  await initPowerSync();
  try {
    await FirebaseService.init();
  } catch (e) {
    debugPrint('[main] Firebase init failed (non-fatal): $e');
  }
  if (isDesktop) {
    await TrayService.instance.init();
    await FileAccessService.instance.restoreSavedAccess();
  }
  await initWorkspacePath();
  await initActiveTeam();
  await HealthNotificationService.instance.initialize();
  runApp(const ProviderScope(child: OrchestraApp()));
}
