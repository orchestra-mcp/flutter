import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  const PlanDetailScreen({
    super.key,
    required this.projectId,
    required this.planId,
  });

  final String projectId;
  final String planId;

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  Map<String, dynamic>? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final plan = await ref
          .read(apiClientProvider)
          .getPlan(widget.projectId, widget.planId);
      if (mounted) {
        setState(() {
          _plan = plan.isEmpty ? null : plan;
          _loading = false;
          if (plan.isEmpty) _error = 'not_found';
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
                : _PlanContent(
                    plan: _plan!,
                    projectId: widget.projectId,
                    tokens: tokens,
                  ),
      ),
    );
  }
}

class _PlanContent extends StatelessWidget {
  const _PlanContent({
    required this.plan,
    required this.projectId,
    required this.tokens,
  });

  final Map<String, dynamic> plan;
  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final title = plan['title']?.toString() ?? plan['id']?.toString() ?? '';
    final status = plan['status']?.toString() ?? 'draft';
    final description = plan['description']?.toString() ?? '';
    final body = plan['body']?.toString() ?? '';
    final content = body.isNotEmpty ? body : description;

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
                      plan['id']?.toString() ?? '',
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
                _StatusBadge(status: status),
                const SizedBox(height: 12),
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
              child: content.isNotEmpty
                  ? MarkdownRendererWidget(
                      content: content,
                    )
                  : _EmptyContent(
                      icon: Icons.map_rounded,
                      label: AppLocalizations.of(context).noContent,
                      tokens: tokens,
                    ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _color() => switch (status) {
        'approved' => const Color(0xFF4ADE80),
        'in-progress' => const Color(0xFF00E5FF),
        'completed' => const Color(0xFF4ADE80),
        'draft' => const Color(0xFF6B7280),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({
    required this.icon,
    required this.label,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: tokens.fgDim, size: 36),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14)),
          ],
        ),
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
