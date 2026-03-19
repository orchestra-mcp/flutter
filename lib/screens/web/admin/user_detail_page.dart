import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _userDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.getAdminUser(userId);
  // API returns { user: {id, name, ...}, project_count, note_count, ... }
  // Merge nested user fields with top-level counts into a flat map.
  final user = response['user'] as Map<String, dynamic>? ?? response;
  return {
    ...user,
    'project_count': response['project_count'] ?? user['project_count'] ?? 0,
    'note_count': response['note_count'] ?? user['note_count'] ?? 0,
    'session_count': response['session_count'] ?? user['session_count'] ?? 0,
    'team_count': response['team_count'] ?? user['team_count'] ?? 0,
    'issue_count': response['issue_count'] ?? user['issue_count'] ?? 0,
  };
});

// ── Per-tab data providers ───────────────────────────────────────────────────

final _userProjectsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.listAdminUserProjects(userId);
  return (resp['projects'] as List?)?.cast<Map<String, dynamic>>() ?? [];
});

final _userNotesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.listAdminUserNotes(userId);
  return (resp['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
});

final _userSessionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.listAdminUserSessions(userId);
  return (resp['sessions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
});

final _userTeamsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.listAdminUserTeams(userId);
  return (resp['teams'] as List?)?.cast<Map<String, dynamic>>() ?? [];
});

final _userIssuesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.listAdminUserIssues(userId);
  return (resp['issues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
});

// ── Tab state ───────────────────────────────────────────────────────────────

class _UserDetailTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final _userDetailTabProvider =
    NotifierProvider<_UserDetailTabNotifier, int>(_UserDetailTabNotifier.new);

// ── Tab definitions ─────────────────────────────────────────────────────────

// Tab labels resolved at build time via _getTabLabels(l10n)

List<String> _getTabLabels(AppLocalizations l10n) => [
  l10n.overview,
  l10n.projects,
  l10n.notes,
  l10n.chats,
  l10n.teams,
  l10n.issues,
];

// ── Role badge colors ───────────────────────────────────────────────────────

({Color bg, Color text}) _roleBadgeColors(String role, OrchestraColorTokens tokens) {
  return switch (role.toLowerCase()) {
    'admin' => (
      bg: const Color(0xFFA900FF).withValues(alpha: 0.12),
      text: const Color(0xFFA900FF),
    ),
    'team_owner' => (
      bg: const Color(0xFF00E5FF).withValues(alpha: 0.12),
      text: const Color(0xFF00E5FF),
    ),
    'team_manager' => (
      bg: const Color(0xFF22C55E).withValues(alpha: 0.12),
      text: const Color(0xFF22C55E),
    ),
    _ => (
      bg: tokens.fgDim.withValues(alpha: 0.12),
      text: tokens.fgDim,
    ),
  };
}

// ── Date formatting ─────────────────────────────────────────────────────────

String _formatDate(String iso) {
  if (iso.isEmpty) return 'N/A';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ── Initials ────────────────────────────────────────────────────────────────

String _initials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name[0].toUpperCase();
}

// ── User detail page ────────────────────────────────────────────────────────

/// Admin user detail page.
///
/// Shows user avatar, name header, email, role badge, status, stat cards,
/// actions dropdown, and tabbed content. Takes a [userId] parameter (String).
class UserDetailPage extends ConsumerWidget {
  const UserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final parsedId = int.tryParse(userId) ?? 0;
    final userAsync = ref.watch(_userDetailProvider(parsedId));

    return ColoredBox(
      color: tokens.bg,
      child: userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).failedToLoadUser,
              style: TextStyle(color: tokens.fgBright, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: tokens.fgDim, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(_userDetailProvider(parsedId)),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (user) => _UserDetailContent(userId: userId, user: user),
      ),
    );
  }
}

// ── Main content ────────────────────────────────────────────────────────────

class _UserDetailContent extends ConsumerWidget {
  const _UserDetailContent({required this.userId, required this.user});

