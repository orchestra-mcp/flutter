import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/features/bridge/bridge_handler.dart';

/// Executor that analyses the provided context for errors and suggests fixes.
///
/// Designed for code snippets and configuration files. In production this
/// would call the orchestrator bridge to run an AI-powered code analysis.
/// The current implementation simulates streaming output.
class FixExecutor implements ActionExecutor {
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

    // Phase 1: Analysis (simulated).
    yield TunnelResponse(
      requestId: requestId,
      status: TunnelResponseStatus.running,
      result: '**Analysing code...**\n\n',
      progress: 0.15,
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Phase 2: Stream fix suggestions.
    final chunks = _buildFixChunks(context);
    final buffer = StringBuffer('**Analysing code...**\n\n');

    for (var i = 0; i < chunks.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 110));

      buffer.write(chunks[i]);
      // Analysis phase takes 15%, streaming takes the remaining 85%.
      final progress = 0.15 + (0.85 * (i + 1) / chunks.length);

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

  /// Builds simulated fix-suggestion chunks from the input [context].
  List<String> _buildFixChunks(String context) {
    final lineCount = context.split('\n').length;
    return [
      '**Found ${lineCount > 1 ? '$lineCount lines' : '1 line'} to review**\n\n',
      '---\n\n',
      '**Issue 1** - Potential improvement detected\n',
      '> Consider adding error handling ',
      'around the main logic block ',
      'to prevent unhandled exceptions.\n\n',
      '**Issue 2** - Style recommendation\n',
      '> Variable naming could be more descriptive. ',
      'Use meaningful names that communicate intent.\n\n',
      '**Suggested fix:**\n',
      '```\n',
      '// Add try-catch wrapper\n',
      '// Rename variables for clarity\n',
      '// Add input validation\n',
      '```\n\n',
      '_This is a simulated analysis. ',
      'Connect the orchestrator bridge ',
      'for real AI-powered code fixes._',
    ];
  }
}
