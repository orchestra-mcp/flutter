import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/screens/health/tabs/caffeine_tab.dart';
import 'package:orchestra/screens/health/tabs/daily_flow_tab.dart';
import 'package:orchestra/screens/health/tabs/hydration_tab.dart';
import 'package:orchestra/screens/health/tabs/nutrition_tab.dart';
import 'package:orchestra/screens/health/tabs/pomodoro_tab.dart';
import 'package:orchestra/screens/health/tabs/shutdown_tab.dart';

// =============================================================================
// Test color tokens — avoids pulling in real theme / InheritedWidget
// =============================================================================

const _testTokens = OrchestraColorTokens(
  bg: Color(0xFF1A1A2E),
  bgAlt: Color(0xFF16213E),
  fgBright: Color(0xFFEEEEEE),
  fgMuted: Color(0xFFAAAAAA),
  fgDim: Color(0xFF666666),
  border: Color(0xFF333355),
  accent: Color(0xFF6C63FF),
  accentAlt: Color(0xFF9D4EDD),
  glass: Color(0x1FFFFFFF),
  isLight: false,
);

/// Wraps [child] in MaterialApp + ThemeTokens so all tab widgets can resolve
/// tokens and overlay / scaffold ancestors.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: ThemeTokens(
      tokens: _testTokens,
      child: Scaffold(body: child),
    ),
  );
}

// =============================================================================
// Test notifiers — return controlled state from build(), avoid API calls
// =============================================================================

class _TestHydrationNotifier extends HydrationNotifier {
  _TestHydrationNotifier(this._initial);
  final HydrationState _initial;

  @override
  HydrationState build() => _initial;

  @override
  Future<void> refresh() async {}
}

class _TestCaffeineNotifier extends CaffeineNotifier {
  _TestCaffeineNotifier(this._initial, {this.cortisolWindow = false});
  final CaffeineState _initial;
  final bool cortisolWindow;

  @override
  CaffeineState build() => _initial;

  @override
  bool isCortisolWindow() => cortisolWindow;

  @override
  Future<void> refresh() async {}
}

class _TestNutritionNotifier extends NutritionNotifier {
  _TestNutritionNotifier(this._initial);
  final NutritionState _initial;

  @override
  NutritionState build() => _initial;

  @override
  Future<void> refresh() async {}
}

class _TestPomodoroNotifier extends PomodoroNotifier {
  _TestPomodoroNotifier(this._initial);
  final PomodoroState _initial;

  @override
  PomodoroState build() => _initial;

  @override
  Future<void> refresh() async {}
}

class _TestShutdownNotifier extends ShutdownNotifier {
  _TestShutdownNotifier(this._initial);
  final ShutdownState _initial;

  @override
  ShutdownState build() => _initial;

  @override
  Future<void> refresh() async {}
}

// =============================================================================
// HYDRATION TAB TESTS
// =============================================================================

