import 'dart:convert';

// ─── Message Types ──────────────────────────────────────────────────────────

/// Classification of tunnel protocol messages.
enum TunnelMessageType {
  /// A request to perform an action on the desktop side.
  action,

  /// A response (possibly streaming) from the desktop side.
  response,

  /// A status update about the tunnel connection or a running action.
  status,

  /// An error that occurred during processing.
  error;

  static TunnelMessageType fromString(String value) => switch (value) {
        'action' => TunnelMessageType.action,
        'response' => TunnelMessageType.response,
        'status' => TunnelMessageType.status,
        'error' => TunnelMessageType.error,
        _ => TunnelMessageType.status,
      };
}

// ─── Action Types ───────────────────────────────────────────────────────────

/// The kind of smart action to execute.
enum TunnelActionType {
  summarize,
  explain,
  fix,
  translate,
  custom;

  static TunnelActionType fromString(String value) => switch (value) {
        'summarize' => TunnelActionType.summarize,
        'explain' => TunnelActionType.explain,
        'fix' => TunnelActionType.fix,
        'translate' => TunnelActionType.translate,
        'custom' => TunnelActionType.custom,
        _ => TunnelActionType.custom,
      };
}

// ─── Response Status ────────────────────────────────────────────────────────

/// Status of an in-flight action response.
enum TunnelResponseStatus {
  pending,
  running,
  completed,
  failed;

  static TunnelResponseStatus fromString(String value) => switch (value) {
        'pending' => TunnelResponseStatus.pending,
        'running' => TunnelResponseStatus.running,
        'completed' => TunnelResponseStatus.completed,
        'failed' => TunnelResponseStatus.failed,
        _ => TunnelResponseStatus.pending,
      };
}

// ─── Tunnel Message ─────────────────────────────────────────────────────────

/// Top-level envelope for all tunnel protocol messages.
///
/// Every message has a unique [id], a [type] discriminator, an opaque
/// [payload] map, and optional routing fields [sourceId] / [targetId].
class TunnelMessage {
  const TunnelMessage({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.sourceId,
    this.targetId,
  });

  /// Unique message identifier (UUID v4).
  final String id;

  /// Discriminator for the message kind.
  final TunnelMessageType type;

  /// Arbitrary key-value payload carried by this message.
  final Map<String, dynamic> payload;

  /// ISO-8601 timestamp of when the message was created.
  final DateTime timestamp;

  /// Identifier of the sending endpoint (e.g. web session id).
  final String? sourceId;

  /// Identifier of the target endpoint (e.g. desktop client id).
  final String? targetId;

  // ── Serialisation ───────────────────────────────────────────────────────

  factory TunnelMessage.fromJson(Map<String, dynamic> json) => TunnelMessage(
        id: json['id'] as String,
        type: TunnelMessageType.fromString(json['type'] as String? ?? ''),
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
        timestamp: DateTime.parse(json['timestamp'] as String),
        sourceId: json['source_id'] as String?,
        targetId: json['target_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        if (sourceId != null) 'source_id': sourceId,
        if (targetId != null) 'target_id': targetId,
      };

  /// Convenience: encode as a JSON string for WebSocket send.
  String encode() => jsonEncode(toJson());

  /// Convenience: decode from a raw JSON string.
  static TunnelMessage decode(String raw) =>
      TunnelMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  @override
  String toString() => 'TunnelMessage($id, $type)';
}

// ─── Tunnel Action ──────────────────────────────────────────────────────────

/// A request to perform an AI-powered action, carried inside a
/// [TunnelMessage] of type [TunnelMessageType.action].
class TunnelAction {
  const TunnelAction({
    required this.actionType,
    required this.context,
    this.parameters = const {},
  });

  /// The kind of action (summarize, explain, fix, translate, custom).
  final TunnelActionType actionType;

  /// Contextual text that the action operates on (e.g. selected code,
  /// a document, or a feature description).
  final String context;

  /// Optional key-value parameters for fine-tuning the action.
  /// For example `{'language': 'Spanish'}` for translate.
  final Map<String, dynamic> parameters;

  // ── Serialisation ───────────────────────────────────────────────────────

  factory TunnelAction.fromJson(Map<String, dynamic> json) => TunnelAction(
        actionType:
            TunnelActionType.fromString(json['action_type'] as String? ?? ''),
        context: json['context'] as String? ?? '',
        parameters:
            (json['parameters'] as Map<String, dynamic>?) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'action_type': actionType.name,
        'context': context,
        'parameters': parameters,
      };

  @override
  String toString() => 'TunnelAction(${actionType.name})';
}

// ─── Tunnel Response ────────────────────────────────────────────────────────

/// A response (or streaming update) for a previously dispatched action.
/// Carried inside a [TunnelMessage] of type [TunnelMessageType.response].
class TunnelResponse {
  const TunnelResponse({
    required this.requestId,
    required this.status,
    this.result,
    this.progress,
    this.error,
  });

  /// The [TunnelMessage.id] of the originating action request.
  final String requestId;

  /// Current status of the action execution.
  final TunnelResponseStatus status;

  /// The (partial or complete) result text. Grows as streaming chunks arrive.
  final String? result;

  /// Optional progress indicator (0.0 – 1.0) for long-running actions.
  final double? progress;

  /// Human-readable error message when [status] is [TunnelResponseStatus.failed].
  final String? error;

  /// Whether this response represents a terminal state (completed or failed).
  bool get isTerminal =>
      status == TunnelResponseStatus.completed ||
      status == TunnelResponseStatus.failed;

  // ── Serialisation ───────────────────────────────────────────────────────

  factory TunnelResponse.fromJson(Map<String, dynamic> json) => TunnelResponse(
        requestId: json['request_id'] as String,
        status: TunnelResponseStatus.fromString(
            json['status'] as String? ?? ''),
        result: json['result'] as String?,
        progress: (json['progress'] as num?)?.toDouble(),
        error: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'status': status.name,
        if (result != null) 'result': result,
        if (progress != null) 'progress': progress,
        if (error != null) 'error': error,
      };

  /// Create a copy with updated fields.
  TunnelResponse copyWith({
    TunnelResponseStatus? status,
    String? result,
    double? progress,
    String? error,
  }) =>
      TunnelResponse(
        requestId: requestId,
        status: status ?? this.status,
        result: result ?? this.result,
        progress: progress ?? this.progress,
        error: error ?? this.error,
      );

  @override
  String toString() => 'TunnelResponse($requestId, ${status.name})';
}
