import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/shell/desktop_shell.dart';
import 'package:orchestra/widgets/spotlight_search.dart';
import 'package:orchestra/widgets/update_banner.dart';

// ── Breakpoints ──────────────────────────────────────────────────────────────

const _kMobileBreakpoint = 600.0;
const _kDesktopBreakpoint = 900.0;

// ── AppShell — responsive wrapper ────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kMobileBreakpoint) {
          return _MobileShell(child: child);
        }
        return DesktopShell(
          child: child,
          canShowSidebar: constraints.maxWidth >= _kDesktopBreakpoint,
        );
      },
    );
  }
}

// ── Mobile shell (bottom nav bar) ────────────────────────────────────────────

int _navIndexFromLocation(String location) {
  if (location.startsWith(Routes.health)) return 1;
  if (location.startsWith(Routes.terminal)) return 2;
  return 0;
}

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});

  final Widget child;

  void _onNavTap(BuildContext context, WidgetRef ref, int i) {
    switch (i) {
      case 0:
        context.go(Routes.summary);
      case 1:
        context.go(Routes.health);
      case 2:
        context.go(Routes.terminal);
      case 3:
        showSpotlightSearch(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final navIndex = _navIndexFromLocation(location);

    // iOS: use AdaptiveScaffold for native liquid glass tab bar.
    // Native UITabBar always puts isSearch items as a circle on the right,
    // so for RTL we drop isSearch and reverse items to get search on the left.
    if (isApple) {
      final l10n = AppLocalizations.of(context);
      final isRtl = Directionality.of(context) == TextDirection.rtl;

      final iosItems = isRtl
          ? [
              // RTL: reversed order, no isSearch — all items in glass pill
              AdaptiveNavigationDestination(
                icon: 'magnifyingglass',
                label: l10n.search,
              ),
              AdaptiveNavigationDestination(
                icon: 'terminal.fill',
                label: l10n.terminal,
              ),
              AdaptiveNavigationDestination(
                icon: 'heart.fill',
                label: l10n.health,
              ),
              AdaptiveNavigationDestination(
                icon: 'house.fill',
                label: l10n.summary,
              ),
            ]
          : [
              // LTR: normal order with isSearch for glass circle
              AdaptiveNavigationDestination(
                icon: 'house.fill',
                label: l10n.summary,
              ),
              AdaptiveNavigationDestination(
                icon: 'heart.fill',
                label: l10n.health,
              ),
              AdaptiveNavigationDestination(
                icon: 'terminal.fill',
                label: l10n.terminal,
              ),
              AdaptiveNavigationDestination(
                icon: 'magnifyingglass',
                label: l10n.search,
                isSearch: true,
              ),
            ];

      final adjustedNavIndex = isRtl ? (3 - navIndex) : navIndex;

      return AdaptiveScaffold(
        minimizeBehavior: TabBarMinimizeBehavior.never,
        body: Column(
          children: [
            const UpdateBanner(),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          selectedIndex: adjustedNavIndex,
          selectedItemColor: tokens.accent,
          unselectedItemColor: tokens.fgMuted,
          useNativeBottomBar: true,
          onTap: (i) {
            final logicalIndex = isRtl ? (3 - i) : i;
            _onNavTap(context, ref, logicalIndex);
          },
          items: iosItems,
        ),
      );
    }

    // Android / Web: Material NavigationBar with proper icons
    // RTL is handled automatically by Flutter's Row-based layout
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        backgroundColor: tokens.bgAlt,
        indicatorColor: tokens.accent.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => _onNavTap(context, ref, i),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: tokens.fgMuted),
            selectedIcon: Icon(Icons.home_rounded, color: tokens.accent),
            label: l10n.summary,
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded, color: tokens.fgMuted),
            selectedIcon: Icon(Icons.favorite_rounded, color: tokens.accent),
            label: l10n.health,
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined, color: tokens.fgMuted),
            selectedIcon: Icon(Icons.terminal_rounded, color: tokens.accent),
            label: l10n.terminal,
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded, color: tokens.fgMuted),
            selectedIcon: Icon(Icons.search_rounded, color: tokens.accent),
            label: l10n.search,
          ),
        ],
      ),
    );
  }
}
