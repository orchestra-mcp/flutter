import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// -- Data provider ------------------------------------------------------------

/// Loads all users and groups them by role to show role user counts alongside
/// the static permission matrix.
final _roleCounts =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminUsers();
  final raw = result['users'];
  if (raw is! List) return {};
  final users = raw.cast<Map<String, dynamic>>();
  final counts = <String, int>{};
  for (final u in users) {
    final role = (u['role'] as String? ?? 'user').toLowerCase();
    counts[role] = (counts[role] ?? 0) + 1;
  }
  return counts;
});

// -- Permission matrix (static definition) ------------------------------------

const _roles = <String>['admin', 'team_owner', 'team_manager', 'user'];

const _permissions = <String>[
  'manage_users',
  'manage_teams',
  'manage_billing',
  'manage_plugins',
  'manage_settings',
  'view_analytics',
  'view_logs',
  'manage_features',
  'manage_content',
  'impersonate',
];

const _matrix = <String, Set<String>>{
  'admin': {
    'manage_users',
    'manage_teams',
    'manage_billing',
    'manage_plugins',
    'manage_settings',
    'view_analytics',
    'view_logs',
    'manage_features',
    'manage_content',
    'impersonate',
  },
  'team_owner': {
    'manage_teams',
    'manage_billing',
    'view_analytics',
    'view_logs',
    'manage_features',
    'manage_content',
  },
  'team_manager': {
    'manage_teams',
    'view_analytics',
    'view_logs',
    'manage_features',
    'manage_content',
  },
  'user': {
    'view_analytics',
    'manage_features',
  },
};

// -- Roles page ---------------------------------------------------------------

/// Admin roles and permissions page.
///
/// Displays each role as a card with a Wrap of permission chips showing
/// granted (green) and denied (dim) permissions.
class RolesPage extends ConsumerWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final roleCountsAsync = ref.watch(_roleCounts);

    // Resolve counts -- show empty map while loading/error, actual once loaded.
    final counts = roleCountsAsync.whenData((v) => v).value ?? <String, int>{};

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Header ---------------------------------------------------------
            Text(
              AppLocalizations.of(context).rolesAndPermissions,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).nRolesNPermissions(_roles.length, _permissions.length),
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // -- Role card list -------------------------------------------------
          Expanded(
            child: ListView.separated(
              itemCount: _roles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final role = _roles[index];
                final userCount = counts[role] ?? 0;
                final granted = _matrix[role] ?? const <String>{};

                return _RoleCard(
                  role: role,
                  userCount: userCount,
                  grantedPermissions: granted,
                  tokens: tokens,
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// -- Role card ----------------------------------------------------------------

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.userCount,
    required this.grantedPermissions,
    required this.tokens,
  });

  final String role;
  final int userCount;
  final Set<String> grantedPermissions;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Role name + user count badge ----------------------------------
          Row(
            children: [
              Text(
                role,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context).nUsersLabel(userCount),
                  style: TextStyle(
                    color: tokens.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // -- Permission chips -----------------------------------------------
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _permissions.map((perm) {
              final granted = grantedPermissions.contains(perm);
              return _PermissionChip(
                name: perm,
                granted: granted,
                tokens: tokens,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -- Permission chip ----------------------------------------------------------

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
    required this.name,
    required this.granted,
    required this.tokens,
  });

  final String name;
  final bool granted;
  final OrchestraColorTokens tokens;

  static const _green = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    final chipColor = granted ? _green : tokens.fgDim;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check : Icons.close,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
