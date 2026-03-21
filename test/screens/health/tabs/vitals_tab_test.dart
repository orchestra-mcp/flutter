import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/health/health_service.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/health/tabs/vitals_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Test color tokens
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

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ThemeTokens(
      tokens: _testTokens,
      child: Scaffold(body: child),
    ),
  );
}

// =============================================================================
// Mock HealthService
// =============================================================================

class _MockHealthService implements HealthService {
  _MockHealthService({
    this.hasPerms = false,
    this.requestPermsResult = true,
    this.steps,
    this.heartRate,
    this.calories,
    this.sleepHours,
    this.weight,
    this.heartRateRange,
    this.bloodOxygen,
    this.respiratoryRate,
  });

  final bool hasPerms;
  final bool requestPermsResult;
  final int? steps;
  final int? heartRate;
  final double? calories;
  final double? sleepHours;
  final double? weight;
  final ({int min, int max})? heartRateRange;
  final double? bloodOxygen;
  final double? respiratoryRate;

  @override
  Future<bool> hasPermissions() async => hasPerms;

  @override
  Future<bool> requestPermissions() async => requestPermsResult;

  @override
  Future<int?> getSteps(DateTime date) async => steps;

  @override
  Future<int?> getHeartRate(DateTime date) async => heartRate;

  @override
  Future<double?> getActiveCalories(DateTime date) async => calories;

  @override
  Future<double?> getSleepHours(DateTime date) async => sleepHours;

  @override
  Future<double?> getLatestWeight() async => weight;

  @override
  Future<double?> getBodyFat() async => null;

  @override
  Future<({int min, int max})?> getHeartRateRange(DateTime date) async =>
      heartRateRange;

  @override
  Future<double?> getBloodOxygen(DateTime date) async => bloodOxygen;

  @override
  Future<double?> getRespiratoryRate(DateTime date) async => respiratoryRate;
}

// =============================================================================
// Mock ApiClient — uses noSuchMethod for unneeded methods
// =============================================================================

class _MockApiClient implements ApiClient {
  _MockApiClient({this.snapshots = const [], this.shouldThrowOnUpsert = false});

  final List<Map<String, dynamic>> snapshots;
  final bool shouldThrowOnUpsert;

  // Track calls
  Map<String, dynamic>? lastUpsertBody;

  @override
  Future<List<Map<String, dynamic>>> listSnapshots({
    String? from,
    String? to,
  }) async => snapshots;

  @override
  Future<Map<String, dynamic>> upsertSnapshot(Map<String, dynamic> body) async {
    lastUpsertBody = body;
    if (shouldThrowOnUpsert) throw Exception('network error');
    return {};
  }