  final String userId;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final selectedTab = ref.watch(_userDetailTabProvider);

    final name = user['name'] as String? ?? AppLocalizations.of(context).unknown;
    final email = user['email'] as String? ?? '';
    final role = user['role'] as String? ?? '';
    final status = user['status'] as String? ?? '';
    final joinedAt = user['created_at'] as String? ?? user['joined_at'] as String? ?? '';
    final parsedId = int.tryParse(userId) ?? 0;

    final statusColor = switch (status.toLowerCase()) {
      'active' => const Color(0xFF22C55E),
      'disabled' || 'suspended' => const Color(0xFFEF4444),
      'invited' => const Color(0xFFFBBF24),
      _ => tokens.fgDim,
    };

    final statusLabel =
        status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : AppLocalizations.of(context).unknown;

    final roleBadge = _roleBadgeColors(role, tokens);

    final projectCount = user['project_count'] as int? ?? 0;
    final noteCount = user['note_count'] as int? ?? 0;
    final sessionCount = user['session_count'] as int? ?? 0;
    final teamCount = user['team_count'] as int? ?? 0;
    final issueCount = user['issue_count'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back link ─────────────────────────────────────────────────
          InkWell(
            onTap: () => context.go('/admin/users'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 16, color: tokens.fgDim),
                  const SizedBox(width: 5),
                  Text(
                    AppLocalizations.of(context).usersNav,
                    style: TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + info + actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          const Color(0xFF00E5FF).withValues(alpha: 0.12),
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),

                    // Info column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + role badge + status
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: tokens.fgBright,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (role.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleBadge.bg,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      color: roleBadge.text,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.02,
                                    ),
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: TextStyle(
                                color: tokens.fgMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Joined ${_formatDate(joinedAt)}',
                            style: TextStyle(
                                color: tokens.fgDim, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Actions dropdown
                    _ActionsDropdown(
                      tokens: tokens,
                      user: user,
                      userId: parsedId,
                      ref: ref,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Stat cards row ──────────────────────────────────────
                Row(
                  children: [
                    _StatMiniCard(
                      tokens: tokens,
                      icon: Icons.folder_outlined,
                      label: AppLocalizations.of(context).projects,
                      value: projectCount,
                    ),
                    const SizedBox(width: 10),
                    _StatMiniCard(
                      tokens: tokens,
                      icon: Icons.note_outlined,
                      label: AppLocalizations.of(context).notes,
                      value: noteCount,
                    ),
                    const SizedBox(width: 10),
                    _StatMiniCard(
                      tokens: tokens,
                      icon: Icons.chat_outlined,
                      label: AppLocalizations.of(context).sessions,
                      value: sessionCount,
                    ),
                    const SizedBox(width: 10),
                    _StatMiniCard(
                      tokens: tokens,
                      icon: Icons.groups_outlined,
                      label: AppLocalizations.of(context).teams,
                      value: teamCount,
                    ),
                    const SizedBox(width: 10),
                    _StatMiniCard(
                      tokens: tokens,
                      icon: Icons.bug_report_outlined,
                      label: AppLocalizations.of(context).issues,
                      value: issueCount,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tab bar (pill style) ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                for (var i = 0; i < _getTabLabels(AppLocalizations.of(context)).length; i++)
                  Expanded(
                    child: _PillTabButton(
                      tokens: tokens,
                      label: _getTabLabels(AppLocalizations.of(context))[i],
                      isSelected: selectedTab == i,
                      onTap: () =>
                          ref.read(_userDetailTabProvider.notifier).select(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildTabContent(
                  tokens,
                  selectedTab,
                  projectCount: projectCount,
                  noteCount: noteCount,
                  sessionCount: sessionCount,
                  teamCount: teamCount,
                  issueCount: issueCount,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(
    OrchestraColorTokens tokens,
    int index, {
    required int projectCount,
    required int noteCount,
    required int sessionCount,
    required int teamCount,
    required int issueCount,
  }) {
    final parsedUserId = int.tryParse(userId) ?? 0;
    switch (index) {
      case 0:
        return _OverviewTab(
          tokens: tokens,
          projectCount: projectCount,
          noteCount: noteCount,
          sessionCount: sessionCount,
          teamCount: teamCount,
          issueCount: issueCount,
        );
      case 1:
        return _ProjectsTab(userId: parsedUserId);
      case 2:
        return _NotesTab(userId: parsedUserId);
      case 3:
        return _ChatsTab(userId: parsedUserId);
      case 4:
        return _TeamsTab(userId: parsedUserId);
      case 5:
        return _IssuesTab(userId: parsedUserId);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Actions dropdown ────────────────────────────────────────────────────────

class _ActionsDropdown extends StatelessWidget {
  const _ActionsDropdown({
    required this.tokens,
    required this.user,
    required this.userId,
    required this.ref,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> user;
  final int userId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final status = (user['status'] as String? ?? '').toLowerCase();
    final isActive = status == 'active';

    return PopupMenuButton<String>(
      onSelected: (action) =>
          _handleAction(context, action),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.border),
      ),
      color: tokens.bg,
      elevation: 8,
      itemBuilder: (ctx) => [
        _menuItem('change_role', Icons.shield_outlined, AppLocalizations.of(context).changeRole),
        _menuItem('change_password', Icons.lock_outline, AppLocalizations.of(context).changePassword),
        _menuItem('send_notification', Icons.notifications_outlined, AppLocalizations.of(context).sendNotification),
        _menuItem('manage_teams', Icons.groups_outlined, AppLocalizations.of(context).manageTeams),
        _menuItem('impersonate', Icons.person_search_outlined, AppLocalizations.of(context).impersonate),
        PopupMenuItem<String>(
          value: 'toggle_verify',
          child: Row(
            children: [
              Icon(
                user['is_verified'] == true
                    ? Icons.verified_outlined
                    : Icons.verified,
                size: 15,
                color: user['is_verified'] == true
                    ? tokens.fgMuted
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              Text(
                user['is_verified'] == true ? AppLocalizations.of(context).removeVerification : AppLocalizations.of(context).verifyUser,
                style: TextStyle(
                  color: user['is_verified'] == true
                      ? tokens.fgMuted
                      : const Color(0xFF22C55E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                isActive ? Icons.block_outlined : Icons.check_circle_outline,
                size: 15,
                color: isActive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? AppLocalizations.of(context).blockUser : AppLocalizations.of(context).unblockUser,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).deleteUser,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_vert, size: 16, color: tokens.fgMuted),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).actionsTooltip,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: tokens.fgMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 15, color: tokens.fgMuted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: tokens.fgBright, fontSize: 13)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context);
      case 'change_password':
        _showChangePasswordDialog(context);
      case 'send_notification':
        _showSendNotificationDialog(context);
      case 'manage_teams':
        _showManageTeamsDialog(context);
      case 'impersonate':
        _showImpersonateDialog(context);
      case 'toggle_status':
        _showToggleStatusDialog(context);
      case 'toggle_verify':
        _toggleVerification(context);
      case 'delete':
        _showDeleteDialog(context);
    }
  }

  // ── Change Role Dialog ──────────────────────────────────────────────────

  void _showChangeRoleDialog(BuildContext context) {
    final name = user['name'] as String? ?? AppLocalizations.of(context).unknown;
    final currentRole = user['role'] as String? ?? 'user';
    String selectedRole = currentRole;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tokens.border),
              ),
              title: Text(
                AppLocalizations.of(context).changeRole,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change role for $name',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  for (final r in const ['admin', 'team_owner', 'team_manager', 'user'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => selectedRole = r),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedRole == r
                                  ? tokens.accent
                                  : tokens.border,
                            ),
                            color: selectedRole == r
                                ? tokens.accent.withValues(alpha: 0.07)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedRole == r
                                          ? tokens.accent
                                          : tokens.fgDim,
                                      width: 2,
                                    ),
                                  ),
                                  child: selectedRole == r
                                      ? Center(
                                          child: SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: tokens.accent,
                                              ),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _roleDisplayLabel(r),
                                style: TextStyle(
                                  color: tokens.fgBright,
                                  fontSize: 13,
                                  fontWeight: selectedRole == r
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    final api = ref.read(apiClientProvider);
                    await api.updateAdminUserRole(
                        userId, {'role': selectedRole});
                    ref.invalidate(_userDetailProvider(userId));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                  child: Text(AppLocalizations.of(context).updateRole),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Change Password Dialog ──────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    String password = '';
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tokens.border),
              ),
              title: Text(
                AppLocalizations.of(context).changePassword,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorText != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    AppLocalizations.of(context).newPassword,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    obscureText: true,
                    onChanged: (v) => password = v,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).userDetailMinCharacters,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      filled: true,
                      fillColor: tokens.bg,
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
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    if (password.trim().isEmpty || password.length < 8) {
                      setState(() {
                        errorText = 'Password must be at least 8 characters';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    final api = ref.read(apiClientProvider);
                    await api.updateAdminUser(
                        userId, {'password': password});
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                  child: Text(AppLocalizations.of(context).updatePassword),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Send Notification Dialog ────────────────────────────────────────────

  void _showSendNotificationDialog(BuildContext context) {
    String title = '';
    String message = '';
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sbContext, setState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tokens.border),
              ),
              title: Text(
                AppLocalizations.of(context).sendNotification,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorText != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    'Title',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => title = v,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).notificationTitleHint,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      filled: true,
                      fillColor: tokens.bg,
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
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Message',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => message = v,
                    maxLines: 3,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).notificationMessage,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      filled: true,
                      fillColor: tokens.bg,
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
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    if (title.trim().isEmpty || message.trim().isEmpty) {
                      setState(() {
                        errorText = AppLocalizations.of(context).notificationTitleRequired;
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    final api = ref.read(apiClientProvider);
                    await api.createAdminNotification({
                      'user_id': userId,
                      'title': title,
                      'message': message,
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                  child: Text(AppLocalizations.of(context).send),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Manage Teams Dialog ─────────────────────────────────────────────────

  void _showManageTeamsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ManageTeamsDialog(
          tokens: tokens,
          userId: userId,
          userName: user['name'] as String? ?? 'this user',
          ref: ref,
        );
      },
    );
  }

  // ── Impersonate Dialog ──────────────────────────────────────────────────

  void _showImpersonateDialog(BuildContext context) {
    final name = user['name'] as String? ?? AppLocalizations.of(context).unknown;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            'Impersonate User',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Impersonate $name? You will be logged in as this user.',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(color: tokens.fgMuted),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Impersonation handled at a higher level
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(context).impersonate),
            ),
          ],
        );
      },
    );
  }

  // ── Toggle Status (Block/Unblock) Dialog ────────────────────────────────

  void _showToggleStatusDialog(BuildContext context) {
    final name = user['name'] as String? ?? AppLocalizations.of(context).unknown;
    final status = (user['status'] as String? ?? '').toLowerCase();
    final isActive = status == 'active';
    final newStatus = isActive ? 'suspended' : 'active';
    final actionLabel = isActive ? 'Block' : 'Unblock';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            '$actionLabel User',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to ${actionLabel.toLowerCase()} $name?',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(color: tokens.fgMuted),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final api = ref.read(apiClientProvider);
                await api.updateAdminUserStatus(
                    userId, {'status': newStatus});
                ref.invalidate(_userDetailProvider(userId));
              },
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  // ── Toggle Verification ──────────────────────────────────────────────────

  Future<void> _toggleVerification(BuildContext context) async {
    final isVerified = user['is_verified'] == true;
    final api = ref.read(apiClientProvider);
    if (isVerified) {
      await api.unverifyAdminUser(userId);
    } else {
      await api.verifyAdminUser(userId);
    }
    ref.invalidate(_userDetailProvider(userId));
  }

  // ── Delete Dialog ───────────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context) {
    final name = user['name'] as String? ?? AppLocalizations.of(context).unknown;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            'Delete user $name?',
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This action cannot be undone. The user will be permanently removed.',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(color: tokens.fgMuted),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final api = ref.read(apiClientProvider);
                await api.deleteAdminUser(userId);
                if (context.mounted) {
                  context.go('/admin/users');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        );
      },
    );
  }

  static String _roleDisplayLabel(String role) {
    return switch (role) {
      'admin' => 'Admin',
      'team_owner' => 'Team Owner',
      'team_manager' => 'Team Manager',
      'user' => 'User',
      _ => role,
    };
  }
}

// ── Manage Teams Dialog (stateful) ──────────────────────────────────────────

class _ManageTeamsDialog extends StatefulWidget {
  const _ManageTeamsDialog({
    required this.tokens,
    required this.userId,
    required this.userName,
    required this.ref,
  });

  final OrchestraColorTokens tokens;
  final int userId;
  final String userName;
  final WidgetRef ref;

  @override
  State<_ManageTeamsDialog> createState() => _ManageTeamsDialogState();
}

class _ManageTeamsDialogState extends State<_ManageTeamsDialog> {
  List<Map<String, dynamic>> memberships = [];
  List<Map<String, dynamic>> allTeams = [];
  bool loading = true;
  String? errorText;
  String addTeamId = '';
  String addTeamRole = 'member';
  bool actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = widget.ref.read(apiClientProvider);
    try {
      final results = await Future.wait([
        api.listAdminTeams(),
        api.listAdminUserMemberships(widget.userId),
      ]);
      final teamsResp = results[0];
      final membershipsResp = results[1];
      final teamList = teamsResp['teams'] as List<dynamic>? ?? [];
      final membershipList =
          membershipsResp['memberships'] as List<dynamic>? ?? [];

      setState(() {
        allTeams = teamList.cast<Map<String, dynamic>>();
        memberships = membershipList.cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorText = 'Failed to load teams';
      });
    }
  }

  Future<void> _removeMembership(int teamId) async {
    setState(() {
      actionLoading = true;
      errorText = null;
    });
    try {
      final api = widget.ref.read(apiClientProvider);
      await api.removeAdminUserMembership(widget.userId, teamId);
      setState(() {
        memberships.removeWhere((m) => m['team_id'] == teamId);
        actionLoading = false;
      });
      widget.ref.invalidate(_userDetailProvider(widget.userId));
      widget.ref.invalidate(_userTeamsProvider(widget.userId));
    } catch (e) {
      setState(() {
        errorText = 'Failed to remove from team';
        actionLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    // Filter out teams the user is already a member of.
    final memberTeamIds =
        memberships.map((m) => m['team_id']).toSet();
    final availableTeams =
        allTeams.where((t) => !memberTeamIds.contains(t['id'])).toList();

    return AlertDialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.border),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Teams',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add or remove ${widget.userName} from teams',
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Current memberships
                    if (memberships.isNotEmpty) ...[
                      Text(
                        'CURRENT TEAMS',
                        style: TextStyle(
                          color: tokens.fgDim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final m in memberships)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: tokens.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: tokens.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['team_name'] as String? ??
                                            'Team #${m['team_id']}',
                                        style: TextStyle(
                                          color: tokens.fgBright,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if ((m['team_plan'] as String? ?? '')
                                              .isNotEmpty) ...[
                                            _badge(
                                              m['team_plan'] as String,
                                              switch ((m['team_plan']
                                                          as String)
                                                      .toLowerCase()) {
                                                'enterprise' =>
                                                  const Color(0xFFA900FF),
                                                'pro' =>
                                                  const Color(0xFF00E5FF),
                                                _ =>
                                                  const Color(0xFF6B7280),
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if ((m['role'] as String? ?? '')
                                              .isNotEmpty)
                                            Text(
                                              m['role'] as String,
                                              style: TextStyle(
                                                color: tokens.fgDim,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: actionLoading
                                      ? null
                                      : () => _removeMembership(
                                          m['team_id'] as int),
                                  icon: const Icon(Icons.close, size: 16),
                                  color: const Color(0xFFEF4444),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  tooltip: AppLocalizations.of(context).removeFromTeam,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    // Add to team section
                    Text(
                      'ADD TO TEAM',
                      style: TextStyle(
                        color: tokens.fgDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.04,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (availableTeams.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          memberships.isEmpty
                              ? 'No teams available'
                              : 'User is a member of all teams',
                          style:
                              TextStyle(color: tokens.fgDim, fontSize: 12),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue:
                                  addTeamId.isEmpty ? null : addTeamId,
                              hint: Text(
                                AppLocalizations.of(context).selectATeam,
                                style: TextStyle(
                                    color: tokens.fgDim, fontSize: 13),
                              ),
                              dropdownColor: tokens.bg,
                              style: TextStyle(
                                  color: tokens.fgBright, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: tokens.bg,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.accent),
                                ),
                              ),
                              items: [
                                for (final t in availableTeams)
                                  DropdownMenuItem(
                                    value: '${t['id']}',
                                    child: Text(
                                      '${t['name']}',
                                      style: TextStyle(
                                        color: tokens.fgBright,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() => addTeamId = v ?? '');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: addTeamRole,
                              dropdownColor: tokens.bg,
                              style: TextStyle(
                                  color: tokens.fgBright, fontSize: 13),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: tokens.bg,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: tokens.accent),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                    value: 'member',
                                    child: Text(AppLocalizations.of(context).memberRole)),
                                DropdownMenuItem(
                                    value: 'admin',
                                    child: Text(AppLocalizations.of(context).adminRole)),
                                DropdownMenuItem(
                                    value: 'owner',
                                    child: Text(AppLocalizations.of(context).ownerRole)),
                                DropdownMenuItem(
                                    value: 'viewer',
                                    child: Text(AppLocalizations.of(context).viewerRole)),
                              ],
                              onChanged: (v) {
                                setState(
                                    () => addTeamRole = v ?? 'member');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed:
                              addTeamId.isEmpty || actionLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        actionLoading = true;
                                        errorText = null;
                                      });
                                      try {
                                        final teamId =
                                            int.tryParse(addTeamId) ?? 0;
                                        final api = widget.ref
                                            .read(apiClientProvider);
                                        await api.addAdminTeamMember(
                                            teamId, {
                                          'user_id': widget.userId,
                                          'role': addTeamRole,
                                        });
                                        // Reload memberships
                                        await _loadData();
                                        setState(() {
                                          addTeamId = '';
                                          actionLoading = false;
                                        });
                                        widget.ref.invalidate(
                                            _userDetailProvider(
                                                widget.userId));
                                        widget.ref.invalidate(
                                            _userTeamsProvider(
                                                widget.userId));
                                      } catch (e) {
                                        setState(() {
                                          errorText =
                                              'Failed to add to team';
                                          actionLoading = false;
                                        });
                                      }
                                    },
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.accent,
                            foregroundColor: tokens.bg,
                          ),
                          child: Text(actionLoading
                              ? AppLocalizations.of(context).addingEllipsis
                              : 'Add to Team'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(color: tokens.fgMuted),
          ),
        ),
      ],
    );
  }
}

// ── Pill tab button ─────────────────────────────────────────────────────────

class _PillTabButton extends StatelessWidget {
  const _PillTabButton({
    required this.tokens,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final OrchestraColorTokens tokens;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? tokens.border : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? tokens.fgBright : tokens.fgMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Stat mini card (inside header) ──────────────────────────────────────────

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.value,
  });

  final OrchestraColorTokens tokens;
  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: tokens.fgDim),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview tab ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.tokens,
    required this.projectCount,
    required this.noteCount,
    required this.sessionCount,
    required this.teamCount,
    required this.issueCount,
  });

  final OrchestraColorTokens tokens;
  final int projectCount;
  final int noteCount;
  final int sessionCount;
  final int teamCount;
  final int issueCount;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (icon: Icons.folder_outlined, label: AppLocalizations.of(context).projects, value: projectCount),
      (icon: Icons.note_outlined, label: AppLocalizations.of(context).notes, value: noteCount),
      (icon: Icons.chat_outlined, label: AppLocalizations.of(context).sessions, value: sessionCount),
      (icon: Icons.groups_outlined, label: AppLocalizations.of(context).teams, value: teamCount),
      (icon: Icons.bug_report_outlined, label: AppLocalizations.of(context).issues, value: issueCount),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid of stat cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in stats)
                SizedBox(
                  width: 180,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: tokens.bgAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          s.icon,
                          size: 20,
                          color: const Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${s.value}',
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: tokens.fgMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No additional overview data',
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state (shared) ─────────────────────────────────────────────────────

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: tokens.fgDim),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge helper ─────────────────────────────────────────────────────────────

Widget _badge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ── Projects tab ─────────────────────────────────────────────────────────────

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dataAsync = ref.watch(_userProjectsProvider(userId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedToLoadProjects,
            style: TextStyle(color: tokens.fgDim, fontSize: 13)),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return _TabEmptyState(
            icon: Icons.folder_outlined,
            label: AppLocalizations.of(context).userDetailNoProjects,
            description: AppLocalizations.of(context).userDetailNoProjectsDesc,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = projects[i];
            final name = p['name'] as String? ?? 'Untitled';
            final status = (p['status'] as String? ?? '').toLowerCase();
            final created = p['created_at'] as String? ?? '';
            final statusColor = switch (status) {
              'active' => const Color(0xFF22C55E),
              'archived' => const Color(0xFF6B7280),
              'paused' => const Color(0xFFCA8A04),
              _ => tokens.fgDim,
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 18, color: const Color(0xFF00E5FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        if (created.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Created ${_formatDate(created)}',
                              style: TextStyle(
                                  color: tokens.fgDim, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (status.isNotEmpty) _badge(status, statusColor),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Notes tab ────────────────────────────────────────────────────────────────

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dataAsync = ref.watch(_userNotesProvider(userId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedToLoadNotes,
            style: TextStyle(color: tokens.fgDim, fontSize: 13)),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return _TabEmptyState(
            icon: Icons.note_outlined,
            label: AppLocalizations.of(context).userDetailNoNotes,
            description: AppLocalizations.of(context).userDetailNoNotesDesc,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = notes[i];
            final title = n['title'] as String? ?? 'Untitled';
            final created = n['created_at'] as String? ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_outlined, size: 18, color: tokens.fgMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        if (created.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatDate(created),
                              style: TextStyle(
                                  color: tokens.fgDim, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Chats tab ────────────────────────────────────────────────────────────────

class _ChatsTab extends ConsumerWidget {
  const _ChatsTab({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dataAsync = ref.watch(_userSessionsProvider(userId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedToLoadSessions,
            style: TextStyle(color: tokens.fgDim, fontSize: 13)),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return _TabEmptyState(
            icon: Icons.chat_outlined,
            label: AppLocalizations.of(context).userDetailNoChats,
            description: AppLocalizations.of(context).userDetailNoChatsDesc,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = sessions[i];
            final name = s['name'] as String? ?? 'Unnamed Session';
            final model = s['model'] as String? ?? '';
            final msgCount = s['message_count'] ?? 0;
            final created = s['created_at'] as String? ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_outlined, size: 18, color: tokens.fgMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (model.isNotEmpty) ...[
                                _badge(model, const Color(0xFF00E5FF)),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '$msgCount messages',
                                style: TextStyle(
                                    color: tokens.fgDim, fontSize: 11),
                              ),
                              if (created.isNotEmpty) ...[
                                Text(' -- ',
                                    style: TextStyle(
                                        color: tokens.fgDim, fontSize: 11)),
                                Text(_formatDate(created),
                                    style: TextStyle(
                                        color: tokens.fgDim, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Teams tab ────────────────────────────────────────────────────────────────

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dataAsync = ref.watch(_userTeamsProvider(userId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedToLoadTeams,
            style: TextStyle(color: tokens.fgDim, fontSize: 13)),
      ),
      data: (teams) {
        if (teams.isEmpty) {
          return _TabEmptyState(
            icon: Icons.groups_outlined,
            label: AppLocalizations.of(context).userDetailNoTeams,
            description: AppLocalizations.of(context).userDetailNoTeamsDesc,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = teams[i];
            final name = t['name'] as String? ?? 'Unnamed Team';
            final plan = (t['plan'] as String? ?? '').toLowerCase();
            final memberCount = t['member_count'] ?? 0;
            final role = t['role'] as String? ?? '';
            final planColor = switch (plan) {
              'enterprise' => const Color(0xFFA900FF),
              'pro' => const Color(0xFF00E5FF),
              _ => const Color(0xFF6B7280),
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups_outlined, size: 18, color: tokens.fgMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (plan.isNotEmpty) ...[
                                _badge(plan, planColor),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '$memberCount members',
                                style: TextStyle(
                                    color: tokens.fgDim, fontSize: 11),
                              ),
                              if (role.isNotEmpty) ...[
                                Text(' -- ',
                                    style: TextStyle(
                                        color: tokens.fgDim, fontSize: 11)),
                                Text(role,
                                    style: TextStyle(
                                        color: tokens.fgMuted, fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Issues tab ───────────────────────────────────────────────────────────────

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dataAsync = ref.watch(_userIssuesProvider(userId));

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(AppLocalizations.of(context).failedToLoadIssues,
            style: TextStyle(color: tokens.fgDim, fontSize: 13)),
      ),
      data: (issues) {
        if (issues.isEmpty) {
          return _TabEmptyState(
            icon: Icons.bug_report_outlined,
            label: AppLocalizations.of(context).userDetailNoIssues,
            description: AppLocalizations.of(context).userDetailNoIssuesDesc,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final issue = issues[i];
            final id = issue['id'];
            final title = issue['title'] as String? ?? 'Untitled';
            final priority =
                (issue['priority'] as String? ?? '').toLowerCase();
            final status = (issue['status'] as String? ?? '').toLowerCase();
            final created = issue['created_at'] as String? ?? '';
            final priorityColor = switch (priority) {
              'high' => const Color(0xFFEF4444),
              'medium' => const Color(0xFFF97316),
              'low' => const Color(0xFF22C55E),
              _ => tokens.fgDim,
            };
            final statusColor = switch (status) {
              'open' => const Color(0xFF3B82F6),
              'in-review' || 'in_review' => const Color(0xFFCA8A04),
              'closed' => const Color(0xFF6B7280),
              _ => tokens.fgDim,
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined,
                      size: 18, color: tokens.fgMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (id != null)
                              Text(
                                '#$id  ',
                                style: TextStyle(
                                  color: tokens.fgDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Expanded(
                              child: Text(title,
                                  style: TextStyle(
                                    color: tokens.fgBright,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (priority.isNotEmpty) ...[
                                _badge(priority, priorityColor),
                                const SizedBox(width: 6),
                              ],
                              if (status.isNotEmpty) ...[
                                _badge(status, statusColor),
                                const SizedBox(width: 8),
                              ],
                              if (created.isNotEmpty)
                                Text(_formatDate(created),
                                    style: TextStyle(
                                        color: tokens.fgDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
