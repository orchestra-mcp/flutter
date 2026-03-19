import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ─── Stat card model ──────────────────────────────────────────────────────────

class _StatCard {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

List<_StatCard> _buildStats(AppLocalizations l10n) => [
  _StatCard(
    label: l10n.dashboardActiveProjects,
    value: '3',
    icon: Icons.folder_outlined,
    color: const Color(0xFF7C6FFF),
  ),
  _StatCard(
    label: l10n.dashboardInProgressFeatures,
    value: '7',
    icon: Icons.task_alt_outlined,
    color: const Color(0xFF4CAF50),
  ),
  _StatCard(
    label: l10n.dashboardOpenBugs,
    value: '2',
    icon: Icons.bug_report_outlined,
    color: const Color(0xFFF44336),
  ),
  _StatCard(
    label: l10n.dashboardInReview,
    value: '4',
    icon: Icons.rate_review_outlined,
    color: const Color(0xFFFF9800),
  ),
];

// ─── Placeholder activity items ───────────────────────────────────────────────

class _ActivityItem {
  const _ActivityItem({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
}

List<_ActivityItem> _buildActivity(AppLocalizations l10n) => [
  _ActivityItem(
    title: l10n.dashboardFeatCompleted,
    subtitle: l10n.dashboardFeatCompletedSub,
    icon: Icons.check_circle_outline,
  ),
  _ActivityItem(
    title: l10n.dashboardFeatAdvanced,
    subtitle: l10n.dashboardFeatAdvancedSub,
    icon: Icons.rate_review_outlined,
  ),
  _ActivityItem(
    title: l10n.dashboardBugReported,
    subtitle: l10n.dashboardBugReportedSub,
    icon: Icons.bug_report_outlined,
  ),
  _ActivityItem(
    title: l10n.dashboardNewSession,
    subtitle: l10n.dashboardNewSessionSub,
    icon: Icons.smart_toy_outlined,
  ),
  _ActivityItem(
    title: l10n.dashboardHydrationGoal,
    subtitle: l10n.dashboardHydrationGoalSub,
    icon: Icons.water_drop_outlined,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Authenticated web dashboard with a 2-col stat grid and activity feed.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = _buildStats(l10n);
    final activity = _buildActivity(l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTitle,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth >= 600 ? 2 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.4,
              children: stats
                  .map((s) => _StatCardWidget(stat: s, tokens: tokens))
                  .toList(),
            );
          }),
          const SizedBox(height: 32),
          Text(
            l10n.dashboardRecentActivity,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < activity.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: tokens.border),
                  _ActivityTile(item: activity[i], tokens: tokens),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _StatCardWidget extends StatelessWidget {
  const _StatCardWidget({required this.stat, required this.tokens});
  final _StatCard stat;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.label,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.tokens});
  final _ActivityItem item;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(item.icon, color: tokens.accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text(item.subtitle,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
