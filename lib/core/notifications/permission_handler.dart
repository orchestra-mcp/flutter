import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Handles remote permission requests from Claude Code hooks.
///
/// When the agent needs permission to execute a tool (Bash, Write, Edit),
/// this handler receives the request via the web-gate WebSocket and shows
/// an approve/deny dialog on the mobile device.
///
/// Flow:
///   1. Claude Code hook → permission-hook.sh → bridge permission server
///   2. Bridge also pushes to web-gate EventBus topic "permissions"
///   3. This handler receives it via WebSocket notification
///   4. Shows dialog → user taps Approve/Deny
///   5. Response sent back to permission server via HTTP
class PermissionHandler {
  PermissionHandler();

  final _pendingController = StreamController<PermissionRequest>.broadcast();

  /// Stream of pending permission requests.
  Stream<PermissionRequest> get onRequest => _pendingController.stream;

  /// Processes an incoming permission notification from the WebSocket.
  void handleNotification(Map<String, dynamic> data) {
    final toolName = data['tool_name'] as String? ?? 'unknown';
    final toolInput = data['tool_input'] as Map<String, dynamic>? ?? {};
    final sessionId = data['session_id'] as String? ?? '';
    final requestId = data['request_id'] as String? ?? '';
    final port = data['port'] as int? ?? 0;

    final request = PermissionRequest(
      requestId: requestId,
      toolName: toolName,
      toolInput: toolInput,
      sessionId: sessionId,
      serverPort: port,
    );

    _pendingController.add(request);
  }

  /// Sends the user's decision back to the permission server.
  static Future<void> respond({
    required int serverPort,
    required String requestId,
    required bool approved,
    String? reason,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.post(
        '127.0.0.1',
        serverPort,
        '/permission/respond',
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'request_id': requestId,
          'decision': approved ? 'approve' : 'deny',
          if (reason != null) 'reason': reason,
        }),
      );
      final response = await request.close();
      await response.drain<void>();
      client.close(force: true);
    } catch (_) {
      // Permission server might not be reachable from mobile.
      // In that case, the server will timeout and allow by default.
    }
  }

  void dispose() {
    _pendingController.close();
  }
}

/// A permission request from Claude Code.
class PermissionRequest {
  const PermissionRequest({
    required this.requestId,
    required this.toolName,
    required this.toolInput,
    required this.sessionId,
    required this.serverPort,
  });

  final String requestId;
  final String toolName;
  final Map<String, dynamic> toolInput;
  final String sessionId;
  final int serverPort;

  /// Human-readable description of what the tool wants to do.
  String get description {
    switch (toolName) {
      case 'Bash':
        final cmd = toolInput['command'] as String? ?? '';
        return cmd.length > 100 ? '${cmd.substring(0, 100)}...' : cmd;
      case 'Write':
        return 'Write to ${toolInput['file_path'] ?? 'file'}';
      case 'Edit':
        return 'Edit ${toolInput['file_path'] ?? 'file'}';
      default:
        return '$toolName call';
    }
  }

  /// Whether this is a destructive/dangerous tool.
  bool get isDangerous =>
      toolName == 'Bash' || toolName == 'Write' || toolName == 'Edit';
}

/// Shows a permission approval dialog.
Future<bool?> showPermissionDialog(
  BuildContext context,
  PermissionRequest request,
) async {
  final tokens = ThemeTokens.of(context);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      title: Row(
        children: [
          Icon(
            request.isDangerous ? Icons.warning_amber_rounded : Icons.security,
            color: request.isDangerous ? Colors.orange : tokens.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Permission Required',
              style: TextStyle(color: tokens.fgBright, fontSize: 17),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.toolName,
            style: TextStyle(
              color: tokens.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Text(
              request.description,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 12,
                fontFamily: 'IBM Plex Mono',
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Deny', style: TextStyle(color: Colors.red.shade300)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: tokens.accent),
          child: const Text('Approve'),
        ),
      ],
    ),
  );
}

/// Provider for the permission handler.
final permissionHandlerProvider = Provider<PermissionHandler>((ref) {
  final handler = PermissionHandler();
  ref.onDispose(handler.dispose);
  return handler;
});
