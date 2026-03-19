import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/widgets/glass_background.dart';
import 'package:orchestra/widgets/glass_button.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:orchestra/widgets/glass_header.dart';

/// Minimal compile-time tests for the Liquid Glass component library.
///
/// Full widget pumping is skipped because [GlassCard] and [GlassBackground]
/// depend on [ThemeTokens] being in the widget tree, which requires a running
/// Flutter app with a MaterialApp ancestor.  These tests verify that the
/// classes exist, have correct default field values, and are const-constructible.
void main() {
  group('GlassCard', () {
    test('const-constructible with required child', () {
      const card = GlassCard(child: SizedBox());
      expect(card, isA<GlassCard>());
    });

    test('default borderRadius is 16', () {
      const card = GlassCard(child: SizedBox());
      expect(card.borderRadius, 16.0);
    });

    test('default padding is EdgeInsets.all(16)', () {
      const card = GlassCard(child: SizedBox());
      expect(card.padding, const EdgeInsets.all(16));
    });

    test('margin defaults to null', () {
      const card = GlassCard(child: SizedBox());
      expect(card.margin, isNull);
    });

    test('onTap defaults to null', () {
      const card = GlassCard(child: SizedBox());
      expect(card.onTap, isNull);
    });

    test('accepts custom borderRadius', () {
      const card = GlassCard(borderRadius: 24.0, child: SizedBox());
      expect(card.borderRadius, 24.0);
    });
  });

  group('GlassBackground', () {
    test('const-constructible with no child', () {
      const bg = GlassBackground();
      expect(bg, isA<GlassBackground>());
    });

    test('child defaults to null', () {
      const bg = GlassBackground();
      expect(bg.child, isNull);
    });

    test('accepts optional child', () {
      const bg = GlassBackground(child: SizedBox());
      expect(bg.child, isNotNull);
    });
  });

  group('GlassButton', () {
    test('const-constructible with required label and callback', () {
      const btn = GlassButton(label: 'OK', onPressed: null);
      expect(btn, isA<GlassButton>());
    });

    test('isLoading defaults to false', () {
      const btn = GlassButton(label: 'OK', onPressed: null);
      expect(btn.isLoading, isFalse);
    });

    test('isDisabled defaults to false', () {
      const btn = GlassButton(label: 'OK', onPressed: null);
      expect(btn.isDisabled, isFalse);
    });

    test('icon defaults to null', () {
      const btn = GlassButton(label: 'OK', onPressed: null);
      expect(btn.icon, isNull);
    });

    test('accepts icon and loading state', () {
      const btn = GlassButton(
        label: 'Save',
        onPressed: null,
        icon: Icons.save,
        isLoading: true,
      );
      expect(btn.icon, Icons.save);
      expect(btn.isLoading, isTrue);
    });
  });

  group('GlassHeader', () {
    test('const-constructible with required title', () {
      const header = GlassHeader(title: 'Home');
      expect(header, isA<GlassHeader>());
    });

    test('default height is 60', () {
      const header = GlassHeader(title: 'Home');
      expect(header.height, 60.0);
    });

    test('preferredSize reflects height', () {
      const header = GlassHeader(title: 'Home');
      expect(header.preferredSize, const Size.fromHeight(60.0));
    });

    test('leading and trailing default to null', () {
      const header = GlassHeader(title: 'Home');
      expect(header.leading, isNull);
      expect(header.trailing, isNull);
    });
  });
}
