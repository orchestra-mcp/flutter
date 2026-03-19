import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/features/sharing/public_share_service.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── State ───────────────────────────────────────────────────────────────────

class _PublicProjectState {
  const _PublicProjectState({
    this.project,
    this.isLoading = true,
    this.selectedTab = 0,
    this.expandedItemId,
  });

  final PublicProject? project;
  final bool isLoading;
  final int selectedTab;
  final String? expandedItemId;

  _PublicProjectState copyWith({
    PublicProject? project,
    bool? isLoading,
    int? selectedTab,
    String? Function()? expandedItemId,
  }) => _PublicProjectState(
    project: project ?? this.project,
    isLoading: isLoading ?? this.isLoading,
    selectedTab: selectedTab ?? this.selectedTab,
    expandedItemId: expandedItemId != null
        ? expandedItemId()
        : this.expandedItemId,
  );
}

class _PublicProjectNotifier extends Notifier<_PublicProjectState> {
  @override
  _PublicProjectState build() {
    _loadProject();
    return const _PublicProjectState();
  }

  Future<void> _loadProject() async {
    const service = PublicShareService();
    final project = await service.getPublicProject('mock-token');
    state = state.copyWith(project: project, isLoading: false);
  }

  void setTab(int tab) =>
      state = state.copyWith(selectedTab: tab, expandedItemId: () => null);

  void toggleExpanded(String id) {
    if (state.expandedItemId == id) {
      state = state.copyWith(expandedItemId: () => null);
    } else {
      state = state.copyWith(expandedItemId: () => id);
    }
  }
}

final _publicProjectProvider =
    NotifierProvider<_PublicProjectNotifier, _PublicProjectState>(
      _PublicProjectNotifier.new,
    );

// ── Status helpers ──────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'done':
      return const Color(0xFF4CAF50);
    case 'in-progress':
      return const Color(0xFF2196F3);
    case 'in-review':
      return const Color(0xFFFF9800);
    case 'in-testing':
      return const Color(0xFF9C27B0);
    case 'in-docs':
      return const Color(0xFF00BCD4);
    case 'todo':
    default:
      return const Color(0xFF9E9E9E);
  }
}

// ── Screen ──────────────────────────────────────────────────────────────────

/// Read-only public project view accessible via a share link.
class PublicProjectScreen extends ConsumerWidget {
  const PublicProjectScreen({super.key});

