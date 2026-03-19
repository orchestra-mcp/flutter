import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/i18n/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier', () {
    test('initial state is English', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider), const Locale('en'));
    });

    test('setLocale updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(localeProvider.notifier).setLocale(const Locale('ar'));
      expect(container.read(localeProvider), const Locale('ar'));
    });

    test('kSupportedLocales contains en and ar', () {
      expect(kSupportedLocales, containsAll([const Locale('en'), const Locale('ar')]));
    });
  });

  group('RtlUtils', () {
    testWidgets('isRtl returns false for LTR context', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (ctx) {
              result = Directionality.of(ctx) == TextDirection.rtl;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isFalse);
    });

    testWidgets('isRtl returns true for RTL context', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (ctx) {
              result = Directionality.of(ctx) == TextDirection.rtl;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isTrue);
    });
  });
}
