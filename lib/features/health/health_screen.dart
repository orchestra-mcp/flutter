import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/health/daily_flow_tab.dart';
import 'package:orchestra/features/health/health_score_tab.dart';
import 'package:orchestra/features/health/vitals_tab.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_header.dart';

// ─── Health Screen ────────────────────────────────────────────────────────────

/// Ten-tab health dashboard.
///
/// Tabs: Health Score · Vitals · Daily Flow · Hydration · Caffeine ·
/// Nutrition · Pomodoro · Shutdown · Weight · Sleep.
///
/// Uses a horizontally-scrollable [TabBar] so all labels fit on narrow screens.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabCount = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _tabLabels(AppLocalizations l10n) => [
    l10n.healthScore,
    l10n.vitals,
    l10n.dailyFlow,
    l10n.hydration,
    l10n.caffeine,
    l10n.nutrition,
    l10n.pomodoro,
    l10n.shutdown,
    l10n.weight,
    l10n.sleep,
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = _tabLabels(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassHeader(
        title: l10n.health,
        trailing: _buildTabBar(tokens, labels),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const HealthScoreTab(),
          const VitalsTab(),
          const DailyFlowTab(),
          _PlaceholderTab(label: labels[3], icon: Icons.water_drop_outlined),
          _PlaceholderTab(label: labels[4], icon: Icons.coffee_outlined),
          _PlaceholderTab(label: labels[5], icon: Icons.restaurant_outlined),
          _PlaceholderTab(label: labels[6], icon: Icons.timer_outlined),
          _PlaceholderTab(label: labels[7], icon: Icons.nightlight_outlined),
          _PlaceholderTab(
            label: labels[8],
            icon: Icons.monitor_weight_outlined,
          ),
          _PlaceholderTab(label: labels[9], icon: Icons.bedtime_outlined),
        ],
      ),
    );
  }

  // A horizontally-scrollable tab bar placed in the header trailing slot.
  Widget _buildTabBar(OrchestraColorTokens tokens, List<String> labels) {
    return SizedBox(
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: tokens.accent,
        labelColor: tokens.accent,
        unselectedLabelColor: tokens.fgMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: labels.map((l) => Tab(text: l, height: 36)).toList(),
      ),
    );
  }
}

// ─── Placeholder tab ──────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: tokens.fgMuted),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 16)),
        ],
      ),
    );
  }
}
