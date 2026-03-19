import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/web/dashboard/dashboard_screen.dart';
import 'package:orchestra/screens/web/features_list_screen.dart';

void main() {
  group('Web authenticated screens', () {
    test('DashboardScreen can be instantiated', () {
      expect(() => const DashboardScreen(), returnsNormally);
    });

    test('FeaturesListScreen can be instantiated', () {
      expect(() => const FeaturesListScreen(), returnsNormally);
    });
  });
}
