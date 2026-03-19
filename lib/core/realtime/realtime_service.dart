import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/realtime/realtime_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─── Well-known channel names ───────────────────────────────────────────────

/// Predefined channel names for the real-time service.
abstract final class RealtimeChannels {
  static const String tunnelStatus = 'tunnel_status';
  static const String fileChanges = 'file_changes';
  static const String featureUpdates = 'feature_updates';
  static const String teamActivity = 'team_activity';
}

// ─── Connection state ───────────────────────────────────────────────────────

enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

// ─── Service ────────────────────────────────────────────────────────────────

/// WebSocket service for receiving real-time broadcast events.
///
/// Connects to the server's WS endpoint and allows subscribing to
/// named channels. Each channel returns a filtered [Stream] of
/// [RealtimeEvent]s.
///
/// Features:
/// - Auth via token in connection query parameters.
/// - Auto-reconnect with exponential backoff.
/// - Subscribe / unsubscribe to individual channels.
/// - Single underlying WebSocket shared across all subscriptions.
class RealtimeService {
  RealtimeService();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _authToken;

  int _retryCount = 0;
  static const int _maxRetries = 15;
  static const Duration _heartbeatInterval = Duration(seconds: 25);

  // Subscribed channel names.
  final Set<String> _subscriptions = {};

  // ── Stream controllers ──────────────────────────────────────────────────

  final _stateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;

  /// Current connection state.
  RealtimeConnectionState get state => _state;

  /// Stream of connection state changes.
  Stream<RealtimeConnectionState> get stateStream => _stateController.stream;

  /// The set of channels currently subscribed to.
  Set<String> get subscriptions => Set.unmodifiable(_subscriptions);

  // ── Internal helpers ────────────────────────────────────────────────────

  void _setState(RealtimeConnectionState s) {
    if (_state == s) return;
    _state = s;
    _stateController.add(s);
  }

  // ── Connect / Disconnect ────────────────────────────────────────────────

  /// Connects to the real-time WebSocket endpoint.
  ///
  /// Uses [Env.wsBaseUrl] as the base URL and appends `/realtime`.
  /// The [authToken] is passed as a query parameter for authentication.
  Future<void> connect(String authToken) async {
    if (_state == RealtimeConnectionState.connected ||
        _state == RealtimeConnectionState.connecting) {
      return;
    }

    _authToken = authToken;
    _retryCount = 0;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    _setState(
      _retryCount == 0
          ? RealtimeConnectionState.connecting
          : RealtimeConnectionState.reconnecting,
    );

    try {
      final url = '${Env.wsBaseUrl}/realtime?token=$_authToken';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _retryCount = 0;
      _setState(RealtimeConnectionState.connected);
      _startHeartbeat();

      // Re-subscribe to channels after reconnect.
      for (final channel in _subscriptions) {
        _sendSubscribe(channel);
      }

      _socketSub = _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Gracefully disconnects from the real-time server.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _socketSub?.cancel();
    _socketSub = null;

    await _channel?.sink.close();
    _channel = null;

    _setState(RealtimeConnectionState.disconnected);
  }

  // ── Reconnect ───────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_state == RealtimeConnectionState.disconnected) return;
    if (_authToken == null) return;

    _heartbeatTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _channel = null;

    if (_retryCount >= _maxRetries) {
      _setState(RealtimeConnectionState.disconnected);
      return;
    }

    _setState(RealtimeConnectionState.reconnecting);

    final delayMs = (1000 * math.pow(2, _retryCount)).clamp(1000, 30000);
    _retryCount++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: delayMs.toInt()),
      _doConnect,
    );
  }

  // ── Heartbeat ───────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_state != RealtimeConnectionState.connected) return;
      _rawSend({'type': 'ping'});
    });
  }

  // ── Data handling ───────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String? ?? '';

      // Ignore pong responses.
      if (type == 'pong') return;

      // Parse as a realtime event.
      if (type == 'event') {
        final event = RealtimeEvent.fromJson(
          (json['data'] as Map<String, dynamic>?) ?? json,
        );
        _eventController.add(event);
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  // ── Send helpers ────────────────────────────────────────────────────────

  void _rawSend(Map<String, dynamic> payload) {
    if (_state != RealtimeConnectionState.connected) return;
    _channel?.sink.add(jsonEncode(payload));
  }

  void _sendSubscribe(String channel) {
    _rawSend({'type': 'subscribe', 'channel': channel});
  }

  void _sendUnsubscribe(String channel) {
    _rawSend({'type': 'unsubscribe', 'channel': channel});
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Subscribes to [channel] and returns a stream of [RealtimeEvent]s
  /// filtered to that channel.
  ///
  /// If already subscribed, returns the filtered stream without
  /// re-sending the subscribe command.
  Stream<RealtimeEvent> subscribe(String channel) {
    if (!_subscriptions.contains(channel)) {
      _subscriptions.add(channel);
      if (_state == RealtimeConnectionState.connected) {
        _sendSubscribe(channel);
      }
    }

    return _eventController.stream.where((event) => event.channel == channel);
  }

  /// Unsubscribes from [channel] and stops receiving its events.
  void unsubscribe(String channel) {
    _subscriptions.remove(channel);
    if (_state == RealtimeConnectionState.connected) {
      _sendUnsubscribe(channel);
    }
  }

  // ── Dispose ─────────────────────────────────────────────────────────────

  /// Releases all resources held by this service.
  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _socketSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscriptions.clear();
    _stateController.close();
    _eventController.close();
  }
}
