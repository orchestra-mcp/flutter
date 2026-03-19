import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_status_provider.dart';
import 'package:orchestra/core/sync/team_management_service.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

// ── Service ──────────────────────────────────────────────────────────────────

/// Provides the [TeamManagementService] backed by the shared [SyncApiClient].
final teamManagementServiceProvider =
    Provider<TeamManagementService>((ref) {
  return TeamManagementService(
    apiClient: ref.watch(syncApiClientProvider),
  );
});

// ── Teams list ───────────────────────────────────────────────────────────────

/// Fetches the list of teams the current user belongs to.
/// Auto-refreshes when invalidated.
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final service = ref.watch(teamManagementServiceProvider);
  return service.getTeams();
});

// ── Team members ─────────────────────────────────────────────────────────────

/// Fetches members for a specific team, keyed by team ID.
final teamMembersProvider =
    FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final service = ref.watch(teamManagementServiceProvider);
  return service.getTeamMembers(teamId);
});

// ── Team selector data ───────────────────────────────────────────────────────

/// Pre-fetches all teams with their members for the selector dialog.
final teamSelectorDataProvider =
    FutureProvider<TeamSelectorData>((ref) async {
  final service = ref.watch(teamManagementServiceProvider);
  return service.loadSelectorData();
});

// ── Entity shares ────────────────────────────────────────────────────────────

/// Fetches the list of shares (who has access) for a specific entity.
/// Key is `(entityType, entityId)`.
final entitySharesListProvider =
    FutureProvider.family<List<TeamShare>, (String, String)>(
        (ref, params) async {
  final service = ref.watch(teamManagementServiceProvider);
  return service.getEntityShares(
    entityType: params.$1,
    entityId: params.$2,
  );
});

// ── Selected team state (for selector dialog) ────────────────────────────────

/// Tracks the currently selected team ID in the team selector dialog.
class SelectedTeamNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String teamId) => state = teamId;
  void clear() => state = null;
}

final selectedTeamProvider =
    NotifierProvider<SelectedTeamNotifier, String?>(SelectedTeamNotifier.new);

// ── Selected members state (for selector dialog) ─────────────────────────────

/// Tracks selected member IDs when sharing with specific members.
class SelectedMembersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String memberId) {
    if (state.contains(memberId)) {
      state = {...state}..remove(memberId);
    } else {
      state = {...state, memberId};
    }
  }

  void selectAll(Set<String> memberIds) => state = memberIds;
  void clear() => state = {};
}

final selectedMembersProvider =
    NotifierProvider<SelectedMembersNotifier, Set<String>>(
        SelectedMembersNotifier.new);

// ── Share mode state ─────────────────────────────────────────────────────────

/// Whether sharing with all team members or selected individuals.
class ShareModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // default: share with all

  void setShareWithAll(bool value) => state = value;
  void toggle() => state = !state;
}

final shareWithAllProvider =
    NotifierProvider<ShareModeNotifier, bool>(ShareModeNotifier.new);

// ── Permission selector state ────────────────────────────────────────────────

/// Tracks the selected permission level for the current share operation.
class PermissionNotifier extends Notifier<SharePermission> {
  @override
  SharePermission build() => SharePermission.read;

  void select(SharePermission permission) => state = permission;
}

final sharePermissionProvider =
    NotifierProvider<PermissionNotifier, SharePermission>(
        PermissionNotifier.new);
