import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/firebase/messaging_service.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/ws/ws_event.dart';

// ── Notification IDs & channel ──────────────────────────────────────────────

class _SyncNotifIds {
  static const int entityUpdated = 20000;
  static const int entityShared = 20001;
  static const int entityDeleted = 20002;
}

const _kChannelId = 'sync_updates';
const _kChannelName = 'Sync Updates';
const _kChannelDesc = 'Notifications when team members update shared entities';

// ── Service ─────────────────────────────────────────────────────────────────

/// Shows local desktop/mobile notifications for incoming sync WebSocket events
/// and manages FCM topic subscriptions for background delivery.
class SyncNotificationService {
  SyncNotificationService({required this.ref});

  final Ref ref;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
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
        importance: Importance.defaultImportance,
      ),
    );
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (kDebugMode && payload != null) {
      debugPrint('[SyncNotif] tapped: $payload');
    }
    // Deep-link routing handled by the global notification response handler.
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Returns true if the user has sync push notifications enabled.
  bool _isEnabled() {
    final prefs = ref.read(preferencesProvider).value;
    if (prefs == null) return true;
    final notifications = prefs['notifications'];
    if (notifications is Map) {
      return notifications['sync'] != false;
    }
    return prefs['notification_sync'] != false;
  }

  /// Shows a local notification for a sync event if notifications are enabled.
  Future<void> showForEvent(WsEvent event) async {
    if (!_isEnabled()) return;
    if (!_initialized) await initialize();

    final (id, title, body, payload) = switch (event) {
      SyncEntityUpdatedEvent(
        :final authorName,
        :final entityTitle,
        :final entityType,
      ) =>
        (
          _SyncNotifIds.entityUpdated,
          '$authorName updated a $entityType',
          entityTitle,
          '/$entityType',
        ),
      SyncEntitySharedEvent(
        :final authorName,
        :final entityTitle,
        :final entityType,
      ) =>
        (
          _SyncNotifIds.entityShared,
          '$authorName shared a $entityType with you',
          entityTitle,
          '/$entityType',
        ),
      SyncEntityDeletedEvent(:final authorName, :final entityType) => (
        _SyncNotifIds.entityDeleted,
        '$authorName deleted a shared $entityType',
        'A shared $entityType was removed',
        '/$entityType',
      ),
      _ => (null, null, null, null),
    };

    if (id == null) return;

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
      payload: payload,
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
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
    );
  }

  // ── FCM topic management ──────────────────────────────────────────────

  /// Subscribe to FCM sync topics for the given team so notifications
  /// arrive even when the app is backgrounded / WS is disconnected.
  Future<void> subscribeToTeamSync(String teamId) async {
    await MessagingService.subscribeToTeam('${teamId}_sync');
  }

  /// Unsubscribe from a team's sync FCM topic.
  Future<void> unsubscribeFromTeamSync(String teamId) async {
    await MessagingService.unsubscribeAll(teamId: '${teamId}_sync');
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final syncNotificationServiceProvider = Provider<SyncNotificationService>((
  ref,
) {
  return SyncNotificationService(ref: ref);
});