  // All other methods are unused in these tests — forward via noSuchMethod.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// =============================================================================
// Helpers
// =============================================================================

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('VitalsTab', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no permissions', (tester) async {
      final health = _MockHealthService(hasPerms: false);
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Connect Health'), findsOneWidget);
    });

    testWidgets('shows all vitals data after permissions granted', (
      tester,
    ) async {
      final health = _MockHealthService(
        hasPerms: true,
        steps: 8432,
        heartRate: 68,
        calories: 1245.0,
        heartRateRange: (min: 55, max: 110),
        sleepHours: 7.3,
        weight: 81.5,
        bloodOxygen: 98.0,
        respiratoryRate: 16.2,
      );
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      // Steps
      expect(find.text('8 432'), findsOneWidget);

      // Heart rate
      expect(find.text('68'), findsOneWidget);
      expect(find.text('Min 55  Max 110'), findsOneWidget);

      // Calories
      expect(find.text('1 245'), findsOneWidget);

      // Sleep
      expect(find.text('7.3'), findsOneWidget);
      expect(find.text('hours'), findsOneWidget);

      // Weight
      expect(find.text('81.5'), findsAtLeastNWidgets(1));
      expect(find.text('kg'), findsAtLeastNWidgets(1));

      // Blood Oxygen
      expect(find.text('98'), findsOneWidget);
      expect(find.text('Blood O\u2082'), findsOneWidget);

      // Respiratory Rate
      expect(find.text('16.2'), findsOneWidget);
      expect(find.text('Breathing'), findsOneWidget);

      // No old mock values
      expect(find.text('6540'), findsNothing);
      expect(find.text('72'), findsNothing);
      expect(find.text('1 840'), findsNothing);
    });

    testWidgets('shows dash when data is null', (tester) async {
      final health = _MockHealthService(
        hasPerms: true,
        steps: null,
        heartRate: null,
        calories: null,
        sleepHours: null,
        weight: null,
        bloodOxygen: null,
        respiratoryRate: null,
        heartRateRange: null,
      );
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('6540'), findsNothing);
      expect(find.text('72'), findsNothing);
      expect(find.text('1 840'), findsNothing);
      expect(find.text('No range data'), findsOneWidget);
    });

    testWidgets('persists permission state in SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      final health = _MockHealthService(
        hasPerms: false,
        requestPermsResult: true,
        steps: 5000,
        heartRate: 75,
        calories: 900.0,
      );
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect Health'), findsOneWidget);

      await tester.tap(find.text('Connect Health'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('health_permissions_granted'), isTrue);
    });

    testWidgets('loads from cached permission on restart', (tester) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(
        hasPerms: true,
        steps: 3200,
        heartRate: 80,
        calories: 600.0,
        heartRateRange: (min: 60, max: 95),
        sleepHours: 6.5,
        weight: 79.0,
        bloodOxygen: 97.0,
        respiratoryRate: 15.0,
      );
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Health Data'), findsNothing);
      expect(find.text('3 200'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('97'), findsOneWidget);
      expect(find.text('15.0'), findsOneWidget);
    });

    testWidgets('Zepp Scale weight pre-fills from HealthKit', (tester) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(hasPerms: true, weight: 83.7);
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      // The Zepp Scale weight field should show the HealthKit weight
      final weightFields = tester.widgetList<TextField>(find.byType(TextField));
      final weightField = weightFields.first;
      expect(weightField.controller?.text, '83.7');
    });

    testWidgets('Zepp Scale pre-fills from snapshot when no HealthKit weight', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(hasPerms: true, weight: null);
      final api = _MockApiClient(
        snapshots: [
          {
            'snapshot_date': '2026-03-20',
            'weight_kg': 80.5,
            'body_fat_pct': 19.3,
            'metabolic_age': 31,
            'visceral_fat': 7,
            'body_water_pct': 59.1,
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      // weight, bodyFat, metAge, visceral, water (in order)
      expect(fields[0].controller?.text, '80.5');
      expect(fields[1].controller?.text, '19.3');
      expect(fields[2].controller?.text, '31');
      expect(fields[3].controller?.text, '7');
      expect(fields[4].controller?.text, '59.1');
    });

    testWidgets('Zepp Scale HealthKit weight overrides snapshot weight', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      // HealthKit has 82.0, snapshot has 79.0 — HealthKit wins for weight
      final health = _MockHealthService(hasPerms: true, weight: 82.0);
      final api = _MockApiClient(
        snapshots: [
          {
            'snapshot_date': '2026-03-20',
            'weight_kg': 79.0,
            'body_fat_pct': 21.0,
          },
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].controller?.text, '82.0'); // HealthKit weight wins
      expect(
        fields[1].controller?.text,
        '21',
      ); // body fat from snapshot (whole number drops decimal)
    });

    testWidgets('Save button calls upsertSnapshot with form values', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(
        hasPerms: true,
        weight: 80.0,
        steps: 5000,
        calories: 400.0,
        heartRate: 70,
        sleepHours: 7.0,
      );
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Save Measurements'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(find.text('Save Measurements'));
      await tester.pumpAndSettle();

      // Verify upsertSnapshot was called
      expect(api.lastUpsertBody, isNotNull);
      expect(api.lastUpsertBody!['weight_kg'], 80.0);
      expect(api.lastUpsertBody!['steps'], 5000);
      expect(api.lastUpsertBody!['active_energy_cal'], 400.0);
      expect(api.lastUpsertBody!['avg_heart_rate'], 70);
      expect(api.lastUpsertBody!['sleep_hours'], 7.0);
      expect(api.lastUpsertBody!.containsKey('snapshot_date'), isTrue);
    });

    testWidgets('Save button shows success snackbar', (tester) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(hasPerms: true, weight: 80.0);
      final api = _MockApiClient();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Save Measurements'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(find.text('Save Measurements'));
      await tester.pump(); // kick off async save
      await tester.pump(
        const Duration(seconds: 1),
      ); // finish save + show snackbar

      expect(find.text('Settings saved'), findsOneWidget);
    });

    testWidgets('Save button shows error snackbar on failure', (tester) async {
      SharedPreferences.setMockInitialValues({
        'health_permissions_granted': true,
      });

      final health = _MockHealthService(hasPerms: true, weight: 80.0);
      final api = _MockApiClient(shouldThrowOnUpsert: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthServiceProvider.overrideWithValue(health),
            apiClientProvider.overrideWithValue(api),
          ],
          child: _wrap(const VitalsTab()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Save Measurements'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(find.text('Save Measurements'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Failed to save'), findsOneWidget);
    });
  });
}
