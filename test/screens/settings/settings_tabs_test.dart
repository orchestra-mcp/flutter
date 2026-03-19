import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/settings/tabs/notifications_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/security_settings_tab.dart';

void main() {
  group('Settings tab constructors', () {
    test('NotificationsSettingsTab can be instantiated', () {
      expect(() => const NotificationsSettingsTab(), returnsNormally);
    });

    test('SecuritySettingsTab can be instantiated', () {
      expect(() => const SecuritySettingsTab(), returnsNormally);
    });
  });
}
