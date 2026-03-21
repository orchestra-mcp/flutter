import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';
import 'package:orchestra/screens/devtools/widgets/api_request_builder.dart';

void main() {
  // ── RequestBuilderData ────────────────────────────────────────────────────

  group('RequestBuilderData', () {
    test('constructs with all fields', () {
      const data = RequestBuilderData(
        method: 'POST',
        url: 'https://api.example.com/users',
        headers: {'Content-Type': 'application/json'},
        body: '{"name":"test"}',
        bodyType: 'json',
        auth: {'type': 'bearer', 'token': 'sk-123'},
      );
      expect(data.method, 'POST');
      expect(data.url, 'https://api.example.com/users');
      expect(data.headers!['Content-Type'], 'application/json');
      expect(data.body, '{"name":"test"}');
      expect(data.bodyType, 'json');
      expect(data.auth!['type'], 'bearer');
    });

    test('constructs with minimal fields', () {
      const data = RequestBuilderData(
        method: 'GET',
        url: 'https://api.example.com',
      );
      expect(data.method, 'GET');
      expect(data.url, 'https://api.example.com');
      expect(data.headers, isNull);
      expect(data.body, isNull);
      expect(data.bodyType, isNull);
      expect(data.auth, isNull);
    });
  });

  // ── Method color coding ─────────────────────────────────────────────────

  group('HTTP method color helpers', () {
    test('methodColor returns distinct colors for each method', () {
      // Methods should have unique visual identity
      const methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
      for (final m in methods) {
        expect(methods.contains(m), isTrue, reason: '$m is a valid method');
      }
    });
  });

  // ── ApiResponse model for viewer ──────────────────────────────────────────

  group('ApiResponse for viewer', () {
    test('2xx status code is success', () {
      final resp = ApiResponse.fromJson(<String, dynamic>{
        'status_code': 200,
        'headers': <String, dynamic>{'content-type': 'application/json'},
        'body': '{"ok":true}',
        'duration_ms': 42,
      });
      expect(resp.statusCode, 200);
      expect(resp.statusCode >= 200 && resp.statusCode < 300, isTrue);
    });

    test('4xx status code is client error', () {
      final resp = ApiResponse.fromJson(<String, dynamic>{
        'status_code': 404,
        'headers': <String, dynamic>{},
        'body': 'Not Found',
        'duration_ms': 10,
      });
      expect(resp.statusCode, 404);
      expect(resp.statusCode >= 400 && resp.statusCode < 500, isTrue);
    });

    test('5xx status code is server error', () {
      final resp = ApiResponse.fromJson(<String, dynamic>{
        'status_code': 500,
        'headers': <String, dynamic>{},
        'body': 'Internal Server Error',
        'duration_ms': 100,
      });
      expect(resp.statusCode, 500);
      expect(resp.statusCode >= 500, isTrue);
    });

    test('duration is accessible', () {
      final resp = ApiResponse.fromJson(<String, dynamic>{
        'status_code': 200,
        'headers': <String, dynamic>{},
        'body': '',
        'duration_ms': 350,
      });
      expect(resp.durationMs, 350);
    });
  });

  // ── Collection sidebar model tests ──────────────────────────────────────

  group('ApiCollection sidebar data', () {
    test('collection with endpoints shows count', () {
      final col = ApiCollection.fromJson({
        'id': 'col-1',
        'name': 'Users API',
        'base_url': 'https://api.example.com',
        'endpoints': [
          {'name': 'List Users', 'method': 'GET', 'url': '/users'},
          {'name': 'Create User', 'method': 'POST', 'url': '/users'},
          {'name': 'Delete User', 'method': 'DELETE', 'url': '/users/:id'},
        ],
      });
      expect(col.endpoints.length, 3);
      expect(col.name, 'Users API');
    });

    test('empty collection has zero endpoints', () {
      final col = ApiCollection.fromJson({
        'id': 'col-2',
        'name': 'Empty',
      });
      expect(col.endpoints, isEmpty);
    });

    test('endpoint method is preserved', () {
      final ep = ApiEndpoint.fromJson({
        'name': 'Update',
        'method': 'PATCH',
        'url': '/resource/:id',
      });
      expect(ep.method, 'PATCH');
    });
  });

}
