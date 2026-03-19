/// Team sharing data models for selective entity sharing and sync metadata.
///
/// These extend the core sync system with team/member awareness, per-entity
/// sync tracking, and version history. Every model supports round-trip JSON
/// serialization so they can travel over REST.
library;

/// Resolves a potentially relative avatar URL to a full URL.
/// [baseUrl] should be the API base URL (e.g. from Dio).
String? resolveAvatarUrl(String? url, String baseUrl) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  // Strip trailing slash from base to avoid double-slash.
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  return '$base$url';
}

// ---------------------------------------------------------------------------
// SyncEntityType
// ---------------------------------------------------------------------------

/// The kind of entity that can be synced and shared.
enum SyncEntityType {
  project,
  note,
  skill,
  agent,
  workflow,
  doc;

  factory SyncEntityType.fromString(String value) => switch (value) {
        'project' => SyncEntityType.project,
        'note' => SyncEntityType.note,
        'skill' => SyncEntityType.skill,
        'agent' => SyncEntityType.agent,
        'workflow' => SyncEntityType.workflow,
        'doc' => SyncEntityType.doc,
        _ => throw ArgumentError('Unknown SyncEntityType: $value'),
      };
}

// ---------------------------------------------------------------------------
// EntitySyncStatus
// ---------------------------------------------------------------------------

/// Per-entity sync status describing the relationship between local and remote.
enum EntitySyncStatus {
  /// Never shared with anyone.
  neverSynced,

  /// Up to date with the server.
  synced,

  /// Local changes not yet pushed.
  pending,

  /// Server has a newer version.
  outdated,

  /// Both sides changed since last sync.
  conflict;

  factory EntitySyncStatus.fromString(String value) => switch (value) {
        'never_synced' => EntitySyncStatus.neverSynced,
        'synced' => EntitySyncStatus.synced,
        'pending' => EntitySyncStatus.pending,
        'outdated' => EntitySyncStatus.outdated,
        'conflict' => EntitySyncStatus.conflict,
        _ => throw ArgumentError('Unknown EntitySyncStatus: $value'),
      };

  String toJson() => switch (this) {
        EntitySyncStatus.neverSynced => 'never_synced',
        EntitySyncStatus.synced => 'synced',
        EntitySyncStatus.pending => 'pending',
        EntitySyncStatus.outdated => 'outdated',
        EntitySyncStatus.conflict => 'conflict',
      };
}

// ---------------------------------------------------------------------------
// SharePermission
// ---------------------------------------------------------------------------

/// Permission level granted when sharing an entity.
enum SharePermission {
  read,
  write,
  admin;

  factory SharePermission.fromString(String value) => switch (value) {
        'read' => SharePermission.read,
        'write' => SharePermission.write,
        'admin' => SharePermission.admin,
        _ => throw ArgumentError('Unknown SharePermission: $value'),
      };
}

// ---------------------------------------------------------------------------
// TeamMember
// ---------------------------------------------------------------------------

/// A member within a team, with role and online status.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.role = 'member',
    this.isOnline = false,
  });

  /// Unique member identifier.
  final String id;

  /// Display name.
  final String name;

  /// Optional email address.
  final String? email;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Role within the team: `admin`, `member`, or `viewer`.
  final String role;

  /// Whether this member is currently online.
  final bool isOnline;

  // -- JSON ------------------------------------------------------------------

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
        id: json['id']?.toString() ?? '',
        name: (json['name'] as String?) ?? '',
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'member',
        isOnline: json['is_online'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'role': role,
        'is_online': isOnline,
      };

  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    bool? isOnline,
  }) =>
      TeamMember(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        role: role ?? this.role,
        isOnline: isOnline ?? this.isOnline,
      );

  @override
  String toString() => 'TeamMember($id, $name, $role)';
}

// ---------------------------------------------------------------------------
// Team
// ---------------------------------------------------------------------------

