import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/screens/splash/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    test('SplashScreen is a Widget type', () {
      // Verify the class exists and is a ConsumerStatefulWidget subtype.
      const widget = SplashScreen();
      expect(widget, isA<SplashScreen>());
    });

    test('Routes.splash equals /splash', () {
      expect(Routes.splash, '/splash');
    });
  });
}
