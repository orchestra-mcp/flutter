import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _usersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminUsers();
  final raw = result['users'];
  if (raw is! List) return [];
  return raw.cast<Map<String, dynamic>>();
});

// ── Filter state ─────────────────────────────────────────────────────────────

class _UserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

final _userSearchProvider =
    NotifierProvider<_UserSearchNotifier, String>(_UserSearchNotifier.new);

class _RoleFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void update(String role) => state = role;
}

final _roleFilterProvider =
    NotifierProvider<_RoleFilterNotifier, String>(_RoleFilterNotifier.new);

class _StatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';
  void update(String status) => state = status;
}

final _statusFilterProvider =
    NotifierProvider<_StatusFilterNotifier, String>(_StatusFilterNotifier.new);

// ── Role helpers ─────────────────────────────────────────────────────────────

const _roleLabels = <String, String>{
  'admin': 'Admin',
  'team_owner': 'Team Owner',
  'team_manager': 'Team Manager',
  'user': 'User',
};

const _roleFilterOrder = ['all', 'admin', 'team_owner', 'team_manager', 'user'];

/// Returns (background, text) colors for a role badge, matching the Next.js
/// reference: admin = red, team_owner = purple, team_manager = cyan, user = grey.
(Color, Color) _roleBadgeColors(String role, OrchestraColorTokens tokens) {
  return switch (role) {
    'admin' => (const Color(0xFFEF4444).withValues(alpha: 0.12), const Color(0xFFEF4444)),
    'team_owner' => (const Color(0xFFA900FF).withValues(alpha: 0.12), const Color(0xFFA900FF)),
    'team_manager' => (const Color(0xFF00E5FF).withValues(alpha: 0.12), const Color(0xFF00E5FF)),
    _ => (tokens.fgDim.withValues(alpha: 0.12), tokens.fgDim),
  };
}

// ── Users page ───────────────────────────────────────────────────────────────

/// Admin users management page.
///
/// Displays a searchable, filterable tile-based list of users with avatar
/// initials, name, email, role badge, status dot, and a 3-dot actions dropdown
/// matching the Next.js admin reference implementation.
class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final usersAsync = ref.watch(_usersProvider);

    return ColoredBox(
      color: tokens.bg,
      child: usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).failedToLoadUsers,
              style: TextStyle(color: tokens.fgBright, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: tokens.fgDim, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(_usersProvider),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (users) => _UsersContent(users: users),
      ),
    );
  }
}

// ── Content ──────────────────────────────────────────────────────────────────

class _UsersContent extends ConsumerWidget {
  const _UsersContent({required this.users});

  final List<Map<String, dynamic>> users;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final query = ref.watch(_userSearchProvider).toLowerCase();
    final roleFilter = ref.watch(_roleFilterProvider);
    final statusFilter = ref.watch(_statusFilterProvider);

    final filtered = users.where((u) {
      // Search filter
      if (query.isNotEmpty) {
        final name = (u['name'] as String? ?? '').toLowerCase();
        final email = (u['email'] as String? ?? '').toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }
      // Role filter
      if (roleFilter != 'all') {
        final role = (u['role'] as String? ?? '');
        if (role != roleFilter) return false;
      }
      // Status filter
      if (statusFilter != 'all') {
        final status = (u['status'] as String? ?? '');
        if (status != statusFilter) return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            AppLocalizations.of(context).users,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.02 * 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).nUsersTotal(users.length),
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── Filters row ─────────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search field
              SizedBox(
                width: 320,
                child: TextField(
                  onChanged: (v) =>
                      ref.read(_userSearchProvider.notifier).update(v),
                  style: TextStyle(color: tokens.fgBright, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchNameOrEmail,
                    hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: tokens.fgDim),
                    filled: true,
                    fillColor: tokens.bgAlt,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                ),
              ),

              // Role filter chips
              ..._roleFilterOrder.map((role) {
                final isSelected = roleFilter == role;
                final label =
                    role == 'all' ? AppLocalizations.of(context).allRoles : (_roleLabels[role] ?? role);
                return _FilterChip(
                  label: label,
                  isSelected: isSelected,
                  tokens: tokens,
                  onTap: () =>
                      ref.read(_roleFilterProvider.notifier).update(role),
                );
              }),

              // Status dropdown
              _StatusDropdown(tokens: tokens),
            ],
          ),
          const SizedBox(height: 20),

