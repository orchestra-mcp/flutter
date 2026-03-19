import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Service for dispatching smart actions (Claude Code bridge) and MCP tool
/// calls to a desktop machine.
///
/// Connection strategy:
///   1. Try local WiFi first (ws://<LAN_IP>:9201/ws) — fast, no auth needed
///   2. Fall back to cloud tunnel (wss://api/tunnels/:id/ws?token=jwt)
class TunnelBridgeService {
  TunnelBridgeService();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  bool _connected = false;
  int _rpcId = 0;
  String _connectionMode = ''; // 'local' or 'tunnel'

  final _messageController = StreamController<BridgeMessage>.broadcast();
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};

  bool get isConnected => _connected;
  String get connectionMode => _connectionMode;
  Stream<BridgeMessage> get messages => _messageController.stream;

  // ── Auto-connect: local WiFi first, cloud tunnel fallback ──────────────

  /// Connects to the desktop's MCP server automatically.
  /// Tries local WiFi first, falls back to cloud tunnel.
  Future<bool> autoConnect({String? tunnelId, String? authToken}) async {
    if (_connected) return true;

    // Step 1: Try local WiFi.
    final localHost = Env.mcpHost;
    if (await _canReach(localHost, 9201)) {
      final url = 'ws://$localHost:9201/ws';
      debugPrint('[Bridge] Connecting via local WiFi: $url');
      if (await connectToUrl(url)) {
        _connectionMode = 'local';
        return true;
      }
    }

    // Step 2: Fall back to cloud tunnel.
    if (tunnelId != null && authToken != null && authToken.isNotEmpty) {
      final wsScheme = Env.apiBaseUrl.startsWith('https') ? 'wss' : 'ws';
      final base = Env.apiBaseUrl.replaceFirst(RegExp(r'^https?'), wsScheme);
      final url = '$base/api/tunnels/$tunnelId/ws?token=$authToken';
      debugPrint('[Bridge] Connecting via cloud tunnel: $tunnelId');
      if (await connectToUrl(url)) {
        _connectionMode = 'tunnel';
        return true;
      }
    }

    _messageController.add(
      const BridgeMessage(
        type: BridgeMessageType.system,
        payload: 'Failed to connect — no local or tunnel connection available',
      ),
    );
    return false;
  }

  /// Connects directly to a WebSocket URL.
  Future<bool> connectToUrl(String wsUrl) async {
    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;

      _socketSub = _channel!.stream.listen(
        _onData,
        onError: (Object e) {
          _messageController.add(
            BridgeMessage(
              type: BridgeMessageType.system,
              payload: 'Connection error: $e',
            ),
          );
          _connected = false;
        },
        onDone: () {
          _connected = false;
          _messageController.add(
            const BridgeMessage(
              type: BridgeMessageType.system,
              payload: 'Disconnected from bridge',
            ),
          );
        },
      );

      // MCP initialize handshake.
      await _sendRpc('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'orchestra-mobile-bridge', 'version': '1.0.0'},
      });

      _messageController.add(
        BridgeMessage(
          type: BridgeMessageType.system,
          payload: 'Connected ($_connectionMode)',
        ),
      );

      return true;
    } catch (e) {
      _channel = null;
      _connected = false;
      return false;
    }
  }

  /// Disconnects from the bridge.
  Future<void> disconnect() async {
    _connected = false;
    _connectionMode = '';
    await _socketSub?.cancel();
    _socketSub = null;
    await _channel?.sink.close();
    _channel = null;
    _pendingRequests.clear();
  }

  // ── Smart action dispatch ─────────────────────────────────────────────

  /// Dispatches a smart action (ai_prompt) through the bridge.
  Future<BridgeMessage> sendSmartAction({
    required String prompt,
    String? context,
  }) async {
    if (!_connected) {
      throw StateError('Bridge not connected. Call autoConnect() first.');
    }

    _messageController.add(
      BridgeMessage(type: BridgeMessageType.request, payload: prompt),
    );

    try {
      final result = await _callTool('ai_prompt', {
        'prompt': prompt,
        if (context != null) 'context': context,
      });

      final responseText = _extractText(result);
      final response = BridgeMessage(
        type: BridgeMessageType.response,
        payload: responseText,
      );
      _messageController.add(response);
      return response;
    } catch (e) {
      final error = BridgeMessage(
        type: BridgeMessageType.system,
        payload: 'Smart action failed: $e',
      );
      _messageController.add(error);
      return error;
    }
  }

  /// Calls any MCP tool through the bridge.
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    if (!_connected) {
      throw StateError('Bridge not connected. Call autoConnect() first.');
    }
    return _callTool(name, arguments);
  }

  /// Lists available tools from the remote machine.
  Future<List<Map<String, dynamic>>> listTools() async {
    if (!_connected) return [];
    final result = await _sendRpc('tools/list', {});
    final tools = result['tools'] as List? ?? [];
    return tools.cast<Map<String, dynamic>>();
  }

  // ── Internal ──────────────────────────────────────────────────────────

  Future<bool> _canReach(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      // Handle relay envelope (tunnel proxy wraps responses).
      final message = data.containsKey('message')
          ? (data['message'] is String
                ? jsonDecode(data['message'] as String) as Map<String, dynamic>
                : data['message'] as Map<String, dynamic>)
          : data;

      final id = message['id'];
      if (id != null) {
        final intId = id is int ? id : int.tryParse(id.toString());
        if (intId != null && _pendingRequests.containsKey(intId)) {
          final result = message['result'] as Map<String, dynamic>? ?? {};
          _pendingRequests.remove(intId)!.complete(_unwrapMcp(result));
        }
      }
    } catch (_) {}
  }

  Map<String, dynamic> _unwrapMcp(Map<String, dynamic> result) {
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        final text = first['text'] as String? ?? '';
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
        return {'text': text};
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> _sendRpc(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = ++_rpcId;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _channel?.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('RPC timeout: $method');
      },
    );
  }

  Future<Map<String, dynamic>> _callTool(
    String name,
    Map<String, dynamic> arguments,
  ) {
    return _sendRpc('tools/call', {'name': name, 'arguments': arguments});
  }

  String _extractText(Map<String, dynamic> result) {
    final text = result['text'] as String?;
    if (text != null) return text;
    return result.toString();
  }

  void dispose() {
    _connected = false;
    _socketSub?.cancel();
    _channel?.sink.close();
    _pendingRequests.clear();
    _messageController.close();
  }
}

/// The type of a bridge message.
enum BridgeMessageType { system, request, response, stream }

/// A message exchanged through the tunnel bridge.
class BridgeMessage {
  const BridgeMessage({
    required this.type,
    required this.payload,
    this.metadata,
  });

  final BridgeMessageType type;
  final String payload;
  final Map<String, String>? metadata;

  @override
  String toString() =>
      'BridgeMessage($type, ${payload.length > 60 ? '${payload.substring(0, 60)}...' : payload})';
}
