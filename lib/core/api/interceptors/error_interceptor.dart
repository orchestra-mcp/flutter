import 'package:dio/dio.dart';

/// Maps [DioException] to typed [AppException] subclasses.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appErr = switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionTimeout =>
        NetworkException(message: err.message ?? 'Network error', cause: err),
      DioExceptionType.badResponse => _fromStatus(err),
      _ => UnknownApiException(message: err.message ?? 'Unknown error', cause: err),
    };
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appErr,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _fromStatus(DioException err) {
    final code = err.response?.statusCode ?? 0;
    if (code == 401 || code == 403) {
      return AuthException(message: 'Unauthorized ($code)', cause: err);
    }
    if (code == 404) return NotFoundException(message: 'Not found', cause: err);
    if (code >= 500) return ServerException(message: 'Server error $code', cause: err);
    return UnknownApiException(message: 'HTTP $code', cause: err);
  }
}

// ── Exception hierarchy ────────────────────────────────────────────────────

sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.cause});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.cause});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.cause});
}

class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.cause});
}

class UnknownApiException extends AppException {
  const UnknownApiException({required super.message, super.cause});
}
