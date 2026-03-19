import 'package:orchestra/core/sync/sync_api_client.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

/// High-level service for team and member management.
///
/// Wraps [SyncApiClient] team endpoints with in-memory caching and combines
/// team + member data for the selector UI.
class TeamManagementService {
  TeamManagementService({required this.apiClient});

  final SyncApiClient apiClient;

  // ── Cache ──────────────────────────────────────────────────────────────

  List<Team>? _teamsCache;
  DateTime? _teamsCacheTime;
  final Map<String, List<TeamMember>> _membersCache = {};
  final Map<String, DateTime> _membersCacheTime = {};

  static const Duration _cacheTtl = Duration(minutes: 5);

  bool _isCacheValid(DateTime? cacheTime) =>
      cacheTime != null && DateTime.now().difference(cacheTime) < _cacheTtl;

  // ── Teams ──────────────────────────────────────────────────────────────

  /// Fetches teams the current user belongs to. Uses a 5-minute cache.
  Future<List<Team>> getTeams({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isCacheValid(_teamsCacheTime) &&
        _teamsCache != null) {
      return _teamsCache!;
    }
    final teams = await apiClient.getTeams();
    _teamsCache = teams;
    _teamsCacheTime = DateTime.now();
    return teams;
  }

  /// Invalidates the teams cache, forcing next [getTeams] to hit the server.
  void invalidateTeamsCache() {
    _teamsCache = null;
    _teamsCacheTime = null;
  }

  // ── Members ────────────────────────────────────────────────────────────

  /// Fetches members of a specific team. Uses a 5-minute per-team cache.
  Future<List<TeamMember>> getTeamMembers(
    String teamId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _isCacheValid(_membersCacheTime[teamId]) &&
        _membersCache.containsKey(teamId)) {
      return _membersCache[teamId]!;
    }
    final members = await apiClient.getTeamMembers(teamId);
    _membersCache[teamId] = members;
    _membersCacheTime[teamId] = DateTime.now();
    return members;
  }

  /// Invalidates the member cache for a specific team.
  void invalidateMembersCache(String teamId) {
    _membersCache.remove(teamId);
    _membersCacheTime.remove(teamId);
  }

  // ── Entity shares ─────────────────────────────────────────────────────

  /// Fetches who has access to an entity.
  Future<List<TeamShare>> getEntityShares({
    required String entityType,
    required String entityId,
  }) => apiClient.getEntityShares(entityType: entityType, entityId: entityId);

  /// Revokes a specific share.
  Future<void> revokeShare(String shareId) => apiClient.revokeShare(shareId);

  // ── Selector data ─────────────────────────────────────────────────────

  /// Loads a [TeamSelectorData] containing teams with their members
  /// pre-fetched. This is the all-in-one call for the team selector dialog.
  ///
  /// Returns an empty [TeamSelectorData] on network/auth errors so the
  /// dialog shows "No teams found" instead of spinning forever.
  Future<TeamSelectorData> loadSelectorData({bool forceRefresh = false}) async {
    List<Team> teams;
    try {
      teams = await getTeams(
        forceRefresh: forceRefresh,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return const TeamSelectorData(teams: [], membersByTeamId: {});
    }
    final membersMap = <String, List<TeamMember>>{};
    for (final team in teams) {
      try {
        membersMap[team.id] = await getTeamMembers(
          team.id,
          forceRefresh: forceRefresh,
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        membersMap[team.id] = const [];
      }
    }
    return TeamSelectorData(teams: teams, membersByTeamId: membersMap);
  }
}

/// Pre-fetched data for the team selector dialog.
class TeamSelectorData {
  const TeamSelectorData({required this.teams, required this.membersByTeamId});

  /// All teams the user belongs to.
  final List<Team> teams;

  /// Members indexed by team ID.
  final Map<String, List<TeamMember>> membersByTeamId;

  /// Returns members for a given team, or empty list if not found.
  List<TeamMember> membersOf(String teamId) =>
      membersByTeamId[teamId] ?? const [];

  /// Whether any teams are available.
  bool get hasTeams => teams.isNotEmpty;
}
