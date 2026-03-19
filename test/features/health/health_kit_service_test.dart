import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/health/health_kit_service.dart';

void main() {
  group('HealthKitService (non-platform test environment)', () {
    final service = HealthKitService.instance;

    test('requestAuthorization returns false on non-health platform', () async {
      final result = await service.requestAuthorization();
      expect(result, isFalse);
    });

    test('hasPermissions returns false before authorization', () async {
      expect(await service.hasPermissions(), isFalse);
    });

    test('getTodaySteps returns null when not authorized', () async {
      expect(await service.getTodaySteps(), isNull);
    });

    test('getTodayEnergy returns null when not authorized', () async {
      expect(await service.getTodayEnergy(), isNull);
    });

    test('getLatestHeartRate returns null when not authorized', () async {
      expect(await service.getLatestHeartRate(), isNull);
    });

    test('getLatestWeight returns null when not authorized', () async {
      expect(await service.getLatestWeight(), isNull);
    });

    test('getBodyFat returns null when not authorized', () async {
      expect(await service.getBodyFat(), isNull);
    });
  });
}
