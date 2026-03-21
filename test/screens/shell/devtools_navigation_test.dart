import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/router/app_router.dart';

void main() {
  // ── Route constants ────────────────────────────────────────────────────────

  group('DevTools route constants', () {
    test('all devtools routes start with /devtools/', () {
      expect(Routes.devtoolsApi, startsWith('/devtools/'));
      expect(Routes.devtoolsDatabase, startsWith('/devtools/'));
      expect(Routes.devtoolsLogs, startsWith('/devtools/'));
      expect(Routes.devtoolsSecrets, startsWith('/devtools/'));
      expect(Routes.devtoolsPrompts, startsWith('/devtools/'));
    });

    test('devtools routes are unique', () {
      final routes = [
        Routes.devtoolsApi,
        Routes.devtoolsDatabase,
        Routes.devtoolsLogs,
        Routes.devtoolsSecrets,
        Routes.devtoolsPrompts,
      ];
      expect(routes.toSet().length, routes.length);
    });

    test('devtools routes have correct paths', () {
      expect(Routes.devtoolsApi, '/devtools/api');
      expect(Routes.devtoolsDatabase, '/devtools/database');
      expect(Routes.devtoolsLogs, '/devtools/logs');
      expect(Routes.devtoolsSecrets, '/devtools/secrets');
      expect(Routes.devtoolsPrompts, '/devtools/prompts');
    });
  });

  // ── Route matching ─────────────────────────────────────────────────────────

  group('DevTools route matching', () {
    test('all devtools routes match /devtools prefix', () {
      const prefix = '/devtools';
      expect(Routes.devtoolsApi.startsWith(prefix), true);
      expect(Routes.devtoolsDatabase.startsWith(prefix), true);
      expect(Routes.devtoolsLogs.startsWith(prefix), true);
      expect(Routes.devtoolsSecrets.startsWith(prefix), true);
      expect(Routes.devtoolsPrompts.startsWith(prefix), true);
    });

    test('devtools routes do not conflict with other route prefixes', () {
      expect(Routes.devtoolsApi.startsWith('/terminal'), false);
      expect(Routes.devtoolsApi.startsWith('/health'), false);
      expect(Routes.devtoolsApi.startsWith('/settings'), false);
      expect(Routes.devtoolsApi.startsWith('/library'), false);
    });
  });
}
