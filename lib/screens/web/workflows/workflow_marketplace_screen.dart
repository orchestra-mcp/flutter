import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/features/workflow/workflow_sharing_service.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── State ───────────────────────────────────────────────────────────────────

class _MarketplaceState {
  const _MarketplaceState({
    this.query = '',
    this.selectedCategory,
    this.workflows = const [],
    this.isLoading = false,
  });

  final String query;
  final String? selectedCategory;
  final List<SharedWorkflow> workflows;
  final bool isLoading;

  _MarketplaceState copyWith({
    String? query,
    String? Function()? selectedCategory,
    List<SharedWorkflow>? workflows,
    bool? isLoading,
  }) =>
      _MarketplaceState(
        query: query ?? this.query,
        selectedCategory: selectedCategory != null
            ? selectedCategory()
            : this.selectedCategory,
        workflows: workflows ?? this.workflows,
        isLoading: isLoading ?? this.isLoading,
      );
}

class _MarketplaceNotifier extends Notifier<_MarketplaceState> {
  final _service = const WorkflowSharingService();

  @override
  _MarketplaceState build() {
    _loadInitial();
    return const _MarketplaceState(isLoading: true);
  }

  Future<void> _loadInitial() async {
    final workflows = await _service.listSharedWorkflows();
    state = state.copyWith(workflows: workflows, isLoading: false);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true);
    final results = await _service.listSharedWorkflows(
      filter: SharedWorkflowFilter(
        query: query.isEmpty ? null : query,
        category: state.selectedCategory,
      ),
    );
    state = state.copyWith(query: query, workflows: results, isLoading: false);
  }

  Future<void> setCategory(String? category) async {
    state = state.copyWith(
        selectedCategory: () => category, isLoading: true);
    final results = await _service.listSharedWorkflows(
      filter: SharedWorkflowFilter(
        query: state.query.isEmpty ? null : state.query,
        category: category,
      ),
    );
    state = state.copyWith(
      selectedCategory: () => category,
      workflows: results,
      isLoading: false,
    );
  }
}

final _marketplaceProvider =
    NotifierProvider<_MarketplaceNotifier, _MarketplaceState>(
  _MarketplaceNotifier.new,
);

// ── Categories ──────────────────────────────────────────────────────────────

List<(String, String?)> _buildCategories(AppLocalizations l10n) => [
  (l10n.categoryAll, null),
  (l10n.categoryWeb, 'web'),
  (l10n.categoryMobile, 'mobile'),
  (l10n.categoryBackend, 'backend'),
  (l10n.categorySystems, 'systems'),
  (l10n.categoryDevOps, 'devops'),
  (l10n.categoryData, 'data'),
  (l10n.categoryManagement, 'management'),
];

// ── Screen ──────────────────────────────────────────────────────────────────

/// Browsable marketplace for shared workflows.
class WorkflowMarketplaceScreen extends ConsumerStatefulWidget {
  const WorkflowMarketplaceScreen({super.key});

  @override
  ConsumerState<WorkflowMarketplaceScreen> createState() =>
      _WorkflowMarketplaceScreenState();
}

class _WorkflowMarketplaceScreenState
    extends ConsumerState<WorkflowMarketplaceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final mState = ref.watch(_marketplaceProvider);
    final categories = _buildCategories(l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Text(
            l10n.workflowMarketplace,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).discoverWorkflows,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Search bar ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (q) =>
                  ref.read(_marketplaceProvider.notifier).search(q),
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchWorkflows,
                hintStyle: TextStyle(color: tokens.fgDim),
                prefixIcon:
                    Icon(Icons.search_rounded, color: tokens.fgDim),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: tokens.fgDim, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(_marketplaceProvider.notifier)
                              .search('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Category chips ────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final isSelected =
                  cat.$2 == mState.selectedCategory;
              return GestureDetector(
                onTap: () => ref
                    .read(_marketplaceProvider.notifier)
                    .setCategory(cat.$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.accent.withValues(alpha: 0.18)
                        : tokens.bgAlt.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? tokens.accent.withValues(alpha: 0.5)
                          : tokens.borderFaint,
                    ),
                  ),
                  child: Text(
                    cat.$1,
                    style: TextStyle(
                      color:
                          isSelected ? tokens.accent : tokens.fgMuted,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Grid ──────────────────────────────────────────────────
          if (mState.isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child:
                    CircularProgressIndicator(color: tokens.accent),
              ),
            )
          else if (mState.workflows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        color: tokens.fgDim, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).noWorkflowsFound,
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: mState.workflows.length,
                  itemBuilder: (ctx, i) => _WorkflowCard(
                    workflow: mState.workflows[i],
                    tokens: tokens,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Workflow card ────────────────────────────────────────────────────────────

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.workflow, required this.tokens});

  final SharedWorkflow workflow;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () => _showPreview(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    workflow.authorAvatar,
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workflow.name,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      workflow.author,
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (workflow.visibility == WorkflowVisibility.team)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context).workflowTeamBadge,
                    style: const TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Description ─────────────────────────────────────────
          Expanded(
            child: Text(
              workflow.description,
              style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Tags ────────────────────────────────────────────────
          if (workflow.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: workflow.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.fgDim.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                        color: tokens.fgDim, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // ── Footer: stars, downloads, install button ────────────
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB300), size: 14),
              const SizedBox(width: 3),
              Text(
                workflow.rating.toStringAsFixed(1),
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${workflow.ratingCount})',
                style:
                    TextStyle(color: tokens.fgDim, fontSize: 10),
              ),
              const SizedBox(width: 12),
              Icon(Icons.download_rounded,
                  color: tokens.fgDim, size: 13),
              const SizedBox(width: 3),
              Text(
                _formatNumber(workflow.downloads),
                style:
                    TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _installWorkflow(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tokens.accent, tokens.accentAlt],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context).install,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  void _installWorkflow(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).workflowInstalling(workflow.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPreview(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.border),
        ),
        title: Text(
          workflow.name,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Author & rating.
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).workflowByAuthor(workflow.author),
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).workflowRatingsCount(workflow.rating.toString(), workflow.ratingCount),
                      style: TextStyle(
                          color: tokens.fgBright, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  workflow.description,
                  style: TextStyle(
                      color: tokens.fgBright, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).contentsLabel,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _ContentRow(
                  icon: Icons.bolt_rounded,
                  label: AppLocalizations.of(context).workflowSkills,
                  count: workflow.skillCount,
                  tokens: tokens,
                ),
                _ContentRow(
                  icon: Icons.smart_toy_outlined,
                  label: AppLocalizations.of(context).workflowAgents,
                  count: workflow.agentCount,
                  tokens: tokens,
                ),
                _ContentRow(
                  icon: Icons.webhook_rounded,
                  label: AppLocalizations.of(context).workflowHooks,
                  count: workflow.hookCount,
                  tokens: tokens,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.download_rounded,
                        color: tokens.fgDim, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).workflowDownloadsCount(workflow.downloads),
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.visibility_outlined,
                        color: tokens.fgDim, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      workflow.visibility.name,
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: workflow.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            tokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                            color: tokens.accent, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text(AppLocalizations.of(context).close, style: TextStyle(color: tokens.fgMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context).workflowInstalling(workflow.name)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context).install),
          ),
        ],
      ),
    );
  }
}

// ── Content row ─────────────────────────────────────────────────────────────

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final int count;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: tokens.accent, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: tokens.fgBright, fontSize: 13)),
          const Spacer(),
          Text('$count',
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
