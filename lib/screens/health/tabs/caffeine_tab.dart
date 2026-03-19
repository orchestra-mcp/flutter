import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/caffeine_item.dart';
import 'package:orchestra/core/health/caffeine_item_provider.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Caffeine tab — log caffeine intake, show cortisol window warning,
/// daily limit progress, and contextual insight cards.
class CaffeineTab extends ConsumerWidget {
  const CaffeineTab({super.key});

  static const int _dailyLimitMg = 400;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(caffeineProvider);
    final notifier = ref.read(caffeineProvider.notifier);
    final inCortisol = notifier.isCortisolWindow();

    // Loading — show shimmer placeholders.
    if (state.isLoading) {
      return _ShimmerPlaceholder(tokens: tokens);
    }

    return RefreshIndicator(
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Error banner with retry action.
          if (state.error != null)
            _ErrorBanner(
              error: state.error!,
              tokens: tokens,
              onRetry: notifier.refresh,
            ),

          // Cortisol window banner with animated pulse.
          if (inCortisol) _CortisolBanner(tokens: tokens),

          // Total today + daily limit progress.
          _DailySummaryCard(state: state, tokens: tokens),
          const SizedBox(height: 16),

          // Insight card — contextual encouragement.
          _InsightCard(state: state, tokens: tokens),
          const SizedBox(height: 16),

          // Searchable drink list.
          _DrinkListCard(
            tokens: tokens,
            inCortisol: inCortisol,
            items: ref.watch(caffeineItemsProvider),
            onAdd: (item) {
              final type = CaffeineState.typeFromString(item.id);
              notifier.addCaffeine(type);
            },
          ),
          const SizedBox(height: 16),

          // Log entries or empty state.
          if (state.entries.isEmpty)
            _EmptyLogState(tokens: tokens)
          else
            _EntryLog(state: state, tokens: tokens),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: notifier.reset,
              child: Text(
                l10n.resetToday,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Static helper used by multiple sub-widgets.
  // TODO: Replace with admin-panel-managed caffeine items with multi-lang support.
  static String typeName(CaffeineType type, AppLocalizations l10n) {
    switch (type) {
      case CaffeineType.espresso:
        return l10n.caffeineEspresso;
      case CaffeineType.blackCoffee:
        return l10n.caffeineBlackCoffee;
      case CaffeineType.coldBrew:
        return l10n.caffeineColdBrew;
      case CaffeineType.matcha:
        return l10n.caffeineMatcha;
      case CaffeineType.greenTea:
        return l10n.caffeineGreenTea;
      case CaffeineType.redBull:
        return l10n.caffeineRedBull;
      case CaffeineType.other:
        return l10n.caffeineOther;
    }
  }

  static String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Shimmer loading placeholder
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final opacity = 0.04 + (_shimmer.value * 0.08);
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _shimmerBlock(tokens, opacity, height: 80),
            const SizedBox(height: 16),
            _shimmerBlock(tokens, opacity, height: 56),
            const SizedBox(height: 16),
            _shimmerBlock(tokens, opacity, height: 120),
            const SizedBox(height: 16),
            _shimmerBlock(tokens, opacity, height: 160),
          ],
        );
      },
    );
  }

  Widget _shimmerBlock(
    OrchestraColorTokens tokens,
    double opacity, {
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: tokens.fgDim.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated builder helper (avoids importing flutter_animate)
// ---------------------------------------------------------------------------

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) => builder(context, null);
}

