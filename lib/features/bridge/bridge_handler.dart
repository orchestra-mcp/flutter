import 'dart:async';

import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/features/bridge/executors/explain_executor.dart';
import 'package:orchestra/features/bridge/executors/fix_executor.dart';
import 'package:orchestra/features/bridge/executors/summarize_executor.dart';

/// Handles incoming [TunnelAction] requests on the desktop side,
/// routing each to the appropriate executor and streaming responses
/// back through the tunnel.
///
/// This is the desktop-side counterpart to the web-side action dispatcher.
/// When the tunnel server forwards an action, [BridgeHandler] picks the
/// right executor and returns a stream of [TunnelResponse] updates.
class BridgeHandler {
  BridgeHandler({
    SummarizeExecutor? summarizeExecutor,
    ExplainExecutor? explainExecutor,
    FixExecutor? fixExecutor,
  }) : _summarizeExecutor = summarizeExecutor ?? SummarizeExecutor(),
       _explainExecutor = explainExecutor ?? ExplainExecutor(),
       _fixExecutor = fixExecutor ?? FixExecutor();

  final SummarizeExecutor _summarizeExecutor;
  final ExplainExecutor _explainExecutor;
  final FixExecutor _fixExecutor;

  /// Routes [action] to the correct executor and returns a stream
  /// of [TunnelResponse] updates.
  ///
  /// The stream emits:
  /// 1. A `pending` response immediately.
  /// 2. One or more `running` responses with partial [TunnelResponse.result].
  /// 3. A final `completed` or `failed` response.
  Stream<TunnelResponse> handleAction(TunnelAction action) async* {
    final requestId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

    // Emit initial pending status.
    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.pending,
    );

    try {
      final executor = _resolveExecutor(action.actionType);

      await for (final response in executor.execute(
        requestId: requestId,
        context: action.context,
        parameters: action.parameters,
      )) {
        yield response;
      }
    } catch (e) {
      yield TunnelResponse(
        requestId: requestId,
        status: TunnelResponseStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Resolves the executor for a given [TunnelActionType].
  ///
  /// For `translate` and `custom` action types, the explain executor
  /// is reused with the raw context passed through (the parameters
  /// carry the custom instruction or target language).
  ActionExecutor _resolveExecutor(TunnelActionType type) => switch (type) {
    TunnelActionType.summarize => _summarizeExecutor,
    TunnelActionType.explain => _explainExecutor,
    TunnelActionType.fix => _fixExecutor,
    // Translate and custom reuse explain with different prompting.
    TunnelActionType.translate => _explainExecutor,
    TunnelActionType.custom => _explainExecutor,
  };
}

/// Abstract interface that all action executors implement.
///
/// Each executor receives the request context and streams back
/// [TunnelResponse] updates as results are produced.
abstract class ActionExecutor {
  /// Executes the action and yields a stream of [TunnelResponse] updates.
  ///
  /// [requestId] is the unique identifier for this request.
  /// [context] is the input text to operate on.
  /// [parameters] are optional action-specific key-value pairs.
  Stream<TunnelResponse> execute({
    required String requestId,
    required String context,
    Map<String, dynamic> parameters = const {},
  });
}
