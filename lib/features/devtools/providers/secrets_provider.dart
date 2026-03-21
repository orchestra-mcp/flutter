import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class Secret {
  final String id;
  final String name;
  final String? value; // null when masked
  final String? maskedValue;
  final String category;
  final String? description;
  final String scope;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;

  const Secret({
    required this.id,
    required this.name,
    this.value,
    this.maskedValue,
    this.category = 'general',
    this.description,
    this.scope = 'global',
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Secret.fromJson(Map<String, dynamic> json) {
    return Secret(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      value: json['value'] as String?,
      maskedValue: json['masked_value'] as String?,
      category: json['category'] as String? ?? 'general',
      description: json['description'] as String?,
      scope: json['scope'] as String? ?? 'global',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Typed Riverpod wrapper around MCP Secrets tools.
///
/// Calls MCP tools: list_secrets, get_secret, create_secret,
/// update_secret, delete_secret, search_secrets, import_env,
/// get_secret_env.
class SecretsNotifier extends AsyncNotifier<List<Secret>> {
  @override
  Future<List<Secret>> build() => listSecrets();

  Future<List<Secret>> listSecrets({String? category}) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('list_secrets', {
      if (category != null) 'category': category,
    });
    final list = result['secrets'] as List<dynamic>? ?? [];
    return list
        .map((e) => Secret.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Secret> getSecret(String secretId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('get_secret', {
      'secret_id': secretId,
    });
    return Secret.fromJson(result);
  }

  Future<void> createSecret({
    required String name,
    required String value,
    String? category,
    String? description,
    String? scope,
    String? tags,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('create_secret', {
      'name': name,
      'value': value,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (scope != null) 'scope': scope,
      if (tags != null) 'tags': tags,
    });
    ref.invalidateSelf();
  }

  Future<void> updateSecret(
    String secretId, {
    String? name,
    String? value,
    String? category,
    String? description,
    String? scope,
    String? tags,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('update_secret', {
      'secret_id': secretId,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (scope != null) 'scope': scope,
      if (tags != null) 'tags': tags,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteSecret(String secretId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('delete_secret', {'secret_id': secretId});
    ref.invalidateSelf();
  }

  Future<List<Secret>> searchSecrets(String query) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('search_secrets', {'query': query});
    final list = result['secrets'] as List<dynamic>? ?? [];
    return list
        .map((e) => Secret.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> importEnv(
    String content, {
    String? category,
    String? scope,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('import_env', {
      'content': content,
      if (category != null) 'category': category,
      if (scope != null) 'scope': scope,
    });
    ref.invalidateSelf();
  }

  Future<String> exportEnv({
    String format = 'env',
    String? scope,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('get_secret_env', {
      'format': format,
      if (scope != null) 'scope': scope,
    });
    return result['output'] as String? ?? '';
  }
}

final secretsProvider =
    AsyncNotifierProvider<SecretsNotifier, List<Secret>>(
  SecretsNotifier.new,
);

/// Reveals a single secret's decrypted value.
final secretDetailProvider =
    FutureProvider.family<Secret, String>((ref, secretId) async {
  final notifier = ref.watch(secretsProvider.notifier);
  return notifier.getSecret(secretId);
});
