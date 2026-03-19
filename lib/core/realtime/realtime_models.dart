// ─── Base Event ─────────────────────────────────────────────────────────────

/// Base model for all real-time events received over WebSocket.
///
/// Each event belongs to a [channel], has an [eventType] discriminator,
/// carries a generic [data] payload, and is stamped with [timestamp]
/// and the originating [userId].
class RealtimeEvent {
  const RealtimeEvent({
    required this.channel,
    required this.eventType,
    required this.data,
    required this.timestamp,
    this.userId,
  });

  /// The channel this event was published to.
  final String channel;

  /// Discriminator within the channel (e.g. 'file.created', 'status.changed').
  final String eventType;

  /// Arbitrary payload map.
  final Map<String, dynamic> data;

  /// Server-side timestamp of the event.
  final DateTime timestamp;

  /// The user who triggered the event, if applicable.
  final String? userId;

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => RealtimeEvent(
        channel: json['channel'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        userId: json['user_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'event_type': eventType,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        if (userId != null) 'user_id': userId,
      };

  @override
  String toString() => 'RealtimeEvent($channel/$eventType)';
}

// ─── Channel-specific events ────────────────────────────────────────────────

/// A file change event from the `file_changes` channel.
class FileChangeEvent {
  const FileChangeEvent({
    required this.filePath,
    required this.changeType,
    required this.timestamp,
    this.userId,
    this.diff,
  });

  /// Absolute path of the changed file.
  final String filePath;

  /// One of 'created', 'modified', 'deleted', 'renamed'.
  final String changeType;

  /// When the change occurred.
  final DateTime timestamp;

  /// The user who made the change.
  final String? userId;

  /// Optional unified diff snippet.
  final String? diff;

  factory FileChangeEvent.fromRealtimeEvent(RealtimeEvent event) =>
      FileChangeEvent(
        filePath: event.data['file_path'] as String? ?? '',
        changeType: event.data['change_type'] as String? ?? 'modified',
        timestamp: event.timestamp,
        userId: event.userId,
        diff: event.data['diff'] as String?,
      );

  @override
  String toString() => 'FileChangeEvent($changeType: $filePath)';
}

/// A feature workflow update from the `feature_updates` channel.
class FeatureUpdateEvent {
  const FeatureUpdateEvent({
    required this.featureId,
    required this.status,
    required this.previousStatus,
    required this.timestamp,
    this.userId,
    this.title,
  });

  /// The feature ID (e.g. 'FEAT-BVM').
  final String featureId;

  /// New status after the transition.
  final String status;

  /// Status before the transition.
  final String previousStatus;

  /// When the transition occurred.
  final DateTime timestamp;

  /// The user who triggered the transition.
  final String? userId;

  /// Optional feature title for display.
  final String? title;

  factory FeatureUpdateEvent.fromRealtimeEvent(RealtimeEvent event) =>
      FeatureUpdateEvent(
        featureId: event.data['feature_id'] as String? ?? '',
        status: event.data['status'] as String? ?? '',
        previousStatus: event.data['previous_status'] as String? ?? '',
        timestamp: event.timestamp,
        userId: event.userId,
        title: event.data['title'] as String?,
      );

  @override
  String toString() => 'FeatureUpdateEvent($featureId: $status)';
}

/// A tunnel connection status event from the `tunnel_status` channel.
class TunnelStatusEvent {
  const TunnelStatusEvent({
    required this.clientId,
    required this.status,
    required this.timestamp,
    this.platform,
    this.version,
  });

  /// The desktop client identifier.
  final String clientId;

  /// Connection status: 'connected', 'disconnected', 'reconnecting'.
  final String status;

  /// When the status changed.
  final DateTime timestamp;

  /// The desktop platform (e.g. 'macos', 'windows', 'linux').
  final String? platform;

  /// Orchestra version running on the desktop.
  final String? version;

  factory TunnelStatusEvent.fromRealtimeEvent(RealtimeEvent event) =>
      TunnelStatusEvent(
        clientId: event.data['client_id'] as String? ?? '',
        status: event.data['status'] as String? ?? 'disconnected',
        timestamp: event.timestamp,
        platform: event.data['platform'] as String?,
        version: event.data['version'] as String?,
      );

  @override
  String toString() => 'TunnelStatusEvent($clientId: $status)';
}

/// A team activity event from the `team_activity` channel.
class TeamActivityEvent {
  const TeamActivityEvent({
    required this.userId,
    required this.action,
    required this.target,
    required this.timestamp,
    this.userName,
    this.details,
  });

  /// The user who performed the action.
  final String userId;

  /// The action taken (e.g. 'started_feature', 'merged_pr', 'deployed').
  final String action;

  /// The target of the action (e.g. feature ID, PR number).
  final String target;

  /// When the action occurred.
  final DateTime timestamp;

  /// Display name of the user.
  final String? userName;

  /// Additional details about the action.
  final String? details;

  factory TeamActivityEvent.fromRealtimeEvent(RealtimeEvent event) =>
      TeamActivityEvent(
        userId: event.userId ?? '',
        action: event.data['action'] as String? ?? '',
        target: event.data['target'] as String? ?? '',
        timestamp: event.timestamp,
        userName: event.data['user_name'] as String?,
        details: event.data['details'] as String?,
      );

  @override
  String toString() => 'TeamActivityEvent($userId: $action on $target)';
}