/// A team that can receive shared entities.
class Team {
  const Team({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.members = const [],
    required this.createdAt,
  });

  /// Unique team identifier.
  final String id;

  /// Team display name.
  final String name;

  /// Optional team description.
  final String? description;

  /// Optional team avatar image URL.
  final String? avatarUrl;

  /// Current team members.
  final List<TeamMember> members;

  /// When the team was created.
  final DateTime createdAt;

  // -- JSON ------------------------------------------------------------------

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id']?.toString() ?? '',
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        members: (json['members'] as List? ?? [])
            .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'members': members.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? avatarUrl,
    List<TeamMember>? members,
    DateTime? createdAt,
  }) =>
      Team(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        members: members ?? this.members,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  String toString() => 'Team($id, $name, ${members.length} members)';
}

// ---------------------------------------------------------------------------
// TeamShare
// ---------------------------------------------------------------------------

/// Represents a share of an entity with a team or selected members.
///
/// When [shareWithAll] is `true`, the entire team has access. Otherwise only
/// the members whose IDs appear in [memberIds] can see the entity.
class TeamShare {
  const TeamShare({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.teamId,
    this.shareWithAll = true,
    this.memberIds = const [],
    this.permission = SharePermission.read,
    required this.sharedBy,
    required this.sharedAt,
    this.lastSyncedAt,
    this.version = 1,
    this.contentHash,
  });

  /// Share identifier (UUID v4).
  final String id;

  /// Entity kind: `project`, `note`, etc.
  final String entityType;

  /// The specific record ID being shared.
  final String entityId;

  /// The team this entity is shared with.
  final String teamId;

  /// When `true`, all current and future team members have access. When
  /// `false`, only members listed in [memberIds] have access.
  final bool shareWithAll;

  /// Selected member IDs when [shareWithAll] is `false`.
  final List<String> memberIds;

  /// Permission level granted to recipients.
  final SharePermission permission;

  /// User ID who initiated the share.
  final String sharedBy;

  /// When the share was created.
  final DateTime sharedAt;

  /// When the shared content was last synced with the server (null if never).
  final DateTime? lastSyncedAt;

  /// Entity version at the time of the last sync.
  final int version;

  /// SHA-256 content hash at time of share for integrity checking.
  final String? contentHash;

  // -- JSON ------------------------------------------------------------------

  factory TeamShare.fromJson(Map<String, dynamic> json) => TeamShare(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        teamId: json['team_id'] as String,
        shareWithAll: json['share_with_all'] as bool? ?? true,
        memberIds: (json['member_ids'] as List? ?? []).cast<String>(),
        permission:
            SharePermission.fromString(json['permission'] as String? ?? 'read'),
        sharedBy: json['shared_by'] as String,
        sharedAt: DateTime.parse(json['shared_at'] as String),
        lastSyncedAt: json['last_synced_at'] != null
            ? DateTime.parse(json['last_synced_at'] as String)
            : null,
        version: json['version'] as int? ?? 1,
        contentHash: json['content_hash'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'team_id': teamId,
        'share_with_all': shareWithAll,
        'member_ids': memberIds,
        'permission': permission.name,
        'shared_by': sharedBy,
        'shared_at': sharedAt.toUtc().toIso8601String(),
        if (lastSyncedAt != null)
          'last_synced_at': lastSyncedAt!.toUtc().toIso8601String(),
        'version': version,
        if (contentHash != null) 'content_hash': contentHash,
      };

  TeamShare copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? teamId,
    bool? shareWithAll,
    List<String>? memberIds,
    SharePermission? permission,
    String? sharedBy,
    DateTime? sharedAt,
    DateTime? lastSyncedAt,
    int? version,
    String? contentHash,
  }) =>
      TeamShare(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        teamId: teamId ?? this.teamId,
        shareWithAll: shareWithAll ?? this.shareWithAll,
        memberIds: memberIds ?? this.memberIds,
        permission: permission ?? this.permission,
        sharedBy: sharedBy ?? this.sharedBy,
        sharedAt: sharedAt ?? this.sharedAt,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        version: version ?? this.version,
        contentHash: contentHash ?? this.contentHash,
      );

  @override
  String toString() =>
      'TeamShare($entityType/$entityId -> team:$teamId v$version)';
}

