import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/secrets_provider.dart';

void main() {
  // ── Secret model ───────────────────────────────────────────────────────────

  group('Secret model parsing', () {
    test('parses full secret with all fields', () {
      final secret = Secret.fromJson({
        'id': 'sec-1',
        'name': 'DATABASE_URL',
        'value': 'postgres://user:pass@localhost/db',
        'masked_value': 'post****b',
        'category': 'database',
        'description': 'Main database connection',
        'scope': 'production',
        'tags': ['db', 'infra'],
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T12:00:00Z',
      });
      expect(secret.id, 'sec-1');
      expect(secret.name, 'DATABASE_URL');
      expect(secret.value, 'postgres://user:pass@localhost/db');
      expect(secret.maskedValue, 'post****b');
      expect(secret.category, 'database');
      expect(secret.description, 'Main database connection');
      expect(secret.scope, 'production');
      expect(secret.tags, ['db', 'infra']);
      expect(secret.createdAt, '2026-03-20T10:00:00Z');
      expect(secret.updatedAt, '2026-03-20T12:00:00Z');
    });

    test('parses masked secret without value', () {
      final secret = Secret.fromJson({
        'id': 'sec-2',
        'name': 'API_KEY',
        'masked_value': 'sk-****xyz',
        'category': 'api_key',
      });
      expect(secret.id, 'sec-2');
      expect(secret.name, 'API_KEY');
      expect(secret.value, isNull);
      expect(secret.maskedValue, 'sk-****xyz');
      expect(secret.category, 'api_key');
    });

    test('uses defaults for missing fields', () {
      final secret = Secret.fromJson({});
      expect(secret.id, '');
      expect(secret.name, '');
      expect(secret.value, isNull);
      expect(secret.maskedValue, isNull);
      expect(secret.category, 'general');
      expect(secret.description, isNull);
      expect(secret.scope, 'global');
      expect(secret.tags, isEmpty);
      expect(secret.createdAt, isNull);
      expect(secret.updatedAt, isNull);
    });

    test('handles tags as empty list when null', () {
      final secret = Secret.fromJson({
        'id': 'sec-3',
        'name': 'SOME_SECRET',
        'tags': null,
      });
      expect(secret.tags, isEmpty);
    });

    test('parses all category types', () {
      for (final cat in ['api_key', 'token', 'env', 'database', 'password', 'general']) {
        final secret = Secret.fromJson({'category': cat});
        expect(secret.category, cat);
      }
    });

    test('parses scope values', () {
      for (final scope in ['global', 'production', 'staging', 'local']) {
        final secret = Secret.fromJson({'scope': scope});
        expect(secret.scope, scope);
      }
    });
  });

  // ── Search/filter logic ────────────────────────────────────────────────────

  group('Secret list filtering', () {
    final secrets = [
      Secret.fromJson({
        'id': 's1',
        'name': 'DATABASE_URL',
        'category': 'database',
        'tags': ['infra'],
      }),
      Secret.fromJson({
        'id': 's2',
        'name': 'STRIPE_KEY',
        'category': 'api_key',
        'tags': ['payments'],
      }),
      Secret.fromJson({
        'id': 's3',
        'name': 'JWT_SECRET',
        'category': 'token',
        'tags': ['auth'],
      }),
      Secret.fromJson({
        'id': 's4',
        'name': 'REDIS_PASSWORD',
        'category': 'password',
        'tags': ['infra'],
      }),
      Secret.fromJson({
        'id': 's5',
        'name': 'APP_ENV',
        'category': 'env',
        'tags': ['config'],
      }),
    ];

    test('filter by name substring', () {
      final filtered = secrets
          .where((s) => s.name.toLowerCase().contains('key'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].name, 'STRIPE_KEY');
    });

    test('filter by category', () {
      final filtered = secrets
          .where((s) => s.category == 'database')
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].name, 'DATABASE_URL');
    });

    test('filter by tag', () {
      final filtered = secrets
          .where((s) => s.tags.contains('infra'))
          .toList();
      expect(filtered.length, 2);
      expect(filtered.map((s) => s.name).toList(),
          ['DATABASE_URL', 'REDIS_PASSWORD']);
    });

    test('empty filter returns all', () {
      final query = '';
      final filtered = secrets
          .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered.length, secrets.length);
    });

    test('case-insensitive name search', () {
      final filtered = secrets
          .where((s) => s.name.toLowerCase().contains('jwt'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].name, 'JWT_SECRET');
    });
  });

  // ── Masking logic ──────────────────────────────────────────────────────────

  group('Secret masking display', () {
    test('shows masked_value when value is null', () {
      final secret = Secret.fromJson({
        'name': 'API_KEY',
        'masked_value': 'sk-****xyz',
      });
      final display = secret.maskedValue ?? '••••••••';
      expect(display, 'sk-****xyz');
    });

    test('shows placeholder when both null', () {
      final secret = Secret.fromJson({'name': 'EMPTY'});
      final display = secret.maskedValue ?? '••••••••';
      expect(display, '••••••••');
    });

    test('value available for revealed secret', () {
      final secret = Secret.fromJson({
        'name': 'TOKEN',
        'value': 'actual-secret-value',
        'masked_value': 'actu****lue',
      });
      expect(secret.value, 'actual-secret-value');
      expect(secret.maskedValue, 'actu****lue');
    });
  });
}
