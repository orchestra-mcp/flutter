import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/features/bridge/bridge_handler.dart';

/// Executor that summarises the provided context text.
///
/// In a production environment this would call the orchestrator bridge
/// (e.g. `ai_prompt` via MCP) to generate a real summary. The current
/// implementation simulates streaming output for UI development.
class SummarizeExecutor implements ActionExecutor {
  @override
  Stream<TunnelResponse> execute({
    required String requestId,
    required String context,
    Map<String, dynamic> parameters = const {},
  }) async* {
    // Signal that work has started.
    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.running,
      progress: 0.0,
    );

    // Simulate chunked AI response.
    final chunks = _buildSummaryChunks(context);
    final buffer = StringBuffer();

    for (var i = 0; i < chunks.length; i++) {
      // Simulate network / inference latency per chunk.
      await Future<void>.delayed(const Duration(milliseconds: 120));

      buffer.write(chunks[i]);
      final progress = (i + 1) / chunks.length;

      yield TunnelResponse(
        requestId: requestId,
        status: TunnelResponseStatus.running,
        result: buffer.toString(),
        progress: progress,
      );
    }

    // Final completed response.
    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.completed,
      result: buffer.toString(),
      progress: 1.0,
    );
  }

  /// Builds simulated summary chunks from the input [context].
  ///
  /// Replace this with a real AI call in production.
  List<String> _buildSummaryChunks(String context) {
    final wordCount = context.split(RegExp(r'\s+')).length;
    return [
      '**Summary** ',
      '($wordCount words analysed)\n\n',
      'The provided text discusses ',
      'the main topic and outlines ',
      'several key points. ',
      'The core themes include ',
      'the primary subject matter, ',
      'supporting details, ',
      'and relevant conclusions. ',
      'Overall the content ',
      'presents a coherent argument ',
      'with clear structure.',
    ];
  }
}
