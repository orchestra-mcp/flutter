import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/tunnel/tunnel_client.dart';
import 'package:orchestra/core/tunnel/tunnel_protocol.dart';

// ─── Singleton tunnel client ────────────────────────────────────────────────

/// Provides a single [TunnelClient] instance for the lifetime of the app.
///
/// The client is created lazily and disposed when the provider is torn down.
final tunnelClientProvider = Provider<TunnelClient>((ref) {
  final client = TunnelClient();
  ref.onDispose(client.dispose);
  return client;
});

// ─── Connection status stream ───────────────────────────────────────────────

/// Exposes the tunnel connection status as a [StreamProvider].
///
/// Widgets that depend on this will rebuild whenever the status changes.
final tunnelStatusProvider = StreamProvider<TunnelConnectionStatus>((ref) {
  final client = ref.watch(tunnelClientProvider);
  return client.statusStream;
});

// ─── Incoming messages stream ───────────────────────────────────────────────

/// Raw stream of every incoming [TunnelMessage] from the server.
final tunnelMessagesProvider = StreamProvider<TunnelMessage>((ref) {
  final client = ref.watch(tunnelClientProvider);
  return client.onMessage;
});

// ─── Action dispatcher ──────────────────────────────────────────────────────

/// Notifier for dispatching actions through the tunnel and tracking
/// the latest response per request.
class TunnelActionsNotifier extends Notifier<TunnelActionsState> {
  @override
  TunnelActionsState build() => const TunnelActionsState();

  /// Connects the tunnel client using credentials from [TokenStorage]
  /// and the WS_BASE_URL from [Env].
  Future<void> connect() async {
    final client = ref.read(tunnelClientProvider);
    if (client.status == TunnelConnectionStatus.connected) return;

    final token = await const TokenStorage().getAccessToken();
    const serverUrl = '${Env.wsBaseUrl}/tunnel';
    await client.connect(serverUrl, token ?? '');
  }

  /// Disconnects the tunnel client.
  Future<void> disconnect() async {
    final client = ref.read(tunnelClientProvider);
    await client.disconnect();
  }

  /// Dispatches a [TunnelAction] and returns a broadcast stream of
  /// [TunnelResponse] updates.
  ///
  /// Also updates [state] with the latest response so widgets can
  /// read it synchronously via `ref.watch(tunnelActionsProvider)`.
  Stream<TunnelResponse> dispatch(TunnelAction action) {
    final client = ref.read(tunnelClientProvider);

    state = state.copyWith(
      isDispatching: true,
      latestResponse: null,
      error: null,
    );

    final responseStream = client.dispatchAction(action);

    // Fork a listener to keep state in sync.
    late StreamSubscription<TunnelResponse> sub;
    sub = responseStream.listen(
      (response) {
        state = state.copyWith(
          latestResponse: response,
          isDispatching: response.status == TunnelResponseStatus.running ||
              response.status == TunnelResponseStatus.pending,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          isDispatching: false,
          error: error.toString(),
        );
      },
      onDone: () {
        state = state.copyWith(isDispatching: false);
        sub.cancel();
      },
    );

    return responseStream;
  }

  /// Clears the latest response from state.
  void clearResponse() {
    state = state.copyWith(
      latestResponse: null,
      error: null,
      isDispatching: false,
    );
  }
}

/// Immutable state snapshot for the tunnel actions notifier.
class TunnelActionsState {
  const TunnelActionsState({
    this.isDispatching = false,
    this.latestResponse,
    this.error,
  });

  /// Whether an action is currently being dispatched / streamed.
  final bool isDispatching;

  /// The most recent [TunnelResponse] received.
  final TunnelResponse? latestResponse;

  /// Human-readable error string, if the last dispatch failed.
  final String? error;

  TunnelActionsState copyWith({
    bool? isDispatching,
    TunnelResponse? latestResponse,
    String? error,
  }) =>
      TunnelActionsState(
        isDispatching: isDispatching ?? this.isDispatching,
        latestResponse: latestResponse ?? this.latestResponse,
        error: error ?? this.error,
      );
}

/// Provides [TunnelActionsNotifier] for dispatching smart actions.
final tunnelActionsProvider =
    NotifierProvider<TunnelActionsNotifier, TunnelActionsState>(
  TunnelActionsNotifier.new,
);