  static const _tabs = ['Features', 'Notes', 'Docs'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final pState = ref.watch(_publicProjectProvider);

    if (pState.isLoading) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: Center(child: CircularProgressIndicator(color: tokens.accent)),
      );
    }

    final project = pState.project;
    if (project == null) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: Center(
          child: Text(
            AppLocalizations.of(context).projectNotFound,
            style: TextStyle(color: tokens.fgMuted, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Project header ─────────────────────────────────────
            _ProjectHeader(project: project, tokens: tokens),

            // ── Tab bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (int i = 0; i < _tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(_publicProjectProvider.notifier).setTab(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: pState.selectedTab == i
                                ? tokens.accent.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: pState.selectedTab == i
                                  ? tokens.accent.withValues(alpha: 0.5)
                                  : tokens.borderFaint,
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              color: pState.selectedTab == i
                                  ? tokens.accent
                                  : tokens.fgMuted,
                              fontSize: 14,
                              fontWeight: pState.selectedTab == i
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tab content ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTabContent(context, ref, pState, project, tokens),
            ),

            // ── Footer ────────────────────────────────────────────
            const SizedBox(height: 48),
            _Footer(tokens: tokens),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    _PublicProjectState pState,
    PublicProject project,
    OrchestraColorTokens tokens,
  ) {
    switch (pState.selectedTab) {
      case 0:
        return _FeaturesTab(
          features: project.features,
          expandedId: pState.expandedItemId,
          tokens: tokens,
          onToggle: (id) =>
              ref.read(_publicProjectProvider.notifier).toggleExpanded(id),
        );
      case 1:
        return _NotesTab(
          notes: project.notes,
          expandedId: pState.expandedItemId,
          tokens: tokens,
          onToggle: (id) =>
              ref.read(_publicProjectProvider.notifier).toggleExpanded(id),
        );
      case 2:
        return _DocsTab(
          docs: project.docs,
          expandedId: pState.expandedItemId,
          tokens: tokens,
          onToggle: (id) =>
              ref.read(_publicProjectProvider.notifier).toggleExpanded(id),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Project header ──────────────────────────────────────────────────────────

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project, required this.tokens});

  final PublicProject project;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.accent.withValues(alpha: 0.08),
            tokens.accentAlt.withValues(alpha: 0.05),
          ],
        ),
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tokens.accent, tokens.accentAlt],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'OA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.description,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Share button.
              _ShareButton(tokens: tokens, projectName: project.name),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row.
          Row(
            children: [
              _StatPill(
                icon: Icons.task_alt_outlined,
                label:
                    '${project.features.where((f) => f.status == 'done').length}/${project.features.length} features done',
                tokens: tokens,
              ),
              const SizedBox(width: 12),
              _StatPill(
                icon: Icons.description_outlined,
                label: '${project.notes.length} notes',
                tokens: tokens,
              ),
              const SizedBox(width: 12),
              _StatPill(
                icon: Icons.menu_book_outlined,
                label: '${project.docs.length} docs',
                tokens: tokens,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Features tab (kanban-like board) ────────────────────────────────────────

class _FeaturesTab extends StatelessWidget {
  const _FeaturesTab({
    required this.features,
    required this.expandedId,
    required this.tokens,
    required this.onToggle,
  });

  final List<PublicFeature> features;
  final String? expandedId;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    // Group by status for a kanban-like view.
    final statuses = ['todo', 'in-progress', 'in-testing', 'in-review', 'done'];
    final grouped = <String, List<PublicFeature>>{};
    for (final s in statuses) {
      grouped[s] = features.where((f) => f.status == s).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Horizontal columns.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in statuses)
                if (grouped[status]!.isNotEmpty)
                  Expanded(
                    child: _StatusColumn(
                      status: status,
                      features: grouped[status]!,
                      expandedId: expandedId,
                      tokens: tokens,
                      onToggle: onToggle,
                    ),
                  ),
            ],
          );
        }
        // Vertical stacked.
        return Column(
          children: [
            for (final status in statuses)
              if (grouped[status]!.isNotEmpty)
                _StatusColumn(
                  status: status,
                  features: grouped[status]!,
                  expandedId: expandedId,
                  tokens: tokens,
                  onToggle: onToggle,
                ),
          ],
        );
      },
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.status,
    required this.features,
    required this.expandedId,
    required this.tokens,
    required this.onToggle,
  });

  final String status;
  final List<PublicFeature> features;
  final String? expandedId;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header.
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${features.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Cards.
          ...features.map((f) {
            final isExpanded = expandedId == f.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                onTap: () => onToggle(f.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.id,
                            style: TextStyle(
                              color: tokens.accent,
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.fgDim.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            f.kind,
                            style: TextStyle(color: tokens.fgDim, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.title,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isExpanded && f.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        f.description,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Notes tab ───────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({
    required this.notes,
    required this.expandedId,
    required this.tokens,
    required this.onToggle,
  });

  final List<PublicNote> notes;
  final String? expandedId;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return _EmptyTab(
        label: AppLocalizations.of(context).noNotesShared,
        tokens: tokens,
      );
    }
    return Column(
      children: notes.map((note) {
        final isExpanded = expandedId == note.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            onTap: () => onToggle(note.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: tokens.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: tokens.fgDim,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded && note.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    note.content,
                    style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Docs tab ────────────────────────────────────────────────────────────────

class _DocsTab extends StatelessWidget {
  const _DocsTab({
    required this.docs,
    required this.expandedId,
    required this.tokens,
    required this.onToggle,
  });

  final List<PublicDoc> docs;
  final String? expandedId;
  final OrchestraColorTokens tokens;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return _EmptyTab(
        label: AppLocalizations.of(context).noDocsShared,
        tokens: tokens,
      );
    }
    return Column(
      children: docs.map((doc) {
        final isExpanded = expandedId == doc.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            onTap: () => onToggle(doc.id),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: tokens.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            doc.path,
                            style: TextStyle(
                              color: tokens.fgDim,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: tokens.fgDim,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded && doc.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    doc.content,
                    style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Empty tab ───────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.label, required this.tokens});

  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: tokens.fgDim, size: 40),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Share button ────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.tokens, required this.projectName});

  final OrchestraColorTokens tokens;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
          const ClipboardData(
            text: 'https://orchestra.dev/p/pub_orchestra-agents',
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).publicLinkCopiedToClipboard,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share_outlined, color: tokens.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                color: tokens.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat pill ───────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.bgAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderFaint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tokens.fgDim, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Divider(color: tokens.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).poweredByOrchestra,
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
