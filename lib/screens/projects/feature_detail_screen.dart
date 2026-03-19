import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// -- Screen ------------------------------------------------------------------

/// Full detail screen for a single feature. Shows status/priority/kind badges,
/// metadata (assignee, estimate, labels), and renders the markdown body.
///
/// Data loading strategy: local SQLite first (fast), then API for freshest data.
class FeatureDetailScreen extends ConsumerStatefulWidget {
  const FeatureDetailScreen({
    super.key,
    required this.featureId,
    required this.projectId,
  });

  final String featureId;
  final String projectId;

  @override
  ConsumerState<FeatureDetailScreen> createState() =>
      _FeatureDetailScreenState();
}

class _FeatureDetailScreenState extends ConsumerState<FeatureDetailScreen> {
  LocalFeature? _feature;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeature();
  }

  Future<void> _loadFeature() async {
    try {
      // Fast path: local database.
      final local =
          await ref.read(featureRepositoryProvider).getById(widget.featureId);
      if (local != null && mounted) {
        setState(() {
          _feature = local;
          _loading = false;
        });
      }

      // Slow path: API for fresh data (fire-and-forget update).
      try {
        final remote =
            await ref.read(apiClientProvider).getFeature(widget.featureId);
        if (mounted && remote.isNotEmpty) {
          // Re-fetch from local after the repository caches the API response.
          final refreshed = await ref
              .read(featureRepositoryProvider)
              .getById(widget.featureId);
          if (refreshed != null && mounted) {
            setState(() {
              _feature = refreshed;
            });
          }
        }
      } catch (_) {
        // API fetch failed — local data is already shown.
      }

      // If we still have nothing after both attempts, mark as error.
      if (_feature == null && mounted) {
        setState(() {
          _error = 'Feature not found';
          _loading = false;
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
                ? _ErrorState(tokens: tokens, message: _error!)
                : _FeatureContent(
                    feature: _feature!,
                    projectId: widget.projectId,
                    tokens: tokens,
                  ),
      ),
    );
  }
}

// -- Content -----------------------------------------------------------------

class _FeatureContent extends StatelessWidget {
  const _FeatureContent({
    required this.feature,
    required this.projectId,
    required this.tokens,
  });

  final LocalFeature feature;
  final String projectId;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final markdownContent =
        feature.body ?? feature.description ?? '';

    return CustomScrollView(
      slivers: [
        // -- Header -----------------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + feature ID
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
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: tokens.fgBright,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      feature.id,
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

                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(status: feature.status),
                    _PriorityBadge(priority: feature.priority),
                    _KindBadge(kind: feature.kind, tokens: tokens),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  feature.title,
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

        // -- Metadata card ----------------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MetadataCard(feature: feature, tokens: tokens),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // -- Body / Description -----------------------------------------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: markdownContent.isNotEmpty
                  ? MarkdownRendererWidget(
                      content: markdownContent,
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.article_outlined,
                                color: tokens.fgDim, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).noDescription,
                              style: TextStyle(
                                  color: tokens.fgMuted, fontSize: 14),
                            ),
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
}

// -- Metadata card -----------------------------------------------------------

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.feature,
    required this.tokens,
  });

  final LocalFeature feature;
  final OrchestraColorTokens tokens;

  List<String> _parseLabels(String? labelsJson) {
    if (labelsJson == null || labelsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(labelsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final labels = _parseLabels(feature.labels);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).details,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Assignee
          _MetadataRow(
            label: AppLocalizations.of(context).featureDetailAssignee,
            value: feature.assigneeId ?? AppLocalizations.of(context).featureDetailUnassigned,
            tokens: tokens,
          ),
          const SizedBox(height: 8),

          // Estimate
          _MetadataRow(
            label: AppLocalizations.of(context).featureDetailEstimate,
            value: feature.estimate ?? '--',
            tokens: tokens,
          ),
          const SizedBox(height: 8),

          // Project
          _MetadataRow(
            label: AppLocalizations.of(context).featureDetailProject,
            value: feature.projectId,
            tokens: tokens,
          ),

          // Labels
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).featureDetailLabels,
              style: TextStyle(color: tokens.fgMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: labels.map((label) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.accent.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    required this.tokens,
  });

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

// -- Badges ------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color _statusColor(String status) => switch (status) {
        'done' => const Color(0xFF4ADE80),
        'in-progress' => const Color(0xFF00E5FF),
        'in-review' => const Color(0xFFFBBF24),
        'in-testing' => const Color(0xFF38BDF8),
        'in-docs' => const Color(0xFF6366F1),
        'needs-edits' => const Color(0xFFEF4444),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final String priority;

  Color _priorityColor(String priority) => switch (priority) {
        'P0' => const Color(0xFFEF4444),
        'P1' => const Color(0xFFF97316),
        'P2' => const Color(0xFFFBBF24),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind, required this.tokens});
  final String kind;
  final OrchestraColorTokens tokens;

  IconData _kindIcon(String kind) => switch (kind) {
        'bug' => Icons.bug_report_rounded,
        'hotfix' => Icons.local_fire_department_rounded,
        'chore' => Icons.build_rounded,
        'testcase' => Icons.science_rounded,
        _ => Icons.auto_awesome_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.fgDim.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: tokens.fgDim.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_kindIcon(kind), size: 13, color: tokens.fgMuted),
          const SizedBox(width: 4),
          Text(
            kind,
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Error state -------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tokens, required this.message});
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
            Text(
              AppLocalizations.of(context).failedToLoadFeature,
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
