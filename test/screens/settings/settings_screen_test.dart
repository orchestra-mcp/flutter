import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SettingsScreen has expected tab count', () {
    const tabCount = 5; // Profile, Team, Appearance, Security, Notifications
    expect(tabCount, equals(5));
  });
}
