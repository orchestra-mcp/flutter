import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/config/env.dart';

/// Wires Firebase Performance traces and HTTP metrics.
abstract final class PerformanceService {
  static FirebasePerformance? _perf;

  static void init() {
    if (!Env.enableFirebase) return;
    _perf = FirebasePerformance.instance;
    _perf!.setPerformanceCollectionEnabled(!kDebugMode);
  }

  // ─── Custom traces ────────────────────────────────────────────────────────

  static Future<Trace?> startTrace(String name) async {
    if (_perf == null) return null;
    final trace = _perf!.newTrace(name);
    await trace.start();
    return trace;
  }

  /// Convenience for named traces used throughout the app.
  static Future<Trace?> startSyncTrace() => startTrace('sync_duration');
  static Future<Trace?> startHealthKitTrace() => startTrace('health_kit_read');
  static Future<Trace?> startMcpToolTrace(String toolName) =>
      startTrace('mcp_tool_$toolName');

  // ─── Dio interceptor ──────────────────────────────────────────────────────

  /// Add to your Dio instance to record HTTP metrics automatically.
  static Interceptor get dioInterceptor => _PerformanceDioInterceptor(_perf);
}

class _PerformanceDioInterceptor extends Interceptor {
  _PerformanceDioInterceptor(this._perf);

  final FirebasePerformance? _perf;
  final Map<String, HttpMetric> _metrics = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final perf = _perf;
    if (perf != null) {
      final method = _httpMethod(options.method);
      if (method != null) {
        final metric = perf.newHttpMetric(options.uri.toString(), method);
        metric.start();
        _metrics[options.hashCode.toString()] = metric;
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.hashCode.toString();
    final metric = _metrics.remove(key);
    if (metric != null) {
      metric
        ..httpResponseCode = response.statusCode
        ..responseContentType =
            response.headers.value('content-type') ?? ''
        ..responsePayloadSize =
            int.tryParse(
              response.headers.value('content-length') ?? '',
            );
      metric.stop();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = err.requestOptions.hashCode.toString();
    final metric = _metrics.remove(key);
    if (metric != null) {
      metric.httpResponseCode = err.response?.statusCode;
      metric.stop();
    }
    handler.next(err);
  }

  HttpMethod? _httpMethod(String method) => switch (method.toUpperCase()) {
    'GET' => HttpMethod.Get,
    'POST' => HttpMethod.Post,
    'PUT' => HttpMethod.Put,
    'DELETE' => HttpMethod.Delete,
    'PATCH' => HttpMethod.Patch,
    'HEAD' => HttpMethod.Head,
    'OPTIONS' => HttpMethod.Options,
    'CONNECT' => HttpMethod.Connect,
    'TRACE' => HttpMethod.Trace,
    _ => null,
  };
}
