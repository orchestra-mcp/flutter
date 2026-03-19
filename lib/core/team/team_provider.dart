import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Team model ──────────────────────────────────────────────────────────────

class Team {
  const Team({
    required this.id,
    required this.name,
    this.slug,
    this.avatarUrl,
    this.plan,
    this.memberCount,
    this.role,
  });

  final String id;
  final String name;
  final String? slug;
  final String? avatarUrl;
  final String? plan;
  final int? memberCount;
  final String? role; // owner, admin, member

  /// Parses from the API response.
  /// The /api/teams endpoint returns `[{"team": {...}, "role": "..."}, ...]`
  /// so we handle both the nested wrapper and a flat team object.
  factory Team.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data;
    final String? role;
    if (json.containsKey('team') && json['team'] is Map) {
      data = json['team'] as Map<String, dynamic>;
      role = json['role'] as String?;
    } else {
      data = json;
      role = json['role'] as String?;
    }
    return Team(
      id: data['id'].toString(),
      name: (data['name'] ?? '') as String,
      slug: data['slug'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      plan: data['plan'] as String?,
      memberCount: data['member_count'] as int?,
      role: role,
    );
  }

  /// Synthetic "Personal" team used when the user has no teams.
  static const personal = Team(id: 'personal', name: 'Personal');

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
}

// ── Team member model ───────────────────────────────────────────────────────

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.status,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? status;
  final DateTime? joinedAt;

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['id'].toString(),
    name: (json['name'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    role: (json['role'] ?? 'member') as String,
    avatarUrl: json['avatar_url'] as String?,
    status: json['status'] as String?,
    joinedAt: DateTime.tryParse(json['joined_at']?.toString() ?? ''),
  );
}

// ── Active team state ───────────────────────────────────────────────────────

const _activeTeamKey = 'active_team_id';

class _ActiveTeamNotifier extends Notifier<String> {
  @override
  String build() => _cachedActiveTeam ?? 'personal';

  void set(String teamId) {
    state = teamId;
    _cachedActiveTeam = teamId;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_activeTeamKey, teamId),
    );
  }
}

final activeTeamIdProvider = NotifierProvider<_ActiveTeamNotifier, String>(
  _ActiveTeamNotifier.new,
);

/// Cached active team ID — call [initActiveTeam] once at startup.
String? _cachedActiveTeam;

/// Primes the active team from SharedPreferences. Call before ProviderScope.
Future<void> initActiveTeam() async {
  final prefs = await SharedPreferences.getInstance();
  _cachedActiveTeam = prefs.getString(_activeTeamKey);
}

// ── Teams list provider ─────────────────────────────────────────────────────

/// Fetches the list of teams the current user belongs to.
/// Falls back to a single "Personal" team on error.
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  try {
    final items = await ref.watch(apiClientProvider).listTeams();
    if (items.isEmpty) return [Team.personal];
    return items.map(Team.fromJson).toList();
  } catch (_) {
    return [Team.personal];
  }
});

/// The currently active [Team] object (derived from [activeTeamIdProvider] +
/// [teamsProvider]).
final activeTeamProvider = Provider<Team>((ref) {
  final activeId = ref.watch(activeTeamIdProvider);
  final teams = ref.watch(teamsProvider).value ?? [Team.personal];
  return teams.firstWhere((t) => t.id == activeId, orElse: () => teams.first);
});

/// Members of the currently active team.
final teamMembersProvider = FutureProvider<List<TeamMember>>((ref) async {
  final activeId = ref.watch(activeTeamIdProvider);
  if (activeId == 'personal') return [];
  try {
    final items = await ref.watch(apiClientProvider).listTeamMembers(activeId);
    return items.map(TeamMember.fromJson).toList();
  } catch (_) {
    return [];
  }
});