// ---------------------------------------------------------------------------
// EntitySyncMetadata
// ---------------------------------------------------------------------------

/// Tracks sync metadata per entity, stored locally in SQLite.
///
/// This is the local bookkeeping record that tells the sync engine whether
/// an entity is up-to-date, pending push, or in conflict.
class EntitySyncMetadata {
  const EntitySyncMetadata({
    required this.entityType,
    required this.entityId,
    this.status = EntitySyncStatus.neverSynced,
    this.lastSyncedAt,
    this.localVersion = 0,
    this.remoteVersion,
    this.contentHash,
    this.lastSyncedBy,
    this.sharedWithTeamIds = const [],
  });

  /// Entity kind: `project`, `note`, etc.
  final String entityType;

  /// The specific record ID.
  final String entityId;

  /// Current sync status.
  final EntitySyncStatus status;

  /// When this entity was last successfully synced (null if never).
  final DateTime? lastSyncedAt;

  /// Local Lamport version counter.
  final int localVersion;

  /// Last known server version (null if never synced).
  final int? remoteVersion;

  /// SHA-256 hash of the local content for quick diff checks.
  final String? contentHash;

  /// User ID who last synced this entity.
  final String? lastSyncedBy;

  /// Team IDs this entity is currently shared with.
  final List<String> sharedWithTeamIds;

  // -- JSON ------------------------------------------------------------------

