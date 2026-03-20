import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/providers/health_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/settings/tabs/health_settings_tab.dart';

const _testTokens = OrchestraColorTokens(
  bg: Color(0xFF0A0A0A),
  bgAlt: Color(0xFF1A1A2E),
  fgBright: Color(0xFFF0F0F0),
  fgMuted: Color(0xFFA0A0A0),
  fgDim: Color(0xFF606060),
  border: Color(0xFF333333),
  accent: Color(0xFF38BDF8),
  accentAlt: Color(0xFFA78BFA),
  glass: Color(0x1F1A1A2E),
  isLight: false,
);

/// A sample profile map with all keys the tab reads.
Map<String, dynamic> _sampleProfile() => {
  'weightAlertEnabled': true,
  'weightAlertHour': 8,
  'weightAlertMinute': 30,
  'weightAlertDelayDays': 2,
  'hygieneAlertEnabled': false,
  'hygieneAlertDelayDays': 1,
  'pomodoroStartAlertEnabled': true,
  'pomodoroStartLeadMinutes': 10,
  'pomodoroEndAlertEnabled': false,
  'pomodoroEndLeadMinutes': 5,
  'heartRateHighThreshold': 140,
  'heartRateLowThreshold': 45,
  'mealReminderEnabled': true,
  'coffeeAlertEnabled': true,
  'coffeeAlertHour': 15,
  'coffeeAlertMinute': 0,
  'hydrationAlertEnabled': true,
  'hydrationAlertGapMinutes': 90,
  'movementAlertEnabled': false,
  'movementAlertIntervalMinutes': 60,
  'gerdShutdownLeadMinutes': 20,
  'sleepBedtimeHour': 22,
  'sleepBedtimeMinute': 45,
  'shutdownWindowHours': 3,
};

void main() {
  group('HealthSettingsTab', () {
    testWidgets('shows loading indicator while health profile loads', (
      tester,
    ) async {
      final completer = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) => completer.future),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith(
              (ref) => Future<Map<String, dynamic>>.error('network down'),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load health profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows section headers when profile loads', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);

      // Sleep section may be off-screen in the ListView — scroll to reveal it.
      await tester.scrollUntilVisible(
        find.text('Sleep'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('renders all toggle labels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weight Check-in'), findsOneWidget);
      expect(find.text('Hygiene Reminder'), findsOneWidget);
      expect(find.text('Pomodoro Start Alert'), findsOneWidget);
      expect(find.text('Pomodoro End Alert'), findsOneWidget);
      expect(find.text('Meal Reminder'), findsOneWidget);
      expect(find.text('Coffee Time'), findsOneWidget);
      expect(find.text('Hydration Alert'), findsOneWidget);
      expect(find.text('Movement Alert'), findsOneWidget);
    });

    testWidgets('renders heart rate steppers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate High'), findsOneWidget);
      expect(find.text('Heart Rate Low'), findsOneWidget);
      expect(find.text('140 bpm'), findsOneWidget);
      expect(find.text('45 bpm'), findsOneWidget);
    });

    testWidgets('renders GERD warning stepper', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GERD Warning'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
    });

    testWidgets('shows conditional sub-rows when toggle is on', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Weight is enabled -> should show Alert Time and Delay Days
      expect(find.text('Alert Time'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);

      // Pomodoro Start is enabled -> should show Lead Time
      expect(find.textContaining('Lead Time'), findsAtLeastNWidgets(1));
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('hides conditional sub-rows when toggle is off', (
      tester,
    ) async {
      final profile = _sampleProfile();
      profile['weightAlertEnabled'] = false;
      profile['coffeeAlertEnabled'] = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => profile),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Weight sub-rows should not be visible
      expect(find.text('08:30'), findsNothing);
      expect(find.text('2 days'), findsNothing);

      // Coffee cutoff time should not be visible
      expect(find.text('Cutoff Time'), findsNothing);
    });

    testWidgets('renders sleep section with bedtime and shutdown window', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to reveal the Sleep section.
      await tester.scrollUntilVisible(
        find.text('Bedtime'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('22:45'), findsOneWidget);
      expect(find.text('Shutdown Window'), findsOneWidget);
      expect(find.text('3 hrs'), findsOneWidget);
    });

    testWidgets('renders correct number of switches', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 8 toggle rows = 8 switches
      expect(find.byType(Switch), findsNWidgets(8));
    });

    testWidgets('renders with all defaults when profile is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{},
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: HealthSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should still render sections without crashing
      expect(find.text('Notifications'), findsOneWidget);

      // All toggles off = no conditional sub-rows visible
      expect(find.text('Alert Time'), findsNothing);
      expect(find.text('Cutoff Time'), findsNothing);

      // Default heart rate values
      expect(find.text('120 bpm'), findsOneWidget);
      expect(find.text('50 bpm'), findsOneWidget);

      // Scroll to reveal the Sleep section (may be off-screen).
      await tester.scrollUntilVisible(
        find.text('Sleep'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sleep'), findsOneWidget);

      // Default bedtime and shutdown
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('2 hrs'), findsOneWidget);
    });
  });
}
