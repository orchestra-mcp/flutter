import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data model ───────────────────────────────────────────────────────────────

class _OverviewData {
  const _OverviewData({
    required this.totalUsers,
    required this.activeUsers,
    required this.invitedUsers,
    required this.suspendedUsers,
    required this.recentUsers,
  });

  final int totalUsers;
  final int activeUsers;
  final int invitedUsers;
  final int suspendedUsers;
  final List<Map<String, dynamic>> recentUsers;
}

// ── Data provider ────────────────────────────────────────────────────────────

final _overviewProvider =
    FutureProvider.autoDispose<_OverviewData>((ref) async {
  final api = ref.watch(apiClientProvider);

  // Try the dedicated stats endpoint first.
  try {
    final stats = await api.getAdminStats();
    final total = stats['total_users'] as int? ?? 0;
    final active = stats['active_users'] as int? ?? 0;
    final invited = stats['invited_users'] as int? ?? 0;
    final suspended = stats['suspended_users'] as int? ?? 0;

    // Load recent users separately.
    final usersResult =
        await api.listAdminUsers(limit: 5, status: 'active');
    final rawUsers = usersResult['users'];
    final recent = rawUsers is List
        ? rawUsers.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return _OverviewData(
      totalUsers: total,
      activeUsers: active,
      invitedUsers: invited,
      suspendedUsers: suspended,
      recentUsers: recent,
    );
  } catch (_) {
    // Fallback: aggregate from the full user list.
    final usersResult = await api.listAdminUsers();
    final rawUsers = usersResult['users'];
    final users = rawUsers is List
        ? rawUsers.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    var active = 0;
    var invited = 0;
    var suspended = 0;
    for (final u in users) {
      final status = (u['status'] as String? ?? '').toLowerCase();
      if (status == 'active') {
        active++;
      } else if (status == 'invited') {
        invited++;
      } else if (status == 'suspended' || status == 'disabled') {
        suspended++;
      }
    }

    return _OverviewData(
      totalUsers: users.length,
      activeUsers: active,
      invitedUsers: invited,
      suspendedUsers: suspended,
      recentUsers: users.take(5).toList(),
    );
  }
});

// ── Quick link data ──────────────────────────────────────────────────────────

class _QuickLink {
  const _QuickLink({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

List<_QuickLink> _getQuickLinks(AppLocalizations l10n) => <_QuickLink>[
  _QuickLink(label: l10n.users, icon: Icons.people_outlined),
  _QuickLink(label: l10n.teams, icon: Icons.groups_outlined),
  _QuickLink(label: l10n.roles, icon: Icons.admin_panel_settings_outlined),
  _QuickLink(label: l10n.settings, icon: Icons.settings_outlined),
];

// ── Admin overview page ─────────────────────────────────────────────────────

/// Admin dashboard overview page.
///
/// Shows stat cards row (Total Users, Active, Invited, Suspended), a quick
/// links grid, and a recent users list.
class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final overviewAsync = ref.watch(_overviewProvider);

    return ColoredBox(
      color: tokens.bg,
      child: overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).failedToLoadOverview,
              style: TextStyle(color: tokens.fgBright, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: tokens.fgDim, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(_overviewProvider),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
      data: (data) => _OverviewContent(data: data),
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    final stats = <_StatDef>[
      _StatDef(
        label: l10n.totalUsers,
        count: data.totalUsers,
        icon: Icons.people_outlined,
        color: const Color(0xFF38BDF8),
      ),
      _StatDef(
        label: l10n.active,
        count: data.activeUsers,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4ADE80),
      ),
      _StatDef(
        label: l10n.invited,
        count: data.invitedUsers,
        icon: Icons.mail_outlined,
        color: const Color(0xFFFBBF24),
      ),
      _StatDef(
        label: l10n.suspended,
        count: data.suspendedUsers,
        icon: Icons.block_outlined,
        color: const Color(0xFFF87171),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Text(
            l10n.overview,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // ── Stats row ─────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.0,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  return _StatCardWidget(tokens: tokens, stat: stats[index]);
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Quick links ───────────────────────────────────────────────
          Text(
            l10n.quickLinks,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.4,
                ),
                itemCount: _getQuickLinks(l10n).length,
                itemBuilder: (context, index) {
                  final link = _getQuickLinks(l10n)[index];
                  return _QuickLinkCard(tokens: tokens, link: link);
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Recent users ──────────────────────────────────────────────
          Text(
            l10n.recentUsers,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (data.recentUsers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Center(
                child: Text(
                  l10n.noRecentUsers,
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < data.recentUsers.length; i++) ...[
                    _RecentUserTile(
                        tokens: tokens, user: data.recentUsers[i]),
                    if (i < data.recentUsers.length - 1)
                      Divider(height: 1, color: tokens.border),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat definition ──────────────────────────────────────────────────────────

class _StatDef {
  const _StatDef({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

// ── Stat card widget ────────────────────────────────────────────────────────

class _StatCardWidget extends StatelessWidget {
  const _StatCardWidget({required this.tokens, required this.stat});

  final OrchestraColorTokens tokens;
  final _StatDef stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 20, color: stat.color),
              const Spacer(),
            ],
          ),
          Text(
            '${stat.count}',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            stat.label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Quick link card ─────────────────────────────────────────────────────────

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({required this.tokens, required this.link});

  final OrchestraColorTokens tokens;
  final _QuickLink link;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tokens.bgAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        hoverColor: tokens.border.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Icon(link.icon, size: 20, color: tokens.accent),
              const SizedBox(width: 12),
              Text(
                link.label,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 12, color: tokens.fgDim),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent user tile ────────────────────────────────────────────────────────

class _RecentUserTile extends StatelessWidget {
  const _RecentUserTile({required this.tokens, required this.user});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> user;

  String _formatJoinedAt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final joinedAt = user['joined_at'] as String?;

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
          Text(
            _formatJoinedAt(joinedAt),
            style: TextStyle(color: tokens.fgDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
