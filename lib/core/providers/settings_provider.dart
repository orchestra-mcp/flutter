import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';

/// User preferences (notification toggles, theme, language, etc.).
final preferencesProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getPreferences();
});

/// Active login sessions for the current user.
final settingsSessionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(apiClientProvider).listSettingsSessions();
});

/// API keys / personal access tokens.
final apiKeysProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(apiClientProvider).listApiKeys();
});

/// Connected third-party accounts (GitHub, Google, etc.).
final connectedAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(apiClientProvider).listConnectedAccounts();
});

/// AI notification settings from the local MCP notify_config tool.
/// Returns all notification settings (bools + strings).
final aiNotificationSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  const defaults = <String, dynamic>{
    'ai_push_enabled': true,
    'ai_voice_enabled': true,
    'socket_push_enabled': true,
    'voice_name': '',
    'voice_speed': '',
    'voice_volume': '',
    'quiet_hours_start': '',
    'quiet_hours_end': '',
  };
  final mcp = ref.watch(mcpClientProvider);
  if (mcp == null) return defaults;
  try {
    final result = await mcp.callTool('notify_config', {'action': 'get'});
    // Unwrap MCP content envelope → JSON text.
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        final text = first['text'] as String? ?? '';
        if (text.isNotEmpty) {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) return {...defaults, ...decoded};
        }
      }
    }
  } catch (_) {}
  return defaults;
});
