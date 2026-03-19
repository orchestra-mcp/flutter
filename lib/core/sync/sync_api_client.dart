import 'package:dio/dio.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

/// REST client for the sync-specific API endpoints.
///
/// Uses the shared [Dio] instance (with auth/error interceptors) from
/// [dioProvider]. Sits alongside the generic [RestClient] — dedicated to
/// the typed push/pull/status sync protocol.
class SyncApiClient {
  SyncApiClient({required this.dio});

  final Dio dio;

  // ── Endpoints ──────────────────────────────────────────────────────────

  static const String _pushPath = '/api/sync/push';
  static const String _pullPath = '/api/sync/pull';
  static const String _statusPath = '/api/sync/status';

  // ── Push ───────────────────────────────────────────────────────────────

  /// Send local deltas to the server. Returns which were accepted and
  /// which conflicted.
  Future<SyncPushResponse> pushDeltas(SyncPushRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      _pushPath,
      data: request.toJson(),
    );
    return SyncPushResponse.fromJson(response.data!);
  }

  // ── Pull ───────────────────────────────────────────────────────────────

  /// Fetch server-side deltas that occurred after [request.since].
  /// Supports pagination via [SyncPullRequest.limit] and the returned
  /// [SyncPullResponse.hasMore] flag.
  Future<SyncPullResponse> pullDeltas(
    SyncPullRequest request, {
    String? deviceId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      _pullPath,
      queryParameters: {
        ...request.toQueryParams(),
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
    );
    return SyncPullResponse.fromJson(response.data!);
  }

  /// Convenience wrapper that pages through all available deltas
  /// until [hasMore] is false. Use sparingly — prefer bounded pulls.
  Future<List<SyncDelta>> pullAllDeltas({
    required DateTime since,
    List<String>? entityTypes,
    int pageSize = 200,
    String? deviceId,
  }) async {
    final allDeltas = <SyncDelta>[];
    var cursor = since;
    var hasMore = true;

    while (hasMore) {
      final response = await pullDeltas(
        SyncPullRequest(
          since: cursor,
          entityTypes: entityTypes,
          limit: pageSize,
        ),
        deviceId: deviceId,
      );
      allDeltas.addAll(response.deltas);
      hasMore = response.hasMore;
      if (response.deltas.isNotEmpty) {
        cursor = response.serverTimestamp;
      } else {
        hasMore = false;
      }
    }

    return allDeltas;
  }

  // ── Status ─────────────────────────────────────────────────────────────

  /// Retrieve the current sync status from the server.
  Future<SyncStatusInfo> getStatus({String? deviceId}) async {
    final response = await dio.get<Map<String, dynamic>>(
      _statusPath,
      queryParameters: {
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
      },
    );
    return SyncStatusInfo.fromJson(response.data!);
  }

  // ── Team Sharing ──────────────────────────────────────────────────────

  static const String _sharePath = '/api/sync/share';
  static const String _teamUpdatesPath = '/api/sync/team-updates';
  static const String _teamsPath = '/api/teams';
  static const String _historyPath = '/api/sync/history';

  /// Share an entity with a team or selected members.
  Future<ShareResponse> shareEntity(ShareRequest request) async {
    final response = await dio.post<Map<String, dynamic>>(
      _sharePath,
      data: request.toJson(),
    );
    return ShareResponse.fromJson(response.data!);
  }

  /// Check for available team updates (used by the update banner).
  Future<TeamUpdateStatus> getTeamUpdates() async {
    final response = await dio.get<Map<String, dynamic>>(_teamUpdatesPath);
    return TeamUpdateStatus.fromJson(response.data!);
  }

  /// Fetch version history for a specific entity.
  Future<List<SyncVersionEntry>> getEntityHistory({
    required String entityType,
    required String entityId,
    int? limit,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '$_historyPath/$entityType/$entityId',
      queryParameters: {if (limit != null) 'limit': limit.toString()},
    );
    final entries = response.data!['entries'] as List? ?? [];
    return entries
        .map((e) => SyncVersionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Teams ─────────────────────────────────────────────────────────────

  /// Fetch the list of teams the current user belongs to.
  Future<List<Team>> getTeams() async {
    final response = await dio.get<dynamic>(_teamsPath);
    final data = response.data;

    // Handle different response shapes: {"teams": [...]}, {"data": [...]}, or [...]
    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      rawList = (data['teams'] as List?) ?? (data['data'] as List?) ?? [];
    } else {
      rawList = [];
    }

    final baseUrl = dio.options.baseUrl;
    return rawList.whereType<Map<String, dynamic>>().map((e) {
      final teamData = e['team'] as Map<String, dynamic>? ?? e;
      final team = Team.fromJson(teamData);
      return team.copyWith(
        avatarUrl: resolveAvatarUrl(team.avatarUrl, baseUrl),
      );
    }).toList();
  }

  /// Fetch members of a specific team.
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await dio.get<dynamic>('$_teamsPath/$teamId/members');
    final data = response.data;

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      rawList = (data['members'] as List?) ?? (data['data'] as List?) ?? [];
    } else {
      rawList = [];
    }

    final baseUrl = dio.options.baseUrl;
    return rawList.whereType<Map<String, dynamic>>().map((e) {
      final member = TeamMember.fromJson(e);
      return member.copyWith(
        avatarUrl: resolveAvatarUrl(member.avatarUrl, baseUrl),
      );
    }).toList();
  }

  /// Fetch shares for a specific entity (who has access).
  Future<List<TeamShare>> getEntityShares({
    required String entityType,
    required String entityId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '$_sharePath/$entityType/$entityId',
    );
    final shares = response.data!['shares'] as List? ?? [];
    return shares
        .map((e) => TeamShare.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Revoke a share by its ID.
  Future<void> revokeShare(String shareId) async {
    await dio.delete<void>('$_sharePath/$shareId');
  }
}
