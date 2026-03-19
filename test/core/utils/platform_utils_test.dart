import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/utils/platform_utils.dart';

void main() {
  group('platform_utils', () {
    // Running in VM (dart test) — kIsWeb is always false here
    test('isWeb is false in VM tests', () {
      expect(isWeb, isFalse);
    });

    test('isMobile is false on macOS/Linux/Windows CI', () {
      // On a desktop CI runner, isMobile must be false
      if (!isDesktop) return; // skip if not on desktop
      expect(isMobile, isFalse);
    });

    test('isDesktop and isMobile are mutually exclusive', () {
      expect(isDesktop && isMobile, isFalse);
    });

    test('isWeb, isDesktop, isMobile cover all platforms', () {
      // On any platform exactly one of these should be true
      final count = [isWeb, isDesktop, isMobile].where((v) => v).length;
      expect(count, 1);
    });
  });
}
