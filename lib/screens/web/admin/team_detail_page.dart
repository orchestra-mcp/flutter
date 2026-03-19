import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers ───────────────────────────────────────────────────────────

final _teamDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  return api.getAdminTeam(teamId);
});

final _teamMembersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, teamId) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminTeamMembers(teamId);
  final raw = result['members'];
  if (raw is! List) return [];
  return raw.cast<Map<String, dynamic>>();
});

// ── Team detail page ────────────────────────────────────────────────────────

/// Admin team detail page.
///
/// Shows team name header, description, member list with roles, "Add Member"
/// button, and team settings section. Takes a [teamId] parameter.
class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final parsedId = int.tryParse(teamId) ?? 0;
    final teamAsync = ref.watch(_teamDetailProvider(parsedId));
    final membersAsync = ref.watch(_teamMembersProvider(parsedId));

    return ColoredBox(
      color: tokens.bg,
      child: teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).failedToLoadTeam,
              style: TextStyle(color: tokens.fgBright, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: tokens.fgDim, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(_teamDetailProvider(parsedId)),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (team) => _TeamDetailContent(
        teamId: teamId,
        team: team,
        membersAsync: membersAsync,
      ),
      ),
    );
  }
}

class _TeamDetailContent extends ConsumerWidget {
  const _TeamDetailContent({
    required this.teamId,
    required this.team,
    required this.membersAsync,
  });

  final String teamId;
  final Map<String, dynamic> team;
  final AsyncValue<List<Map<String, dynamic>>> membersAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);

    final name = team['name'] as String? ?? 'Unknown Team';
    final description = team['description'] as String? ?? '';
    final avatarUrl = team['avatar_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, size: 20, color: tokens.fgMuted),
                onPressed: () {},
                tooltip: AppLocalizations.of(context).backToTeams,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: tokens.accent.withValues(alpha: 0.15),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.groups_outlined,
                        size: 22, color: tokens.accent)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).teamIdLabel(teamId),
                      style: TextStyle(color: tokens.fgDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                description,
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            ),
          const SizedBox(height: 32),

          // ── Members section ───────────────────────────────────────────
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              AppLocalizations.of(context).failedToLoadMembersError(e.toString()),
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            data: (members) => _MembersSection(
              tokens: tokens,
              members: members,
            ),
          ),
          const SizedBox(height: 32),

          // ── Team settings section ─────────────────────────────────────
          Text(
            AppLocalizations.of(context).teamSettingsLabel,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _SettingRow(
            tokens: tokens,
            title: AppLocalizations.of(context).teamName,
            subtitle: name,
            trailing: IconButton(
              icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
              onPressed: () {},
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 8),
          _SettingRow(
            tokens: tokens,
            title: AppLocalizations.of(context).defaultRole,
            subtitle: AppLocalizations.of(context).newMembersJoinAsMember,
            trailing: SizedBox(
              width: 120,
              child: DropdownButton<String>(
                value: 'Member',
                isExpanded: true,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                underline: Container(height: 1, color: tokens.border),
                items: [
                  DropdownMenuItem(value: 'Owner', child: Text(AppLocalizations.of(context).ownerRole)),
                  DropdownMenuItem(value: 'Manager', child: Text(AppLocalizations.of(context).teamManagerTarget)),
                  DropdownMenuItem(value: 'Member', child: Text(AppLocalizations.of(context).memberRole)),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SettingRow(
            tokens: tokens,
            title: AppLocalizations.of(context).visibilityLabel,
            subtitle: AppLocalizations.of(context).teamVisibleToAll,
            trailing: Switch.adaptive(
              value: true,
              onChanged: (_) {},
              activeTrackColor: tokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members section ──────────────────────────────────────────────────────────

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.tokens, required this.members});

  final OrchestraColorTokens tokens;
  final List<Map<String, dynamic>> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).teamMembers,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${members.length}',
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: Text(AppLocalizations.of(context).addMember),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.bg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++) ...[
                _MemberTile(tokens: tokens, member: members[i]),
                if (i < members.length - 1)
                  Divider(height: 1, color: tokens.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Member tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.tokens, required this.member});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '';
    final email = member['email'] as String? ?? '';
    final role = member['role'] as String? ?? 'Member';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tokens.accent.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: tokens.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(color: tokens.fgDim, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: role.toLowerCase() == 'owner'
                  ? tokens.accent.withValues(alpha: 0.12)
                  : tokens.fgDim.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: role.toLowerCase() == 'owner'
                    ? tokens.accent
                    : tokens.fgMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.more_vert, size: 16, color: tokens.fgDim),
            onPressed: () {},
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Setting row ─────────────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final OrchestraColorTokens tokens;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.fgDim, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
