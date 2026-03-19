import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:orchestra/features/terminal/terminal_backend.dart';
import 'package:xterm/xterm.dart';

/// Claude Code backend — launches `claude` CLI as a native PTY process.
///
/// This gives the user a fully interactive Claude Code session with all
/// keyboard I/O handled natively by xterm + flutter_pty. Desktop only.
class ClaudeTerminalBackend extends TerminalBackend {
  ClaudeTerminalBackend({
    this.model = 'claude-sonnet-4-6',
    this.workingDirectory,
  });

  final String model;
  final String? workingDirectory;
  Pty? _pty;

  @override
  final Terminal terminal = Terminal(maxLines: 10000);

  @override
  Future<void> start() async {
    final pty = Pty.start(
      'claude',
      columns: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
      rows: terminal.viewHeight > 0 ? terminal.viewHeight : 25,
      workingDirectory: workingDirectory,
      environment: {
        ...Platform.environment,
        'TERM': 'xterm-256color',
      },
    );
    _pty = pty;

    pty.output.cast<List<int>>().transform(utf8.decoder).listen(
      (String data) {
        terminal.write(_sanitizeUnicode(data));
      },
      onDone: () {
        terminal.write('\r\n[Claude session ended]\r\n');
      },
    );

    terminal.onOutput = (String data) {
      pty.write(Uint8List.fromList(utf8.encode(data)));
    };

    terminal.onResize = (int w, int h, int pw, int ph) {
      pty.resize(h, w);
    };
  }

  /// Strip variation selectors (VS15/VS16) and zero-width joiners that cause
  /// xterm.dart's Unicode 11 wcwidth table to miscalculate character widths.
  static String _sanitizeUnicode(String data) {
    return data.replaceAll(
      RegExp('[\uFE0E\uFE0F\u200D]'),
      '',
    );
  }

  @override
  Future<void> dispose() async {
    try {
      _pty?.kill();
    } catch (e) {
      debugPrint('[ClaudeTerminalBackend] kill error: $e');
    }
    _pty = null;
  }
}
