import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';

// ── Notification IDs & channel ──────────────────────────────────────────────

class _McpNotifIds {
  static const int toolCalled = 30000;
  static const int agentSpawned = 30001;
  static const int notification = 30002;
}

const _kChannelId = 'mcp_agent';
const _kChannelName = 'Agent Activity';
const _kChannelDesc =
    'Notifications when AI agents need attention (delegation, permission, review)';

// ── Service ─────────────────────────────────────────────────────────────────

/// Shows desktop system notifications and optional TTS for MCP hook events
/// that require user attention — delegations, permission requests, and reviews.
class AgentNotificationService {
  AgentNotificationService({required this.ref, required this.wsManager}) {
    _sub = wsManager.eventStream.listen(_onEvent);
  }

  final Ref ref;
  final WsManager wsManager;
  StreamSubscription<WsEvent>? _sub;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createAndroidChannel();
    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: _kChannelDesc,
        importance: Importance.high,
      ),
    );
  }

  static void _onTap(NotificationResponse response) {
    if (kDebugMode && response.payload != null) {
      debugPrint('[AgentNotif] tapped: ${response.payload}');
    }
  }

  // ── Event handling ──────────────────────────────────────────────────────

  void _onEvent(WsEvent event) {
    switch (event) {
      case McpNotificationEvent():
        _showNotification(event);
      case McpAgentSpawnedEvent():
        // Optional: notify on agent spawn if enabled.
        if (_isVerboseEnabled()) {
          _showAgentSpawnNotification(event);
        }
      default:
        break;
    }
  }

  // ── Settings check ────────────────────────────────────────────────────

  bool _isEnabled() {
    final prefs = ref.read(preferencesProvider).value;
    if (prefs == null) return true;
    final notifications = prefs['notifications'];
    if (notifications is Map) {
      return notifications['agent_push'] != false;
    }
    return true;
  }

  bool _isVerboseEnabled() {
    final prefs = ref.read(preferencesProvider).value;
    if (prefs == null) return false;
    final notifications = prefs['notifications'];
    if (notifications is Map) {
      return notifications['agent_verbose'] == true;
    }
    return false;
  }

  // ── Notification display ──────────────────────────────────────────────

  Future<void> _showNotification(McpNotificationEvent event) async {
    if (!_isEnabled()) return;
    await _ensureInitialized();

    final title = _notificationTitle(event.entityType);
    final body = 'Agent needs your attention — ${event.entityType}';

    await _plugin.show(
      id: _McpNotifIds.notification,
      title: title,
      body: body,
      notificationDetails: _details(Importance.high),
      payload: '/hooks/${event.sessionId}',
    );
  }

  Future<void> _showAgentSpawnNotification(McpAgentSpawnedEvent event) async {
    if (!_isEnabled()) return;
    await _ensureInitialized();

    await _plugin.show(
      id: _McpNotifIds.agentSpawned,
      title: 'Agent Spawned',
      body: 'A ${event.agentType} agent started working',
      notificationDetails: _details(Importance.defaultImportance),
      payload: '/hooks/${event.sessionId}',
    );
  }

  String _notificationTitle(String entityType) {
    return switch (entityType) {
      'delegation' => 'Delegation Request',
      'permission' => 'Permission Required',
      'review' => 'Review Requested',
      _ => 'Agent Attention Needed',
    };
  }

  NotificationDetails _details(Importance importance) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: importance,
        priority: importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        groupKey: _kChannelId,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final agentNotificationServiceProvider = Provider<AgentNotificationService>((
  ref,
) {
  final service = AgentNotificationService(
    ref: ref,
    wsManager: ref.watch(wsManagerProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Watch this provider at app root to activate agent notifications.
final agentNotificationsProvider = Provider<void>((ref) {
  ref.watch(agentNotificationServiceProvider);
});
