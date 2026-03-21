import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/api/interceptors/error_interceptor.dart';

void main() {
  group('Endpoints', () {
    test('static paths are correct', () {
      expect(Endpoints.authLogin, '/api/auth/login');
      expect(Endpoints.authLogout, '/api/auth/logout');
      expect(Endpoints.projects, '/api/projects');
      expect(Endpoints.notes, '/api/notes');
      expect(Endpoints.syncPush, '/api/sync/push');
      expect(Endpoints.mcpToolsCall, '/api/mcp/tools/call');
    });

    test('dynamic path helpers interpolate correctly', () {
      expect(Endpoints.project('abc'), '/api/projects/abc');
      expect(Endpoints.feature('f-1'), '/api/features/f-1');
      expect(Endpoints.note('n-2'), '/api/notes/n-2');
      expect(Endpoints.projectFeatures('p-1'), '/api/projects/p-1/features');
      expect(Endpoints.projectTree('p-2'), '/api/projects/p-2/tree');
    });
  });

  group('Admin notification endpoint', () {
    test('adminNotificationSend points to /send endpoint not list endpoint', () {
      expect(
        Endpoints.adminNotificationSend,
        '/api/admin/notifications/send',
      );
    });

    test('adminNotifications and adminNotificationSend are different paths', () {
      expect(
        Endpoints.adminNotifications,
        isNot(equals(Endpoints.adminNotificationSend)),
      );
    });

    test('adminNotificationSend ends with /send', () {
      expect(Endpoints.adminNotificationSend, endsWith('/send'));
    });
  });

  group('user_id to user_ids conversion logic', () {
    // Tests the conversion logic extracted from RestClient.createAdminNotification
    Map<String, dynamic> convertPayload(Map<String, dynamic> body) {
      final payload = Map<String, dynamic>.from(body);
      if (payload.containsKey('user_id') && !payload.containsKey('user_ids')) {
        payload['user_ids'] = [payload.remove('user_id')];
      }
      return payload;
    }

    test('converts user_id int to user_ids array', () {
      final result = convertPayload({'title': 'Test', 'user_id': 42});
      expect(result.containsKey('user_ids'), isTrue);
      expect(result['user_ids'], [42]);
      expect(result.containsKey('user_id'), isFalse);
    });

    test('does not overwrite user_ids if already present', () {
      final result = convertPayload({
        'title': 'Test',
        'user_ids': [1, 2, 3],
        'user_id': 99,
      });
      expect(result['user_ids'], [1, 2, 3]);
      expect(result.containsKey('user_id'), isTrue);
    });

    test('passes through body without user_id unchanged', () {
      final body = {'title': 'Broadcast', 'message': 'Hello'};
      final result = convertPayload(body);
      expect(result, equals(body));
    });

    test('user_ids wraps single int in a list', () {
      final result = convertPayload({'user_id': 7});
      expect(result['user_ids'], isList);
      expect((result['user_ids'] as List).length, 1);
      expect((result['user_ids'] as List).first, 7);
    });
  });

  group('AppException hierarchy', () {
    test('NetworkException toString includes class name', () {
      const e = NetworkException(message: 'no connection');
      expect(e.toString(), contains('NetworkException'));
      expect(e.message, 'no connection');
    });

    test('AuthException is AppException', () {
      const e = AuthException(message: 'unauthorized');
      expect(e, isA<AppException>());
    });

    test('NotFoundException is AppException', () {
      const e = NotFoundException(message: 'not found');
      expect(e, isA<AppException>());
    });

    test('ServerException is AppException', () {
      const e = ServerException(message: 'server error 500');
      expect(e, isA<AppException>());
    });
  });
}
