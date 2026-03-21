import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/log_runner_provider.dart';

void main() {
  // ── LogProcess ──────────────────────────────────────────────────────────

  group('LogProcess for sidebar', () {
    test('parses running process', () {
      final proc = LogProcess.fromJson({
        'id': 'proc-1',
        'command': 'make dev',
        'working_directory': '/home/user/app',
        'status': 'running',
        'pid': 12345,
        'uptime': '5m 30s',
        'tail': ['server started on :8080'],
      });
      expect(proc.id, 'proc-1');
      expect(proc.command, 'make dev');
      expect(proc.workingDirectory, '/home/user/app');
      expect(proc.status, 'running');
      expect(proc.pid, 12345);
      expect(proc.uptime, '5m 30s');
      expect(proc.tailLines, ['server started on :8080']);
      expect(proc.isRunning, true);
    });

    test('parses finished process', () {
      final proc = LogProcess.fromJson({
        'id': 'proc-2',
        'command': 'go test ./...',
        'status': 'finished',
        'lines': ['PASS', 'ok 1.234s'],
      });
      expect(proc.status, 'finished');
      expect(proc.isRunning, false);
      expect(proc.tailLines, ['PASS', 'ok 1.234s']);
    });

    test('parses failed process', () {
      final proc = LogProcess.fromJson({
        'id': 'proc-3',
        'command': 'npm start',
        'status': 'failed',
      });
      expect(proc.status, 'failed');
      expect(proc.isRunning, false);
    });

    test('handles empty JSON', () {
      final proc = LogProcess.fromJson({});
      expect(proc.id, '');
      expect(proc.command, '');
      expect(proc.status, 'unknown');
      expect(proc.isRunning, false);
      expect(proc.tailLines, isEmpty);
    });

    test('isRunning only true for running status', () {
      expect(LogProcess.fromJson({'status': 'running'}).isRunning, true);
      expect(LogProcess.fromJson({'status': 'finished'}).isRunning, false);
      expect(LogProcess.fromJson({'status': 'failed'}).isRunning, false);
      expect(LogProcess.fromJson({'status': 'unknown'}).isRunning, false);
    });
  });

  // ── LogSearchMatch ──────────────────────────────────────────────────────

  group('LogSearchMatch for search results', () {
    test('parses match with context', () {
      final match = LogSearchMatch.fromJson({
        'line_number': 42,
        'line': 'ERROR: connection refused',
        'context': [
          'attempting connection...',
          'ERROR: connection refused',
          'retrying in 5s',
        ],
      });
      expect(match.lineNumber, 42);
      expect(match.line, 'ERROR: connection refused');
      expect(match.context.length, 3);
    });

    test('parses match without context', () {
      final match = LogSearchMatch.fromJson({
        'line_number': 1,
        'line': 'started',
      });
      expect(match.lineNumber, 1);
      expect(match.line, 'started');
      expect(match.context, isEmpty);
    });

    test('handles empty JSON', () {
      final match = LogSearchMatch.fromJson({});
      expect(match.lineNumber, 0);
      expect(match.line, '');
      expect(match.context, isEmpty);
    });
  });

  // ── Output line filtering ──────────────────────────────────────────────

  group('Output line regex filtering', () {
    final lines = [
      'INFO: server started',
      'DEBUG: loading config',
      'ERROR: port already in use',
      'INFO: listening on :8080',
      'WARN: deprecated API call',
      'ERROR: timeout exceeded',
    ];

    test('empty pattern returns all lines', () {
      final filtered = lines.where((l) => RegExp('').hasMatch(l)).toList();
      expect(filtered.length, lines.length);
    });

    test('filter by ERROR', () {
      final filtered = lines.where((l) => RegExp('ERROR').hasMatch(l)).toList();
      expect(filtered.length, 2);
      expect(filtered[0], contains('port already in use'));
      expect(filtered[1], contains('timeout exceeded'));
    });

    test('case-insensitive filter', () {
      final filtered = lines
          .where((l) => RegExp('error', caseSensitive: false).hasMatch(l))
          .toList();
      expect(filtered.length, 2);
    });

    test('regex filter for port numbers', () {
      final filtered = lines.where((l) => RegExp(r':\d+').hasMatch(l)).toList();
      expect(filtered.length, 1);
      expect(filtered[0], contains(':8080'));
    });
  });
}
