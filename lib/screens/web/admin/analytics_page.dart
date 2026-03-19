import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Stats provider ───────────────────────────────────────────────────────────

final _adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getAdminStats();
});

// ── Analytics page ──────────────────────────────────────────────────────────

/// Admin analytics page.
///
/// Fetches stats from [ApiClient.getAdminStats] and renders them in a
/// responsive metric-card grid.  Falls back to an empty state when the
/// API returns no data or an error occurs.
class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final statsAsync = ref.watch(_adminStatsProvider);

    return ColoredBox(
      color: tokens.bg,
      child: statsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.accent),
        ),
        error: (error, _) => _ErrorState(tokens: tokens, error: error),
        data: (stats) => _StatsContent(tokens: tokens, stats: stats),
      ),
    );
  }
}

// ── Stats content ───────────────────────────────────────────────────────────

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.tokens, required this.stats});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    // Build metric list from whatever keys the API returns.
    final metrics = _extractMetricsWithLabels(stats, AppLocalizations.of(context));

    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: tokens.fgDim),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noAnalyticsData,
              style: TextStyle(color: tokens.fgDim, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            AppLocalizations.of(context).analyticsTitle,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // ── Metrics grid ────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                ),
                itemCount: metrics.length,
                itemBuilder: (context, index) {
                  return _MetricCard(tokens: tokens, metric: metrics[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Extract display-ready metrics from the raw stats map.
  ///
  /// The API may return keys like `total_users`, `total_projects`, etc.
  /// We map known keys to friendly labels and icons.
  List<_Metric> _extractMetricsWithLabels(Map<String, dynamic> data, AppLocalizations? l10n) {
    final result = <_Metric>[];

    void add(String key, String label, IconData icon) {
      if (data.containsKey(key) && data[key] != null) {
        result.add(_Metric(
          label: label,
          value: '${data[key]}',
          icon: icon,
        ));
      }
    }

    // Well-known stat keys — extend as the API grows.
    add('total_users', l10n?.totalUsersLabel ?? 'Total Users', Icons.people_outlined);
    add('active_users', l10n?.activeUsersLabel ?? 'Active Users', Icons.groups_outlined);
    add('total_projects', l10n?.totalProjectsLabel ?? 'Total Projects', Icons.folder_outlined);
    add('total_features', l10n?.totalFeaturesLabel ?? 'Total Features', Icons.flag_outlined);
    add('total_teams', l10n?.totalTeamsLabel ?? 'Total Teams', Icons.workspaces_outlined);
    add('total_notes', l10n?.totalNotesLabel ?? 'Total Notes', Icons.note_outlined);
    add('total_pages', l10n?.totalPagesLabel ?? 'Total Pages', Icons.article_outlined);
    add('total_sessions', l10n?.activeSessionsLabel ?? 'Active Sessions', Icons.devices_outlined);
    add('total_api_keys', l10n?.apiKeysLabel ?? 'API Keys', Icons.key_outlined);
    add('total_sponsors', l10n?.sponsorsLabel ?? 'Sponsors', Icons.volunteer_activism_outlined);
    add('total_issues', l10n?.openIssuesLabel ?? 'Open Issues', Icons.bug_report_outlined);
    add('total_contacts', l10n?.contactMessagesLabel ?? 'Contact Messages', Icons.mail_outlined);
    add('storage_used', l10n?.storageUsedLabel ?? 'Storage Used', Icons.storage_outlined);
    add('api_calls_24h', l10n?.apiCalls24hLabel ?? 'API Calls (24h)', Icons.api_outlined);
    add('error_rate', l10n?.errorRateLabel ?? 'Error Rate', Icons.error_outline);

    // Fallback: render any remaining numeric keys not already mapped.
    for (final entry in data.entries) {
      if (result.any((m) => m.label == entry.key)) continue;
      final value = entry.value;
      if (value is num || value is String) {
        final alreadyMapped = result.any((m) =>
            m.value == '$value' &&
            m.label == _humanize(entry.key));
        if (!alreadyMapped) {
          result.add(_Metric(
            label: _humanize(entry.key),
            value: '$value',
            icon: Icons.info_outline,
          ));
        }
      }
    }

    return result;
  }

  /// Turn `snake_case` into `Title Case`.
  String _humanize(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ── Metric model ────────────────────────────────────────────────────────────

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
}

// ── Metric card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.tokens, required this.metric});

  final OrchestraColorTokens tokens;
  final _Metric metric;

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
          Icon(metric.icon, size: 18, color: tokens.fgDim),
          const SizedBox(height: 8),
          Text(
            metric.value,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            metric.label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tokens, required this.error});

  final OrchestraColorTokens tokens;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).failedToLoadAnalytics,
            style: TextStyle(color: tokens.fgBright, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: TextStyle(color: tokens.fgDim, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
