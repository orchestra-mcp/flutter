/// Sync protocol data models for push/pull/delta operations.
///
/// These mirror the server-side PostgreSQL sync API contract. Every model
/// supports round-trip JSON serialization so they can travel over REST.

/// The kind of mutation that produced a delta.
enum SyncOperation {
  create,
  update,
  delete;

  factory SyncOperation.fromString(String value) => switch (value) {
    'create' => SyncOperation.create,
    'update' => SyncOperation.update,
    'delete' => SyncOperation.delete,
    _ => throw ArgumentError('Unknown SyncOperation: $value'),
  };
}

// ---------------------------------------------------------------------------
// SyncDelta
// ---------------------------------------------------------------------------

/// A single change record produced by either the client or server.
///
/// Each delta is tagged with a [version] (Lamport timestamp) and a wall-clock
/// [timestamp] so the conflict resolver can compare causality.
class SyncDelta {
  const SyncDelta({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.timestamp,
    required this.version,
    this.data,
    this.clientId,
    this.versionVector,
  });

  /// Unique delta identifier (UUID v4 on the client, server-assigned on pull).
  final String id;

  /// Entity kind: `feature`, `project`, `note`, `health_log`, etc.
  final String entityType;

  /// The specific record id within [entityType].
  final String entityId;

  /// What happened to the entity.
  final SyncOperation operation;

  /// The serialized entity payload (null for deletes).
  final Map<String, dynamic>? data;

  /// ISO-8601 wall-clock time when this change was created.
  final DateTime timestamp;

  /// Monotonically increasing Lamport counter for ordering.
  final int version;

  /// The originating client identifier (set on push, echoed on pull).
  final String? clientId;

  /// Optional serialized version vector for conflict detection.
  final Map<String, dynamic>? versionVector;

  // -- JSON ------------------------------------------------------------------

  factory SyncDelta.fromJson(Map<String, dynamic> json) => SyncDelta(
    id: json['id'] as String? ?? '',
    entityType: json['entity_type'] as String? ?? '',
    entityId: json['entity_id'] as String? ?? '',
    operation: SyncOperation.fromString(
      json['operation'] as String? ?? 'update',
    ),
    data: json['data'] as Map<String, dynamic>?,
    timestamp: json['timestamp'] != null
        ? DateTime.parse(json['timestamp'] as String)
        : DateTime.now(),
    version: json['version'] as int? ?? 0,
    clientId: json['client_id'] as String?,
    versionVector: json['version_vector'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'operation': operation.name,
    'data': data,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'version': version,
    if (clientId != null) 'client_id': clientId,
    if (versionVector != null) 'version_vector': versionVector,
  };

  SyncDelta copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? version,
    String? clientId,
    Map<String, dynamic>? versionVector,
  }) => SyncDelta(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    data: data ?? this.data,
    timestamp: timestamp ?? this.timestamp,
    version: version ?? this.version,
    clientId: clientId ?? this.clientId,
    versionVector: versionVector ?? this.versionVector,
  );

  @override
  String toString() =>
      'SyncDelta($entityType/$entityId ${operation.name} v$version)';
}

// ---------------------------------------------------------------------------
// Push
// ---------------------------------------------------------------------------

/// Request body for `POST /api/sync/push`.
class SyncPushRequest {
  const SyncPushRequest({
    required this.deltas,
    required this.clientId,
    required this.lastSyncTimestamp,
  });

  final List<SyncDelta> deltas;
  final String clientId;
  final DateTime lastSyncTimestamp;

  Map<String, dynamic> toJson() => {
    'deltas': deltas.map((d) => d.toJson()).toList(),
    'client_id': clientId,
    'last_sync_timestamp': lastSyncTimestamp.toUtc().toIso8601String(),
  };

  factory SyncPushRequest.fromJson(Map<String, dynamic> json) =>
      SyncPushRequest(
        deltas: (json['deltas'] as List? ?? [])
            .map((e) => SyncDelta.fromJson(e as Map<String, dynamic>))
            .toList(),
        clientId: json['client_id'] as String? ?? '',
        lastSyncTimestamp: json['last_sync_timestamp'] != null
            ? DateTime.parse(json['last_sync_timestamp'] as String)
            : DateTime.now(),
      );
}

/// Response from `POST /api/sync/push`.
class SyncPushResponse {
  const SyncPushResponse({
    required this.accepted,
    required this.conflicts,
    required this.serverTimestamp,
  });

  /// Delta IDs that the server accepted without conflict.
  final List<String> accepted;

  /// Deltas that conflicted with server state. Each entry contains the
  /// server-side version so the client can resolve.
  final List<SyncConflict> conflicts;

