import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/core/tunnel/tunnel_provider.dart';
import 'package:orchestra/features/bridge/bridge_handler.dart';

// ─── Bridge handler singleton ───────────────────────────────────────────────

/// Provides a single [BridgeHandler] instance for the desktop side.
final bridgeHandlerProvider = Provider<BridgeHandler>((ref) {
  return BridgeHandler();
});

// ─── Bridge state ───────────────────────────────────────────────────────────

/// Immutable state for bridge processing.
class BridgeState {
  const BridgeState({
    this.isProcessing = false,
    this.activeRequestId,
    this.latestResponse,
    this.error,
  });

  /// Whether the bridge is currently processing an action.
  final bool isProcessing;

  /// The request ID of the currently active action, if any.
  final String? activeRequestId;

  /// The most recent response from the bridge handler.
  final TunnelResponse? latestResponse;

  /// Human-readable error, if the last action failed.
  final String? error;

  BridgeState copyWith({
    bool? isProcessing,
    String? activeRequestId,
    TunnelResponse? latestResponse,
    String? error,
  }) => BridgeState(
    isProcessing: isProcessing ?? this.isProcessing,
    activeRequestId: activeRequestId ?? this.activeRequestId,
    latestResponse: latestResponse ?? this.latestResponse,
    error: error ?? this.error,
  );
}

// ─── Bridge notifier ────────────────────────────────────────────────────────

/// Wires the [BridgeHandler] to the tunnel so that incoming actions
/// are automatically handled and responses are sent back.
///
/// On the desktop side, this listens for incoming tunnel messages
/// of type [TunnelMessageType.action], processes them through
/// [BridgeHandler], and sends responses back through the tunnel.
class BridgeNotifier extends Notifier<BridgeState> {
  StreamSubscription<TunnelMessage>? _tunnelSub;

  @override
  BridgeState build() {
    // Start listening for incoming actions from the tunnel.
    _startListening();
    ref.onDispose(_stopListening);
    return const BridgeState();
  }

  void _startListening() {
    final client = ref.read(tunnelClientProvider);
    _tunnelSub = client.onMessage.listen(_onTunnelMessage);
  }

  void _stopListening() {
    _tunnelSub?.cancel();
    _tunnelSub = null;
  }

  /// Handles an incoming tunnel message. Only processes action-type messages.
  void _onTunnelMessage(TunnelMessage message) {
    if (message.type != TunnelMessageType.action) return;

    final action = TunnelAction.fromJson(message.payload);
    _processAction(message.id, action);
  }

  /// Processes an action through the bridge handler and streams responses
  /// back through the tunnel.
  Future<void> _processAction(String messageId, TunnelAction action) async {
    final handler = ref.read(bridgeHandlerProvider);
    final client = ref.read(tunnelClientProvider);

    state = state.copyWith(
      isProcessing: true,
      activeRequestId: messageId,
      error: null,
      latestResponse: null,
    );

    try {
      await for (final response in handler.handleAction(action)) {
        state = state.copyWith(latestResponse: response);

        // Send each response back through the tunnel.
        final responseMessage = TunnelMessage(
          id: '${messageId}_resp_${DateTime.now().microsecondsSinceEpoch}',
          type: TunnelMessageType.response,
          payload: {...response.toJson(), 'request_id': messageId},
          timestamp: DateTime.now(),
          sourceId: null,
          targetId: null,
        );
        client.sendMessage(responseMessage);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      // Send error response back through the tunnel.
      final errorMessage = TunnelMessage(
        id: '${messageId}_err',
        type: TunnelMessageType.error,
        payload: {
          'request_id': messageId,
          'status': TunnelResponseStatus.failed.name,
          'error': e.toString(),
        },
        timestamp: DateTime.now(),
      );
      client.sendMessage(errorMessage);
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Manually dispatches an action through the bridge (for local use,
  /// without going through the tunnel).
  Stream<TunnelResponse> dispatchLocal(TunnelAction action) {
    final handler = ref.read(bridgeHandlerProvider);
    return handler.handleAction(action);
  }

  /// Clears the current bridge state.
  void clear() {
    state = const BridgeState();
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

/// Provides [BridgeNotifier] for the desktop bridge handler.
final bridgeProvider = NotifierProvider<BridgeNotifier, BridgeState>(
  BridgeNotifier.new,
);
