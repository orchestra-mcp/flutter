import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

// ─── Breakpoints ──────────────────────────────────────────────────────────────

abstract class _WebBreakpoints {
  static const double desktop = 800;
}

// ─── Navigation destinations ─────────────────────────────────────────────────

class _NavDest {
  const _NavDest({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

const _destinations = [
  _NavDest(label: 'Summary',       icon: Icons.home_outlined),
  _NavDest(label: 'Notifications', icon: Icons.notifications_outlined),
  _NavDest(label: 'Projects',      icon: Icons.folder_outlined),
  _NavDest(label: 'Library',       icon: Icons.book_outlined),
  _NavDest(label: 'Health',        icon: Icons.favorite_outline),
  _NavDest(label: 'Settings',      icon: Icons.settings_outlined),
];

// ─── Shell state ─────────────────────────────────────────────────────────────

class _WebShellState {
  const _WebShellState({this.selectedIndex = 0});
  final int selectedIndex;
  _WebShellState copyWith({int? selectedIndex}) =>
      _WebShellState(selectedIndex: selectedIndex ?? this.selectedIndex);
}

class _WebShellNotifier extends Notifier<_WebShellState> {
  @override
  _WebShellState build() => const _WebShellState();

  void select(int index) => state = state.copyWith(selectedIndex: index);
}

final _webShellProvider =
    NotifierProvider<_WebShellNotifier, _WebShellState>(_WebShellNotifier.new);

// ─── Public shell widget ──────────────────────────────────────────────────────

/// Adaptive web shell.
///
/// - Width >= [_WebBreakpoints.desktop]: [NavigationRail] on the left.
/// - Width < [_WebBreakpoints.desktop]: [BottomNavigationBar].
class WebShell extends ConsumerStatefulWidget {
  const WebShell({super.key, required this.body});

  /// The main content area.  In a real app this is typically the go_router
  /// `child` passed from the shell route.
  final Widget body;

  @override
  ConsumerState<WebShell> createState() => _WebShellState2();
}

class _WebShellState2 extends ConsumerState<WebShell> {
  @override
  Widget build(BuildContext context) {
    final shellState = ref.watch(_webShellProvider);
    final tokens = ThemeTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _WebBreakpoints.desktop;
        return isDesktop
            ? _DesktopLayout(
                tokens: tokens,
                selectedIndex: shellState.selectedIndex,
                onSelect: (i) =>
                    ref.read(_webShellProvider.notifier).select(i),
                body: widget.body,
              )
            : _MobileLayout(
                tokens: tokens,
                selectedIndex: shellState.selectedIndex,
                onSelect: (i) =>
                    ref.read(_webShellProvider.notifier).select(i),
                body: widget.body,
              );
      },
    );
  }
}

// ─── Desktop layout (NavigationRail) ─────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.tokens,
    required this.selectedIndex,
    required this.onSelect,
    required this.body,
  });

  final OrchestraColorTokens tokens;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: tokens.bgAlt,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: IconThemeData(color: tokens.accent),
            selectedLabelTextStyle: TextStyle(
              color: tokens.accent,
              fontWeight: FontWeight.w600,
            ),
            unselectedIconTheme: IconThemeData(color: tokens.fgMuted),
            unselectedLabelTextStyle: TextStyle(color: tokens.fgMuted),
            destinations: [
              for (final dest in _destinations)
                NavigationRailDestination(
                  icon: Icon(dest.icon),
                  label: Text(dest.label),
                ),
            ],
          ),
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: tokens.border,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ─── Mobile layout (BottomNavigationBar) ─────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.tokens,
    required this.selectedIndex,
    required this.onSelect,
    required this.body,
  });

  final OrchestraColorTokens tokens;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tokens.bg,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onSelect,
        backgroundColor: tokens.bgAlt,
        selectedItemColor: tokens.accent,
        unselectedItemColor: tokens.fgMuted,
        type: BottomNavigationBarType.fixed,
        items: [
          for (final dest in _destinations)
            BottomNavigationBarItem(
              icon: Icon(dest.icon),
              label: dest.label,
            ),
        ],
      ),
    );
  }
}
