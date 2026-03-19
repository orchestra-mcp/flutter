import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/auth/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('parses full user object', () {
      final u = User.fromJson({
        'id': 'u-1',
        'email': 'test@example.com',
        'name': 'Test User',
        'role': 'admin',
        'team_id': 't-1',
        'workspace_id': 'w-1',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(u.id, 'u-1');
      expect(u.email, 'test@example.com');
      expect(u.name, 'Test User');
      expect(u.role, 'admin');
      expect(u.teamId, 't-1');
    });

    test('uses display_name fallback', () {
      final u = User.fromJson({
        'id': 'u-2',
        'email': 'a@b.com',
        'display_name': 'Display',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(u.name, 'Display');
      expect(u.role, 'member'); // default
    });

    test('toJson round-trips', () {
      final original = User.fromJson({
        'id': 'u-3',
        'email': 'x@y.com',
        'name': 'Round Trip',
        'created_at': '2024-06-15T12:00:00.000Z',
      });
      final roundTripped = User.fromJson(original.toJson());
      expect(roundTripped.id, original.id);
      expect(roundTripped.email, original.email);
    });

    test('copyWith updates only specified fields', () {
      final u = User.fromJson({
        'id': 'u-4',
        'email': 'copy@test.com',
        'name': 'Original',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      final updated = u.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.email, u.email);
      expect(updated.id, u.id);
    });
  });

  group('AuthState', () {
    test('AuthAuthenticated holds user', () {
      final u = User.fromJson({
        'id': 'u-5',
        'email': 'auth@test.com',
        'name': 'Auth User',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      final state = AuthAuthenticated(u);
      expect(state.user.email, 'auth@test.com');
      expect(state, isA<AuthState>());
    });

    test('AuthUnauthenticated is AuthState', () {
      expect(const AuthUnauthenticated(), isA<AuthState>());
    });

    test('AuthLoading is AuthState', () {
      expect(const AuthLoading(), isA<AuthState>());
    });
  });
}
