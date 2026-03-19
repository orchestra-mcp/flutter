import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:orchestra/features/terminal/terminal_backend.dart';
import 'package:xterm/xterm.dart';

/// Local shell backend using flutter_pty (C FFI).
///
/// Spawns a real PTY process via forkpty/openpty. Desktop only.
/// Output is broadcast so remote clients (mobile via tunnel) can
/// receive the same terminal output.
class PtyTerminalBackend extends TerminalBackend {
  PtyTerminalBackend({String? shell, this.workingDirectory})
    : _shell = shell ?? Platform.environment['SHELL'] ?? '/bin/bash';

  final String _shell;
  final String? workingDirectory;
  Pty? _pty;

  /// Broadcast stream of raw output from the PTY.
  /// Remote clients subscribe to this to mirror the terminal.
  final _outputController = StreamController<String>.broadcast();
  Stream<String> get outputStream => _outputController.stream;

  @override
  final Terminal terminal = Terminal(maxLines: 10000);

  @override
  Future<void> start() async {
    final pty = Pty.start(
      _shell,
      columns: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
      rows: terminal.viewHeight > 0 ? terminal.viewHeight : 25,
      workingDirectory: workingDirectory,
    );
    _pty = pty;

    // PTY output → xterm terminal + broadcast to remote clients
    pty.output
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(
          (String data) {
            terminal.write(data);
            _outputController.add(data);
          },
          onDone: () {
            terminal.write('\r\n[Process exited]\r\n');
            _outputController.add('\r\n[Process exited]\r\n');
          },
        );

    // xterm keystrokes → PTY stdin
    terminal.onOutput = (String data) {
      pty.write(Uint8List.fromList(utf8.encode(data)));
    };

    // xterm resize → PTY resize
    terminal.onResize = (int w, int h, int pw, int ph) {
      pty.resize(h, w);
    };
  }

  /// Writes input data to the PTY (used by remote clients sending keystrokes).
  void writeInput(String data) {
    _pty?.write(Uint8List.fromList(utf8.encode(data)));
  }

  /// Resizes the PTY (used by remote clients).
  void resizePty(int rows, int cols) {
    _pty?.resize(rows, cols);
  }

  @override
  Future<void> dispose() async {
    try {
      _pty?.kill();
    } catch (e) {
      debugPrint('[PtyTerminalBackend] kill error: $e');
    }
    _pty = null;
    _outputController.close();
  }
}
