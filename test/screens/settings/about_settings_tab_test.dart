import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/settings/tabs/about_settings_tab.dart';

void main() {
  group('AboutSettingsTab', () {
    testWidgets('displays Orchestra logo image instead of music note icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AboutSettingsTab())),
        ),
      );

      // Should NOT have the old music_note icon
      expect(find.byIcon(Icons.music_note_rounded), findsNothing);

      // Should have an Image.asset with the logo
      final imageFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == 'assets/images/logo.png',
      );
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('displays updated tagline', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AboutSettingsTab())),
        ),
      );

      expect(find.text('AI Agentic First IDE'), findsOneWidget);
      expect(find.text('AI-powered agent client'), findsNothing);
    });

    testWidgets('displays app name and version', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AboutSettingsTab())),
        ),
      );

      expect(find.text('Orchestra'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });
  });
}
