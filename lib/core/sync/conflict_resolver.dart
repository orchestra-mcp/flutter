import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/version_vector.dart';

// ---------------------------------------------------------------------------
// Strategy enum
// ---------------------------------------------------------------------------

/// Available strategies for automatic conflict resolution.
enum ConflictStrategy {
  /// The delta with the later wall-clock timestamp wins.
  lastWriteWins,

  /// The server-side delta always wins.
  serverWins,

  /// The client-side delta always wins.
  clientWins,

  /// No automatic resolution — the conflict is queued for manual review.
  manual,
}

// ---------------------------------------------------------------------------
// Resolution result
// ---------------------------------------------------------------------------

/// Which side won the conflict (or manual if unresolved).
enum ResolutionKind { useLocal, useRemote, merged, manual }

/// The outcome of a conflict resolution attempt.
class ResolvedDelta {
  const ResolvedDelta({
    required this.resolution,
    required this.winningDelta,
    this.mergedData,
  });

  /// Which resolution path was taken.
  final ResolutionKind resolution;

  /// The delta that should be applied. For [merged], this carries
  /// [mergedData] as its payload.
  final SyncDelta winningDelta;

  /// When [resolution] is [ResolutionKind.merged], this contains the
  /// hand-merged payload. Otherwise null.
  final Map<String, dynamic>? mergedData;
}

// ---------------------------------------------------------------------------
// Conflict record (for manual queue)
// ---------------------------------------------------------------------------

/// Persisted record of an unresolved conflict awaiting user action.
class ConflictRecord {
  const ConflictRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localDelta,
    required this.remoteDelta,
    required this.detectedAt,
    this.resolvedAt,
    this.resolution,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncDelta localDelta;
  final SyncDelta remoteDelta;
  final DateTime detectedAt;
  final DateTime? resolvedAt;
  final ResolutionKind? resolution;

  ConflictRecord copyWith({
    DateTime? resolvedAt,
    ResolutionKind? resolution,
  }) =>
      ConflictRecord(
        id: id,
        entityType: entityType,
        entityId: entityId,
        localDelta: localDelta,
        remoteDelta: remoteDelta,
        detectedAt: detectedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolution: resolution ?? this.resolution,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'local_delta': localDelta.toJson(),
        'remote_delta': remoteDelta.toJson(),
        'detected_at': detectedAt.toUtc().toIso8601String(),
        if (resolvedAt != null)
          'resolved_at': resolvedAt!.toUtc().toIso8601String(),
        if (resolution != null) 'resolution': resolution!.name,
      };

  factory ConflictRecord.fromJson(Map<String, dynamic> json) => ConflictRecord(
        id: json['id'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        localDelta:
            SyncDelta.fromJson(json['local_delta'] as Map<String, dynamic>),
        remoteDelta:
            SyncDelta.fromJson(json['remote_delta'] as Map<String, dynamic>),
        detectedAt: DateTime.parse(json['detected_at'] as String),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
        resolution: json['resolution'] != null
            ? ResolutionKind.values.byName(json['resolution'] as String)
            : null,
      );
}

// ---------------------------------------------------------------------------
// Conflict resolver
// ---------------------------------------------------------------------------

/// Stateless conflict resolver that compares two deltas and picks a winner
/// according to the chosen [ConflictStrategy].
class ConflictResolver {
  const ConflictResolver();

  /// Resolve a conflict between a [local] and [remote] delta.
  ResolvedDelta resolveConflict({
    required SyncDelta local,
    required SyncDelta remote,
    required ConflictStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictStrategy.lastWriteWins:
        return _resolveLastWriteWins(local, remote);
      case ConflictStrategy.serverWins:
        return ResolvedDelta(
          resolution: ResolutionKind.useRemote,
          winningDelta: remote,
        );
      case ConflictStrategy.clientWins:
        return ResolvedDelta(
          resolution: ResolutionKind.useLocal,
          winningDelta: local,
        );
      case ConflictStrategy.manual:
        return ResolvedDelta(
          resolution: ResolutionKind.manual,
          winningDelta: remote, // default to remote until user decides
        );
    }
  }

  /// Last-write-wins using version vectors first, then wall-clock fallback.
  ResolvedDelta _resolveLastWriteWins(SyncDelta local, SyncDelta remote) {
    // Try version vector comparison if both sides carry one.
    if (local.versionVector != null && remote.versionVector != null) {
      final localVV = VersionVector.fromJson(local.versionVector!);
      final remoteVV = VersionVector.fromJson(remote.versionVector!);

      if (localVV.happensAfter(remoteVV)) {
        return ResolvedDelta(
          resolution: ResolutionKind.useLocal,
          winningDelta: local,
        );
      }
      if (remoteVV.happensAfter(localVV)) {
        return ResolvedDelta(
          resolution: ResolutionKind.useRemote,
          winningDelta: remote,
        );
      }
      // Vectors are concurrent — fall through to timestamp comparison.
    }

    // Wall-clock comparison. On tie, prefer server (consistent tiebreaker).
    if (local.timestamp.isAfter(remote.timestamp)) {
      return ResolvedDelta(
        resolution: ResolutionKind.useLocal,
        winningDelta: local,
      );
    }
    return ResolvedDelta(
      resolution: ResolutionKind.useRemote,
      winningDelta: remote,
    );
  }

  /// Merge two data maps field-by-field using last-write-wins per field.
  /// Returns a merged delta that combines non-conflicting fields from both
  /// sides and picks the later value for conflicting fields.
  ResolvedDelta mergeFieldLevel({
    required SyncDelta local,
    required SyncDelta remote,
  }) {
    final localData = local.data ?? {};
    final remoteData = remote.data ?? {};
    final merged = <String, dynamic>{...remoteData};

    // For each field in local that differs from remote, pick the one
    // from the side with the higher version.
    for (final entry in localData.entries) {
      if (!remoteData.containsKey(entry.key)) {
        // Field only exists locally — keep it.
        merged[entry.key] = entry.value;
      } else if (remoteData[entry.key] != entry.value) {
        // Both sides have the field but differ — use version to decide.
        if (local.version >= remote.version) {
          merged[entry.key] = entry.value;
        }
        // else remote value already in merged
      }
    }

    final winningDelta = local.copyWith(data: merged);
    return ResolvedDelta(
      resolution: ResolutionKind.merged,
      winningDelta: winningDelta,
      mergedData: merged,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Provides a stateless [ConflictResolver] instance.
final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return const ConflictResolver();
});
