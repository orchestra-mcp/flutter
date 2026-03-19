import 'package:xterm/xterm.dart';

/// Abstract backend for a terminal session.
///
/// Implementations:
/// - [PtyTerminalBackend] — Local shell via flutter_pty (desktop only)
/// - [SshTerminalBackend] — Remote shell via dartssh2
/// - [ClaudeTerminalBackend] — Claude Code CLI via flutter_pty (desktop only)
abstract class TerminalBackend {
  /// The xterm [Terminal] instance that this backend reads from / writes to.
  Terminal get terminal;

  /// Starts the backend (spawn process, connect SSH, etc.).
  Future<void> start();

  /// Tears down the backend (kill process, close connection, etc.).
  Future<void> dispose();
}
