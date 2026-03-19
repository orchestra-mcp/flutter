import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/api/interceptors/error_interceptor.dart';

void main() {
  group('Endpoints', () {
    test('static paths are correct', () {
      expect(Endpoints.authLogin, '/api/auth/login');
      expect(Endpoints.authRefresh, '/api/auth/refresh');
      expect(Endpoints.projects, '/api/projects');
      expect(Endpoints.features, '/api/features');
      expect(Endpoints.notes, '/api/notes');
      expect(Endpoints.syncPush, '/api/sync/push');
      expect(Endpoints.toolsCall, '/api/tools/call');
    });

    test('dynamic path helpers interpolate correctly', () {
      expect(Endpoints.project('abc'), '/api/projects/abc');
      expect(Endpoints.feature('f-1'), '/api/features/f-1');
      expect(Endpoints.note('n-2'), '/api/notes/n-2');
      expect(Endpoints.projectFeatures('p-1'), '/api/projects/p-1/features');
      expect(Endpoints.projectNotes('p-2'), '/api/projects/p-2/notes');
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