// ---------------------------------------------------------------------------
// Error banner with retry
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.error,
    required this.tokens,
    required this.onRetry,
  });

  final String error;
  final OrchestraColorTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const bannerColor = Color(0xFFF44336);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: bannerColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).failedToLoad,
              style: const TextStyle(color: bannerColor, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context).retry,
                style: const TextStyle(
                  color: bannerColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cortisol window banner with animated pulse
// ---------------------------------------------------------------------------

class _CortisolBanner extends StatefulWidget {
  const _CortisolBanner({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  State<_CortisolBanner> createState() => _CortisolBannerState();
}

class _CortisolBannerState extends State<_CortisolBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  static const _warningColor = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.10, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _warningColor.withValues(alpha: _pulseAnim.value),
            border: Border.all(color: _warningColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _warningColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).cortisolWindow,
                  style: const TextStyle(
                    color: _warningColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Daily summary card with progress bar
// ---------------------------------------------------------------------------

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.state, required this.tokens});

  final CaffeineState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = (state.totalMg / CaffeineTab._dailyLimitMg).clamp(
      0.0,
      1.0,
    );
    final overLimit = state.totalMg > CaffeineTab._dailyLimitMg;
    final progressColor = overLimit ? const Color(0xFFF44336) : tokens.accent;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.coffee_rounded, color: tokens.accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.totalMg} mg',
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.mgToday,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: state.status, tokens: tokens),
            ],
          ),
          const SizedBox(height: 14),

          // Daily limit progress bar.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: tokens.fgDim.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          overLimit
                              ? l10n.overLimit
                              : '${CaffeineTab._dailyLimitMg - state.totalMg} mg ${l10n.remaining}',
                          style: TextStyle(
                            color: overLimit
                                ? const Color(0xFFF44336)
                                : tokens.fgDim,
                            fontSize: 11,
                            fontWeight: overLimit
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          l10n.mgLimit(CaffeineTab._dailyLimitMg),
                          style: TextStyle(color: tokens.fgDim, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insight card — contextual encouragement
// ---------------------------------------------------------------------------

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.state, required this.tokens});

  final CaffeineState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final insight = _resolveInsight(AppLocalizations.of(context));
    if (insight == null) return const SizedBox.shrink();

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight.icon, color: insight.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.subtitle,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _Insight? _resolveInsight(AppLocalizations l10n) {
    final hasRedBull = state.entries.any((e) => e.type == CaffeineType.redBull);
    final redBullCount = state.entries
        .where((e) => e.type == CaffeineType.redBull)
        .length;
    final coffeeCount = state.entries
        .where(
          (e) =>
              e.type == CaffeineType.espresso ||
              e.type == CaffeineType.blackCoffee ||
              e.type == CaffeineType.coldBrew,
        )
        .length;

    // No Red Bull today — celebration.
    if (!hasRedBull && state.entries.isNotEmpty) {
      return _Insight(
        icon: Icons.celebration_rounded,
        title: l10n.noRedBullToday,
        subtitle: l10n.noRedBullSubtitle,
        color: const Color(0xFF4CAF50),
      );
    }

    // Heavy Red Bull usage.
    if (redBullCount >= 2) {
      return _Insight(
        icon: Icons.swap_horiz_rounded,
        title: l10n.switchToMatchaRedBull,
        subtitle: l10n.switchToMatchaRedBullSub,
        color: const Color(0xFFFF9800),
      );
    }

    // Heavy coffee usage — suggest matcha.
    if (coffeeCount >= 3) {
      return _Insight(
        icon: Icons.eco_rounded,
        title: l10n.switchToMatcha,
        subtitle: l10n.switchToMatchaSub,
        color: const Color(0xFF66BB6A),
      );
    }

    // Over the daily limit.
    if (state.totalMg > CaffeineTab._dailyLimitMg) {
      return _Insight(
        icon: Icons.do_not_disturb_on_rounded,
        title: l10n.overDailyLimit,
        subtitle: l10n.overDailyLimitSub,
        color: const Color(0xFFF44336),
      );
    }

    // No entries yet — no insight to show.
    return null;
  }
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

// ---------------------------------------------------------------------------
// Empty state when no entries logged
// ---------------------------------------------------------------------------

