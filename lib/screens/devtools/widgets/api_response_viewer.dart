import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';

// ── Status code colour logic ────────────────────────────────────────────────

Color _statusColor(int code) {
  if (code >= 200 && code < 300) return const Color(0xFF22C55E);
  if (code >= 300 && code < 400) return const Color(0xFFEAB308);
  if (code >= 400 && code < 500) return const Color(0xFFEF4444);
  if (code >= 500) return const Color(0xFFDC2626);
  return const Color(0xFF6B7280);
}

String _statusLabel(int code) {
  return switch (code) {
    200 => '200 OK',
    201 => '201 Created',
    204 => '204 No Content',
    301 => '301 Moved Permanently',
    302 => '302 Found',
    304 => '304 Not Modified',
    400 => '400 Bad Request',
    401 => '401 Unauthorized',
    403 => '403 Forbidden',
    404 => '404 Not Found',
    405 => '405 Method Not Allowed',
    409 => '409 Conflict',
    422 => '422 Unprocessable Entity',
    429 => '429 Too Many Requests',
    500 => '500 Internal Server Error',
    502 => '502 Bad Gateway',
    503 => '503 Service Unavailable',
    504 => '504 Gateway Timeout',
    _ => '$code',
  };
}

// ── Widget ──────────────────────────────────────────────────────────────────

/// Right-pane response viewer showing status badge, duration, and tabs for
/// the response body and headers.
class ApiResponseViewer extends StatefulWidget {
  const ApiResponseViewer({
    super.key,
    this.response,
    this.error,
  });

  /// The response to display. Null when no request has been sent yet.
  final ApiResponse? response;

  /// An error message to display instead of the response.
  final String? error;

  @override
  State<ApiResponseViewer> createState() => _ApiResponseViewerState();
}

class _ApiResponseViewerState extends State<ApiResponseViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    if (widget.error != null) {
      return _buildErrorState(tokens);
    }

    if (widget.response == null) {
      return _buildEmptyState(tokens);
    }

    final resp = widget.response!;

    return Column(
      children: [
        // ── Status + Duration badges ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(resp.statusCode).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _statusColor(resp.statusCode).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _statusLabel(resp.statusCode),
                  style: TextStyle(
                    color: _statusColor(resp.statusCode),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Duration badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tokens.bgAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tokens.borderFaint, width: 0.5),
                ),
                child: Text(
                  '${resp.durationMs}ms',
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const Spacer(),

              // Copy body button
              if (resp.body.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: tokens.fgMuted,
                  ),
                  tooltip: 'Copy response body',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: resp.body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Response body copied'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: tokens.bgAlt,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgMuted,
            indicatorColor: tokens.accent,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Body'),
              Tab(text: 'Headers'),
            ],
          ),
        ),

        // ── Tab views ────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBodyTab(tokens, resp),
              _buildHeadersTab(tokens, resp),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 40,
              color: tokens.fgDim.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No response yet',
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a request to see the response here.',
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────

  Widget _buildErrorState(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: const Color(0xFFEF4444).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Request Failed',
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.error ?? 'An unknown error occurred.',
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Body tab ────────────────────────────────────────────────────────────

  Widget _buildBodyTab(OrchestraColorTokens tokens, ApiResponse resp) {
    if (resp.body.isEmpty) {
      return Center(
        child: Text(
          'Empty response body',
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      );
    }

    // Try to pretty-print JSON
    String displayBody = resp.body;
    try {
      final decoded = jsonDecode(resp.body);
      displayBody = const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      // Not JSON — show raw body.
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderFaint, width: 0.5),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            displayBody,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ── Headers tab ─────────────────────────────────────────────────────────

  Widget _buildHeadersTab(OrchestraColorTokens tokens, ApiResponse resp) {
    final entries = resp.headers.entries.toList();

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No response headers',
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(
        color: tokens.borderFaint,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: tokens.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  entry.value?.toString() ?? '',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
