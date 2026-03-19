import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a singleton [McpClient] instance.
///
/// The client is created once and shared across the app. Use
/// [mcpConnectionProvider] to trigger the actual WebSocket connection.
final mcpClientProvider = Provider<McpClient>((ref) {
  final client = McpClient();
  ref.onDispose(client.disconnect);
  return client;
});

/// Connects the [McpClient] to the Orchestra backend over WebSocket.
///
/// Reads `server_url` and `web_gate_key` from [SharedPreferences] to build
/// the connection URL. Defaults to `http://localhost:9201` when no URL is
/// stored.
///
/// Returns the connected [McpClient] so downstream providers can depend on
/// the connection being ready.
final mcpConnectionProvider = FutureProvider<McpClient>((ref) async {
  final client = ref.watch(mcpClientProvider);
  final prefs = await SharedPreferences.getInstance();

  final serverUrl = prefs.getString('server_url') ?? 'http://localhost:9201';
  final apiKey = prefs.getString('web_gate_key') ?? '';

  // Convert the HTTP URL to a WebSocket URL.
  final uri = Uri.parse(serverUrl);
  final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
  final wsUri = uri.replace(
    scheme: wsScheme,
    path: '/ws',
    queryParameters: apiKey.isNotEmpty ? {'api_key': apiKey} : null,
  );

  await client.connect(wsUri.toString());
  return client;
});
