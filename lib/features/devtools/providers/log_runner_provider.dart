import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class LogProcess {
  final String id;
  final String command;
  final String? workingDirectory;
  final String status; // running, finished, failed
  final int? pid;
  final String? uptime;
  final List<String> tailLines;

  const LogProcess({
    required this.id,
    required this.command,
    this.workingDirectory,
    this.status = 'running',
    this.pid,
    this.uptime,
    this.tailLines = const [],
  });

  factory LogProcess.fromJson(Map<String, dynamic> json) {
    return LogProcess(
      id: json['id'] as String? ?? '',
      command: json['command'] as String? ?? '',
      workingDirectory: json['working_directory'] as String?,
      status: json['status'] as String? ?? 'unknown',
      pid: json['pid'] as int?,
      uptime: json['uptime'] as String?,
      tailLines: (json['tail'] as List<dynamic>?)?.cast<String>() ??
          (json['lines'] as List<dynamic>?)?.cast<String>() ??
          [],
    );
  }

  bool get isRunning => status == 'running';
}

class LogSearchMatch {
  final int lineNumber;
  final String line;
  final List<String> context;

  const LogSearchMatch({
    required this.lineNumber,
    required this.line,
    this.context = const [],
  });

  factory LogSearchMatch.fromJson(Map<String, dynamic> json) {
    return LogSearchMatch(
      lineNumber: json['line_number'] as int? ?? 0,
      line: json['line'] as String? ?? '',
      context: (json['context'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

/// Typed Riverpod wrapper around MCP Log Runner tools.
///
/// Calls MCP tools: log_run, log_run_output, log_run_list,
/// log_run_status, log_run_kill, log_run_restart, log_search.
class LogRunnerNotifier extends AsyncNotifier<List<LogProcess>> {
  @override
  Future<List<LogProcess>> build() => listProcesses();

  Future<List<LogProcess>> listProcesses() async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_run_list', {});
    final list = result['processes'] as List<dynamic>? ?? [];
    return list
        .map((e) => LogProcess.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LogProcess> run(String command, {String? workingDirectory}) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_run', {
      'command': command,
      if (workingDirectory != null) 'working_directory': workingDirectory,
    });
    ref.invalidateSelf();
    return LogProcess.fromJson(result);
  }

  Future<List<String>> getOutput(
    String processId, {
    int? lines,
    String? pattern,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_run_output', {
      'id': processId,
      if (lines != null) 'lines': lines,
      if (pattern != null) 'pattern': pattern,
    });
    return (result['lines'] as List<dynamic>?)?.cast<String>() ??
        (result['output'] as String?)?.split('\n') ??
        [];
  }

  Future<LogProcess> getStatus(String processId, {int? tail}) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_run_status', {
      'id': processId,
      if (tail != null) 'tail': tail,
    });
    return LogProcess.fromJson(result);
  }

  Future<void> kill(String processId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    await mcp.callTool('log_run_kill', {'id': processId});
    ref.invalidateSelf();
  }

  Future<LogProcess> restart(String processId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_run_restart', {'id': processId});
    ref.invalidateSelf();
    return LogProcess.fromJson(result);
  }

  Future<List<LogSearchMatch>> searchLog(
    String path,
    String pattern, {
    int? contextLines,
  }) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('log_search', {
      'path': path,
      'pattern': pattern,
      if (contextLines != null) 'context_lines': contextLines,
    });
    final list = result['matches'] as List<dynamic>? ?? [];
    return list
        .map((e) => LogSearchMatch.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final logRunnerProvider =
    AsyncNotifierProvider<LogRunnerNotifier, List<LogProcess>>(
  LogRunnerNotifier.new,
);

/// Streams output for a given process ID.
final logOutputProvider =
    FutureProvider.family<List<String>, String>((ref, processId) async {
  final notifier = ref.watch(logRunnerProvider.notifier);
  return notifier.getOutput(processId);
});
