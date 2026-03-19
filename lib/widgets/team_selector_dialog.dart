import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/team_management_provider.dart';
import 'package:orchestra/core/sync/team_share_models.dart'
    hide resolveAvatarUrl;
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_sheet.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Result returned when the user confirms the team selector dialog.
class TeamShareSelection {
  const TeamShareSelection({
    required this.teamId,
    required this.shareWithAll,
    required this.memberIds,
    required this.permission,
  });

  final String teamId;
  final bool shareWithAll;
  final List<String> memberIds;
  final SharePermission permission;
}

/// Shows the team selector bottom sheet and returns the user's selection,
/// or `null` if dismissed.
Future<TeamShareSelection?> showTeamSelectorDialog({
  required BuildContext context,
  required String entityType,
  required String entityId,
}) {
  return showGlassSheet<TeamShareSelection>(
    context: context,
    child: _TeamSelectorSheet(entityType: entityType, entityId: entityId),
  );
}

// ---------------------------------------------------------------------------
// Sheet content
// ---------------------------------------------------------------------------

class _TeamSelectorSheet extends ConsumerStatefulWidget {
  const _TeamSelectorSheet({required this.entityType, required this.entityId});

  final String entityType;
  final String entityId;

  @override
  ConsumerState<_TeamSelectorSheet> createState() => _TeamSelectorSheetState();
}

