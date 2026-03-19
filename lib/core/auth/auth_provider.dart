import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/interceptors/error_interceptor.dart';
import 'package:orchestra/core/api/rest_client.dart';
import 'package:orchestra/core/auth/auth_repository.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/auth/user_model.dart';
import 'package:orchestra/platform/web/web_token_handler.dart'
    if (dart.library.io) 'package:orchestra/platform/stub/web_token_handler_stub.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated([this.error]);
  final String? error;
}

// ── Repository provider ───────────────────────────────────────────────────────

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(),
);

/// Auth always goes through REST (web gate API), never MCP.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    client: RestClient(dio: ref.watch(dioProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

// ── Auth notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(tokenStorageProvider);

    // On web, check if a token was passed via URL parameter (cross-domain redirect).
    if (kIsWeb) {
      final urlToken = extractTokenFromUrl();
      if (urlToken != null) {
        await storage.saveTokens(accessToken: urlToken, refreshToken: '');
      }
    }

    final token = await storage.getAccessToken();
    if (token == null) return const AuthUnauthenticated();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getMe();
      return AuthAuthenticated(user);
    } catch (_) {
      await storage.clearTokens();
      return const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email, password);
      return AuthAuthenticated(user);
    });
    if (state.hasError) {
      state = AsyncValue.data(AuthUnauthenticated(_friendlyError(state.error)));
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(email, password, name);
      return AuthAuthenticated(user);
    });
    if (state.hasError) {
      state = AsyncValue.data(AuthUnauthenticated(_friendlyError(state.error)));
    }
  }

  static String _friendlyError(Object? error) {
    try {
      if (error is DioException) {
        final inner = error.error;
        if (inner is AppException) return inner.message;
        final status = error.response?.statusCode;
        if (status == 401) return 'Invalid email or password';
        if (status == 422) return 'Please check your input';
        if (status != null && status >= 500)
          return 'Server error. Try again later.';
        if (error.type == DioExceptionType.connectionError) {
          return 'Cannot reach server. Check your connection.';
        }
        return error.message ?? 'Something went wrong';
      }
    } catch (_) {
      // Fall through to generic handling
    }
    final msg = error?.toString() ?? '';
    if (msg.contains('Null') && msg.contains('String')) {
      return 'Invalid email or password';
    }
    return msg.isNotEmpty ? msg : 'Something went wrong';
  }

  Future<void> fetchMe() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getMe();
      state = AsyncValue.data(AuthAuthenticated(user));
    } catch (_) {
      // Silently fail — user state unchanged
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }

  User? get currentUser {
    final s = state.value;
    return s is AuthAuthenticated ? s.user : null;
  }

  bool get isAuthenticated => state.value is AuthAuthenticated;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
