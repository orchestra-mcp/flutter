import 'package:dio/dio.dart';
import 'package:orchestra/core/auth/token_storage.dart';

/// Injects Bearer token. On 401, clears tokens (no refresh endpoint exists).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skip_auth'] == true) return handler.next(options);
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await tokenStorage.clearTokens();
    }
    handler.next(err);
  }
}
