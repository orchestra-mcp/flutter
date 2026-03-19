import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:orchestra/features/terminal/terminal_backend.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xterm/xterm.dart';

/// Remote terminal backend that connects to the desktop's `orchestra serve`
/// web-gate WebSocket and uses MCP tool calls to manage a PTY terminal.
///
/// Works in two modes:
/// - **Direct** (local dev): connects to `ws://<desktop-ip>:9201` web-gate
/// - **Tunnel** (cloud): connects to `/api/tunnels/:id/ws` on the web server
class RemoteTerminalBackend extends TerminalBackend {
  RemoteTerminalBackend({
    required this.wsUrl,
    this.shell,
  });

  /// Full WebSocket URL to connect to.
  /// Direct: `ws://192.168.1.x:9201` (web-gate)
  /// Tunnel: `ws://api.example.com/api/tunnels/:id/ws?token=xxx`
  final String wsUrl;
  final String? shell;

  @override
  final Terminal terminal = Terminal(maxLines: 10000);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _outputPollTimer;
  String? _remoteTerminalId;
  int _rpcId = 0;
  int _errorCount = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pendingRequests = {};

  int _nextRpcId() => ++_rpcId;

  @override
  Future<void> start() async {
    terminal.write('Connecting to remote terminal...\r\n');

    try {
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
    } catch (e) {
      terminal.write('\x1B[31mConnection failed: $e\x1B[0m\r\n');
      return;
    }

    _socketSub = _channel!.stream.listen(
      _onMessage,
      onError: (e) {
        terminal.write('\r\n\x1B[31m[Connection error: $e]\x1B[0m\r\n');
      },
      onDone: () {
        terminal.write('\r\n\x1B[33m[Disconnected]\x1B[0m\r\n');
        _outputPollTimer?.cancel();
      },
    );

    // MCP initialize handshake.
    try {
      await _sendRpc('initialize', {
        'protocolVersion': '2024-11-05',
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'orchestra-mobile', 'version': '1.0.0'},
      });
    } catch (e) {
      terminal.write('\x1B[31mMCP handshake failed: $e\x1B[0m\r\n');
      return;
    }

    // Create a terminal on the remote machine (retry on rate limit).
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final result = await _callTool('create_terminal', {
          if (shell != null) 'shell': shell!,
        });

        final text = result['text'] as String? ?? '';

        // Check for rate limit error.
        if (text.contains('rate limit')) {
          terminal.write('\x1B[33mWaiting for server...\x1B[0m\r\n');
          await Future<void>.delayed(const Duration(seconds: 3));
          continue;
        }

        try {
          final parsed = jsonDecode(text) as Map<String, dynamic>;
          _remoteTerminalId = parsed['terminal_id'] as String?;
        } catch (_) {
          _remoteTerminalId = null;
        }

        if (_remoteTerminalId != null) break;

        terminal.write('\x1B[31mUnexpected response, retrying...\x1B[0m\r\n');
        await Future<void>.delayed(const Duration(seconds: 2));
      } catch (e) {
        terminal.write('\x1B[31mRetrying... ($e)\x1B[0m\r\n');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    if (_remoteTerminalId == null) {
      terminal.write('\x1B[31mFailed to create terminal session\x1B[0m\r\n');
      return;
    }

    // Wire keyboard input.
    terminal.onOutput = (data) {
      if (_remoteTerminalId == null) return;
      _callToolFire('send_input', {
        'terminal_id': _remoteTerminalId!,
        'data': data,
      });
    };

    // Wire resize.
    terminal.onResize = (w, h, pw, ph) {
      if (_remoteTerminalId == null) return;
      _callToolFire('resize_terminal', {
        'terminal_id': _remoteTerminalId!,
        'cols': w,
        'rows': h,
      });
    };

    // Poll for output.
    _outputPollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _pollOutput();
    });
  }

  bool _polling = false;

  Future<void> _pollOutput() async {
    if (_remoteTerminalId == null || _channel == null || _polling) return;
    _polling = true;
    try {
      final result = await _callTool('terminal_output', {
        'terminal_id': _remoteTerminalId!,
      });
      _errorCount = 0;
      final output = result['text'] as String? ?? '';
      if (output.isNotEmpty) {
        terminal.write(output);
      }
    } catch (e) {
      _errorCount++;
      if (_errorCount >= 3) {
        _outputPollTimer?.cancel();
        _outputPollTimer = null;
        terminal.write('\r\n\x1B[31m[Disconnected]\x1B[0m\r\n');
      }
    } finally {
      _polling = false;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      // Handle relay envelope (tunnel proxy wraps responses).
      final inner = data.containsKey('message')
          ? (data['message'] is String
              ? jsonDecode(data['message'] as String) as Map<String, dynamic>
              : data['message'] as Map<String, dynamic>)
          : data;

      final id = inner['id'];
      if (id != null) {
        final intId = id is int ? id : int.tryParse(id.toString());
        if (intId != null && _pendingRequests.containsKey(intId)) {
          // Unwrap MCP content envelope if present.
          final result = inner['result'] as Map<String, dynamic>? ?? {};
          final unwrapped = _unwrapMcpResult(result);
          _pendingRequests.remove(intId)!.complete(unwrapped);
          return;
        }
      }
    } catch (e) {
      debugPrint('[RemoteTerminal] parse error: $e');
    }
  }

  /// Unwraps MCP content envelope:
  /// {"content": [{"type": "text", "text": "..."}]} → {"text": "..."}
  Map<String, dynamic> _unwrapMcpResult(Map<String, dynamic> result) {
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        final text = first['text'] as String? ?? '';
        return {'text': text};
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> _sendRpc(
      String method, Map<String, dynamic> params) async {
    final id = _nextRpcId();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    final request = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    _channel?.sink.add(request);

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('RPC timeout: $method');
      },
    );
  }

  Future<Map<String, dynamic>> _callTool(
      String name, Map<String, dynamic> arguments) {
    return _sendRpc('tools/call', {'name': name, 'arguments': arguments});
  }

  void _callToolFire(String name, Map<String, dynamic> arguments) {
    final id = _nextRpcId();
    _channel?.sink.add(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': 'tools/call',
      'params': {'name': name, 'arguments': arguments},
    }));
  }

  @override
  Future<void> dispose() async {
    _outputPollTimer?.cancel();
    if (_remoteTerminalId != null && _channel != null) {
      try {
        await _callTool(
            'close_terminal', {'terminal_id': _remoteTerminalId!});
      } catch (_) {}
    }
    await _socketSub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _pendingRequests.clear();
  }
}
