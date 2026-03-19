import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/features/bridge/bridge_handler.dart';

/// Executor that explains the provided context in simple terms.
///
/// Also used as the fallback executor for `translate` and `custom`
/// action types (the parameters map carries the specific instruction).
///
/// In production this would route through the orchestrator bridge to
/// an AI provider. The current implementation simulates streaming.
class ExplainExecutor implements ActionExecutor {
  @override
  Stream<TunnelResponse> execute({
    required String requestId,
    required String context,
    Map<String, dynamic> parameters = const {},
  }) async* {
    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.running,
      progress: 0.0,
    );

    final chunks = _buildExplanationChunks(context, parameters);
    final buffer = StringBuffer();

    for (var i = 0; i < chunks.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));

      buffer.write(chunks[i]);
      final progress = (i + 1) / chunks.length;

      yield TunnelResponse(
        requestId: requestId,
        status: TunnelResponseStatus.running,
        result: buffer.toString(),
        progress: progress,
      );
    }

    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.completed,
      result: buffer.toString(),
      progress: 1.0,
    );
  }

  /// Builds simulated explanation chunks.
  ///
  /// If [parameters] contains a `'custom_prompt'` key, it is treated
  /// as a custom instruction. If it contains `'language'`, it is
  /// treated as a translation request.
  List<String> _buildExplanationChunks(
    String context,
    Map<String, dynamic> parameters,
  ) {
    final customPrompt = parameters['custom_prompt'] as String?;
    final language = parameters['language'] as String?;

    if (language != null) {
      return [
        '**Translation to $language**\n\n',
        'The following is a translation ',
        'of the provided text ',
        'into $language. ',
        'Note that this is a simulated response ',
        'and will be replaced with a real AI translation ',
        'when the orchestrator bridge is connected.\n\n',
        '> [Translated content would appear here]',
      ];
    }

    if (customPrompt != null) {
      return [
        '**Custom Action**\n\n',
        'Instruction: _${customPrompt}_\n\n',
        'Processing the provided context ',
        'according to the custom instruction. ',
        'This is a simulated response ',
        'that will be replaced with real AI output ',
        'when the orchestrator bridge is connected.\n\n',
        'The context contains ',
        '${context.split(RegExp(r'\\s+')).length} words ',
        'that have been analysed.',
      ];
    }

    return [
      '**Explanation**\n\n',
      'Let me break this down ',
      'in simple terms.\n\n',
      'The text describes ',
      'a concept that can be understood ',
      'by looking at its core components. ',
      'At its simplest, ',
      'the main idea is about ',
      'how different parts work together ',
      'to form a coherent whole.\n\n',
      'Think of it like building blocks: ',
      'each piece has a specific role, ',
      'and when combined they create ',
      'the complete picture.',
    ];
  }
}
