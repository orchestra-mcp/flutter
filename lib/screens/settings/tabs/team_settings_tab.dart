import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/team/team_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/tray/workspace_switcher.dart';

/// Full team settings — team info, members list, invite, edit name.
class TeamSettingsTab extends ConsumerStatefulWidget {
  const TeamSettingsTab({super.key});

  @override
  ConsumerState<TeamSettingsTab> createState() => _TeamSettingsTabState();
}

class _TeamSettingsTabState extends ConsumerState<TeamSettingsTab> {
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final team = ref.watch(activeTeamProvider);
    final membersAsync = ref.watch(teamMembersProvider);

    if (team.id == 'personal') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).noTeamSelected,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: tokens.fgMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).createOrJoinTeamHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: tokens.fgDim),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => showCreateTeamSheet(context, ref),
                icon: Icon(Icons.add_rounded, size: 18, color: tokens.accent),
                label: Text(AppLocalizations.of(context).createTeam,
                    style: TextStyle(color: tokens.accent)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // ── Team header ──────────────────────────────────────────────
        _TeamHeader(team: team, tokens: tokens),
        const SizedBox(height: 24),

        // ── Team name ────────────────────────────────────────────────
        if (team.isAdmin) ...[
          _EditableTeamName(team: team, tokens: tokens),
          const SizedBox(height: 24),
        ],

        // ── Members section ──────────────────────────────────────────
        Row(
          children: [
            Text(
              AppLocalizations.of(context).membersSection,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tokens.fgBright,
              ),
            ),
            if (team.memberCount != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.fgDim.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${team.memberCount}',
                  style: TextStyle(fontSize: 11, color: tokens.fgMuted),
                ),
              ),
            ],
            const Spacer(),
            if (team.isAdmin)
              TextButton.icon(
                onPressed: () => _showInviteSheet(context),
                icon: Icon(Icons.person_add_alt_1_outlined,
                    size: 16, color: tokens.accent),
                label: Text(AppLocalizations.of(context).invite,
                    style: TextStyle(fontSize: 13, color: tokens.accent)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: membersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context).failedToLoadMembers,
                  style: TextStyle(color: tokens.fgDim, fontSize: 13)),
            ),
            data: (members) {
              if (members.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(AppLocalizations.of(context).noMembersYet,
                      style: TextStyle(color: tokens.fgDim, fontSize: 13)),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < members.length; i++) ...[
                    _MemberTile(
                      member: members[i],
                      isAdmin: team.isAdmin,
                      tokens: tokens,
                      onRemove: team.isAdmin
                          ? () => _removeMember(members[i])
                          : null,
                    ),
                    if (i < members.length - 1)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 56,
                        color: tokens.borderFaint,
                      ),
                  ],
                ],
              );
            },
          ),
        ),

        // ── Danger zone ──────────────────────────────────────────────
        if (team.isOwner) ...[
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).dangerZoneTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _confirmDeleteTeam(team),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 20, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).deleteTeam,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context).deleteTeamPermanentlyDesc,
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.fgDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  void _showInviteSheet(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final emailController = TextEditingController();
    String selectedRole = 'member';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.fgDim.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).inviteMember,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tokens.fgBright,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: tokens.fgBright, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).emailAddressHint,
                    hintStyle: TextStyle(color: tokens.fgDim),
                    prefixIcon: Icon(Icons.email_outlined,
                        size: 20, color: tokens.fgDim),
                    filled: true,
                    fillColor: tokens.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${AppLocalizations.of(context).role}:',
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 13)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedRole,
                      dropdownColor: tokens.bgAlt,
                      style:
                          TextStyle(color: tokens.fgBright, fontSize: 13),
                      underline: Container(
                          height: 1, color: tokens.borderFaint),
                      items: [
                        DropdownMenuItem(
                            value: 'member', child: Text(AppLocalizations.of(context).member)),
                        DropdownMenuItem(
                            value: 'admin', child: Text(AppLocalizations.of(context).teamAdmin)),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedRole = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      final team = ref.read(activeTeamProvider);
                      try {
                        await ref.read(apiClientProvider).inviteTeamMember(
                              team.id,
                              email,
                              role: selectedRole,
                            );
                        ref.invalidate(teamsProvider);
                        ref.invalidate(teamMembersProvider);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${AppLocalizations.of(context).invited} $email')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${AppLocalizations.of(context).failedToInvite}: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context).sendInvite,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeMember(TeamMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = ThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text(AppLocalizations.of(context).removeMemberConfirm(member.name),
              style: TextStyle(color: tokens.fgBright)),
          content: Text(
            AppLocalizations.of(context).removeThisWillRemoveFromTeam,
            style: TextStyle(color: tokens.fgMuted, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: tokens.fgMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).remove,
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).removeTeamMember(member.id);
      ref.invalidate(teamMembersProvider);
      ref.invalidate(teamsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).memberRemoved(member.name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToRemoveMember}: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = ThemeTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text(AppLocalizations.of(context).deleteItemTitle(team.name),
              style: TextStyle(color: tokens.fgBright)),
          content: Text(
            AppLocalizations.of(context).deleteTeamAllDataWarning,
            style: TextStyle(color: tokens.fgMuted, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: tokens.fgMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).delete,
                  style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).deleteTeam(team.id);
      ref.read(activeTeamIdProvider.notifier).set('personal');
      ref.invalidate(teamsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).deleteTeamConfirm)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToDeleteTeam}: $e')),
        );
      }
    }
  }
}

// ── Team header ──────────────────────────────────────────────────────────────

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team, required this.tokens});
  final Team team;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        buildTeamAvatar(team, size: 56, tokens: tokens),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: tokens.fgBright,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (team.plan != null) team.plan!,
                  if (team.role != null) team.role!,
                  if (team.memberCount != null)
                    '${team.memberCount} member${team.memberCount == 1 ? '' : 's'}',
                ].join(' \u00B7 '),
                style: TextStyle(fontSize: 13, color: tokens.fgDim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Editable team name ──────────────────────────────────────────────────────

class _EditableTeamName extends ConsumerStatefulWidget {
  const _EditableTeamName({required this.team, required this.tokens});
  final Team team;
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_EditableTeamName> createState() => _EditableTeamNameState();
}

class _EditableTeamNameState extends ConsumerState<_EditableTeamName> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.team.name);
  }

  @override
  void didUpdateWidget(covariant _EditableTeamName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.name != widget.team.name && !_saving) {
      _controller.text = widget.team.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.team.name) return;

    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateTeam({'name': newName});
      ref.invalidate(teamsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).teamRenamedTo(newName))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToRenameTeam}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).teamName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.tokens.fgMuted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                    color: widget.tokens.fgBright, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.tokens.bgAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tokens.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(AppLocalizations.of(context).save,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Member tile ──────────────────────────────────────────────────────────────

String? _resolveAvatarUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('/')) return '${Env.apiBaseUrl}$raw';
  return raw;
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.tokens,
    this.onRemove,
  });

  final TeamMember member;
  final bool isAdmin;
  final OrchestraColorTokens tokens;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final url = _resolveAvatarUrl(member.avatarUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tokens.accent.withValues(alpha: 0.12),
            backgroundImage: url != null ? NetworkImage(url) : null,
            child: url == null
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.accent,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.email,
                  style: TextStyle(fontSize: 12, color: tokens.fgDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.fgDim.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              member.role,
              style: TextStyle(fontSize: 11, color: tokens.fgMuted),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: AppLocalizations.of(context).remove,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: tokens.fgDim),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
