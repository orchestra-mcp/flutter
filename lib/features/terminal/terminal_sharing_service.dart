import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/features/terminal/pty_terminal_backend.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';

/// Service that shares desktop flutter_pty sessions with remote clients
/// (mobile/web) via the MCP notification channel.
///
/// On desktop, this listens for `terminal/*` notifications from the MCP
/// server (relayed from mobile through the tunnel) and routes them to
/// the local flutter_pty sessions.
///
/// Flow:
///   Mobile → tunnel WebSocket → orchestra serve → MCP notification → this service
///   → flutter_pty.writeInput(data)
///   → flutter_pty output → this service → MCP tool call → orchestra serve
///   → tunnel WebSocket → mobile
class TerminalSharingService {
  TerminalSharingService(this._ref);

  final Ref _ref;
  StreamSubscription<dynamic>? _notifSub;
  final Map<String, StreamSubscription<String>> _outputSubs = {};
  final Map<String, List<String>> _outputBuffers = {};
  bool _started = false;

  /// Starts listening for remote terminal commands.
  void start() {
    if (_started) return;
    _started = true;

    final mcp = _ref.read(mcpClientProvider);
    if (mcp == null) return;

    // Listen for MCP notifications (server → client).
    _notifSub = mcp.notifications.listen((notification) {
      final method = notification['method'] as String?;
      final params = notification['params'] as Map<String, dynamic>? ?? {};

      switch (method) {
        case 'terminal/list':
          _handleListSessions(mcp, params);
        case 'terminal/attach':
          _handleAttach(mcp, params);
        case 'terminal/input':
          _handleInput(params);
        case 'terminal/resize':
          _handleResize(params);
        case 'terminal/detach':
          _handleDetach(params);
      }
    });

    debugPrint(
      '[TerminalSharing] Started — listening for remote terminal commands',
    );
  }

  void _handleListSessions(dynamic mcp, Map<String, dynamic> params) {
    final sessions = _ref.read(terminalSessionsProvider);
    final notifier = _ref.read(terminalSessionsProvider.notifier);
    final sessionList = sessions
        .map(
          (s) => {
            'id': s.id,
            'label': s.label,
            'type': s.type.name,
            'status': s.status.name,
          },
        )
        .toList();

    // Respond via tool call.
    mcp
        .callTool('_terminal_share_response', {
          'type': 'session_list',
          'sessions': sessionList,
        })
        .catchError((_) {});
  }

  void _handleAttach(dynamic mcp, Map<String, dynamic> params) {
    final sessionId = params['session_id'] as String?;
    if (sessionId == null) return;

    final notifier = _ref.read(terminalSessionsProvider.notifier);
    final backend = notifier.backends[sessionId];
    if (backend is! PtyTerminalBackend) return;

    // Subscribe to output and buffer it for polling.
    _outputBuffers[sessionId] = [];
    _outputSubs[sessionId]?.cancel();
    _outputSubs[sessionId] = backend.outputStream.listen((data) {
      _outputBuffers[sessionId]?.add(data);
    });

    debugPrint('[TerminalSharing] Attached to session $sessionId');
  }

  void _handleInput(Map<String, dynamic> params) {
    final sessionId = params['session_id'] as String?;
    final data = params['data'] as String?;
    if (sessionId == null || data == null) return;

    final notifier = _ref.read(terminalSessionsProvider.notifier);
    final backend = notifier.backends[sessionId];
    if (backend is PtyTerminalBackend) {
      backend.writeInput(data);
    }
  }

  void _handleResize(Map<String, dynamic> params) {
    final sessionId = params['session_id'] as String?;
    final cols = params['cols'] as int?;
    final rows = params['rows'] as int?;
    if (sessionId == null || cols == null || rows == null) return;

    final notifier = _ref.read(terminalSessionsProvider.notifier);
    final backend = notifier.backends[sessionId];
    if (backend is PtyTerminalBackend) {
      backend.resizePty(rows, cols);
    }
  }

  void _handleDetach(Map<String, dynamic> params) {
    final sessionId = params['session_id'] as String?;
    if (sessionId == null) return;

    _outputSubs[sessionId]?.cancel();
    _outputSubs.remove(sessionId);
    _outputBuffers.remove(sessionId);
    debugPrint('[TerminalSharing] Detached from session $sessionId');
  }

  /// Drains buffered output for a session (called by the Go relay).
  String drainOutput(String sessionId) {
    final buffer = _outputBuffers[sessionId];
    if (buffer == null || buffer.isEmpty) return '';
    final output = buffer.join();
    buffer.clear();
    return output;
  }

  void dispose() {
    _notifSub?.cancel();
    for (final sub in _outputSubs.values) {
      sub.cancel();
    }
    _outputSubs.clear();
    _outputBuffers.clear();
    _started = false;
  }
}

/// Provider for the terminal sharing service (desktop only).
final terminalSharingProvider = Provider<TerminalSharingService>((ref) {
  final service = TerminalSharingService(ref);
  ref.onDispose(service.dispose);
  return service;
});
