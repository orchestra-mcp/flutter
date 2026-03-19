import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/features/terminal/terminal_backend.dart';
import 'package:xterm/xterm.dart';

/// Remote shell backend using dartssh2.
///
/// Opens an SSH connection and interactive shell. Works on desktop + mobile.
class SshTerminalBackend extends TerminalBackend {
  SshTerminalBackend({
    required this.host,
    required this.username,
    this.port = 22,
    this.password,
    this.keyFile,
  });

  final String host;
  final String username;
  final int port;
  final String? password;
  final String? keyFile;

  SSHClient? _client;
  SSHSession? _shell;

  @override
  final Terminal terminal = Terminal(maxLines: 10000);

  @override
  Future<void> start() async {
    terminal.write('Connecting to $username@$host:$port...\r\n');

    try {
      final socket = await SSHSocket.connect(host, port);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
        identities: _buildIdentities(),
      );

      final shell = await _client!.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );
      _shell = shell;

      // SSH stdout → xterm terminal (stream-decode UTF-8 for multi-byte glyphs)
      shell.stdout
          .cast<List<int>>()
          .transform(utf8.decoder)
          .listen(
            (String data) {
              terminal.write(data);
            },
            onDone: () {
              terminal.write('\r\n[Connection closed]\r\n');
            },
          );

      // SSH stderr → xterm terminal
      shell.stderr.cast<List<int>>().transform(utf8.decoder).listen((
        String data,
      ) {
        terminal.write(data);
      });

      // xterm keystrokes → SSH stdin
      terminal.onOutput = (String data) {
        shell.write(Uint8List.fromList(utf8.encode(data)));
      };

      // xterm resize → SSH pty resize
      terminal.onResize = (int w, int h, int pw, int ph) {
        shell.resizeTerminal(w, h);
      };
    } catch (e) {
      terminal.write('\r\n[SSH Error] $e\r\n');
      debugPrint('[SshTerminalBackend] connect error: $e');
    }
  }

  List<SSHKeyPair>? _buildIdentities() {
    if (keyFile == null) return null;
    try {
      final pem = File(keyFile!).readAsStringSync();
      return SSHKeyPair.fromPem(pem);
    } catch (e) {
      debugPrint('[SshTerminalBackend] key load error: $e');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _shell?.close();
    _client?.close();
    _shell = null;
    _client = null;
  }
}