void main() {
  group('HydrationTab', () {
    testWidgets('loading state shows shimmer indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () =>
                  _TestHydrationNotifier(const HydrationState(isLoading: true)),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      // The shimmer is a 4px tall animated container rendered when isLoading.
      // It should not render the "No water logged yet" text.
      expect(find.text('No water logged yet'), findsNothing);
      // Quick Add section should still render.
      expect(find.text('Quick Add'), findsOneWidget);
    });

    testWidgets('error state shows error banner with retry', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(
                const HydrationState(error: 'Network failure'),
              ),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      expect(find.text('Network failure'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('gout flush card visible when totalMl < 1500', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(
                const HydrationState(totalMl: 500, goalMl: 2500),
              ),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      expect(find.text('Gout Flush Recommended'), findsOneWidget);
    });

    testWidgets('gout flush card hidden when totalMl >= 1500', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(
                const HydrationState(totalMl: 2000, goalMl: 2500),
              ),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      expect(find.text('Gout Flush Recommended'), findsNothing);
    });

    testWidgets('quick-add buttons render all four amounts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(const HydrationState()),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      expect(find.text('150ml'), findsOneWidget);
      expect(find.text('250ml'), findsOneWidget);
      expect(find.text('350ml'), findsOneWidget);
      expect(find.text('500ml'), findsOneWidget);
    });

    testWidgets('empty state shows when no entries and not loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(const HydrationState()),
            ),
          ],
          child: _wrap(const HydrationTab()),
        ),
      );
      await tester.pump();

      expect(find.text('No water logged yet'), findsOneWidget);
    });
  });

  // ===========================================================================
  // CAFFEINE TAB TESTS
  // ===========================================================================

  group('CaffeineTab', () {
    testWidgets('loading state shows shimmer placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caffeineProvider.overrideWith(
              () => _TestCaffeineNotifier(const CaffeineState(isLoading: true)),
            ),
          ],
          child: _wrap(const CaffeineTab()),
        ),
      );
      await tester.pump();

      // When loading, the tab returns the shimmer placeholder. The daily
      // summary card and drink chips should not be present.
      expect(find.text('Log Drink'), findsNothing);
      expect(find.text('Total caffeine today'), findsNothing);
    });

    testWidgets('daily limit progress bar renders with data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caffeineProvider.overrideWith(
              () => _TestCaffeineNotifier(const CaffeineState(totalMg: 200)),
            ),
          ],
          child: _wrap(const CaffeineTab()),
        ),
      );
      await tester.pump();

      // The daily summary card shows total mg and progress text.
      expect(find.text('200 mg'), findsOneWidget);
      expect(find.text('Total caffeine today'), findsOneWidget);
      expect(find.text('200 mg remaining'), findsOneWidget);
      // LinearProgressIndicator is rendered inside the summary card.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('cortisol banner shows when in cortisol window', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caffeineProvider.overrideWith(
              () => _TestCaffeineNotifier(
                const CaffeineState(totalMg: 100),
                cortisolWindow: true,
              ),
            ),
          ],
          child: _wrap(const CaffeineTab()),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Cortisol window active \u2014 caffeine is not recommended right now.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cortisol banner hidden when outside cortisol window', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            caffeineProvider.overrideWith(
              () => _TestCaffeineNotifier(
                const CaffeineState(totalMg: 100),
                cortisolWindow: false,
              ),
            ),
          ],
          child: _wrap(const CaffeineTab()),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Cortisol window active \u2014 caffeine is not recommended right now.',
        ),
        findsNothing,
      );
    });
  });

  // ===========================================================================
  // NUTRITION TAB TESTS
  // ===========================================================================

  group('NutritionTab', () {
    testWidgets('loading state shows shimmer skeleton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionProvider.overrideWith(
              () =>
                  _TestNutritionNotifier(const NutritionState(isLoading: true)),
            ),
          ],
          child: _wrap(const NutritionTab()),
        ),
      );
      await tester.pump();

      // Safety Score card should not render when loading with no entries.
      expect(find.text('Safety Score'), findsNothing);
    });

    testWidgets('safety score arc gauge renders with data', (tester) async {
      final now = DateTime.now();
      final entries = [
        NutritionEntry(
          id: '1',
          food: const FoodItem(
            title: {'en': 'Grilled Chicken'},
            category: FoodCategory.protein,
          ),
          portionSpoons: 2.0,
          timestamp: now,
        ),
        NutritionEntry(
          id: '2',
          food: const FoodItem(
            title: {'en': 'Rice'},
            category: FoodCategory.carb,
          ),
          portionSpoons: 3.0,
          timestamp: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionProvider.overrideWith(
              () => _TestNutritionNotifier(NutritionState(entries: entries)),
            ),
          ],
          child: _wrap(const NutritionTab()),
        ),
      );
      await tester.pump();

      // Safety Score heading and the /100 label inside the arc gauge.
      expect(find.text('Safety Score'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      // CustomPaint is used for the arc gauge.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('empty meal state shows when no entries', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            nutritionProvider.overrideWith(
              () => _TestNutritionNotifier(const NutritionState()),
            ),
          ],
          child: _wrap(const NutritionTab()),
        ),
      );
      await tester.pump();

      expect(find.text('No meals logged today'), findsOneWidget);
    });
  });

  // ===========================================================================
  // POMODORO TAB TESTS
  // ===========================================================================

  group('PomodoroTab', () {
    testWidgets('loading state shows shimmer skeleton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pomodoroProvider.overrideWith(
              () => _TestPomodoroNotifier(const PomodoroState(isLoading: true)),
            ),
          ],
          child: _wrap(const PomodoroTab()),
        ),
      );
      await tester.pump();

      // Timer controls should not be present during loading.
      expect(find.text('Ready'), findsNothing);
      expect(find.text('Daily Progress'), findsNothing);
    });

    testWidgets('idle state renders controls and Ready label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pomodoroProvider.overrideWith(
              () => _TestPomodoroNotifier(const PomodoroState()),
            ),
          ],
          child: _wrap(const PomodoroTab()),
        ),
      );
      await tester.pump();

      // Phase label shows "Ready" in idle.
      expect(find.text('Ready'), findsOneWidget);
      // Play button is a FilledButton with play_arrow icon.
      expect(find.byType(FilledButton), findsOneWidget);
      // Timer display shows "25:00".
      expect(find.text('25:00'), findsOneWidget);
      // Daily stats show.
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets(
      'insight card shows Ready to Focus when idle with 0 completed',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pomodoroProvider.overrideWith(
                () => _TestPomodoroNotifier(const PomodoroState()),
              ),
            ],
            child: _wrap(const PomodoroTab()),
          ),
        );
        await tester.pump();

        expect(find.text('Ready to Focus'), findsOneWidget);
        expect(
          find.text('Start your first session to build momentum today.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'insight card shows Target Reached when completed >= dailyTarget',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pomodoroProvider.overrideWith(
                () => _TestPomodoroNotifier(
                  const PomodoroState(completedToday: 8, dailyTarget: 8),
                ),
              ),
            ],
            child: _wrap(const PomodoroTab()),
          ),
        );
        await tester.pump();

        expect(find.text('Target Reached!'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SHUTDOWN TAB TESTS
  // ===========================================================================

  group('ShutdownTab', () {
    testWidgets('loading state shows shimmer skeleton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(const ShutdownState(isLoading: true)),
            ),
          ],
          child: _wrap(const ShutdownTab()),
        ),
      );
      await tester.pump();

      // Shimmer skeleton replaces the whole tab content.
      expect(find.text('Evening Routine'), findsNothing);
      expect(find.text('Start Shutdown'), findsNothing);
    });

    testWidgets('inactive phase shows Start Shutdown button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(const ShutdownState()),
            ),
          ],
          child: _wrap(const ShutdownTab()),
        ),
      );
      await tester.pump();

      expect(find.text('Start Shutdown'), findsOneWidget);
      expect(find.text('Wind down for the night'), findsOneWidget);
      expect(find.text('Not Active'), findsOneWidget);
    });

    testWidgets('active phase shows countdown card and checklist', (
      tester,
    ) async {
      final sleepTime = DateTime.now().add(const Duration(hours: 2));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(
                ShutdownState(
                  phase: ShutdownPhase.active,
                  targetSleepTime: sleepTime,
                  timeUntilSleep: const Duration(hours: 1, minutes: 45),
                ),
              ),
            ),
          ],
          child: _wrap(const ShutdownTab()),
        ),
      );
      await tester.pump();

      // Phase badge shows "Shutdown Active".
      expect(find.text('Shutdown Active'), findsOneWidget);
      // Countdown card shows target bedtime.
      expect(find.text('Target bedtime'), findsOneWidget);
      expect(find.text('Time left'), findsOneWidget);
      // Checklist renders.
      expect(find.text('Evening Routine'), findsOneWidget);
      // First routine item renders.
      expect(find.text('Stop screens'), findsOneWidget);
    });

    testWidgets('violated phase shows violated banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(
                const ShutdownState(phase: ShutdownPhase.violated),
              ),
            ),
          ],
          child: _wrap(const ShutdownTab()),
        ),
      );
      await tester.pump();

      expect(find.text('Shutdown violated'), findsOneWidget);
      expect(find.text('Violated'), findsOneWidget);
    });
  });

  // ===========================================================================
  // DAILY FLOW TAB TESTS
  // ===========================================================================

  group('DailyFlowTab', () {
    testWidgets('component scores render from providers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pomodoroProvider.overrideWith(
              () => _TestPomodoroNotifier(
                const PomodoroState(completedToday: 4, dailyTarget: 8),
              ),
            ),
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(
                const HydrationState(totalMl: 1250, goalMl: 2500),
              ),
            ),
            nutritionProvider.overrideWith(
              () => _TestNutritionNotifier(const NutritionState()),
            ),
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(const ShutdownState()),
            ),
          ],
          child: _wrap(const DailyFlowTab()),
        ),
      );
      await tester.pump();

      // The Component Breakdown heading should be rendered.
      expect(find.text('Component Breakdown'), findsOneWidget);

      // Each component label should appear.
      expect(find.text('Pomodoro'), findsOneWidget);
      expect(find.text('Hydration'), findsOneWidget);
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Shutdown'), findsOneWidget);

      // Weight labels should appear.
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);

      // The flow ring heading is present.
      expect(find.text('Daily Flow'), findsOneWidget);

      // Weekly chart heading.
      expect(find.text('This Week'), findsOneWidget);

      // Component progress bars render (4 in breakdown + weekly bar chart).
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });

    testWidgets('insight text reflects weakest component', (tester) async {
      // Hydration at 0%, all others higher -- insight should mention hydration.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pomodoroProvider.overrideWith(
              () => _TestPomodoroNotifier(
                const PomodoroState(completedToday: 8, dailyTarget: 8),
              ),
            ),
            hydrationProvider.overrideWith(
              () => _TestHydrationNotifier(
                const HydrationState(totalMl: 0, goalMl: 2500),
              ),
            ),
            nutritionProvider.overrideWith(
              () => _TestNutritionNotifier(const NutritionState()),
            ),
            shutdownProvider.overrideWith(
              () => _TestShutdownNotifier(
                const ShutdownState(phase: ShutdownPhase.active),
              ),
            ),
          ],
          child: _wrap(const DailyFlowTab()),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'You are behind on hydration. '
          'Have a glass of water now to catch up.',
        ),
        findsOneWidget,
      );
    });
  });
}
