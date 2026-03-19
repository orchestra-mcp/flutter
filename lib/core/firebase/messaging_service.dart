import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/config/env.dart';

/// Handles FCM registration, deep-link routing and notification channels.
abstract final class MessagingService {
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  static Future<void> init() async {
    if (!Env.enableFirebase) return;
    _messaging = FirebaseMessaging.instance;

    // Request permission (iOS / macOS)
    await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Background / terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleDeepLink(msg.data['path'] as String? ?? '/');
    });

    // App launched from a notification
    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      _handleDeepLink(initial.data['path'] as String? ?? '/');
    }

    // Token
    _fcmToken = await _messaging!.getToken();
    _messaging!.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _registerToken(token);
    });

    if (_fcmToken != null) _registerToken(_fcmToken!);

    if (kDebugMode) debugPrint('[FCM] token: $_fcmToken');
  }

  static void _handleForeground(RemoteMessage message) {
    // TODO(FEAT-WLD): Show GlassSheet banner when design system is ready.
    if (kDebugMode)
      debugPrint('[FCM] foreground: ${message.notification?.title}');
  }

  static void _handleDeepLink(String path) {
    // TODO(FEAT-OYK): Route via go_router once router is configured.
    if (kDebugMode) debugPrint('[FCM] deep-link: $path');
  }

  static void _registerToken(String token) {
    // TODO(FEAT-XQI): POST /api/devices/register via Dio client.
    if (kDebugMode)
      debugPrint('[FCM] register token: ${token.substring(0, 12)}...');
  }

  // ─── Topic subscriptions ──────────────────────────────────────────────────

  static Future<void> subscribeToUser(String userId) async {
    await _messaging?.subscribeToTopic('user_$userId');
  }

  static Future<void> subscribeToTeam(String teamId) async {
    await _messaging?.subscribeToTopic('team_$teamId');
  }

  static Future<void> subscribeToWorkspace(String workspaceId) async {
    await _messaging?.subscribeToTopic('workspace_$workspaceId');
  }

  static Future<void> unsubscribeAll({
    String? userId,
    String? teamId,
    String? workspaceId,
  }) async {
    if (userId != null) await _messaging?.unsubscribeFromTopic('user_$userId');
    if (teamId != null) await _messaging?.unsubscribeFromTopic('team_$teamId');
    if (workspaceId != null) {
      await _messaging?.unsubscribeFromTopic('workspace_$workspaceId');
    }
  }
}

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) debugPrint('[FCM] background: ${message.messageId}');
}
