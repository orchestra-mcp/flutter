import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class _Project {
  const _Project({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.features,
    required this.members,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<_Feature> features;
  final List<_Member> members;

  int get doneCount => features.where((f) => f.status == 'done').length;
  int get totalCount => features.length;
  double get progress => totalCount == 0 ? 0.0 : doneCount / totalCount;
}

class _Feature {
  const _Feature({
    required this.id,
    required this.title,
    required this.status,
    required this.kind,
    required this.priority,
    required this.assignee,
  });

  final String id;
  final String title;
  final String status;
  final String kind;
  final String priority;
  final String assignee;
}

class _Member {
  const _Member({
    required this.name,
    required this.avatar,
    required this.role,
    required this.assignedCount,
    required this.completedCount,
  });

  final String name;
  final String avatar;
  final String role;
  final int assignedCount;
  final int completedCount;

  double get workload =>
      assignedCount == 0 ? 0.0 : assignedCount / 8.0; // max 8 per person
}

// ── Mock data ───────────────────────────────────────────────────────────────

final _mockProjects = [
  _Project(
    id: 'proj-agents',
    name: 'Orchestra Agents',
    icon: Icons.smart_toy_outlined,
    color: const Color(0xFF7C6FFF),
    features: const [
      _Feature(
        id: 'FEAT-BWL',
        title: 'Delegation Notifications',
        status: 'in-progress',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-XND',
        title: 'Activity Feed',
        status: 'in-progress',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Marcus Rivera',
      ),
      _Feature(
        id: 'FEAT-IGV',
        title: 'Tunnels Dashboard',
        status: 'todo',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Aisha Patel',
      ),
      _Feature(
        id: 'FEAT-KTT',
        title: 'Workflow Generator',
        status: 'done',
        kind: 'chore',
        priority: 'P2',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-CRJ',
        title: 'Workflow Sharing',
        status: 'in-testing',
        kind: 'feature',
        priority: 'P2',
        assignee: 'James Wilson',
      ),
      _Feature(
        id: 'FEAT-EPW',
        title: 'Public Sharing',
        status: 'in-review',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Marcus Rivera',
      ),
      _Feature(
        id: 'FEAT-CUY',
        title: 'Project Manager UI',
        status: 'in-progress',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-UJV',
        title: 'Web Architecture',
        status: 'done',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-FRU',
        title: 'Web App Shell',
        status: 'done',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Marcus Rivera',
      ),
      _Feature(
        id: 'FEAT-HUF',
        title: 'Marketing Pages',
        status: 'done',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Aisha Patel',
      ),
      _Feature(
        id: 'FEAT-YOZ',
        title: 'Auth Web Routes',
        status: 'in-testing',
        kind: 'feature',
        priority: 'P1',
        assignee: 'James Wilson',
      ),
      _Feature(
        id: 'FEAT-FNB',
        title: 'Admin Panel',
        status: 'todo',
        kind: 'feature',
        priority: 'P2',
        assignee: 'Aisha Patel',
      ),
    ],
    members: const [
      _Member(
        name: 'Sarah Chen',
        avatar: 'SC',
        role: 'Lead Engineer',
        assignedCount: 4,
        completedCount: 2,
      ),
      _Member(
        name: 'Marcus Rivera',
        avatar: 'MR',
        role: 'Frontend Dev',
        assignedCount: 3,
        completedCount: 1,
      ),
      _Member(
        name: 'Aisha Patel',
        avatar: 'AP',
        role: 'Backend Dev',
        assignedCount: 3,
        completedCount: 1,
      ),
      _Member(
        name: 'James Wilson',
        avatar: 'JW',
        role: 'QA Engineer',
        assignedCount: 2,
        completedCount: 0,
      ),
    ],
  ),
  _Project(
    id: 'proj-swift',
    name: 'Orchestra Swift',
    icon: Icons.apple,
    color: const Color(0xFFFF6B6B),
    features: const [
      _Feature(
        id: 'FEAT-BKJ',
        title: 'Tray-Only Mode',
        status: 'done',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-BSI',
        title: 'Plugin System',
        status: 'done',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Sarah Chen',
      ),
      _Feature(
        id: 'FEAT-CBE',
        title: 'Smart Input',
        status: 'in-progress',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Marcus Rivera',
      ),
      _Feature(
        id: 'FEAT-DAX',
        title: 'Workspace Switch',
        status: 'done',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Aisha Patel',
      ),
      _Feature(
        id: 'FEAT-DHD',
        title: 'Voice Input',
        status: 'todo',
        kind: 'feature',
        priority: 'P2',
        assignee: 'James Wilson',
      ),
    ],
    members: const [
      _Member(
        name: 'Sarah Chen',
        avatar: 'SC',
        role: 'Lead',
        assignedCount: 2,
        completedCount: 2,
      ),
      _Member(
        name: 'Marcus Rivera',
        avatar: 'MR',
        role: 'Dev',
        assignedCount: 1,
        completedCount: 0,
      ),
      _Member(
        name: 'Aisha Patel',
        avatar: 'AP',
        role: 'Dev',
        assignedCount: 1,
        completedCount: 1,
      ),
      _Member(
        name: 'James Wilson',
        avatar: 'JW',
        role: 'QA',
        assignedCount: 1,
        completedCount: 0,
      ),
    ],
  ),
  _Project(
    id: 'proj-web',
    name: 'Orchestra Web',
    icon: Icons.language_rounded,
    color: const Color(0xFF4ECDC4),
    features: const [
      _Feature(
        id: 'FEAT-AAM',
        title: 'SSR Support',
        status: 'todo',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Marcus Rivera',
      ),
      _Feature(
        id: 'FEAT-BLR',
        title: 'OAuth2 Flow',
        status: 'in-progress',
        kind: 'feature',
        priority: 'P0',
        assignee: 'Aisha Patel',
      ),
      _Feature(
        id: 'FEAT-CCN',
        title: 'Dashboard Widgets',
        status: 'done',
        kind: 'feature',
        priority: 'P1',
        assignee: 'Sarah Chen',
      ),
    ],
    members: const [
      _Member(
        name: 'Sarah Chen',
        avatar: 'SC',
        role: 'Lead',
        assignedCount: 1,
        completedCount: 1,
      ),
      _Member(
        name: 'Marcus Rivera',
        avatar: 'MR',
        role: 'Dev',
        assignedCount: 1,
        completedCount: 0,
      ),
      _Member(
        name: 'Aisha Patel',
        avatar: 'AP',
        role: 'Dev',
        assignedCount: 1,
        completedCount: 0,
      ),
    ],
  ),
];

// ── State ───────────────────────────────────────────────────────────────────

class _PMState {
  const _PMState({this.selectedProjectIndex = 0, this.selectedTab = 0});

  final int selectedProjectIndex;
  final int selectedTab;

  _PMState copyWith({int? selectedProjectIndex, int? selectedTab}) => _PMState(
    selectedProjectIndex: selectedProjectIndex ?? this.selectedProjectIndex,
    selectedTab: selectedTab ?? this.selectedTab,
  );
}

class _PMNotifier extends Notifier<_PMState> {
  @override
  _PMState build() => const _PMState();

  void selectProject(int index) =>
      state = state.copyWith(selectedProjectIndex: index, selectedTab: 0);

  void selectTab(int tab) => state = state.copyWith(selectedTab: tab);
}

final _pmProvider = NotifierProvider<_PMNotifier, _PMState>(_PMNotifier.new);

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
    case 'todo':
    default:
      return const Color(0xFF9E9E9E);
  }
}

