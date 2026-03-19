import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/health/health_service.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Health hub — scrollable grid of tappable summary cards.
///
/// Each card shows an icon, title, key metric from its Riverpod provider,
/// and navigates to the dedicated sub-route on tap.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  void initState() {
    super.initState();
    _requestHealthPermissions();
  }

  Future<void> _requestHealthPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final granted = await healthService.hasPermissions();
    if (!granted) {
      await healthService.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return ColoredBox(
      color: tokens.bg,
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).health,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.favorite_rounded,
                        color: tokens.accent, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // ── Card grid ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _HealthHubCard(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: l10n.healthScore,
                    route: Routes.healthScore,
                    subtitle: l10n.overall,
                  );
                }),
                _VitalsCard(),
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _HealthHubCard(
                    icon: Icons.auto_graph_rounded,
                    iconColor: const Color(0xFF818CF8),
                    title: l10n.dailyFlow,
                    route: Routes.healthFlow,
                    subtitle: l10n.routines,
                  );
                }),
                _HydrationCard(),
                _CaffeineCard(),
                _NutritionCard(),
                _PomodoroCard(),
                _ShutdownCard(),
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _HealthHubCard(
                    icon: Icons.monitor_weight_rounded,
                    iconColor: const Color(0xFF14B8A6),
                    title: l10n.weight,
                    route: Routes.healthWeight,
                    subtitle: l10n.trackLabel,
                  );
                }),
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _HealthHubCard(
                    icon: Icons.bedtime_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: l10n.sleep,
                    route: Routes.healthSleep,
                    subtitle: l10n.restLabel,
                  );
                }),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

String _localizedPhase(AppLocalizations l10n, PomodoroPhase phase) =>
    switch (phase) {
      PomodoroPhase.work => l10n.focus,
      PomodoroPhase.shortBreak => l10n.shortBreak,
      PomodoroPhase.longBreak => l10n.longBreak,
      PomodoroPhase.standAlert => l10n.standUp,
      PomodoroPhase.idle => l10n.ready,
    };

// ---------------------------------------------------------------------------
// Static hub card (no live data)
// ---------------------------------------------------------------------------

class _HealthHubCard extends StatelessWidget {
  const _HealthHubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.route,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String route;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return GlassCard(
      onTap: () => context.go(route),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vitals card
// ---------------------------------------------------------------------------

class _VitalsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    const color = Color(0xFFF43F5E);

    return GlassCard(
      onTap: () => context.go(Routes.healthVitals),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.monitor_heart_rounded,
                color: color, size: 22),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).vitals,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).heartAndBody,
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hydration card (live data)
// ---------------------------------------------------------------------------

class _HydrationCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(hydrationProvider);
    const color = Color(0xFF38BDF8);

    return GlassCard(
      onTap: () => context.go(Routes.healthHydration),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: color, size: 22),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).hydration,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${state.totalMl} / ${state.goalMl} ml',
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caffeine card (live data)
// ---------------------------------------------------------------------------

class _CaffeineCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(caffeineProvider);
    const color = Color(0xFFF97316);

    final l10n = AppLocalizations.of(context);
    final statusLabel = switch (state.status) {
      CaffeineStatus.noIntake => l10n.caffeineNoIntake,
      CaffeineStatus.clean => l10n.caffeineClean,
      CaffeineStatus.transitioning => l10n.caffeineTransitioning,
      CaffeineStatus.redBullDependent => l10n.caffeineRedBullDep,
    };

    return GlassCard(
      onTap: () => context.go(Routes.healthCaffeine),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.coffee_rounded, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            l10n.caffeine,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.caffeineMgStatus(state.totalMg, statusLabel),
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nutrition card (live data)
// ---------------------------------------------------------------------------

class _NutritionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(nutritionProvider);
    const color = Color(0xFF4ADE80);

    final meals = state.todayEntries.length;

    return GlassCard(
      onTap: () => context.go(Routes.healthNutrition),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: color, size: 22),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).nutrition,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).mealsCount(meals, state.safetyScore.toStringAsFixed(0)),
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pomodoro card (live data)
// ---------------------------------------------------------------------------

class _PomodoroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(pomodoroProvider);
    const color = Color(0xFFF97316);

    return GlassCard(
      onTap: () => context.go(Routes.healthPomodoro),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_rounded, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            AppLocalizations.of(context).pomodoro,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${state.completedToday}/${state.dailyTarget} · ${_localizedPhase(AppLocalizations.of(context), state.phase)}',
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shutdown card (live data)
// ---------------------------------------------------------------------------

class _ShutdownCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final state = ref.watch(shutdownProvider);
    const color = Color(0xFF6366F1);

    final l10n = AppLocalizations.of(context);
    final phaseLabel = switch (state.phase) {
      ShutdownPhase.inactive => l10n.shutdownInactive,
      ShutdownPhase.active => l10n.shutdownActive,
      ShutdownPhase.violated => l10n.shutdownPhaseViolated,
    };

    return GlassCard(
      onTap: () => context.go(Routes.healthShutdown),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.nightlight_rounded,
                color: color, size: 22),
          ),
          const Spacer(),
          Text(
            l10n.shutdown,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phaseLabel,
            style: TextStyle(color: tokens.fgMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
