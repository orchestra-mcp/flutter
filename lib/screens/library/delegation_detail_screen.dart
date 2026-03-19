import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

class DelegationDetailScreen extends ConsumerWidget {
  const DelegationDetailScreen({super.key, required this.delegationId});

  final String delegationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final delegations = ref.watch(delegationsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: delegations.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: tokens.accent)),
          error: (e, _) => _ErrorBody(tokens: tokens, message: e.toString()),
          data: (list) {
            final l10n = AppLocalizations.of(context);
            final d = list
                .where((d) => d['id']?.toString() == delegationId)
                .firstOrNull;
            if (d == null) {
              return _ErrorBody(
                tokens: tokens,
                message: l10n.delegationNotFound,
              );
            }
            return _DelegationContent(delegation: d, tokens: tokens);
          },
        ),
      ),
    );
  }
}

class _DelegationContent extends StatelessWidget {
  const _DelegationContent({required this.delegation, required this.tokens});

  final Map<String, dynamic> delegation;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = delegation['question']?.toString() ?? '';
    final status = delegation['status']?.toString() ?? 'pending';
    final from = delegation['from_person']?.toString() ?? '';
    final to = delegation['to_person']?.toString() ?? '';
    final featureId = delegation['feature_id']?.toString() ?? '';
    final ctx = delegation['context']?.toString() ?? '';
    final response = delegation['response']?.toString() ?? '';

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
                          context.go(Routes.delegations);
                        }
                      },
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: tokens.fgBright,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      delegation['id']?.toString() ?? '',
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
                _Badge(
                  label: status,
                  color: status == 'responded'
                      ? const Color(0xFF4ADE80)
                      : status == 'pending'
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.details,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Row(label: l10n.fromLabel, value: from, tokens: tokens),
                  const SizedBox(height: 8),
                  _Row(label: l10n.toLabel, value: to, tokens: tokens),
                  if (featureId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Row(
                      label: l10n.featureLabel,
                      value: featureId,
                      tokens: tokens,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (ctx.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.contextLabel,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownRendererWidget(content: ctx),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (response.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.response,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownRendererWidget(content: response),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.tokens});
  final String label;
  final String value;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadDelegation,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
