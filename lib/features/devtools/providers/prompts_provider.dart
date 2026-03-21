import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class Prompt {
  final String id;
  final String title;
  final String prompt;
  final String trigger; // startup, manual, scheduled
  final int priority;
  final bool enabled;
  final List<String> tags;
  final String? createdAt;
  final String? updatedAt;

  const Prompt({
    required this.id,
    required this.title,
    required this.prompt,
    this.trigger = 'startup',
    this.priority = 0,
    this.enabled = true,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? json['content'] as String? ?? '',
      trigger: json['trigger'] as String? ?? 'startup',
      priority: json['priority'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Typed Riverpod wrapper around MCP Prompts tools.
///
/// Calls MCP tools: list_prompts, get_prompt, create_prompt,
/// update_prompt, delete_prompt.
class PromptsNotifier extends AsyncNotifier<List<Prompt>> {
  @override
  Future<List<Prompt>> build() => listPrompts();

  Future<List<Prompt>> listPrompts({
    String? trigger,
    bool? enabled,
    String? tag,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('list_prompts', {
      if (trigger != null) 'trigger': trigger,
      if (enabled != null) 'enabled': enabled,
      if (tag != null) 'tag': tag,
    });
    final list = result['prompts'] as List<dynamic>? ?? [];
    return list.map((e) => Prompt.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Prompt> getPrompt(String promptId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('get_prompt', {'prompt_id': promptId});
    return Prompt.fromJson(result);
  }

  Future<void> createPrompt({
    required String title,
    required String prompt,
    String? trigger,
    int? priority,
    bool? enabled,
    List<String>? tags,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('create_prompt', {
      'title': title,
      'prompt': prompt,
      if (trigger != null) 'trigger': trigger,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (tags != null) 'tags': tags,
    });
    ref.invalidateSelf();
  }

  Future<void> updatePrompt(
    String promptId, {
    String? title,
    String? prompt,
    String? trigger,
    int? priority,
    bool? enabled,
    List<String>? tags,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('update_prompt', {
      'prompt_id': promptId,
      if (title != null) 'title': title,
      if (prompt != null) 'prompt': prompt,
      if (trigger != null) 'trigger': trigger,
      if (priority != null) 'priority': priority,
      if (enabled != null) 'enabled': enabled,
      if (tags != null) 'tags': tags,
    });
    ref.invalidateSelf();
  }

  Future<void> deletePrompt(String promptId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('delete_prompt', {'prompt_id': promptId});
    ref.invalidateSelf();
  }

  Future<void> togglePrompt(String promptId, {required bool enabled}) async {
    await updatePrompt(promptId, enabled: enabled);
  }
}

final promptsProvider = AsyncNotifierProvider<PromptsNotifier, List<Prompt>>(
  PromptsNotifier.new,
);

/// Fetches a single prompt with full content.
final promptDetailProvider = FutureProvider.family<Prompt, String>((
  ref,
  promptId,
) async {
  final notifier = ref.watch(promptsProvider.notifier);
  return notifier.getPrompt(promptId);
});