const _kanbanStatuses = [
  'todo',
  'in-progress',
  'in-testing',
  'in-review',
  'done',
];
List<String> _kanbanLabelsL10n(AppLocalizations l10n) => [
  l10n.kanbanTodo,
  l10n.kanbanInProgress,
  l10n.kanbanInTesting,
  l10n.kanbanInReview,
  l10n.kanbanDone,
];

// ── Screen ──────────────────────────────────────────────────────────────────

/// Full project management dashboard with sidebar, kanban board, team, and reports.
class ProjectManagerScreen extends ConsumerWidget {
  const ProjectManagerScreen({super.key});

  static List<String> _tabs(AppLocalizations l10n) => [
    l10n.tabBoard,
    l10n.tabTimeline,
    l10n.tabTeam,
    l10n.tabReports,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final pmState = ref.watch(_pmProvider);
    final project = _mockProjects[pmState.selectedProjectIndex];

    final l10n = AppLocalizations.of(context);
    final tabs = _tabs(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 900;

        return Row(
          children: [
            // ── Sidebar ───────────────────────────────────────────
            if (showSidebar)
              SizedBox(
                width: 260,
                child: _ProjectSidebar(
                  projects: _mockProjects,
                  selectedIndex: pmState.selectedProjectIndex,
                  tokens: tokens,
                  onSelect: (i) =>
                      ref.read(_pmProvider.notifier).selectProject(i),
                ),
              ),

            // ── Main content ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar.
                    _TopBar(
                      project: project,
                      tokens: tokens,
                      showProjectSelector: !showSidebar,
                      selectedIndex: pmState.selectedProjectIndex,
                      onProjectChanged: (i) =>
                          ref.read(_pmProvider.notifier).selectProject(i),
                    ),
                    const SizedBox(height: 24),

                    // Tab bar.
                    Row(
                      children: [
                        for (int i = 0; i < tabs.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  ref.read(_pmProvider.notifier).selectTab(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: pmState.selectedTab == i
                                      ? tokens.accent.withValues(alpha: 0.18)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: pmState.selectedTab == i
                                        ? tokens.accent.withValues(alpha: 0.5)
                                        : tokens.borderFaint,
                                  ),
                                ),
                                child: Text(
                                  tabs[i],
                                  style: TextStyle(
                                    color: pmState.selectedTab == i
                                        ? tokens.accent
                                        : tokens.fgMuted,
                                    fontSize: 13,
                                    fontWeight: pmState.selectedTab == i
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tab content.
                    _buildTab(pmState.selectedTab, project, tokens),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(int tab, _Project project, OrchestraColorTokens tokens) {
    switch (tab) {
      case 0:
        return _BoardTab(project: project, tokens: tokens);
      case 1:
        return _TimelineTab(project: project, tokens: tokens);
      case 2:
        return _TeamTab(members: project.members, tokens: tokens);
      case 3:
        return _ReportsTab(project: project, tokens: tokens);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Project sidebar ─────────────────────────────────────────────────────────

class _ProjectSidebar extends StatelessWidget {
  const _ProjectSidebar({
    required this.projects,
    required this.selectedIndex,
    required this.tokens,
    required this.onSelect,
  });

  final List<_Project> projects;
  final int selectedIndex;
  final OrchestraColorTokens tokens;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(right: BorderSide(color: tokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: tokens.accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).pmProjects,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          // Project list.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: projects.length,
              itemBuilder: (ctx, i) {
                final p = projects[i];
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Material(
                    color: isSelected
                        ? tokens.accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => onSelect(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(p.icon, color: p.color, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? tokens.accent
                                          : tokens.fgBright,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // Progress bar.
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: p.progress,
                                      minHeight: 3,
                                      backgroundColor: tokens.border,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        p.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${p.doneCount}/${p.totalCount}',
                              style: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // New project button.
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).comingSoon),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.borderFaint),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: tokens.fgMuted, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).newProject,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.project,
    required this.tokens,
    required this.showProjectSelector,
    required this.selectedIndex,
    required this.onProjectChanged,
  });

  final _Project project;
  final OrchestraColorTokens tokens;
  final bool showProjectSelector;
  final int selectedIndex;
  final ValueChanged<int> onProjectChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showProjectSelector) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedIndex,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
                items: [
                  for (int i = 0; i < _mockProjects.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(_mockProjects[i].name),
                    ),
                ],
                onChanged: (i) {
                  if (i != null) onProjectChanged(i);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: project.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(project.icon, color: project.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(
                  context,
                ).pmFeaturesComplete(project.doneCount, project.totalCount),
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        // Progress ring.
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: project.progress,
                strokeWidth: 4,
                backgroundColor: tokens.border,
                valueColor: AlwaysStoppedAnimation<Color>(project.color),
              ),
              Text(
                '${(project.progress * 100).toInt()}%',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Board tab (Kanban) ──────────────────────────────────────────────────────

class _BoardTab extends StatelessWidget {
  const _BoardTab({required this.project, required this.tokens});

  final _Project project;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final kanbanLabels = _kanbanLabelsL10n(AppLocalizations.of(context));
    final grouped = <String, List<_Feature>>{};
    for (final s in _kanbanStatuses) {
      grouped[s] = project.features.where((f) => f.status == s).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _kanbanStatuses.length; i++)
                  SizedBox(
                    width: 220,
                    child: _KanbanColumn(
                      label: kanbanLabels[i],
                      status: _kanbanStatuses[i],
                      features: grouped[_kanbanStatuses[i]]!,
                      tokens: tokens,
                    ),
                  ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (int i = 0; i < _kanbanStatuses.length; i++)
              _KanbanColumn(
                label: kanbanLabels[i],
                status: _kanbanStatuses[i],
                features: grouped[_kanbanStatuses[i]]!,
                tokens: tokens,
              ),
          ],
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.label,
    required this.status,
    required this.features,
    required this.tokens,
  });

  final String label;
  final String status;
  final List<_Feature> features;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${features.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Feature cards.
          if (features.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).pmNoItems,
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ),
            )
          else
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
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
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            f.priority,
                            style: TextStyle(
                              color: f.priority == 'P0'
                                  ? const Color(0xFFF44336)
                                  : tokens.fgDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.title,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
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
                              style: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            f.assignee.split(' ').first,
                            style: TextStyle(
                              color: tokens.fgMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Timeline tab ────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.project, required this.tokens});

  final _Project project;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Simple timeline representation: features listed in status order.
    final sorted = List<_Feature>.of(project.features)
      ..sort((a, b) {
        final order = _kanbanStatuses
            .indexOf(a.status)
            .compareTo(_kanbanStatuses.indexOf(b.status));
        if (order != 0) return order;
        return a.priority.compareTo(b.priority);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).features,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final color = _statusColor(f.status);
          final isLast = i == sorted.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline bar.
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 56, color: tokens.border),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.title,
                                style: TextStyle(
                                  color: tokens.fgBright,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    f.id,
                                    style: TextStyle(
                                      color: tokens.accent,
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    f.assignee,
                                    style: TextStyle(
                                      color: tokens.fgMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            f.status,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Team tab ────────────────────────────────────────────────────────────────

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.members, required this.tokens});

  final List<_Member> members;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).teamMembers,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...members.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar.
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        m.avatar,
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          m.role,
                          style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Stats.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).pmNAssigned(m.assignedCount),
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).pmNCompleted(m.completedCount),
                        style: TextStyle(
                          color: const Color(0xFF4CAF50),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Workload indicator.
                  _WorkloadIndicator(value: m.workload, tokens: tokens),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkloadIndicator extends StatelessWidget {
  const _WorkloadIndicator({required this.value, required this.tokens});

  final double value;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = value > 0.75
        ? const Color(0xFFF44336)
        : value > 0.5
        ? const Color(0xFFFF9800)
        : const Color(0xFF4CAF50);

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: tokens.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${(value * 100).toInt()}',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reports tab ─────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.project, required this.tokens});

  final _Project project;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    // Status counts for the donut chart.
    final statusCounts = <String, int>{};
    for (final f in project.features) {
      statusCounts[f.status] = (statusCounts[f.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).pmReports,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),

        // ── Completion chart + velocity ──────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final chart = _DonutChart(
              statusCounts: statusCounts,
              total: project.features.length,
              tokens: tokens,
            );
            final velocity = _VelocityCard(project: project, tokens: tokens);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: 16),
                  Expanded(child: velocity),
                ],
              );
            }
            return Column(
              children: [chart, const SizedBox(height: 16), velocity],
            );
          },
        ),
        const SizedBox(height: 24),

        // ── Burn-down placeholder ────────────────────────────────
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).pmBurndownChart,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tokens.bgAlt.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.borderFaint),
                ),
                child: CustomPaint(
                  painter: _BurndownPainter(
                    total: project.features.length,
                    done: project.doneCount,
                    accent: tokens.accent,
                    muted: tokens.fgDim,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Donut chart (custom paint) ──────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.statusCounts,
    required this.total,
    required this.tokens,
  });

