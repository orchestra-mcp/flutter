import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// JSON-RPC 2.0 client for communicating with the Orchestra MCP backend
/// over a WebSocket connection.
class McpClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Map<String, StreamController<List<int>>> _streams = {};

  bool _connected = false;

  /// Whether the client is currently connected.
  bool get isConnected => _connected;

  /// Opens a WebSocket connection to [url] and starts listening for messages.
  Future<void> connect(String url) async {
    if (_connected) return;

    final uri = Uri.parse(url);
    _channel = WebSocketChannel.connect(uri);

    // Wait for the connection to be established.
    await _channel!.ready;
    _connected = true;

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
    );
  }

  /// Closes the WebSocket connection and cleans up pending state.
  Future<void> disconnect() async {
    _connected = false;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    // Fail all pending requests.
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('WebSocket disconnected while request was pending'),
        );
      }
    }
    _pending.clear();

    // Close all active streaming controllers.
    for (final controller in _streams.values) {
      if (!controller.isClosed) {
        controller.addError(
          StateError('WebSocket disconnected while stream was active'),
        );
        unawaited(controller.close());
      }
    }
    _streams.clear();
  }

  /// Calls an MCP tool by [name] with the given [args] and returns the
  /// `result` field from the JSON-RPC response.
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    _ensureConnected();

    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final request = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': 'tools/call',
      'params': {
        'name': name,
        'arguments': args,
      },
    });

    _channel!.sink.add(request);
    return completer.future;
  }

  /// Calls an MCP tool in streaming mode. Returns a [Stream] of raw byte
  /// chunks that arrive as `stream/chunk` notifications from the server.
  ///
  /// The initial JSON-RPC response carries a `stream_id` which is used to
  /// correlate subsequent `stream/chunk` and `stream/end` notifications.
  /// Each chunk's `data` field is base64-decoded before being emitted.
  Stream<List<int>> callToolStreaming(
    String name,
    Map<String, dynamic> args,
  ) {
    _ensureConnected();

    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    // The stream controller that callers will listen to.
    // We don't know the stream_id yet, so we register it once the initial
    // response arrives.
    late final StreamController<List<int>> controller;
    controller = StreamController<List<int>>(
      onCancel: () {
        // Remove from the active streams map when the listener cancels.
        for (final entry in _streams.entries) {
          if (entry.value == controller) {
            _streams.remove(entry.key);
            break;
          }
        }
      },
    );

    final request = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': 'tools/call',
      'params': {
        'name': name,
        'arguments': args,
        'streaming': true,
      },
    });

    _channel!.sink.add(request);

    // When the initial response arrives, register the stream_id mapping.
    unawaited(
      completer.future.then((result) {
        final streamId = result['stream_id'] as String?;
        if (streamId == null) {
          controller.addError(
            const FormatException('Streaming response missing stream_id'),
          );
          unawaited(controller.close());
          return;
        }
        _streams[streamId] = controller;
      }).catchError((Object error) {
        controller.addError(error);
        unawaited(controller.close());
      }),
    );

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Internal message handling
  // ---------------------------------------------------------------------------

  void _onMessage(dynamic raw) {
    if (raw is! String) return;

    final Map<String, dynamic> message;
    try {
      message = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return; // Ignore non-JSON frames.
    }

    // --- JSON-RPC response (has 'id') ---
    if (message.containsKey('id') && message['id'] != null) {
      _handleResponse(message);
      return;
    }

    // --- JSON-RPC notification (no 'id', has 'method') ---
    final method = message['method'] as String?;
    if (method == 'stream/chunk') {
      _handleStreamChunk(message);
    } else if (method == 'stream/end') {
      _handleStreamEnd(message);
    }
  }

  void _handleResponse(Map<String, dynamic> message) {
    final id = message['id'] as int?;
    if (id == null) return;

    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;

    // Check for JSON-RPC error.
    if (message.containsKey('error')) {
      final error = message['error'] as Map<String, dynamic>;
      final code = error['code'] as int? ?? -1;
      final errorMessage = error['message'] as String? ?? 'Unknown error';
      final data = error['data'];
      completer.completeError(
        McpError(code: code, message: errorMessage, data: data),
      );
      return;
    }

    final result = message['result'];
    if (result is Map<String, dynamic>) {
      completer.complete(result);
    } else {
      completer.complete(<String, dynamic>{});
    }
  }

  void _handleStreamChunk(Map<String, dynamic> message) {
    final params = message['params'] as Map<String, dynamic>?;
    if (params == null) return;

    final streamId = params['stream_id'] as String?;
    if (streamId == null) return;

    final controller = _streams[streamId];
    if (controller == null || controller.isClosed) return;

    final b64 = params['data'] as String?;
    if (b64 == null) return;

    try {
      final bytes = base64Decode(b64);
      controller.add(Uint8List.fromList(bytes));
    } on FormatException catch (e) {
      controller.addError(e);
    }
  }

  void _handleStreamEnd(Map<String, dynamic> message) {
    final params = message['params'] as Map<String, dynamic>?;
    if (params == null) return;

    final streamId = params['stream_id'] as String?;
    if (streamId == null) return;

    final controller = _streams.remove(streamId);
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }

  void _onError(Object error) {
    // Propagate the WebSocket error to all pending requests.
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pending.clear();

    for (final controller in _streams.values) {
      if (!controller.isClosed) {
        controller.addError(error);
        unawaited(controller.close());
      }
    }
    _streams.clear();

    _connected = false;
  }

  void _onDone() {
    _connected = false;

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('WebSocket connection closed unexpectedly'),
        );
      }
    }
    _pending.clear();

    for (final controller in _streams.values) {
      if (!controller.isClosed) {
        unawaited(controller.close());
      }
    }
    _streams.clear();
  }

  void _ensureConnected() {
    if (!_connected || _channel == null) {
      throw StateError('McpClient is not connected. Call connect() first.');
    }
  }
}

/// Represents a JSON-RPC error returned by the MCP server.
class McpError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const McpError({
    required this.code,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'McpError($code): $message${data != null ? ' [$data]' : ''}';
}