  /// The server's current wall-clock time (used as `since` for next pull).
  final DateTime serverTimestamp;

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) =>
      SyncPushResponse(
        accepted: (json['accepted'] as List? ?? []).cast<String>(),
        conflicts: (json['conflicts'] as List? ?? [])
            .map((e) => SyncConflict.fromJson(e as Map<String, dynamic>))
            .toList(),
        serverTimestamp: json['server_timestamp'] != null
            ? DateTime.parse(json['server_timestamp'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'accepted': accepted,
    'conflicts': conflicts.map((c) => c.toJson()).toList(),
    'server_timestamp': serverTimestamp.toUtc().toIso8601String(),
  };
}

/// A conflict returned inside [SyncPushResponse].
class SyncConflict {
  const SyncConflict({required this.clientDelta, required this.serverDelta});

  final SyncDelta clientDelta;
  final SyncDelta serverDelta;

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    clientDelta: SyncDelta.fromJson(
      json['client_delta'] as Map<String, dynamic>,
    ),
    serverDelta: SyncDelta.fromJson(
      json['server_delta'] as Map<String, dynamic>,
    ),
  );

  Map<String, dynamic> toJson() => {
    'client_delta': clientDelta.toJson(),
    'server_delta': serverDelta.toJson(),
  };
}

// ---------------------------------------------------------------------------
// Pull
// ---------------------------------------------------------------------------

/// Request query for `GET /api/sync/pull`.
class SyncPullRequest {
  const SyncPullRequest({
    required this.since,
    this.entityTypes,
    this.limit,
    this.deviceId,
  });

  /// Only return deltas after this timestamp (ISO-8601).
  final DateTime since;

  /// Optional filter: only pull these entity types.
  final List<String>? entityTypes;

  /// Maximum number of deltas to return (server-side page size).
  final int? limit;

  /// Device identifier sent as `device_id` query param so the backend can
  /// scope sync logs to this client.
  final String? deviceId;

  Map<String, dynamic> toQueryParams() => {
    'since': since.toUtc().toIso8601String(),
    if (entityTypes != null && entityTypes!.isNotEmpty)
      'entity_types': entityTypes!.join(','),
    if (limit != null) 'limit': limit.toString(),
    if (deviceId != null && deviceId!.isNotEmpty) 'device_id': deviceId,
  };

  factory SyncPullRequest.fromJson(Map<String, dynamic> json) =>
      SyncPullRequest(
        since: DateTime.parse(json['since'] as String),
        entityTypes: (json['entity_types'] as String?)?.split(','),
        limit: json['limit'] != null
            ? int.tryParse(json['limit'].toString())
            : null,
        deviceId: json['device_id'] as String?,
      );
}

/// Response from `GET /api/sync/pull`.
class SyncPullResponse {
  const SyncPullResponse({
    required this.deltas,
    required this.hasMore,
    required this.serverTimestamp,
  });

  final List<SyncDelta> deltas;

  /// `true` when the server has more deltas beyond [limit].
  final bool hasMore;

  /// Server wall-clock used as `since` for next incremental pull.
  final DateTime serverTimestamp;

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) =>
      SyncPullResponse(
        deltas: (json['deltas'] as List? ?? [])
            .map((e) => SyncDelta.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: json['has_more'] as bool? ?? false,
        serverTimestamp: json['server_timestamp'] != null
            ? DateTime.parse(json['server_timestamp'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'deltas': deltas.map((d) => d.toJson()).toList(),
    'has_more': hasMore,
    'server_timestamp': serverTimestamp.toUtc().toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/// High-level sync status returned from `GET /api/sync/status`.
class SyncStatusInfo {
  const SyncStatusInfo({
    required this.lastSync,
    required this.pendingCount,
    required this.connected,
  });

  /// When the last successful sync completed (null if never synced).
  final DateTime? lastSync;

  /// Number of un-pushed local deltas.
  final int pendingCount;

  /// Whether the client currently has connectivity to the sync server.
  final bool connected;

  factory SyncStatusInfo.fromJson(Map<String, dynamic> json) => SyncStatusInfo(
    lastSync: json['last_sync'] != null
        ? DateTime.parse(json['last_sync'] as String)
        : null,
    pendingCount: json['pending_count'] as int? ?? 0,
    connected: json['connected'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'last_sync': lastSync?.toUtc().toIso8601String(),
    'pending_count': pendingCount,
    'connected': connected,
  };

  SyncStatusInfo copyWith({
    DateTime? lastSync,
    int? pendingCount,
    bool? connected,
  }) => SyncStatusInfo(
    lastSync: lastSync ?? this.lastSync,
    pendingCount: pendingCount ?? this.pendingCount,
    connected: connected ?? this.connected,
  );
}
