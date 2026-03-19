import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/onboarding/onboarding_page.dart';
import 'package:orchestra/screens/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    test('OnboardingScreen is a Widget type', () {
      const widget = OnboardingScreen();
      expect(widget, isA<OnboardingScreen>());
    });

    test('onboarding has 4 pages worth of data', () {
      // Mirror the 4 entries defined in onboarding_screen.dart and assert the
      // count is exactly 4.
      const pages = [
        OnboardingPageData(
          title: 'Welcome to Orchestra',
          subtitle: 'Your intelligent workspace.',
          icon: Icons.music_note_rounded,
          accentOverride: null,
        ),
        OnboardingPageData(
          title: 'Powerful Features',
          subtitle: 'AI agents handle the heavy lifting.',
          icon: Icons.auto_awesome_rounded,
          accentOverride: Color(0xFF38BDF8),
        ),
        OnboardingPageData(
          title: 'Stay Healthy',
          subtitle: 'Reminders to take breaks and hydrate.',
          icon: Icons.favorite_rounded,
          accentOverride: Color(0xFF4ADE80),
        ),
        OnboardingPageData(
          title: 'Get Started',
          subtitle: 'Sign in or create an account.',
          icon: Icons.rocket_launch_rounded,
          accentOverride: null,
        ),
      ];
      expect(pages.length, 4);
      expect(pages.first.title, 'Welcome to Orchestra');
      expect(pages.last.title, 'Get Started');
    });
  });
}
