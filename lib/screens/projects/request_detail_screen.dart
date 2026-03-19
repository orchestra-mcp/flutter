import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.projectId,
    required this.requestId,
  });

  final String projectId;
  final String requestId;

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  Map<String, dynamic>? _request;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final req =
          await ref.read(apiClientProvider).getRequest(widget.requestId);
      if (mounted) {
        setState(() {
          _request = req.isEmpty ? null : req;
          _loading = false;
          if (req.isEmpty) _error = 'not_found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: tokens.accent))
            : _error != null
                ? _ErrorBody(tokens: tokens, message: _error!)
                : _RequestContent(
                    request: _request!,
                    projectId: widget.projectId,
                    tokens: tokens,
                  ),
      ),
    );
  }
}

class _RequestContent extends StatelessWidget {
  const _RequestContent({
    required this.request,
    required this.projectId,
    required this.tokens,
  });

  final Map<String, dynamic> request;
  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final title = request['title']?.toString() ?? '';
    final kind = request['kind']?.toString() ?? 'feature';
    final priority = request['priority']?.toString() ?? 'P3';
    final status = request['status']?.toString() ?? 'pending';
    final body = request['body']?.toString() ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go(Routes.project(projectId));
                        }
                      },
                      child: Icon(Icons.arrow_back_rounded,
                          color: tokens.fgBright, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      request['id']?.toString() ?? '',
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(label: kind, color: _kindColor(kind)),
                    _Badge(label: priority, color: _priorityColor(priority)),
                    _Badge(label: status, color: _statusColor(status)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: body.isNotEmpty
                  ? MarkdownRendererWidget(
                      content: body,
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                color: tokens.fgDim, size: 36),
                            const SizedBox(height: 8),
                            Text(AppLocalizations.of(context).noDescription,
                                style: TextStyle(
                                    color: tokens.fgMuted, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Color _kindColor(String kind) => switch (kind) {
        'bug' => const Color(0xFFEF4444),
        'hotfix' => const Color(0xFFF97316),
        'feature' => const Color(0xFF00E5FF),
        _ => const Color(0xFF6B7280),
      };

  Color _priorityColor(String p) => switch (p) {
        'P0' => const Color(0xFFEF4444),
        'P1' => const Color(0xFFF97316),
        'P2' => const Color(0xFFFBBF24),
        _ => const Color(0xFF6B7280),
      };

  Color _statusColor(String s) => switch (s) {
        'pending' => const Color(0xFFFBBF24),
        'converted' => const Color(0xFF4ADE80),
        'dismissed' => const Color(0xFF6B7280),
        _ => const Color(0xFF6B7280),
      };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).failedToLoad,
                style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