          // ── User list ───────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_outlined,
                            size: 36, color: tokens.fgDim),
                        const SizedBox(height: 10),
                        Text(
                          query.isEmpty && roleFilter == 'all' &&
                                  statusFilter == 'all'
                              ? AppLocalizations.of(context).noUsersFound
                              : AppLocalizations.of(context).noMatchingUsers,
                          style:
                              TextStyle(color: tokens.fgMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _UserTile(user: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tokens.border : tokens.bgAlt,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? tokens.fgBright : tokens.fgMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Status dropdown ──────────────────────────────────────────────────────────

class _StatusDropdown extends ConsumerWidget {
  const _StatusDropdown({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_statusFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isDense: true,
          dropdownColor: tokens.bg,
          style: TextStyle(color: tokens.fgBright, fontSize: 12),
          icon: Icon(Icons.expand_more, size: 16, color: tokens.fgMuted),
          items: [
            DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context).allStatuses)),
            DropdownMenuItem(value: 'active', child: Text(AppLocalizations.of(context).active)),
            DropdownMenuItem(value: 'invited', child: Text(AppLocalizations.of(context).invited)),
            DropdownMenuItem(value: 'suspended', child: Text(AppLocalizations.of(context).blocked)),
          ],
          onChanged: (v) {
            if (v != null) {
              ref.read(_statusFilterProvider.notifier).update(v);
            }
          },
        ),
      ),
    );
  }
}

// ── User tile ────────────────────────────────────────────────────────────────

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);

    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final role = user['role'] as String? ?? '';
    final status = user['status'] as String? ?? '';
    final userId = (user['id'] as num).toInt();

    // Avatar initials — up to 2 chars from first letters of words
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    final statusColor = switch (status.toLowerCase()) {
      'active' => const Color(0xFF22C55E),
      'invited' => const Color(0xFFF97316),
      'suspended' || 'disabled' => const Color(0xFFEF4444),
      _ => tokens.fgDim,
    };

    final statusLabel = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : '';

    final (badgeBg, badgeText) = _roleBadgeColors(role, tokens);
    final isSuspended = status.toLowerCase() == 'suspended';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSuspended
            ? const Color(0xFFEF4444).withValues(alpha: 0.03)
            : tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────────────────
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.10),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Name + Email ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSuspended ? tokens.fgDim : tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Role badge ──────────────────────────────────────────────────
          if (role.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: badgeText.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _roleLabels[role] ?? role,
                style: TextStyle(
                  color: badgeText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.02 * 10,
                ),
              ),
            ),
          const SizedBox(width: 12),

          // ── Status dot + label ──────────────────────────────────────────
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 72,
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),

          // ── Actions dropdown (3-dot) ────────────────────────────────────
          _ActionsPopupMenu(
            userId: userId,
            userName: name,
            userEmail: email,
            userRole: role,
            userStatus: status,
          ),
        ],
      ),
    );
  }
}

// ── Actions popup menu ───────────────────────────────────────────────────────

class _ActionsPopupMenu extends ConsumerWidget {
  const _ActionsPopupMenu({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.userStatus,
  });

