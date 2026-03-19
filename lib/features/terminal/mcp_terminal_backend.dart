import 'dart:async';
import 'dart:convert';

import 'package:xterm/xterm.dart';

import 'package:orchestra/features/terminal/terminal_backend.dart';

/// Terminal backend that uses Go PTY manager via MCP tool calls.
///
/// Used by mobile to get a terminal on the remote machine through the tunnel.
/// The Go `orchestra serve` process spawns the actual PTY.
class McpTerminalBackend extends TerminalBackend {
  McpTerminalBackend({required this.callTool, this.shell});

  /// Calls an MCP tool. Returns the unwrapped result map.
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> arguments,
  )
  callTool;
  final String? shell;

  late final Terminal _terminal;
  String? _terminalId;
  Timer? _pollTimer;
  bool _disposed = false;
  int _errorCount = 0;

  @override
  Terminal get terminal => _terminal;

  String? get terminalId => _terminalId;

  @override
  Future<void> start() async {
    _terminal = Terminal(maxLines: 10000);

    // Create a terminal on the Go PTY manager.
    final result = await callTool('create_terminal', {
      if (shell != null) 'shell': shell!,
    });

    // Result is {"text": "{\"terminal_id\":\"term-1\",\"shell\":\"/bin/zsh\"}"}.
    final text = result['text'] as String? ?? '';
    try {
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      _terminalId = parsed['terminal_id'] as String?;
    } catch (_) {
      // If not JSON, use a default.
      _terminalId = null;
    }

    if (_terminalId == null) {
      _terminal.write('\x1B[31m[Failed to create terminal session]\x1B[0m\r\n');
      return;
    }

    // Wire keyboard input.
    _terminal.onOutput = (data) {
      if (_terminalId == null || _disposed) return;
      callTool('send_input', {
        'terminal_id': _terminalId!,
        'data': data,
      }).catchError((_) => <String, dynamic>{});
    };

    // Wire resize.
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      if (_terminalId == null || _disposed) return;
      callTool('resize_terminal', {
        'terminal_id': _terminalId!,
        'cols': width,
        'rows': height,
      }).catchError((_) => <String, dynamic>{});
    };

    // Poll for output.
    _pollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _pollOutput();
    });
  }

  Future<void> _pollOutput() async {
    if (_terminalId == null || _disposed) return;
    try {
      final result = await callTool('terminal_output', {
        'terminal_id': _terminalId!,
      });
      _errorCount = 0;
      // terminal_output returns {"text": "<raw output>"}.
      final output = result['text'] as String? ?? '';
      if (output.isNotEmpty) {
        _terminal.write(output);
      }
    } catch (e) {
      _errorCount++;
      if (_errorCount >= 3) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _terminal.write('\r\n\x1B[31m[Terminal disconnected]\x1B[0m\r\n');
      }
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_terminalId != null) {
      try {
        await callTool('close_terminal', {'terminal_id': _terminalId!});
      } catch (_) {}
    }
  }
}
