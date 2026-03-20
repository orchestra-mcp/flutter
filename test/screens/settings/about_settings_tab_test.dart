import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/update/update_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/settings/tabs/about_settings_tab.dart';

const _testTokens = OrchestraColorTokens(
  bg: Color(0xFF0A0A0A),
  bgAlt: Color(0xFF1A1A2E),
  fgBright: Color(0xFFF0F0F0),
  fgMuted: Color(0xFFA0A0A0),
  fgDim: Color(0xFF606060),
  border: Color(0xFF333333),
  accent: Color(0xFF38BDF8),
  accentAlt: Color(0xFFA78BFA),
  glass: Color(0x1F1A1A2E),
  isLight: false,
);

void main() {
  group('AboutSettingsTab', () {
    testWidgets('displays Orchestra logo image instead of music note icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [updateProvider.overrideWith(() => _TestUpdateNotifier())],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: AboutSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
        ProviderScope(
          overrides: [updateProvider.overrideWith(() => _TestUpdateNotifier())],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: AboutSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Agentic First IDE'), findsOneWidget);
      expect(find.text('AI-powered agent client'), findsNothing);
    });

    testWidgets('displays app name and version', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [updateProvider.overrideWith(() => _TestUpdateNotifier())],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeTokens(
              tokens: _testTokens,
              child: const Scaffold(body: AboutSettingsTab()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orchestra'), findsOneWidget);
    });
  });
}

class _TestUpdateNotifier extends UpdateNotifier {
  @override
  UpdateState build() => const UpdateState();
}
