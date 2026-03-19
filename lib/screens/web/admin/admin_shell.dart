import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/web/admin/users_page.dart';
import 'package:orchestra/screens/web/admin/billing_page.dart';
import 'package:orchestra/screens/web/admin/analytics_page.dart';
import 'package:orchestra/screens/web/admin/logs_page.dart';
import 'package:orchestra/screens/web/admin/plugins_page.dart';
import 'package:orchestra/screens/web/admin/security_page.dart';
import 'package:orchestra/screens/web/admin/feature_flags_page.dart';

// ── Navigation destinations ─────────────────────────────────────────────────

class _AdminDest {
  const _AdminDest({required this.labelKey, required this.icon});
  final String Function(AppLocalizations) labelKey;
  final IconData icon;
}

List<_AdminDest> _getDestinations() => [
  _AdminDest(labelKey: (l) => l.usersNav, icon: Icons.people_outlined),
  _AdminDest(labelKey: (l) => l.billingNav, icon: Icons.payment_outlined),
  _AdminDest(labelKey: (l) => l.analyticsNav, icon: Icons.bar_chart_outlined),
  _AdminDest(labelKey: (l) => l.logsNav, icon: Icons.article_outlined),
  _AdminDest(labelKey: (l) => l.pluginsNav, icon: Icons.extension_outlined),
  _AdminDest(labelKey: (l) => l.securityNav, icon: Icons.shield_outlined),
  _AdminDest(labelKey: (l) => l.featureFlags, icon: Icons.flag_outlined),
];

const _pages = <Widget>[
  UsersPage(),
  BillingPage(),
  AnalyticsPage(),
  LogsPage(),
  PluginsPage(),
  SecurityPage(),
  FeatureFlagsPage(),
];

// ── Shell state ─────────────────────────────────────────────────────────────

class _AdminShellState {
  const _AdminShellState({this.selectedIndex = 0});
  final int selectedIndex;
  _AdminShellState copyWith({int? selectedIndex}) =>
      _AdminShellState(selectedIndex: selectedIndex ?? this.selectedIndex);
}

class _AdminShellNotifier extends Notifier<_AdminShellState> {
  @override
  _AdminShellState build() => const _AdminShellState();

  void select(int index) => state = state.copyWith(selectedIndex: index);
}

final _adminShellProvider =
    NotifierProvider<_AdminShellNotifier, _AdminShellState>(
      _AdminShellNotifier.new,
    );

// ── Admin shell widget ──────────────────────────────────────────────────────

/// Full-screen admin panel with a persistent sidebar navigation.
///
/// Sidebar items: Users, Billing, Analytics, Logs, Plugins, Security,
/// Feature Flags.  Each item swaps the body content while keeping the
/// sidebar visible.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellState = ref.watch(_adminShellProvider);
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────
          _AdminSidebar(
            tokens: tokens,
            selectedIndex: shellState.selectedIndex,
            onSelect: (i) => ref.read(_adminShellProvider.notifier).select(i),
          ),
          VerticalDivider(thickness: 1, width: 1, color: tokens.border),
          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: ClipRect(
              child: IndexedStack(
                index: shellState.selectedIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sidebar ─────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.tokens,
    required this.selectedIndex,
    required this.onSelect,
  });

  final OrchestraColorTokens tokens;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: tokens.bgAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: tokens.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).adminPanel,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _getDestinations().length,
              itemBuilder: (context, index) {
                final dest = _getDestinations()[index];
                final isSelected = index == selectedIndex;
                return _NavTile(
                  tokens: tokens,
                  icon: dest.icon,
                  label: dest.labelKey(AppLocalizations.of(context)),
                  isSelected: isSelected,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final OrchestraColorTokens tokens;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? tokens.accentSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: tokens.border.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? tokens.accent : tokens.fgMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? tokens.accent : tokens.fgMuted,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