class _TeamSelectorSheetState extends ConsumerState<_TeamSelectorSheet> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Reset dialog state on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedTeamProvider.notifier).clear();
      ref.read(selectedMembersProvider.notifier).clear();
      ref.read(shareWithAllProvider.notifier).setShareWithAll(true);
      ref.read(sharePermissionProvider.notifier).select(SharePermission.read);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final selectorData = ref.watch(teamSelectorDataProvider);
    final selectedTeamId = ref.watch(selectedTeamProvider);
    final selectedMembers = ref.watch(selectedMembersProvider);
    final shareWithAll = ref.watch(shareWithAllProvider);
    final permission = ref.watch(sharePermissionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ─────────────────────────────────────────────────────
        Text(
          AppLocalizations.of(context).shareEntityTitle(widget.entityType),
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).selectTeamAndShare,
          style: TextStyle(color: tokens.fgMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // ── Content ────────────────────────────────────────────────────
        selectorData.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: tokens.accent),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppLocalizations.of(context).failedToLoadTeams,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.fgMuted),
            ),
          ),
          data: (data) {
            if (!data.hasTeams) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off_rounded,
                      size: 40,
                      color: tokens.fgDim,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).noTeamsFound,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).joinOrCreateTeam,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Team selector chips ────────────────────────────────
                _SectionLabel(
                  tokens: tokens,
                  text: AppLocalizations.of(context).team,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: data.teams.map((team) {
                      final isSelected = selectedTeamId == team.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TeamChip(
                          team: team,
                          isSelected: isSelected,
                          onTap: () => ref
                              .read(selectedTeamProvider.notifier)
                              .select(team.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (selectedTeamId != null) ...[
                  const SizedBox(height: 16),

                  // ── Share mode toggle ────────────────────────────────
                  _ShareModeToggle(
                    shareWithAll: shareWithAll,
                    onChanged: (v) => ref
                        .read(shareWithAllProvider.notifier)
                        .setShareWithAll(v),
                    tokens: tokens,
                  ),

                  // ── Member list (when not share-with-all) ────────────
                  if (!shareWithAll) ...[
                    const SizedBox(height: 12),
                    _SearchField(
                      tokens: tokens,
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                    const SizedBox(height: 8),
                    _MemberList(
                      members: _filteredMembers(
                        data.membersOf(selectedTeamId!),
                      ),
                      selectedIds: selectedMembers,
                      tokens: tokens,
                      onToggle: (id) =>
                          ref.read(selectedMembersProvider.notifier).toggle(id),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Permission selector ──────────────────────────────
                  _SectionLabel(
                    tokens: tokens,
                    text: AppLocalizations.of(context).permission,
                  ),
                  const SizedBox(height: 8),
                  _PermissionSelector(
                    permission: permission,
                    tokens: tokens,
                    onSelect: (p) =>
                        ref.read(sharePermissionProvider.notifier).select(p),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: TextStyle(color: tokens.fgMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed:
                              _canConfirm(
                                selectedTeamId,
                                shareWithAll,
                                selectedMembers,
                              )
                              ? () => Navigator.of(context).pop(
                                  TeamShareSelection(
                                    teamId: selectedTeamId!,
                                    shareWithAll: shareWithAll,
                                    memberIds: selectedMembers.toList(),
                                    permission: permission,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(AppLocalizations.of(context).share),
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.accent,
                            disabledBackgroundColor: tokens.accent.withValues(
                              alpha: 0.3,
                            ),
                            foregroundColor: tokens.fgBright,
                            disabledForegroundColor: tokens.fgBright.withValues(
                              alpha: 0.4,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<TeamMember> _filteredMembers(List<TeamMember> members) {
    if (_searchQuery.isEmpty) return members;
    final q = _searchQuery.toLowerCase();
    return members
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              (m.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  bool _canConfirm(
    String? teamId,
    bool shareWithAll,
    Set<String> selectedMembers,
  ) {
    if (teamId == null) return false;
    if (!shareWithAll && selectedMembers.isEmpty) return false;
    return true;
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.tokens, required this.text});
  final OrchestraColorTokens tokens;
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: tokens.fgMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.team,
    required this.isSelected,
    required this.onTap,
  });

  final Team team;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tokens.accent.withValues(alpha: 0.15) : tokens.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? tokens.accent
                : tokens.border.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? tokens.accent
                  : tokens.fgDim.withValues(alpha: 0.3),
              backgroundImage: resolveAvatarUrl(team.avatarUrl) != null
                  ? NetworkImage(resolveAvatarUrl(team.avatarUrl)!)
                  : null,
              child: resolveAvatarUrl(team.avatarUrl) == null
                  ? Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                      style: TextStyle(
                        color: isSelected ? tokens.fgBright : tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              team.name,
              style: TextStyle(
                color: isSelected ? tokens.accent : tokens.fgBright,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareModeToggle extends StatelessWidget {
  const _ShareModeToggle({
    required this.shareWithAll,
    required this.onChanged,
    required this.tokens,
  });

  final bool shareWithAll;
  final ValueChanged<bool> onChanged;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        shareWithAll ? Icons.group_rounded : Icons.person_rounded,
        color: tokens.fgMuted,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          AppLocalizations.of(context).shareWithEntireTeam,
          style: TextStyle(color: tokens.fgBright, fontSize: 14),
        ),
      ),
      Switch.adaptive(
        value: shareWithAll,
        onChanged: onChanged,
        activeTrackColor: tokens.accent,
      ),
    ],
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.tokens, required this.onChanged});

  final OrchestraColorTokens tokens;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    style: TextStyle(color: tokens.fgBright, fontSize: 14),
    decoration: InputDecoration(
      hintText: AppLocalizations.of(context).searchMembers,
      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
      prefixIcon: Icon(Icons.search, color: tokens.fgDim, size: 20),
      filled: true,
      fillColor: tokens.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.accent, width: 1.5),
      ),
    ),
  );
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.members,
    required this.selectedIds,
    required this.tokens,
    required this.onToggle,
  });

  final List<TeamMember> members;
  final Set<String> selectedIds;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppLocalizations.of(context).noMembersFound,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: members.length,
        itemBuilder: (_, index) {
          final member = members[index];
          final isSelected = selectedIds.contains(member.id);
          return _MemberTile(
            member: member,
            isSelected: isSelected,
            tokens: tokens,
            onTap: () => onToggle(member.id),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final TeamMember member;
  final bool isSelected;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: tokens.accent,
              side: BorderSide(color: tokens.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: tokens.fgDim.withValues(alpha: 0.2),
            backgroundImage: resolveAvatarUrl(member.avatarUrl) != null
                ? NetworkImage(resolveAvatarUrl(member.avatarUrl)!)
                : null,
            child: resolveAvatarUrl(member.avatarUrl) == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (member.email != null)
                  Text(
                    member.email!,
                    style: TextStyle(color: tokens.fgDim, fontSize: 12),
                  ),
              ],
            ),
          ),

          // Online dot
          if (member.isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),

          // Role badge
          if (member.role == 'admin')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.accentAlt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: tokens.accentAlt,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PermissionSelector extends StatelessWidget {
  const _PermissionSelector({
    required this.permission,
    required this.tokens,
    required this.onSelect,
  });

  final SharePermission permission;
  final OrchestraColorTokens tokens;
  final ValueChanged<SharePermission> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    children: SharePermission.values.map((p) {
      final isSelected = permission == p;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: p != SharePermission.admin ? 8 : 0),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.accent.withValues(alpha: 0.15)
                    : tokens.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? tokens.accent
                      : tokens.border.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    _iconFor(p),
                    size: 18,
                    color: isSelected ? tokens.accent : tokens.fgMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labelFor(p),
                    style: TextStyle(
                      color: isSelected ? tokens.accent : tokens.fgBright,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  IconData _iconFor(SharePermission p) => switch (p) {
    SharePermission.read => Icons.visibility_rounded,
    SharePermission.write => Icons.edit_rounded,
    SharePermission.admin => Icons.admin_panel_settings_rounded,
  };

  String _labelFor(SharePermission p) {
    // Note: this is a StatelessWidget, can't access context easily for l10n
    // Use English fallback since the context isn't available here
    return switch (p) {
      SharePermission.read => 'Read',
      SharePermission.write => 'Write',
      SharePermission.admin => 'Admin',
    };
  }
}