class _EmptyLogState extends StatelessWidget {
  const _EmptyLogState({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.coffee_outlined,
            color: tokens.fgDim.withValues(alpha: 0.4),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noResults,
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addCaffeine,
            style: TextStyle(color: tokens.fgDim, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry log (existing today's log with visual enhancements)
// ---------------------------------------------------------------------------

class _EntryLog extends StatelessWidget {
  const _EntryLog({required this.state, required this.tokens});

  final CaffeineState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.today,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                l10n.drinksCount(state.entries.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.entries.reversed
              .take(6)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _DrinkChip._icons[e.type] ?? Icons.coffee_rounded,
                          color: tokens.accent,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CaffeineTab.typeName(e.type, l10n),
                        style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        l10n.plusMg(e.mg),
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CaffeineTab.formatTime(e.timestamp),
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
          if (state.entries.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  l10n.moreEntries(state.entries.length - 6),
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.tokens});

  final CaffeineStatus status;
  final OrchestraColorTokens tokens;

  String _label(AppLocalizations l10n) {
    switch (status) {
      case CaffeineStatus.noIntake:
        return l10n.caffeineNoIntake;
      case CaffeineStatus.clean:
        return l10n.caffeineClean;
      case CaffeineStatus.transitioning:
        return l10n.caffeineTransitioning;
      case CaffeineStatus.redBullDependent:
        return l10n.caffeineRedBullDep;
    }
  }

  Color get _color {
    switch (status) {
      case CaffeineStatus.noIntake:
        return const Color(0xFF9E9E9E);
      case CaffeineStatus.clean:
        return const Color(0xFF4CAF50);
      case CaffeineStatus.transitioning:
        return const Color(0xFFFF9800);
      case CaffeineStatus.redBullDependent:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _label(AppLocalizations.of(context)),
        style: TextStyle(color: _color, fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drink chip
// ---------------------------------------------------------------------------

class _DrinkChip extends StatelessWidget {
  const _DrinkChip({
    required this.type,
    required this.tokens,
    required this.inCortisol,
    required this.onTap,
  });

  final CaffeineType type;
  final OrchestraColorTokens tokens;
  final bool inCortisol;
  final VoidCallback onTap;

  static const _icons = {
    CaffeineType.espresso: Icons.coffee_rounded,
    CaffeineType.blackCoffee: Icons.local_cafe_rounded,
    CaffeineType.coldBrew: Icons.water_rounded,
    CaffeineType.matcha: Icons.eco_rounded,
    CaffeineType.greenTea: Icons.emoji_nature_rounded,
    CaffeineType.redBull: Icons.bolt_rounded,
    CaffeineType.other: Icons.add_circle_outline_rounded,
  };

  static const _mg = {
    CaffeineType.espresso: 63,
    CaffeineType.blackCoffee: 95,
    CaffeineType.coldBrew: 200,
    CaffeineType.matcha: 70,
    CaffeineType.greenTea: 28,
    CaffeineType.redBull: 80,
    CaffeineType.other: 50,
  };

  // TODO: Replace with admin-panel-managed items with multi-lang + seeder preset data.
  String _name(AppLocalizations l10n) {
    switch (type) {
      case CaffeineType.espresso:
        return l10n.caffeineEspresso;
      case CaffeineType.blackCoffee:
        return l10n.caffeineBlack;
      case CaffeineType.coldBrew:
        return l10n.caffeineColdBrew;
      case CaffeineType.matcha:
        return l10n.caffeineMatcha;
      case CaffeineType.greenTea:
        return l10n.caffeineGreenTea;
      case CaffeineType.redBull:
        return l10n.caffeineRedBull;
      case CaffeineType.other:
        return l10n.caffeineOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = inCortisol ? const Color(0xFFFF9800) : tokens.accent;
    final name = _name(l10n);

    return Semantics(
      button: true,
      label: l10n.logDrinkSemantic(name, _mg[type] ?? 50),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icons[type] ?? Icons.coffee_rounded,
                color: color,
                size: 14,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l10n.mgValue(_mg[type] ?? 50),
                    style: TextStyle(color: tokens.fgDim, fontSize: 10),
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

// ---------------------------------------------------------------------------
// Searchable drink list card
// ---------------------------------------------------------------------------

class _DrinkListCard extends StatefulWidget {
  const _DrinkListCard({
    required this.tokens,
    required this.inCortisol,
    required this.items,
    required this.onAdd,
  });

  final OrchestraColorTokens tokens;
  final bool inCortisol;
  final List<CaffeineItem> items;
  final ValueChanged<CaffeineItem> onAdd;

  @override
  State<_DrinkListCard> createState() => _DrinkListCardState();
}

class _DrinkListCardState extends State<_DrinkListCard> {
  String _query = '';

  List<CaffeineItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      return item.title.values.any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final color = widget.inCortisol
        ? const Color(0xFFFF9800)
        : widget.tokens.accent;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addCaffeine,
            style: TextStyle(
              color: widget.tokens.fgBright,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          // Search field
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: widget.tokens.fgBright, fontSize: 14),
            cursorColor: widget.tokens.accent,
            decoration: InputDecoration(
              hintText: l10n.search,
              hintStyle: TextStyle(color: widget.tokens.fgDim, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: widget.tokens.fgDim,
                size: 18,
              ),
              filled: true,
              fillColor: widget.tokens.bg.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: widget.tokens.borderFaint,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: widget.tokens.borderFaint,
                  width: 0.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.tokens.accent),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Item list
          ..._filtered.map((item) {
            final name = item.localizedTitle(locale);
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (_) async {
                widget.onAdd(item);
                return false; // Don't remove the item from list
              },
              background: Container(
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsetsDirectional.only(start: 16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_rounded, color: color, size: 20),
              ),
              child: InkWell(
                onTap: () => widget.onAdd(item),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, color: color, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: widget.tokens.fgBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        l10n.mgValue(item.mg),
                        style: TextStyle(
                          color: widget.tokens.fgDim,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_left_rounded,
                        color: widget.tokens.fgDim,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
