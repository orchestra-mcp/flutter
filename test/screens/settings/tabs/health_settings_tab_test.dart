import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/providers/health_provider.dart';
import 'package:orchestra/screens/settings/tabs/health_settings_tab.dart';

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
    testWidgets('shows loading indicator while health profile loads',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith(
            (ref) => Future<Map<String, dynamic>>.delayed(
              const Duration(seconds: 10),
              () => {},
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith(
            (ref) => Future<Map<String, dynamic>>.error('network down'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load health profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows section headers when profile loads', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('renders all toggle labels', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
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
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Heart Rate High'), findsOneWidget);
      expect(find.text('Heart Rate Low'), findsOneWidget);
      expect(find.text('140 bpm'), findsOneWidget);
      expect(find.text('45 bpm'), findsOneWidget);
    });

    testWidgets('renders GERD warning stepper', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('GERD Warning'), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
    });

    testWidgets('shows conditional sub-rows when toggle is on',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      // Weight is enabled → should show Alert Time and Delay Days
      expect(find.text('Alert Time'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);

      // Pomodoro Start is enabled → should show Lead Time
      expect(find.textContaining('Lead Time'), findsAtLeastNWidgets(1));
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('hides conditional sub-rows when toggle is off',
        (tester) async {
      final profile = _sampleProfile();
      profile['weightAlertEnabled'] = false;
      profile['coffeeAlertEnabled'] = false;

      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => profile),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      // Weight sub-rows should not be visible
      expect(find.text('08:30'), findsNothing);
      expect(find.text('2 days'), findsNothing);

      // Coffee cutoff time should not be visible
      expect(find.text('Cutoff Time'), findsNothing);
    });

    testWidgets('renders sleep section with bedtime and shutdown window',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bedtime'), findsOneWidget);
      expect(find.text('22:45'), findsOneWidget);
      expect(find.text('Shutdown Window'), findsOneWidget);
      expect(find.text('3 hrs'), findsOneWidget);
    });

    testWidgets('renders correct number of switches', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider.overrideWith((ref) async => _sampleProfile()),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      // 8 toggle rows = 8 switches
      expect(find.byType(Switch), findsNWidgets(8));
    });

    testWidgets('renders with all defaults when profile is empty',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          healthProfileProvider
              .overrideWith((ref) async => <String, dynamic>{}),
        ],
        child: const MaterialApp(home: Scaffold(body: HealthSettingsTab())),
      ));
      await tester.pumpAndSettle();

      // Should still render sections without crashing
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);

      // All toggles off = no conditional sub-rows visible
      expect(find.text('Alert Time'), findsNothing);
      expect(find.text('Cutoff Time'), findsNothing);

      // Default heart rate values
      expect(find.text('120 bpm'), findsOneWidget);
      expect(find.text('50 bpm'), findsOneWidget);

      // Default bedtime and shutdown
      expect(find.text('23:00'), findsOneWidget);
      expect(find.text('2 hrs'), findsOneWidget);
    });
  });
}