  factory EntitySyncMetadata.fromJson(Map<String, dynamic> json) =>
      EntitySyncMetadata(
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        status: EntitySyncStatus.fromString(
            json['status'] as String? ?? 'never_synced'),
        lastSyncedAt: json['last_synced_at'] != null
            ? DateTime.parse(json['last_synced_at'] as String)
            : null,
        localVersion: json['local_version'] as int? ?? 0,
        remoteVersion: json['remote_version'] as int?,
        contentHash: json['content_hash'] as String?,
        lastSyncedBy: json['last_synced_by'] as String?,
        sharedWithTeamIds:
            (json['shared_with_team_ids'] as List? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'status': status.toJson(),
        if (lastSyncedAt != null)
          'last_synced_at': lastSyncedAt!.toUtc().toIso8601String(),
        'local_version': localVersion,
        if (remoteVersion != null) 'remote_version': remoteVersion,
        if (contentHash != null) 'content_hash': contentHash,
        if (lastSyncedBy != null) 'last_synced_by': lastSyncedBy,
        'shared_with_team_ids': sharedWithTeamIds,
      };

  EntitySyncMetadata copyWith({
    String? entityType,
    String? entityId,
    EntitySyncStatus? status,
    DateTime? lastSyncedAt,
    int? localVersion,
    int? remoteVersion,
    String? contentHash,
    String? lastSyncedBy,
    List<String>? sharedWithTeamIds,
  }) =>
      EntitySyncMetadata(
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        localVersion: localVersion ?? this.localVersion,
        remoteVersion: remoteVersion ?? this.remoteVersion,
        contentHash: contentHash ?? this.contentHash,
        lastSyncedBy: lastSyncedBy ?? this.lastSyncedBy,
        sharedWithTeamIds: sharedWithTeamIds ?? this.sharedWithTeamIds,
      );

  @override
  String toString() =>
      'EntitySyncMetadata($entityType/$entityId ${status.name} v$localVersion)';
}

// ---------------------------------------------------------------------------
// SyncVersionEntry
// ---------------------------------------------------------------------------

/// A single version history entry for an entity, recording who changed what
/// and when. Stored locally to support version browsing and rollback UI.
class SyncVersionEntry {
  const SyncVersionEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.version,
    required this.authorId,
    required this.authorName,
    this.changeSummary,
    required this.timestamp,
    this.contentHash,
  });

  /// Unique version entry identifier (UUID v4).
  final String id;

  /// Entity kind: `project`, `note`, etc.
  final String entityType;

  /// The specific record ID.
  final String entityId;

  /// Monotonically increasing version number for this entity.
  final int version;

  /// User ID of the author who made this change.
  final String authorId;

  /// Display name of the author (denormalized for quick rendering).
  final String authorName;

  /// Human-readable summary of what changed (optional).
  final String? changeSummary;

  /// When this version was created.
  final DateTime timestamp;

  /// SHA-256 content hash at this version.
  final String? contentHash;

  // -- JSON ------------------------------------------------------------------

  factory SyncVersionEntry.fromJson(Map<String, dynamic> json) =>
      SyncVersionEntry(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        version: json['version'] as int,
        authorId: json['author_id'] as String,
        authorName: json['author_name'] as String,
        changeSummary: json['change_summary'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        contentHash: json['content_hash'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'version': version,
        'author_id': authorId,
        'author_name': authorName,
        if (changeSummary != null) 'change_summary': changeSummary,
        'timestamp': timestamp.toUtc().toIso8601String(),
        if (contentHash != null) 'content_hash': contentHash,
      };

  SyncVersionEntry copyWith({
    String? id,
    String? entityType,
    String? entityId,
    int? version,
    String? authorId,
    String? authorName,
    String? changeSummary,
    DateTime? timestamp,
    String? contentHash,
  }) =>
      SyncVersionEntry(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        version: version ?? this.version,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        changeSummary: changeSummary ?? this.changeSummary,
        timestamp: timestamp ?? this.timestamp,
        contentHash: contentHash ?? this.contentHash,
      );

  @override
  String toString() =>
      'SyncVersionEntry($entityType/$entityId v$version by $authorName)';
}

// ---------------------------------------------------------------------------
// ShareRequest
// ---------------------------------------------------------------------------

/// Request body for `POST /api/sync/share`.
///
/// Contains the full entity payload so the server can store a snapshot
/// for recipients who haven't synced yet.
class ShareRequest {
  const ShareRequest({
    required this.entityType,
    required this.entityId,
    required this.teamId,
    this.shareWithAll = true,
    this.memberIds = const [],
    this.permission = SharePermission.read,
    required this.entityData,
    required this.contentHash,
  });

  /// Entity kind: `project`, `note`, etc.
  final String entityType;

  /// The specific record ID being shared.
  final String entityId;

  /// Target team identifier.
  final String teamId;

  /// Share with the whole team or selected members.
  final bool shareWithAll;

  /// Selected member IDs when [shareWithAll] is `false`.
  final List<String> memberIds;

  /// Permission level to grant.
  final SharePermission permission;

  /// Full serialized entity payload for the server to store.
  final Map<String, dynamic> entityData;

  /// SHA-256 hash of [entityData] for integrity verification.
  final String contentHash;

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'team_id': teamId,
        'share_with_all': shareWithAll,
        'member_ids': memberIds,
        'permission': permission.name,
        'entity_data': entityData,
        'content_hash': contentHash,
      };

  factory ShareRequest.fromJson(Map<String, dynamic> json) => ShareRequest(
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        teamId: json['team_id'] as String,
        shareWithAll: json['share_with_all'] as bool? ?? true,
        memberIds: (json['member_ids'] as List? ?? []).cast<String>(),
        permission:
            SharePermission.fromString(json['permission'] as String? ?? 'read'),
        entityData: json['entity_data'] as Map<String, dynamic>,
        contentHash: json['content_hash'] as String,
      );
}

// ---------------------------------------------------------------------------
// ShareResponse
// ---------------------------------------------------------------------------

/// Response from `POST /api/sync/share`.
class ShareResponse {
  const ShareResponse({
    required this.shareId,
    required this.success,
    required this.version,
    required this.serverTimestamp,
    this.errorMessage,
  });