  final int userId;
  final String userName;
  final String userEmail;
  final String userRole;
  final String userStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final isSuspended = userStatus.toLowerCase() == 'suspended';

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18, color: tokens.fgMuted),
      tooltip: AppLocalizations.of(context).actionsTooltip,
      color: tokens.bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.border),
      ),
      elevation: 8,
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        _menuItem('view_profile', Icons.account_circle_outlined,
            AppLocalizations.of(context).viewProfile, const Color(0xFF00E5FF)),
        _menuItem('change_role', Icons.shield_outlined, AppLocalizations.of(context).changeRole,
            const Color(0xFFA900FF)),
        _menuItem('change_password', Icons.lock_outline, AppLocalizations.of(context).changePassword,
            const Color(0xFFF97316)),
        _menuItem('send_notification', Icons.notifications_outlined,
            AppLocalizations.of(context).sendNotification, const Color(0xFF00E5FF)),
        const PopupMenuDivider(),
        _menuItem(
          'toggle_block',
          isSuspended ? Icons.check_circle_outline : Icons.block,
          isSuspended ? AppLocalizations.of(context).unblockLabel : AppLocalizations.of(context).blockLabel,
          isSuspended ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
        ),
        const PopupMenuDivider(),
        _menuItem(
            'delete', Icons.delete_outline, AppLocalizations.of(context).delete, const Color(0xFFEF4444)),
      ],
      onSelected: (action) {
        switch (action) {
          case 'view_profile':
            context.go('/admin/users/$userId');
          case 'change_role':
            _showChangeRoleDialog(context, ref);
          case 'change_password':
            _showChangePasswordDialog(context, ref);
          case 'send_notification':
            _showSendNotificationDialog(context, ref);
          case 'toggle_block':
            _showToggleBlockDialog(context, ref);
          case 'delete':
            _showDeleteDialog(context, ref);
        }
      },
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color iconColor) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: value == 'delete' || (value == 'toggle_block' &&
                      userStatus.toLowerCase() != 'suspended')
                  ? iconColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Change Role Dialog ──────────────────────────────────────────────────

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    String selectedRole = userRole.isNotEmpty ? userRole : 'user';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sbCtx, setState) {
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
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName  ·  $userEmail',
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).newRole,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      dropdownColor: tokens.bgAlt,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: _inputDecoration(tokens),
                      items: [
                        DropdownMenuItem(value: 'user', child: Text(AppLocalizations.of(context).user)),
                        DropdownMenuItem(
                            value: 'team_manager',
                            child: Text(AppLocalizations.of(context).teamManagerTarget)),
                        DropdownMenuItem(
                            value: 'team_owner', child: Text(AppLocalizations.of(context).teamOwnerTarget)),
                        DropdownMenuItem(
                            value: 'admin', child: Text(AppLocalizations.of(context).adminTarget)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedRole = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context).cancel,
                      style: TextStyle(color: tokens.fgMuted)),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final api = ref.read(apiClientProvider);
                    await api
                        .updateAdminUserRole(userId, {'role': selectedRole});
                    ref.invalidate(_usersProvider);
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

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sbCtx, setState) {
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
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName  ·  $userEmail',
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).newPassword,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: _inputDecoration(tokens).copyWith(
                        hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        hintStyle:
                            TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context).confirmPasswordLabel,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: _inputDecoration(tokens).copyWith(
                        hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                        hintStyle:
                            TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                            color: Color(0xFFEF4444), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context).cancel,
                      style: TextStyle(color: tokens.fgMuted)),
                ),
                FilledButton(
                  onPressed: () async {
                    if (passwordCtrl.text != confirmCtrl.text) {
                      setState(() => errorText = AppLocalizations.of(context).passwordsDoNotMatch);
                      return;
                    }
                    if (passwordCtrl.text.isEmpty) {
                      setState(() => errorText = AppLocalizations.of(context).passwordCannotBeEmpty);
                      return;
                    }
                    Navigator.of(ctx).pop();
                    final api = ref.read(apiClientProvider);
                    await api.updateAdminUser(
                        userId, {'password': passwordCtrl.text});
                    ref.invalidate(_usersProvider);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                  child: Text(AppLocalizations.of(context).changePassword),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Send Notification Dialog ────────────────────────────────────────────

  void _showSendNotificationDialog(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sbCtx, setState) {
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
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName  ·  $userEmail',
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).title,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: _inputDecoration(tokens).copyWith(
                        hintText: AppLocalizations.of(context).notificationTitleHint,
                        hintStyle:
                            TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLocalizations.of(context).messageLabel,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: _inputDecoration(tokens).copyWith(
                        hintText: AppLocalizations.of(context).writeYourMessage,
                        hintStyle:
                            TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context).cancel,
                      style: TextStyle(color: tokens.fgMuted)),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final api = ref.read(apiClientProvider);
                    await api.createAdminNotification({
                      'user_id': userId,
                      'title': titleCtrl.text,
                      'message': messageCtrl.text,
                    });
                    ref.invalidate(_usersProvider);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                  ),
                  child: Text(AppLocalizations.of(context).sendNotification),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Block / Unblock Dialog ──────────────────────────────────────────────

  void _showToggleBlockDialog(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final isActive = userStatus.toLowerCase() != 'suspended';
    final newStatus = isActive ? 'suspended' : 'active';
    final actionLabel = isActive ? AppLocalizations.of(context).blockLabel : AppLocalizations.of(context).unblockLabel;
    final actionColor =
        isActive ? const Color(0xFFEF4444) : const Color(0xFF22C55E);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            AppLocalizations.of(context).blockUserTitle(actionLabel, userName),
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            isActive
                ? AppLocalizations.of(context).blockUserConfirm(userName)
                : AppLocalizations.of(context).unblockUserConfirm(userName),
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  Text(AppLocalizations.of(context).cancel, style: TextStyle(color: tokens.fgMuted)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final api = ref.read(apiClientProvider);
                await api
                    .updateAdminUserStatus(userId, {'status': newStatus});
                ref.invalidate(_usersProvider);
              },
              style: FilledButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  // ── Delete Dialog ───────────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            AppLocalizations.of(context).deleteUserTitle(userName),
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            AppLocalizations.of(context).deleteUserConfirm,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  Text(AppLocalizations.of(context).cancel, style: TextStyle(color: tokens.fgMuted)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final api = ref.read(apiClientProvider);
                await api.deleteAdminUser(userId);
                ref.invalidate(_usersProvider);
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
}

// ── Shared input decoration ──────────────────────────────────────────────────

InputDecoration _inputDecoration(OrchestraColorTokens tokens) {
  return InputDecoration(
    filled: true,
    fillColor: tokens.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: tokens.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: tokens.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: tokens.accent),
    ),
  );
}
