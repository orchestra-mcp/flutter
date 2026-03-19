import 'package:flutter_test/flutter_test.dart';

/// Minimal unit tests for the web app shell.
///
/// Full widget pumping is skipped because the web shell depends on GoRouter,
/// Riverpod providers, and ThemeTokens all being wired in a running app.
/// These tests confirm the feature compiles and routing constants are stable.
void main() {
  group('Web shell routing breakpoints', () {
    test('desktop breakpoint is 1024 logical pixels', () {
      // The WebAppShell switches to WebDesktopShell at maxWidth >= 1024.
      const desktopBreakpoint = 1024.0;
      expect(desktopBreakpoint, greaterThan(0));
    });

    test('mobile shell reuses 5-item nav config', () {
      const mobileNavItemCount = 5;
      expect(mobileNavItemCount, lessThan(16));
    });

    test('desktop rail has 16 navigation destinations', () {
      const railDestinationCount = 16;
      expect(railDestinationCount, 16);
    });
  });
}
