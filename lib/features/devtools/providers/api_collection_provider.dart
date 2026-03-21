import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class ApiCollection {
  final String id;
  final String name;
  final String? baseUrl;
  final String? description;
  final List<ApiEndpoint> endpoints;

  const ApiCollection({
    required this.id,
    required this.name,
    this.baseUrl,
    this.description,
    this.endpoints = const [],
  });

  factory ApiCollection.fromJson(Map<String, dynamic> json) {
    final endpoints = (json['endpoints'] as List<dynamic>?)
            ?.map((e) => ApiEndpoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ApiCollection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      baseUrl: json['base_url'] as String?,
      description: json['description'] as String?,
      endpoints: endpoints,
    );
  }
}

class ApiEndpoint {
  final String? id;
  final String name;
  final String method;
  final String url;
  final String? description;
  final String? body;
  final String? bodyType;
  final Map<String, dynamic>? headers;
  final String? folder;

  const ApiEndpoint({
    this.id,
    required this.name,
    required this.method,
    required this.url,
    this.description,
    this.body,
    this.bodyType,
    this.headers,
    this.folder,
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    return ApiEndpoint(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      method: json['method'] as String? ?? 'GET',
      url: json['url'] as String? ?? '',
      description: json['description'] as String?,
      body: json['body'] as String?,
      bodyType: json['body_type'] as String?,
      headers: json['headers'] as Map<String, dynamic>?,
      folder: json['folder'] as String?,
    );
  }
}

class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> headers;
  final String body;
  final int durationMs;

  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.durationMs,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      statusCode: json['status_code'] as int? ?? 0,
      headers: json['headers'] as Map<String, dynamic>? ?? {},
      body: json['body'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
    );
  }
}

class ApiEnvironment {
  final String name;
  final Map<String, dynamic> variables;

  const ApiEnvironment({required this.name, required this.variables});

  factory ApiEnvironment.fromJson(Map<String, dynamic> json) {
    return ApiEnvironment(
      name: json['name'] as String? ?? '',
      variables: json['variables'] as Map<String, dynamic>? ?? {},
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Typed Riverpod wrapper around MCP API Collection tools.
///
/// Calls MCP tools: api_list_collections, api_get_collection,
/// api_save_request, api_delete_collection, api_request,
/// api_search_endpoints, api_history, api_get_env, api_set_env.
class ApiCollectionNotifier extends AsyncNotifier<List<ApiCollection>> {
  @override
  Future<List<ApiCollection>> build() => listCollections();

  Future<List<ApiCollection>> listCollections() async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_list_collections', {});
    final list = result['collections'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiCollection> getCollection(String collectionId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_get_collection', {
      'collection_id': collectionId,
    });
    return ApiCollection.fromJson(result);
  }

  Future<void> saveRequest({
    String? collectionId,
    String? collectionName,
    required String name,
    required String method,
    required String url,
    String? description,
    String? body,
    String? bodyType,
    Map<String, dynamic>? headers,
    String? folder,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('api_save_request', {
      if (collectionId != null) 'collection_id': collectionId,
      if (collectionName != null) 'collection_name': collectionName,
      'name': name,
      'method': method,
      'url': url,
      if (description != null) 'description': description,
      if (body != null) 'body': body,
      if (bodyType != null) 'body_type': bodyType,
      if (headers != null) 'headers': headers,
      if (folder != null) 'folder': folder,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteCollection(String collectionId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('api_delete_collection', {
      'collection_id': collectionId,
    });
    ref.invalidateSelf();
  }

  Future<ApiResponse> sendRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    String? body,
    String? bodyType,
    Map<String, dynamic>? auth,
    String? environment,
    num? timeout,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_request', {
      'method': method,
      'url': url,
      if (headers != null) 'headers': headers,
      if (body != null) 'body': body,
      if (bodyType != null) 'body_type': bodyType,
      if (auth != null) 'auth': auth,
      if (environment != null) 'environment': environment,
      if (timeout != null) 'timeout': timeout,
    });
    return ApiResponse.fromJson(result);
  }

  Future<List<ApiEndpoint>> searchEndpoints(
    String query, {
    String? method,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_search_endpoints', {
      'query': query,
      if (method != null) 'method': method,
    });
    final list = result['endpoints'] as List<dynamic>? ?? [];
    return list
        .map((e) => ApiEndpoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getHistory({int? limit}) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_history', {
      if (limit != null) 'limit': limit,
    });
    return (result['history'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<ApiEnvironment> getEnvironment(String name) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('api_get_env', {'name': name});
    return ApiEnvironment.fromJson(result);
  }

  Future<void> setEnvironment(
    String name,
    Map<String, dynamic> variables,
  ) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('api_set_env', {
      'name': name,
      'variables': variables,
    });
  }
}

final apiCollectionProvider =
    AsyncNotifierProvider<ApiCollectionNotifier, List<ApiCollection>>(
  ApiCollectionNotifier.new,
);

/// Fetches a single collection by ID.
final apiCollectionDetailProvider =
    FutureProvider.family<ApiCollection, String>((ref, id) async {
  final notifier = ref.watch(apiCollectionProvider.notifier);
  return notifier.getCollection(id);
});
