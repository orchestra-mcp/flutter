/// Data models for sync conflict detection and resolution.
library;

// ── Resolution strategy ─────────────────────────────────────────────────────

/// How a conflict should be resolved.
enum ConflictResolution {
  /// Discard remote, keep local version.
  keepLocal,

  /// Discard local, accept remote version.
  keepRemote,

  /// Merge field by field (manual or auto).
  merge;

  factory ConflictResolution.fromString(String value) => switch (value) {
    'keep_local' => ConflictResolution.keepLocal,
    'keep_remote' => ConflictResolution.keepRemote,
    'merge' => ConflictResolution.merge,
    _ => throw ArgumentError('Unknown ConflictResolution: $value'),
  };

  String toJson() => switch (this) {
    ConflictResolution.keepLocal => 'keep_local',
    ConflictResolution.keepRemote => 'keep_remote',
    ConflictResolution.merge => 'merge',
  };
}

// ── Field diff ──────────────────────────────────────────────────────────────

/// A single field-level difference between local and remote versions.
class FieldDiff {
  const FieldDiff({
    required this.field,
    required this.localValue,
    required this.remoteValue,
    this.isTextContent = false,
  });

  /// The key name (e.g., 'title', 'content', 'name').
  final String field;

  /// Local value (may be null if field was deleted locally).
  final dynamic localValue;

  /// Remote value (may be null if field was deleted remotely).
  final dynamic remoteValue;

  /// Whether this field contains long-form text suitable for merge.
  final bool isTextContent;

  /// True when local and remote values differ.
  bool get hasConflict => localValue?.toString() != remoteValue?.toString();

  factory FieldDiff.fromJson(Map<String, dynamic> json) => FieldDiff(
    field: json['field'] as String,
    localValue: json['local_value'],
    remoteValue: json['remote_value'],
    isTextContent: json['is_text_content'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'field': field,
    'local_value': localValue,
    'remote_value': remoteValue,
    'is_text_content': isTextContent,
  };

  @override
  String toString() => 'FieldDiff($field: $localValue ↔ $remoteValue)';
}

// ── Sync conflict ───────────────────────────────────────────────────────────

/// Represents a detected conflict between local and remote versions of an entity.
class SyncConflict {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.localVersion,
    required this.remoteVersion,
    required this.localData,
    required this.remoteData,
    required this.diffs,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution,
    this.resolvedData,
  });

  /// Entity kind: `project`, `note`, etc.
  final String entityType;

  /// The specific record ID.
  final String entityId;

  /// Human-readable title for display.
  final String entityTitle;

  /// Local version number.
  final int localVersion;

  /// Remote version number.
  final int remoteVersion;

  /// Full local entity data snapshot.
  final Map<String, dynamic> localData;

  /// Full remote entity data snapshot.
  final Map<String, dynamic> remoteData;

  /// Field-level differences between local and remote.
  final List<FieldDiff> diffs;

  /// When the conflict was detected.
  final DateTime detectedAt;

  /// When the conflict was resolved (null if still open).
  final DateTime? resolvedAt;

  /// How the conflict was resolved (null if still open).
  final ConflictResolution? resolution;

  /// The merged/resolved entity data (null if still open).
  final Map<String, dynamic>? resolvedData;

  /// Whether this conflict is still unresolved.
  bool get isOpen => resolvedAt == null;

  /// Number of fields that actually differ.
  int get conflictingFieldCount => diffs.where((d) => d.hasConflict).length;

  /// Whether any text fields have conflicts (needs manual merge).
  bool get hasTextConflicts =>
      diffs.any((d) => d.hasConflict && d.isTextContent);

  // ── JSON ──────────────────────────────────────────────────────────────

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
    entityType: json['entity_type'] as String,
    entityId: json['entity_id'] as String,
    entityTitle: json['entity_title'] as String? ?? '',
    localVersion: json['local_version'] as int,
    remoteVersion: json['remote_version'] as int,
    localData: Map<String, dynamic>.from(
      json['local_data'] as Map<String, dynamic>,
    ),
    remoteData: Map<String, dynamic>.from(
      json['remote_data'] as Map<String, dynamic>,
    ),
    diffs: (json['diffs'] as List? ?? [])
        .map((e) => FieldDiff.fromJson(e as Map<String, dynamic>))
        .toList(),
    detectedAt: DateTime.parse(json['detected_at'] as String),
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'] as String)
        : null,
    resolution: json['resolution'] != null
        ? ConflictResolution.fromString(json['resolution'] as String)
        : null,
    resolvedData: json['resolved_data'] != null
        ? Map<String, dynamic>.from(
            json['resolved_data'] as Map<String, dynamic>,
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'entity_type': entityType,
    'entity_id': entityId,
    'entity_title': entityTitle,
    'local_version': localVersion,
    'remote_version': remoteVersion,
    'local_data': localData,
    'remote_data': remoteData,
    'diffs': diffs.map((d) => d.toJson()).toList(),
    'detected_at': detectedAt.toUtc().toIso8601String(),
    if (resolvedAt != null)
      'resolved_at': resolvedAt!.toUtc().toIso8601String(),
    if (resolution != null) 'resolution': resolution!.toJson(),
    if (resolvedData != null) 'resolved_data': resolvedData,
  };

  SyncConflict copyWith({
    DateTime? resolvedAt,
    ConflictResolution? resolution,
    Map<String, dynamic>? resolvedData,
  }) => SyncConflict(
    entityType: entityType,
    entityId: entityId,
    entityTitle: entityTitle,
    localVersion: localVersion,
    remoteVersion: remoteVersion,
    localData: localData,
    remoteData: remoteData,
    diffs: diffs,
    detectedAt: detectedAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    resolution: resolution ?? this.resolution,
    resolvedData: resolvedData ?? this.resolvedData,
  );

  @override
  String toString() =>
      'SyncConflict($entityType/$entityId v$localVersion↔v$remoteVersion '
      '${isOpen ? "OPEN" : "resolved:${resolution?.name}"})';
}
