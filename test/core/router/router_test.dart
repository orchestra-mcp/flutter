import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/router/app_router.dart';

void main() {
  group('Routes constants', () {
    test('auth routes are correct', () {
      expect(Routes.splash, '/splash');
      expect(Routes.onboarding, '/onboarding');
      expect(Routes.login, '/login');
      expect(Routes.register, '/register');
      expect(Routes.forgotPassword, '/forgot-password');
      expect(Routes.resetPassword, '/reset-password');
      expect(Routes.twoFactor, '/two-factor');
      expect(Routes.magicLogin, '/magic-login');
      expect(Routes.passkey, '/passkey');
      expect(Routes.authCallback, '/auth/callback');
      expect(Routes.authMagic, '/auth/magic');
    });

    test('shell routes are correct', () {
      expect(Routes.summary, '/summary');
      expect(Routes.notifications, '/notifications');
    });

    test('dynamic project routes interpolate correctly', () {
      expect(Routes.project('abc'), '/projects/abc');
      expect(Routes.projectTree('xyz'), '/projects/xyz/tree');
    });

    test('dynamic library routes interpolate correctly', () {
      expect(Routes.note('n-1'), '/library/notes/n-1');
      expect(Routes.agent('a-1'), '/library/agents/a-1');
      expect(Routes.skill('s-1'), '/library/skills/s-1');
      expect(Routes.workflow('w-1'), '/library/workflows/w-1');
      expect(Routes.doc('d-1'), '/library/docs/d-1');
    });

    test('settings routes are correct', () {
      expect(Routes.settings, '/settings');
      expect(Routes.settingsProfile, '/settings/profile');
      expect(Routes.settingsTeam, '/settings/team');
      expect(Routes.settingsAppearance, '/settings/appearance');
      expect(Routes.settingsSecurity, '/settings/security');
      expect(Routes.settingsNotifications, '/settings/notifications');
      expect(Routes.settingsAbout, '/settings/about');
    });

    test('health and search routes are correct', () {
      expect(Routes.health, '/health');
      expect(Routes.search, '/search');
    });
  });
}
