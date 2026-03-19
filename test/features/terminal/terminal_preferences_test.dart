import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/terminal/terminal_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ── Constants ──────────────────────────────────────────────────────────────

  group('Terminal font size constants', () {
    test('default is 14.0', () {
      expect(kTerminalFontSizeDefault, 14.0);
    });

    test('min is 10.0', () {
      expect(kTerminalFontSizeMin, 10.0);
    });

    test('max is 24.0', () {
      expect(kTerminalFontSizeMax, 24.0);
    });

    test('step is 1.0', () {
      expect(kTerminalFontSizeStep, 1.0);
    });

    test('default is within valid range', () {
      expect(kTerminalFontSizeDefault, greaterThanOrEqualTo(kTerminalFontSizeMin));
      expect(kTerminalFontSizeDefault, lessThanOrEqualTo(kTerminalFontSizeMax));
    });

    test('min is less than max', () {
      expect(kTerminalFontSizeMin, lessThan(kTerminalFontSizeMax));
    });

    test('step is positive', () {
      expect(kTerminalFontSizeStep, greaterThan(0));
    });

    test('range accommodates at least one step in each direction from default', () {
      expect(kTerminalFontSizeDefault - kTerminalFontSizeStep,
          greaterThanOrEqualTo(kTerminalFontSizeMin));
      expect(kTerminalFontSizeDefault + kTerminalFontSizeStep,
          lessThanOrEqualTo(kTerminalFontSizeMax));
    });
  });

  // ── Boundary math (pure logic, no providers) ──────────────────────────────

  group('Font size clamping math', () {
    test('value below min clamps to min', () {
      final clamped = 5.0.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMin);
    });

    test('value above max clamps to max', () {
      final clamped = 30.0.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMax);
    });

    test('value at min stays at min', () {
      final clamped =
          kTerminalFontSizeMin.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMin);
    });

    test('value at max stays at max', () {
      final clamped =
          kTerminalFontSizeMax.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMax);
    });

    test('default + step does not exceed max', () {
      final increased = (kTerminalFontSizeDefault + kTerminalFontSizeStep)
          .clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(increased, kTerminalFontSizeDefault + kTerminalFontSizeStep);
    });

    test('default - step does not go below min', () {
      final decreased = (kTerminalFontSizeDefault - kTerminalFontSizeStep)
          .clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(decreased, kTerminalFontSizeDefault - kTerminalFontSizeStep);
    });

    test('max + step clamps back to max', () {
      final clamped = (kTerminalFontSizeMax + kTerminalFontSizeStep)
          .clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMax);
    });

    test('min - step clamps back to min', () {
      final clamped = (kTerminalFontSizeMin - kTerminalFontSizeStep)
          .clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMin);
    });

    test('negative value clamps to min', () {
      final clamped = (-1.0).clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMin);
    });

    test('zero clamps to min', () {
      final clamped = 0.0.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, kTerminalFontSizeMin);
    });

    test('mid-range value is unchanged', () {
      const mid = 18.0;
      final clamped = mid.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
      expect(clamped, mid);
    });
  });

  // ── TerminalFontSizeNotifier (via ProviderContainer) ──────────────────────

  group('terminalFontSizeProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('initial value is kTerminalFontSizeDefault', () {
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('increase raises font size by one step', () {
      container.read(terminalFontSizeProvider.notifier).increase();
      expect(
        container.read(terminalFontSizeProvider),
        kTerminalFontSizeDefault + kTerminalFontSizeStep,
      );
    });

    test('decrease lowers font size by one step', () {
      container.read(terminalFontSizeProvider.notifier).decrease();
      expect(
        container.read(terminalFontSizeProvider),
        kTerminalFontSizeDefault - kTerminalFontSizeStep,
      );
    });

    test('increase multiple times accumulates', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.increase();
      notifier.increase();
      notifier.increase();
      expect(
        container.read(terminalFontSizeProvider),
        kTerminalFontSizeDefault + (3 * kTerminalFontSizeStep),
      );
    });

    test('decrease multiple times accumulates', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.decrease();
      notifier.decrease();
      expect(
        container.read(terminalFontSizeProvider),
        kTerminalFontSizeDefault - (2 * kTerminalFontSizeStep),
      );
    });

    test('increase clamps at max', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      // Set to max first
      notifier.set(kTerminalFontSizeMax);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);

      // Try to go above max
      notifier.increase();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('decrease clamps at min', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      // Set to min first
      notifier.set(kTerminalFontSizeMin);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);

      // Try to go below min
      notifier.decrease();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('increase from one step below max reaches max', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(kTerminalFontSizeMax - kTerminalFontSizeStep);
      notifier.increase();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('decrease from one step above min reaches min', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(kTerminalFontSizeMin + kTerminalFontSizeStep);
      notifier.decrease();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('reset returns to default', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.increase();
      notifier.increase();
      notifier.reset();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('reset from min returns to default', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(kTerminalFontSizeMin);
      notifier.reset();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('reset from max returns to default', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(kTerminalFontSizeMax);
      notifier.reset();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('set to a valid value updates state', () {
      container.read(terminalFontSizeProvider.notifier).set(18.0);
      expect(container.read(terminalFontSizeProvider), 18.0);
    });

    test('set below min clamps to min', () {
      container.read(terminalFontSizeProvider.notifier).set(5.0);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('set above max clamps to max', () {
      container.read(terminalFontSizeProvider.notifier).set(50.0);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('set to min stays at min', () {
      container.read(terminalFontSizeProvider.notifier).set(kTerminalFontSizeMin);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('set to max stays at max', () {
      container.read(terminalFontSizeProvider.notifier).set(kTerminalFontSizeMax);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('set to negative clamps to min', () {
      container.read(terminalFontSizeProvider.notifier).set(-5.0);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('set to zero clamps to min', () {
      container.read(terminalFontSizeProvider.notifier).set(0.0);
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });

    test('independent containers have isolated state', () {
      SharedPreferences.setMockInitialValues({});
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      containerA.read(terminalFontSizeProvider.notifier).set(20.0);
      expect(containerA.read(terminalFontSizeProvider), 20.0);
      expect(containerB.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('increase then decrease returns to original', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.increase();
      notifier.decrease();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('set then reset returns to default', () {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(22.0);
      notifier.reset();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('persists to SharedPreferences after set', () async {
      container.read(terminalFontSizeProvider.notifier).set(16.0);
      // Allow async _persist to complete
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('terminal_font_size'), 16.0);
    });

    test('persists to SharedPreferences after increase', () async {
      container.read(terminalFontSizeProvider.notifier).increase();
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getDouble('terminal_font_size'),
        kTerminalFontSizeDefault + kTerminalFontSizeStep,
      );
    });

    test('persists to SharedPreferences after decrease', () async {
      container.read(terminalFontSizeProvider.notifier).decrease();
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getDouble('terminal_font_size'),
        kTerminalFontSizeDefault - kTerminalFontSizeStep,
      );
    });

    test('persists to SharedPreferences after reset', () async {
      final notifier = container.read(terminalFontSizeProvider.notifier);
      notifier.set(20.0);
      notifier.reset();
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('terminal_font_size'), kTerminalFontSizeDefault);
    });

    test('loads persisted value on init', () async {
      SharedPreferences.setMockInitialValues({'terminal_font_size': 18.0});
      final c = ProviderContainer();
      addTearDown(c.dispose);

      // Read to trigger build + async _load
      c.read(terminalFontSizeProvider);
      // Allow async _load to complete
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(terminalFontSizeProvider), 18.0);
    });

    test('clamps persisted value that exceeds max', () async {
      SharedPreferences.setMockInitialValues({'terminal_font_size': 100.0});
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(terminalFontSizeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('clamps persisted value that is below min', () async {
      SharedPreferences.setMockInitialValues({'terminal_font_size': 1.0});
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(terminalFontSizeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });
  });

  // ── terminalSearchVisibleProvider ─────────────────────────────────────────

  group('terminalSearchVisibleProvider', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial value is false', () {
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('toggle from false makes it true', () {
      container.read(terminalSearchVisibleProvider.notifier).toggle();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
    });

    test('toggle twice returns to false', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.toggle();
      notifier.toggle();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('toggle three times ends at true', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.toggle();
      notifier.toggle();
      notifier.toggle();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
    });

    test('show sets to true', () {
      container.read(terminalSearchVisibleProvider.notifier).show();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
    });

    test('show when already true stays true', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.show();
      notifier.show();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
    });

    test('hide sets to false', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.show();
      notifier.hide();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('hide when already false stays false', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.hide();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('show then toggle makes false', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.show();
      notifier.toggle();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('hide then toggle makes true', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.hide();
      notifier.toggle();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
    });

    test('sequence: show, hide, toggle, toggle ends at false', () {
      final notifier = container.read(terminalSearchVisibleProvider.notifier);
      notifier.show(); // true
      notifier.hide(); // false
      notifier.toggle(); // true
      notifier.toggle(); // false
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('independent containers have isolated state', () {
      final containerA = ProviderContainer();
      final containerB = ProviderContainer();
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      containerA.read(terminalSearchVisibleProvider.notifier).show();
      expect(containerA.read(terminalSearchVisibleProvider), isTrue);
      expect(containerB.read(terminalSearchVisibleProvider), isFalse);
    });
  });
}