  /// The server-assigned share identifier.
  final String shareId;

  /// Whether the share was accepted by the server.
  final bool success;

  /// Server-side version assigned to this share.
  final int version;

  /// Server wall-clock time when the share was processed.
  final DateTime serverTimestamp;

  /// Error description if [success] is `false`.
  final String? errorMessage;

  factory ShareResponse.fromJson(Map<String, dynamic> json) => ShareResponse(
        shareId: json['share_id'] as String,
        success: json['success'] as bool,
        version: json['version'] as int,
        serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
        errorMessage: json['error_message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'share_id': shareId,
        'success': success,
        'version': version,
        'server_timestamp': serverTimestamp.toUtc().toIso8601String(),
        if (errorMessage != null) 'error_message': errorMessage,
      };
}

// ---------------------------------------------------------------------------
// TeamUpdateStatus / TeamUpdateEntry
// ---------------------------------------------------------------------------

/// Status check response used to populate the "updates available" banner.
class TeamUpdateStatus {
  const TeamUpdateStatus({
    required this.availableUpdates,
    this.updates = const [],
    required this.checkedAt,
  });

  /// Total number of entity updates available from teams.
  final int availableUpdates;

  /// Individual update entries describing what changed.
  final List<TeamUpdateEntry> updates;

  /// When this status was last checked.
  final DateTime checkedAt;

  factory TeamUpdateStatus.fromJson(Map<String, dynamic> json) =>
      TeamUpdateStatus(
        availableUpdates: json['available_updates'] as int? ?? 0,
        updates: (json['updates'] as List? ?? [])
            .map((e) => TeamUpdateEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        checkedAt: json['checked_at'] != null
            ? DateTime.parse(json['checked_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'available_updates': availableUpdates,
        'updates': updates.map((u) => u.toJson()).toList(),
        'checked_at': checkedAt.toUtc().toIso8601String(),
      };

  TeamUpdateStatus copyWith({
    int? availableUpdates,
    List<TeamUpdateEntry>? updates,
    DateTime? checkedAt,
  }) =>
      TeamUpdateStatus(
        availableUpdates: availableUpdates ?? this.availableUpdates,
        updates: updates ?? this.updates,
        checkedAt: checkedAt ?? this.checkedAt,
      );

  @override
  String toString() => 'TeamUpdateStatus($availableUpdates updates)';
}

/// A single pending update from a team member.
class TeamUpdateEntry {
  const TeamUpdateEntry({
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.teamId,
    required this.teamName,
    required this.authorName,
    required this.fromVersion,
    required this.toVersion,
    required this.updatedAt,
  });

  /// Entity kind that was updated.
  final String entityType;

  /// The specific record ID.
  final String entityId;

  /// Human-readable title of the entity.
  final String entityTitle;

  /// Team the update came from.
  final String teamId;

  /// Team display name.
  final String teamName;

  /// Display name of the author who made the update.
  final String authorName;

  /// The local version before the update.
  final int fromVersion;

  /// The server version after the update.
  final int toVersion;

  /// When the update was created on the server.
  final DateTime updatedAt;

  factory TeamUpdateEntry.fromJson(Map<String, dynamic> json) =>
      TeamUpdateEntry(
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as String? ?? '',
        entityTitle: json['entity_title'] as String? ?? '',
        teamId: json['team_id'] as String? ?? '',
        teamName: json['team_name'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        fromVersion: json['from_version'] as int? ?? 0,
        toVersion: json['to_version'] as int? ?? 0,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'entity_type': entityType,
        'entity_id': entityId,
        'entity_title': entityTitle,
        'team_id': teamId,
        'team_name': teamName,
        'author_name': authorName,
        'from_version': fromVersion,
        'to_version': toVersion,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  @override
  String toString() =>
      'TeamUpdateEntry($entityType/$entityId v$fromVersion->v$toVersion by $authorName)';
}
