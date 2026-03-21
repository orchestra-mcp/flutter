// Sealed union for all incoming WebSocket events

sealed class WsEvent {
  const WsEvent();
  factory WsEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'feature.updated' => FeatureUpdatedEvent.fromJson(json),
      'note.created' => NoteCreatedEvent.fromJson(json),
      'sync.ack' => SyncAckEvent.fromJson(json),
      'sync.entity_updated' => SyncEntityUpdatedEvent.fromJson(json),
      'sync.entity_shared' => SyncEntitySharedEvent.fromJson(json),
      'sync.entity_deleted' => SyncEntityDeletedEvent.fromJson(json),
      'health.updated' => HealthDataUpdatedEvent.fromJson(json),
      'ping' => const PingEvent(),
      'mcp' => McpEvent.fromJson(json),
      'sync' => SyncBroadcastEvent.fromJson(json),
      'presence' => PresenceEvent.fromJson(json),
      _ => UnknownWsEvent(type: type, data: json),
    };
  }
}

class FeatureUpdatedEvent extends WsEvent {
  const FeatureUpdatedEvent({required this.featureId, required this.payload});
  final String featureId;
  final Map<String, dynamic> payload;
  factory FeatureUpdatedEvent.fromJson(Map<String, dynamic> json) =>
      FeatureUpdatedEvent(
        featureId: json['feature_id'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );
}

class NoteCreatedEvent extends WsEvent {
  const NoteCreatedEvent({required this.noteId, required this.payload});
  final String noteId;
  final Map<String, dynamic> payload;
  factory NoteCreatedEvent.fromJson(Map<String, dynamic> json) =>
      NoteCreatedEvent(
        noteId: json['note_id'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );
}

class SyncAckEvent extends WsEvent {
  const SyncAckEvent({required this.queueId});
  final int queueId;
  factory SyncAckEvent.fromJson(Map<String, dynamic> json) =>
      SyncAckEvent(queueId: json['queue_id'] as int);
}

class PingEvent extends WsEvent {
  const PingEvent();
}

// ── Sync events ──────────────────────────────────────────────────────────────

/// A team member updated an entity that is shared with you.
class SyncEntityUpdatedEvent extends WsEvent {
  const SyncEntityUpdatedEvent({
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.authorId,
    required this.authorName,
    required this.teamId,
    required this.version,
  });

  final String entityType;
  final String entityId;
  final String entityTitle;
  final String authorId;
  final String authorName;
  final String teamId;
  final int version;

  factory SyncEntityUpdatedEvent.fromJson(Map<String, dynamic> json) =>
      SyncEntityUpdatedEvent(
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        entityTitle: json['entity_title'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        teamId: json['team_id'] as String? ?? '',
        version: json['version'] as int? ?? 0,
      );
}

/// A team member shared an entity with you or your team.
class SyncEntitySharedEvent extends WsEvent {
  const SyncEntitySharedEvent({
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.authorId,
    required this.authorName,
    required this.teamId,
    required this.permission,
  });

  final String entityType;
  final String entityId;
  final String entityTitle;
  final String authorId;
  final String authorName;
  final String teamId;
  final String permission;

  factory SyncEntitySharedEvent.fromJson(Map<String, dynamic> json) =>
      SyncEntitySharedEvent(
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        entityTitle: json['entity_title'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        teamId: json['team_id'] as String? ?? '',
        permission: json['permission'] as String? ?? 'read',
      );
}

/// A team member deleted a shared entity.
class SyncEntityDeletedEvent extends WsEvent {
  const SyncEntityDeletedEvent({
    required this.entityType,
    required this.entityId,
    required this.authorId,
    required this.authorName,
    required this.teamId,
  });

  final String entityType;
  final String entityId;
  final String authorId;
  final String authorName;
  final String teamId;

  factory SyncEntityDeletedEvent.fromJson(Map<String, dynamic> json) =>
      SyncEntityDeletedEvent(
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        teamId: json['team_id'] as String? ?? '',
      );
}

// ── Health sync events ───────────────────────────────────────────────────────

/// A health data dimension was updated on another device.
/// The backend broadcasts this after any health mutation (water, caffeine,
/// meal, pomodoro, shutdown, weight, sleep).
class HealthDataUpdatedEvent extends WsEvent {
  const HealthDataUpdatedEvent({required this.dimension, required this.userId});

  /// Which health dimension changed: hydration, caffeine, nutrition,
  /// pomodoro, shutdown, weight, sleep, or "all" for full refresh.
  final String dimension;

