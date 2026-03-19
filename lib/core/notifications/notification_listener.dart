import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';

// ── Notification IDs (11000+ range to avoid colliding with health IDs) ──────

class _NotifIds {
  static const int mcpToolCall = 11000;
  static const int mcpAgentSpawn = 11001;
  static const int mcpNotification = 11002;
  static const int mcpGeneric = 11003;
}

const _kChannelId = 'mcp_events';
const _kChannelName = 'MCP Events';

// ── Notification Listener ───────────────────────────────────────────────────

/// Listens for real-time MCP events from the orchestra web-gate WebSocket
/// and delivers local notifications on mobile/desktop.
///
/// Piggybacks on the existing [WsManager] connection instead of opening a
/// separate WebSocket. When an [McpEvent] arrives, it:
///   1. Shows a local notification via flutter_local_notifications.
///   2. Increments the [unreadCount] badge counter.
///   3. Emits the event on [onNotification] for in-app consumers.
class NotificationListener {
  NotificationListener(this._ref);

  final Ref _ref;
  StreamSubscription<WsEvent>? _sub;
  bool _running = false;
  bool _localNotifInitialized = false;

  final _notificationController =
      StreamController<McpEvent>.broadcast();

  /// Stream of incoming MCP notification events.
  Stream<McpEvent> get onNotification => _notificationController.stream;

  /// Number of unread MCP notifications since the listener started.
  final unreadCount = ValueNotifier<int>(0);

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start listening for MCP events on the existing WebSocket connection.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    await _initLocalNotifications();

    final ws = _ref.read(wsManagerProvider);

    // Connect if not already connected.
    if (ws.state != WsState.connected) {
      await ws.connect();
    }

    _sub = ws.eventStream.listen(_onWsEvent);
    debugPrint('[NotifListener] Started listening for MCP events');
  }

  /// Stop listening and clean up.
  void stop() {
    _running = false;
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    stop();
    _notificationController.close();
    unreadCount.dispose();
  }

  // ── Event handling ────────────────────────────────────────────────────────

  void _onWsEvent(WsEvent event) {
    if (event is! McpEvent) return;

    _notificationController.add(event);
    unreadCount.value++;

    _showLocalNotification(event);
  }

  /// Mark all notifications as read (resets badge count).
  void markAllRead() {
    unreadCount.value = 0;
  }

  // ── Local notifications ───────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    if (_localNotifInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested by HealthNotifService
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotif.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create Android channel.
    final android = _localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          description: 'Notifications from MCP tool calls and agent events',
          importance: Importance.defaultImportance,
        ),
      );
    }

    _localNotifInitialized = true;
    debugPrint('[NotifListener] Local notifications initialized');
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Deep-link handling can be wired up here in the future.
    debugPrint('[NotifListener] Notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification(McpEvent event) async {
    if (!_localNotifInitialized) return;

    final (int id, String title, String body) = _notifContent(event);

    await _localNotif.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription:
              'Notifications from MCP tool calls and agent events',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          groupKey: _kChannelId,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '/notifications',
    );
  }

  (int, String, String) _notifContent(McpEvent event) {
    return switch (event) {
      McpToolCalledEvent(:final toolName) => (
          _NotifIds.mcpToolCall,
          'Tool Called',
          'Claude used $toolName',
        ),
      McpAgentSpawnedEvent(:final agentType) => (
          _NotifIds.mcpAgentSpawn,
          'Agent Spawned',
          'Sub-agent "$agentType" started',
        ),
      McpNotificationEvent(:final entityType, :final entityId) => (
          _NotifIds.mcpNotification,
          'Action Required',
          '$entityType: $entityId needs your attention',
        ),
      McpGenericEvent(:final action) => (
          _NotifIds.mcpGeneric,
          'MCP Event',
          action.isNotEmpty ? action : 'New event received',
        ),
    };
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Singleton [NotificationListener] for the app lifetime.
final notificationListenerProvider = Provider<NotificationListener>((ref) {
  final listener = NotificationListener(ref);
  ref.onDispose(listener.dispose);
  return listener;
});

/// Stream of MCP notification events for in-app display.
final notificationStreamProvider = StreamProvider<McpEvent>((ref) {
  final listener = ref.watch(notificationListenerProvider);
  listener.start();
  return listener.onNotification;
});

/// Unread MCP notification count as a [ValueNotifier].
final unreadNotificationCountProvider = Provider<ValueNotifier<int>>((ref) {
  return ref.watch(notificationListenerProvider).unreadCount;
});
