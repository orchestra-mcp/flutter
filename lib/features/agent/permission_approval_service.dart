import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/config/env.dart';

/// Service that polls for pending agent permission requests and shows
/// approval dialogs.
class PermissionApprovalService {
  PermissionApprovalService._();
  static final instance = PermissionApprovalService._();

  Timer? _pollTimer;
  final _storage = const TokenStorage();
  BuildContext? _context;

  /// Start polling for pending permission requests.
  void start(BuildContext context) {
    _context = context;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _context = null;
  }

  Future<void> _poll() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${Env.apiBaseUrl}/api/agent/permissions/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>? ?? [];

      for (final item in items) {
        final req = item as Map<String, dynamic>;
        _showApprovalDialog(req);
      }
    } catch (e) {
      debugPrint('[PermissionApproval] Poll error: $e');
    }
  }

  void _showApprovalDialog(Map<String, dynamic> request) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;

    final id = request['id'] as String? ?? '';
    final tool = request['tool'] as String? ?? 'Unknown tool';
    final reason = request['reason'] as String? ?? '';

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Agent Permission Request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An agent wants to use:',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.build_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tool,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Reason: $reason',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _respond(id, 'denied');
            },
            child: const Text(
              'Deny',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _respond(id, 'approved');
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(String id, String decision) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${Env.apiBaseUrl}/api/agent/permissions/$id/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'decision': decision}),
      );
      debugPrint('[PermissionApproval] Responded $decision for $id');
    } catch (e) {
      debugPrint('[PermissionApproval] Respond error: $e');
    }
  }
}
