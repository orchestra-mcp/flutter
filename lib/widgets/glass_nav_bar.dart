import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Width of a single tab button in the nav pill.
const _kTabWidth = 88.0;

/// Height of the nav bar.
const _kBarHeight = 64.0;

/// A single item definition for [GlassNavBar].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
}

/// Floating liquid-glass bottom navigation bar with sliding indicator.
///
/// Tapping search morphs the entire bar into a glass search field.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.actionIcon = Icons.search_rounded,
    this.onAction,
    this.onSearch,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final ValueChanged<String>? onSearch;

  @override
  State<GlassNavBar> createState() => GlassNavBarState();
}

class GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  bool _searchMode = false;
  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _enterSearch() {
    setState(() => _searchMode = true);
    _morphController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _exitSearch() {
    _searchFocus.unfocus();
    _morphController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _searchMode = false;
          _searchController.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return DefaultTextStyle(
      style: TextStyle(decoration: TextDecoration.none, color: tokens.fgBright),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
        child: AnimatedBuilder(
          animation: _morphAnimation,
          builder: (context, _) {
            final t = _morphAnimation.value;
            if (t == 0 && !_searchMode) return _buildNavMode(tokens);
            return _buildSearchMode(tokens, t);
          },
        ),
      ),
    );
  }

  Widget _buildNavMode(OrchestraColorTokens tokens) {
    return Row(
      children: [
        _GlassTabBar(
          items: widget.items,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          tokens: tokens,
        ),
        const Spacer(),
        _GlassCircleButton(
          icon: widget.actionIcon,
          tokens: tokens,
          onTap: () {
            if (widget.onSearch != null) {
              _enterSearch();
            } else {
              widget.onAction?.call();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchMode(OrchestraColorTokens tokens, double t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: _kBarHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: tokens.fgBright.withValues(alpha: 0.08),
            border: Border.all(color: tokens.fgBright.withValues(alpha: 0.12)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: tokens.fgMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: t,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                    cursorColor: tokens.accent,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchEverything,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (query) {
                      widget.onSearch?.call(query);
                      _exitSearch();
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: _exitSearch,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    AppLocalizations.of(context).cancel,
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass tab bar with sliding indicator ─────────────────────────────────────

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.tokens,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    const borderWidth = 1.0;
    final pillWidth = items.length * _kTabWidth + borderWidth * 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: pillWidth,
          height: _kBarHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: tokens.fgBright.withValues(alpha: 0.06),
            border: Border.all(color: tokens.fgBright.withValues(alpha: 0.10)),
          ),
          child: Stack(
            children: [
              // ── Sliding glass indicator (directional for RTL) ──
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                start: currentIndex * _kTabWidth + 4,
                top: 4,
                bottom: 4,
                width: _kTabWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 0.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Tab buttons ──
              Row(
                children: [
                  for (int i = 0; i < items.length; i++)
                    GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: _kTabWidth,
                        height: _kBarHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: i == currentIndex ? 1.1 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                items[i].icon,
                                color: i == currentIndex
                                    ? tokens.accent
                                    : tokens.fgMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[i].label,
                              style: TextStyle(
                                color: i == currentIndex
                                    ? tokens.accent
                                    : tokens.fgMuted,
                                fontSize: 10,
                                fontWeight: i == currentIndex
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Circular glass button ────────────────────────────────────────────────────

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            width: _kBarHeight,
            height: _kBarHeight,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.fgBright.withValues(alpha: 0.06),
              border: Border.all(
                color: tokens.fgBright.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(icon, color: tokens.fgBright, size: 24),
          ),
        ),
      ),
    );
  }
}
