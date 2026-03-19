import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Connection state ───────────────────────────────────────────────────────

/// Observable connection status of the tunnel WebSocket.
enum TunnelConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// ─── Tunnel Client ──────────────────────────────────────────────────────────

/// WebSocket-based client for the tunnel action dispatch protocol.
///
/// Usage:
/// ```dart
/// final client = TunnelClient();
/// await client.connect('wss://example.com/tunnel', 'my-token');
/// client.dispatchAction(action).listen((response) { ... });
/// await client.disconnect();
/// ```
class TunnelClient {
  TunnelClient();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _serverUrl;
  String? _authToken;

  int _retryCount = 0;
  static const int _maxRetries = 12;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // ── Stream controllers ────────────────────────────────────────────────────

  final _statusController =
      StreamController<TunnelConnectionStatus>.broadcast();
  final _messageController = StreamController<TunnelMessage>.broadcast();

  TunnelConnectionStatus _status = TunnelConnectionStatus.disconnected;

  /// Current connection status.
  TunnelConnectionStatus get status => _status;

  /// Stream of connection status changes.
  Stream<TunnelConnectionStatus> get statusStream => _statusController.stream;

  /// Stream of all incoming [TunnelMessage]s from the server.
  Stream<TunnelMessage> get onMessage => _messageController.stream;

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _setStatus(TunnelConnectionStatus s) {
    if (_status == s) return;
    _status = s;
    _statusController.add(s);
  }

  /// Generates a v4-ish UUID for message IDs.
  static String _uuid() {
    final rng = math.Random.secure();
    return '${_hex(rng, 8)}-${_hex(rng, 4)}-4${_hex(rng, 3)}-${_hex(rng, 4)}-${_hex(rng, 12)}';
  }

  static String _hex(math.Random rng, int length) =>
      List.generate(length, (_) => rng.nextInt(16).toRadixString(16)).join();

  // ── Connect / Disconnect ──────────────────────────────────────────────────

  /// Establishes a WebSocket connection to the tunnel server.
  ///
  /// [serverUrl] must be a `ws://` or `wss://` URL.
  /// [authToken] is sent as a query parameter for authentication.
  Future<void> connect(String serverUrl, String authToken) async {
    if (_status == TunnelConnectionStatus.connected ||
        _status == TunnelConnectionStatus.connecting) {
      return;
    }

    _serverUrl = serverUrl;
    _authToken = authToken;
    _retryCount = 0;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    _setStatus(
      _retryCount == 0
          ? TunnelConnectionStatus.connecting
          : TunnelConnectionStatus.reconnecting,
    );

    try {
      final uri = Uri.parse('$_serverUrl?token=$_authToken');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _retryCount = 0;
      _setStatus(TunnelConnectionStatus.connected);
      _startHeartbeat();

      _socketSub = _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Gracefully closes the WebSocket and stops reconnection.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _socketSub?.cancel();
    _socketSub = null;

    await _channel?.sink.close();
    _channel = null;

    _setStatus(TunnelConnectionStatus.disconnected);
  }

  // ── Reconnect ─────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_status == TunnelConnectionStatus.disconnected) return;
    if (_serverUrl == null || _authToken == null) return;

    _heartbeatTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _channel = null;

    if (_retryCount >= _maxRetries) {
      _setStatus(TunnelConnectionStatus.disconnected);
      return;
    }

    _setStatus(TunnelConnectionStatus.reconnecting);

    // Exponential backoff: 1s, 2s, 4s, ... capped at 30s.
    final delayMs = (1000 * math.pow(2, _retryCount)).clamp(1000, 30000);
    _retryCount++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: delayMs.toInt()),
      _doConnect,
    );
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_status != TunnelConnectionStatus.connected) return;

      final ping = TunnelMessage(
        id: _uuid(),
        type: TunnelMessageType.status,
        payload: const {'kind': 'ping'},
        timestamp: DateTime.now(),
      );
      _rawSend(ping.encode());
    });
  }

  // ── Incoming data ─────────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = TunnelMessage.fromJson(json);

      // Respond to server pong silently.
      if (msg.type == TunnelMessageType.status &&
          msg.payload['kind'] == 'pong') {
        return;
      }

      _messageController.add(msg);
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  void _rawSend(String data) {
    if (_status != TunnelConnectionStatus.connected) return;
    _channel?.sink.add(data);
  }

  /// Sends a raw [TunnelMessage] through the WebSocket.
  void sendMessage(TunnelMessage message) => _rawSend(message.encode());

  /// Dispatches a [TunnelAction] and returns a stream of [TunnelResponse]
  /// updates. The stream completes when the response reaches a terminal
  /// status (completed or failed).
  ///
  /// Each intermediate response carries partial [TunnelResponse.result] text
  /// and an optional [TunnelResponse.progress] value.
  Stream<TunnelResponse> dispatchAction(TunnelAction action) {
    final requestId = _uuid();

    // Build the action message.
    final message = TunnelMessage(
      id: requestId,
      type: TunnelMessageType.action,
      payload: action.toJson(),
      timestamp: DateTime.now(),
    );

    // Create a broadcast stream so multiple listeners can consume responses.
    final controller = StreamController<TunnelResponse>.broadcast();

    late StreamSubscription<TunnelMessage> sub;
    sub = onMessage.listen((msg) {
      if (msg.type != TunnelMessageType.response &&
          msg.type != TunnelMessageType.error) {
        return;
      }

      final responsePayload = msg.payload;
      if (responsePayload['request_id'] != requestId) return;

      final response = TunnelResponse.fromJson(responsePayload);
      controller.add(response);

      if (response.isTerminal) {
        sub.cancel();
        controller.close();
      }
    });

    // If the client disconnects before the response completes, clean up.
    controller.onCancel = () {
      sub.cancel();
    };

    // Actually send the message.
    sendMessage(message);

    return controller.stream;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  /// Releases all resources. Call when the client is no longer needed.
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.close();
    _messageController.close();
  }
}