  final Map<String, int> statusCounts;
  final int total;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).pmCompletion,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: statusCounts.entries.map((e) {
                  return _DonutSegment(
                    value: e.value.toDouble(),
                    color: _statusColor(e.key),
                  );
                }).toList(),
                total: total.toDouble(),
                centerText:
                    '${((statusCounts['done'] ?? 0) / (total == 0 ? 1 : total) * 100).toInt()}%',
                textColor: tokens.fgBright,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend.
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: statusCounts.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key} (${e.value})',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DonutSegment {
  const _DonutSegment({required this.value, required this.color});
  final double value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.total,
    required this.centerText,
    required this.textColor,
  });

  final List<_DonutSegment> segments;
  final double total;
  final String centerText;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value / (total == 0 ? 1 : total)) * 2 * math.pi;
      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }

    // Center text.
    final textPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Velocity card ───────────────────────────────────────────────────────────

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({required this.project, required this.tokens});

  final _Project project;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pmVelocityMetrics,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: l10n.pmFeaturesDone,
            value: '${project.doneCount}',
            tokens: tokens,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.pmInProgress,
            value:
                '${project.features.where((f) => f.status == 'in-progress').length}',
            tokens: tokens,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.pmBlockedReview,
            value:
                '${project.features.where((f) => f.status == 'in-review').length}',
            tokens: tokens,
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.pmAvgCycleTime,
            value: l10n.pmDays('2.4'),
            tokens: tokens,
            color: tokens.accent,
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.pmThroughput7d,
            value: l10n.pmNFeatures(project.doneCount),
            tokens: tokens,
            color: tokens.accentAlt,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.tokens,
    required this.color,
  });

  final String label;
  final String value;
  final OrchestraColorTokens tokens;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Burn-down painter ───────────────────────────────────────────────────────

class _BurndownPainter extends CustomPainter {
  _BurndownPainter({
    required this.total,
    required this.done,
    required this.accent,
    required this.muted,
  });

  final int total;
  final int done;
  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 24.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Ideal line (diagonal from top-left to bottom-right).
    final idealPaint = Paint()
      ..color = muted.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(pad, pad), Offset(pad + w, pad + h), idealPaint);

    // Actual line (stepped based on done ratio).
    final progress = done / (total == 0 ? 1 : total);
    final points = <Offset>[
      Offset(pad, pad),
      Offset(pad + w * 0.15, pad + h * 0.05),
      Offset(pad + w * 0.3, pad + h * 0.15),
      Offset(pad + w * 0.45, pad + h * 0.25),
      Offset(pad + w * 0.55, pad + h * 0.35),
      Offset(pad + w * 0.7, pad + h * 0.5),
      Offset(pad + w * 0.85, pad + h * 0.7),
      Offset(pad + w * progress.clamp(0.0, 1.0), pad + h * progress),
    ];

    final actualPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, actualPaint);

    // Dot at current position.
    final dotPaint = Paint()..color = accent;
    canvas.drawCircle(points.last, 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
