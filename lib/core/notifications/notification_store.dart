import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real notification item (replaces placeholder data).
class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.data = const {},
  });

  final String id;
  final String type; // feature_update, health_alert, smart_action, sync, agent_event
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> data;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    data: data,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'general',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    isRead: json['isRead'] as bool? ?? false,
  );
}

/// Notification store — manages real notifications from MCP events,
/// persists to SharedPreferences, and listens to the MCP notification stream.
class NotificationStoreNotifier extends Notifier<List<AppNotification>> {
  StreamSubscription<Map<String, dynamic>>? _mcpSub;
  static const _storageKey = 'app_notifications_v1';
  static const _maxNotifications = 50;

  @override
  List<AppNotification> build() {
    _loadFromStorage();
    _listenToMcpEvents();
    ref.onDispose(() => _mcpSub?.cancel());
    return [];
  }

  /// Load persisted notifications from SharedPreferences.
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        state = list
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationStore] Load error: $e');
    }
  }

  /// Listen to MCP notification stream for real-time events.
  void _listenToMcpEvents() {
    if (!isDesktop) return;

    // Delay to let MCP client initialize.
    Future.delayed(const Duration(seconds: 3), () {
      final mcp = ref.read(mcpClientProvider);
      if (mcp == null) return;

      _mcpSub = mcp.notifications.listen((json) {
        // Format 1: Direct MCP notification (has "method" at top level).
        final method = json['method'] as String?;
        if (method == 'notifications/event') {
          final params = json['params'] as Map<String, dynamic>?;
          if (params == null) return;
          _handleTopicEvent(
            params['topic'] as String? ?? '',
            params['data'] as Map<String, dynamic>? ?? {},
          );
          return;
        }

        // Format 2: WebGate realtime broadcast — notifications/data
        // Shape: {method: "notifications/data", params: {topic, event_type, payload}}
        if (method == 'notifications/data') {
          final params = json['params'] as Map<String, dynamic>?;
          if (params != null) {
            _handleTopicEvent(
              params['topic'] as String? ?? '',
              params['payload'] as Map<String, dynamic>? ?? {},
            );
          }
          return;
        }

        // Format 3: Bridge streaming events (no-id, result.method).
        final result = json['result'] as Map<String, dynamic>?;
        if (result != null && result['method'] == 'notifications/events') {
          final params = result['params'];
          if (params is List) {
            for (final event in params) {
              if (event is! Map<String, dynamic>) continue;
              _handleStreamingEvent(event);
            }
          }
        }
      });
    });
  }

  /// Handle topic-based MCP events (features, smart_action, sync).
  void _handleTopicEvent(String topic, Map<String, dynamic> data) {
    switch (topic) {
      case 'features':
        final status = data['status']?.toString() ?? '';
        final featureTitle = data['title']?.toString() ?? '';
        final isDone = status == 'done';
        _addNotification(
          type: 'feature_update',
          // titleKey is read by _NotificationTile for localization.
          title: isDone ? 'notifFeatureComplete' : 'notifFeatureUpdated',
          body: status.isNotEmpty && featureTitle.isNotEmpty
              ? '$featureTitle → $status'
              : featureTitle,
          data: {
            ...data,
            '_titleKey': isDone ? 'notifFeatureComplete' : 'notifFeatureUpdated',
          },
        );
      case 'smart_action':
        final actionTitle = data['title']?.toString() ?? '';
        _addNotification(
          type: 'smart_action',
          title: 'notifSmartActionComplete',
          body: actionTitle,
          data: {...data, '_titleKey': 'notifSmartActionComplete'},
        );
      case 'sync':
        final count = data['count'] ?? 0;
        _addNotification(
          type: 'sync',
          title: 'notifSyncComplete',
          body: '$count',
          data: {...data, '_titleKey': 'notifSyncComplete', '_bodyCount': count},
        );
    }
  }

  /// Handle bridge streaming events (tool_start, tool_end, etc.).
  /// Only creates notifications for significant events (not every chunk).
  void _handleStreamingEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString() ?? '';

    // Only notify on agent completion events, not every tool call.
    if (type == 'agent_complete' || type == 'session_end') {
      _addNotification(
        type: 'agent_event',
        title: 'notifAgentFinished',
        body: event['text']?.toString() ?? '',
        data: {...event, '_titleKey': 'notifAgentFinished'},
      );
    }
  }

  /// Add a notification (called from MCP events or directly).
  void _addNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      data: data,
    );

    state = [notification, ...state].take(_maxNotifications).toList();
    _persistToStorage();
  }

  /// Add a smart action completion notification with optional note link.
  void addSmartActionComplete(String noteTitle, {String? noteId}) {
    _addNotification(
      type: 'smart_action',
      title: 'notifNoteGenerated',
      body: noteTitle,
      data: {
        'noteId': noteId,
        '_titleKey': 'notifNoteGenerated',
        '_bodyNoteTitle': noteTitle,
      },
    );
  }

  /// Add a sync broadcast notification (from WebSocket sync events).
  void addSyncEvent(String entityType, String entityId, String action) {
    // Only track deletes and significant actions in the notification store.
    if (action == 'delete') {
      _addNotification(
        type: 'sync',
        title: 'notifEntityDeleted',
        body: '$entityType $entityId',
        data: {
          'entity_type': entityType,
          'entity_id': entityId,
          'action': action,
          '_titleKey': 'notifEntityDeleted',
        },
      );
    }
  }

  /// Add a health alert notification.
  void addHealthAlert(String title, String body) {
    _addNotification(type: 'health_alert', title: title, body: body);
  }

  /// Mark a notification as read.
  void markRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    _persistToStorage();
  }

  /// Mark all as read.
  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _persistToStorage();
  }

  /// Clear all notifications.
  void clearAll() {
    state = [];
    _persistToStorage();
  }

  /// Unread count.
  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Persist to SharedPreferences.
  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('[NotificationStore] Persist error: $e');
    }
  }
}

final notificationStoreProvider =
    NotifierProvider<NotificationStoreNotifier, List<AppNotification>>(
  NotificationStoreNotifier.new,
);

/// Convenience provider for unread count (for badge display).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationStoreProvider);
  return notifications.where((n) => !n.isRead).length;
});
