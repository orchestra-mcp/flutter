import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/theme/orchestra_theme.dart';

void main() {
  group('OrchestraTheme', () {
    test('allThemes contains exactly 25 entries', () {
      expect(OrchestraTheme.allThemes.length, 25);
    });

    test('all theme IDs are unique', () {
      final ids = OrchestraTheme.allThemes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('byId returns orchestra for unknown id', () {
      final t = OrchestraTheme.byId('does-not-exist');
      expect(t.id, 'orchestra');
    });

    test('byId returns correct theme', () {
      final t = OrchestraTheme.byId('dracula');
      expect(t.name, 'Dracula');
    });

    test('dark theme glassColor has alpha ~0.12', () {
      const t = OrchestraTheme.orchestra;
      expect(t.isLight, isFalse);
      expect(t.glassColor.a, closeTo(0.12, 0.01));
    });

    test('light theme glassColor has alpha ~0.15', () {
      const t = OrchestraTheme.githubLight;
      expect(t.isLight, isTrue);
      expect(t.glassColor.a, closeTo(0.15, 0.01));
    });

    test('Orchestra group has 6 themes', () {
      final group =
          OrchestraTheme.allThemes.where((t) => t.group == ThemeGroup.orchestra);
      expect(group.length, 6);
    });

    test('Popular group has 8 themes', () {
      final group =
          OrchestraTheme.allThemes.where((t) => t.group == ThemeGroup.popular);
      expect(group.length, 8);
    });
  });

  group('OrchestraColorTokens', () {
    test('fromTheme maps all fields', () {
      final tokens = OrchestraColorTokens.fromTheme(OrchestraTheme.orchestra);
      expect(tokens.accent, OrchestraTheme.orchestra.accent);
      expect(tokens.isLight, isFalse);
    });

    test('borderFaint has low alpha', () {
      final tokens = OrchestraColorTokens.fromTheme(OrchestraTheme.orchestra);
      expect(tokens.borderFaint.a, closeTo(0.3, 0.01));
    });

    test('accentSurface has 15% alpha', () {
      final tokens = OrchestraColorTokens.fromTheme(OrchestraTheme.orchestra);
      expect(tokens.accentSurface.a, closeTo(0.15, 0.01));
    });
  });
}