  /// The user whose health data was updated.
  final String userId;

  factory HealthDataUpdatedEvent.fromJson(Map<String, dynamic> json) =>
      HealthDataUpdatedEvent(
        dimension: json['dimension'] as String? ?? 'all',
        userId: json['user_id'] as String? ?? '',
      );
}

// ── MCP hook events ─────────────────────────────────────────────────────────

/// Base class for MCP hook events (type: "mcp").
/// The backend sends these when Claude Code tool calls, agent spawns,
/// or notifications occur via the hook bridge.
sealed class McpEvent extends WsEvent {
  const McpEvent({required this.sessionId, required this.timestamp});

  final String sessionId;
  final int timestamp;

  factory McpEvent.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String? ?? '';
    return switch (action) {
      'tool_called' => McpToolCalledEvent.fromJson(json),
      'agent_spawned' => McpAgentSpawnedEvent.fromJson(json),
      'notification' => McpNotificationEvent.fromJson(json),
      _ => McpGenericEvent.fromJson(json),
    };
  }
}

/// A Claude Code tool was called (e.g. Read, Write, Bash).
class McpToolCalledEvent extends McpEvent {
  const McpToolCalledEvent({
    required this.toolName,
    required this.entityType,
    required super.sessionId,
    required super.timestamp,
  });

  final String toolName;
  final String entityType;

  factory McpToolCalledEvent.fromJson(Map<String, dynamic> json) =>
      McpToolCalledEvent(
        toolName: json['tool_name'] as String? ?? '',
        entityType: json['entity_type'] as String? ?? 'tool',
        sessionId: json['session_id'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
      );
}

/// A sub-agent was spawned by Claude Code.
class McpAgentSpawnedEvent extends McpEvent {
  const McpAgentSpawnedEvent({
    required this.agentType,
    required super.sessionId,
    required super.timestamp,
  });

  final String agentType;

  factory McpAgentSpawnedEvent.fromJson(Map<String, dynamic> json) =>
      McpAgentSpawnedEvent(
        agentType: json['agent_type'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
      );
}

/// An MCP notification requiring user attention (delegation, permission, review).
class McpNotificationEvent extends McpEvent {
  const McpNotificationEvent({
    required this.entityType,
    required this.entityId,
    required super.sessionId,
    required super.timestamp,
  });

  final String entityType;
  final String entityId;

  factory McpNotificationEvent.fromJson(Map<String, dynamic> json) =>
      McpNotificationEvent(
        entityType: json['entity_type'] as String? ?? 'notification',
        entityId: json['entity_id'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
      );
}

/// Fallback for unrecognized MCP action types.
class McpGenericEvent extends McpEvent {
  const McpGenericEvent({
    required this.action,
    required this.data,
    required super.sessionId,
    required super.timestamp,
  });

  final String action;
  final Map<String, dynamic> data;

  factory McpGenericEvent.fromJson(Map<String, dynamic> json) =>
      McpGenericEvent(
        action: json['action'] as String? ?? '',
        data: json,
        sessionId: json['session_id'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? 0,
      );
}

// ── Sync broadcast events ──────────────────────────────────────────────────

/// A real-time sync broadcast from the web-gate (entity CRUD operations).
/// The Go backend broadcasts these when entities are created/updated/deleted.
class SyncBroadcastEvent extends WsEvent {
  const SyncBroadcastEvent({
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.userId,
    required this.timestamp,
  });

  final String entityType; // "note", "feature", "agent", "workflow", etc.
  final String entityId;
  final String action; // "upsert", "delete"
  final int userId;
  final int timestamp;

  factory SyncBroadcastEvent.fromJson(Map<String, dynamic> json) =>
      SyncBroadcastEvent(
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        action: json['action'] as String? ?? '',
        userId: json['user_id'] as int? ?? 0,
        timestamp: json['timestamp'] as int? ?? 0,
      );
}

/// Presence change event (user came online or went offline).
class PresenceEvent extends WsEvent {
  const PresenceEvent({
    required this.userId,
    required this.action,
    required this.timestamp,
  });

  final int userId;
  final String action; // "online", "offline"
  final int timestamp;

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
    userId: json['user_id'] as int? ?? 0,
    action: json['action'] as String? ?? '',
    timestamp: json['timestamp'] as int? ?? 0,
  );
}

class UnknownWsEvent extends WsEvent {
  const UnknownWsEvent({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
}
