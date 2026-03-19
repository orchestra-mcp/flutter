import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/interceptors/auth_interceptor.dart';
import 'package:orchestra/core/api/interceptors/error_interceptor.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/firebase/performance_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(dio: dio, tokenStorage: const TokenStorage()),
    ErrorInterceptor(),
    PerformanceService.dioInterceptor,
  ]);

  return dio;
});
