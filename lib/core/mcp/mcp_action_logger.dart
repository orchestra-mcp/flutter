import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A single logged MCP action.
class McpActionEntry {
  McpActionEntry({
    required this.toolName,
    required this.arguments,
    required this.timestamp,
    required this.durationMs,
    required this.success,
    this.error,
  });

  final String toolName;
  final Map<String, dynamic> arguments;
  final DateTime timestamp;
  final int durationMs;
  final bool success;
  final String? error;

  /// Human-readable label for the action.
  String get humanLabel => _toolHumanLabels[toolName] ?? _formatToolName(toolName);

  /// Category for filtering.
  String get category => _toolCategories[toolName] ?? 'other';

  Map<String, dynamic> toJson() => {
        'tool': toolName,
        'args': arguments,
        'timestamp': timestamp.toIso8601String(),
        'duration_ms': durationMs,
        'success': success,
        if (error != null) 'error': error,
      };

  static String _formatToolName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Tool name → human-readable label mapping.
const _toolHumanLabels = {
  'create_note': 'Created a note',
  'update_note': 'Updated a note',
  'delete_note': 'Deleted a note',
  'list_notes': 'Listed notes',
  'get_note': 'Viewed a note',
  'create_feature': 'Created a feature',
  'update_feature': 'Updated a feature',
  'list_features': 'Listed features',
  'get_feature': 'Viewed a feature',
  'advance_feature': 'Advanced feature status',
  'set_current_feature': 'Started working on feature',
  'submit_review': 'Submitted review',
  'create_project': 'Created a project',
  'list_projects': 'Listed projects',
  'get_project': 'Viewed a project',
  'create_plan': 'Created a plan',
  'approve_plan': 'Approved a plan',
  'breakdown_plan': 'Broke down plan into features',
  'ai_prompt': 'AI generation',
  'spawn_session': 'Spawned AI session',
  'search': 'Searched workspace',
  'create_agent': 'Created an agent',
  'create_skill': 'Created a skill',
  'list_agents': 'Listed agents',
  'list_skills': 'Listed skills',
  'list_workflows': 'Listed workflows',
  'sync_now': 'Synced to backend',
};

/// Tool name → category mapping.
const _toolCategories = {
  'create_note': 'notes',
  'update_note': 'notes',
  'delete_note': 'notes',
  'list_notes': 'notes',
  'get_note': 'notes',
  'create_feature': 'features',
  'update_feature': 'features',
  'list_features': 'features',
  'get_feature': 'features',
  'advance_feature': 'features',
  'set_current_feature': 'features',
  'submit_review': 'features',
  'create_project': 'projects',
  'list_projects': 'projects',
  'get_project': 'projects',
  'create_plan': 'plans',
  'approve_plan': 'plans',
  'breakdown_plan': 'plans',
  'ai_prompt': 'ai',
  'spawn_session': 'ai',
  'search': 'search',
  'create_agent': 'library',
  'create_skill': 'library',
  'list_agents': 'library',
  'list_skills': 'library',
  'list_workflows': 'library',
  'sync_now': 'sync',
};

/// Logs MCP tool calls in-memory for the activity screen.
///
/// Keeps the most recent [maxEntries] actions. Notifies listeners on new
/// entries so the activity screen can react.
class McpActionLogger extends ChangeNotifier {
  McpActionLogger({this.maxEntries = 500});

  final int maxEntries;
  final _entries = Queue<McpActionEntry>();

  /// Unmodifiable view of logged actions (newest first).
  List<McpActionEntry> get entries => _entries.toList();

  /// Number of logged actions.
  int get length => _entries.length;

  /// Logs a new MCP action.
  void log({
    required String toolName,
    required Map<String, dynamic> arguments,
    required int durationMs,
    required bool success,
    String? error,
  }) {
    _entries.addFirst(McpActionEntry(
      toolName: toolName,
      arguments: _sanitizeArgs(arguments),
      timestamp: DateTime.now(),
      durationMs: durationMs,
      success: success,
      error: error,
    ));

    // Cap the list
    while (_entries.length > maxEntries) {
      _entries.removeLast();
    }

    notifyListeners();
  }

  /// Filter entries by category.
  List<McpActionEntry> byCategory(String category) =>
      _entries.where((e) => e.category == category).toList();

  /// Clear all entries.
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Export all entries as JSON for publishing to backend.
  String exportJson() => jsonEncode(_entries.map((e) => e.toJson()).toList());

  /// Sanitize arguments to remove sensitive data.
  Map<String, dynamic> _sanitizeArgs(Map<String, dynamic> args) {
    final sanitized = Map<String, dynamic>.from(args);
    // Remove potentially large body content from logs
    if (sanitized.containsKey('body') && sanitized['body'] is String) {
      final body = sanitized['body'] as String;
      if (body.length > 200) {
        sanitized['body'] = '${body.substring(0, 200)}... (truncated)';
      }
    }
    if (sanitized.containsKey('content') && sanitized['content'] is String) {
      final content = sanitized['content'] as String;
      if (content.length > 200) {
        sanitized['content'] = '${content.substring(0, 200)}... (truncated)';
      }
    }
    return sanitized;
  }
}
