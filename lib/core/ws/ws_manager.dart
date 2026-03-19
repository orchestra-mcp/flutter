import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/ws/ws_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WsState { disconnected, connecting, connected, reconnecting }

class WsManager {
  WsManager({Ref? ref}) : _ref = ref;

  // ignore: unused_field
  final Ref? _ref;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  int _retryCount = 0;
  static const int _maxRetries = 10;

  final _stateController = StreamController<WsState>.broadcast();
  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<WsState> get stateStream => _stateController.stream;
  Stream<WsEvent> get eventStream => _eventController.stream;
  WsState _state = WsState.disconnected;
  WsState get state => _state;

  void _setState(WsState s) {
    _state = s;
    _stateController.add(s);
  }

  Future<String> _resolveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final base = prefs.getString('server_url') ?? 'http://localhost:8080';
    final wsBase = base.replaceFirst(RegExp('^http'), 'ws');

    // Server authenticates WS via ?token= query param.
    const storage = TokenStorage();
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return '$wsBase/ws?token=${Uri.encodeComponent(token)}';
    }
    return '$wsBase/ws';
  }

  Future<void> connect() async {
    if (_state == WsState.connected || _state == WsState.connecting) return;
    _setState(WsState.connecting);
    try {
      final url = await _resolveUrl();
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _retryCount = 0;
      _setState(WsState.connected);
      _sub = _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      _eventController.add(WsEvent.fromJson(json));
    } catch (_) {
      // ignore malformed frames
    }
  }

  void _scheduleReconnect() {
    if (_state == WsState.disconnected) return;
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    if (_retryCount >= _maxRetries) {
      _setState(WsState.disconnected);
      return;
    }
    _setState(WsState.reconnecting);
    final delay = Duration(
      milliseconds: (1000 * math.pow(2, _retryCount).clamp(1, 30)).toInt(),
    );
    _retryCount++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  void send(Map<String, dynamic> payload) {
    if (_state != WsState.connected) return;
    _channel?.sink.add(jsonEncode(payload));
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(WsState.disconnected);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _stateController.close();
    _eventController.close();
  }
}
