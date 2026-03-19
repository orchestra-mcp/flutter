import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/workflow/workflow_generator.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Mock data ───────────────────────────────────────────────────────────────

final _defaultSkills = [
  const SkillConfig(
    command: 'docs',
    path: '.claude/skills/docs/',
    description: 'Generate and manage documentation',
  ),
  const SkillConfig(
    command: 'plugin-generator',
    path: '.claude/skills/plugin-generator/',
    description: 'Scaffold new Orchestra plugins',
  ),
  const SkillConfig(
    command: 'project-manager',
    path: '.claude/skills/project-manager/',
    description: 'Manage features, plans, and workflows',
  ),
  const SkillConfig(
    command: 'qa-testing',
    path: '.claude/skills/qa-testing/',
    description: 'Run QA tests and validation',
  ),
  const SkillConfig(
    command: 'typescript-react',
    path: '.claude/skills/typescript-react/',
    description: 'TypeScript/React development patterns',
  ),
  const SkillConfig(
    command: 'rust-engine',
    path: '.claude/skills/rust-engine/',
    description: 'Rust engine development',
    enabled: false,
  ),
];

final _defaultAgents = [
  const AgentConfig(
    name: 'devops',
    file: '.claude/agents/devops.md',
    description: 'Infrastructure, CI/CD, and deployment',
  ),
  const AgentConfig(
    name: 'qa-playwright',
    file: '.claude/agents/qa-playwright.md',
    description: 'End-to-end browser testing',
  ),
  const AgentConfig(
    name: 'scrum-master',
    file: '.claude/agents/scrum-master.md',
    description: 'Sprint management and ceremonies',
  ),
  const AgentConfig(
    name: 'rust-engineer',
    file: '.claude/agents/rust-engineer.md',
    description: 'Rust systems programming',
    enabled: false,
  ),
  const AgentConfig(
    name: 'frontend-dev',
    file: '.claude/agents/frontend-dev.md',
    description: 'React/TypeScript frontend development',
  ),
];

final _defaultHooks = [
  const HookConfig(
    name: 'notify',
    file: '.claude/hooks/notify.sh',
    description: 'Desktop notification on task completion',
  ),
  const HookConfig(
    name: 'orchestra-mcp-hook',
    file: '.claude/hooks/orchestra-mcp-hook.sh',
    description: 'Syncs feature state with MCP server',
  ),
];

// ── State ───────────────────────────────────────────────────────────────────

class _WorkflowEditorState {
  const _WorkflowEditorState({
    required this.skills,
    required this.agents,
    required this.hooks,
    this.selectedTab = 0,
    this.generatedPreview,
  });

  final List<SkillConfig> skills;
  final List<AgentConfig> agents;
  final List<HookConfig> hooks;
  final int selectedTab;
  final String? generatedPreview;

  _WorkflowEditorState copyWith({
    List<SkillConfig>? skills,
    List<AgentConfig>? agents,
    List<HookConfig>? hooks,
    int? selectedTab,
    String? Function()? generatedPreview,
  }) => _WorkflowEditorState(
    skills: skills ?? this.skills,
    agents: agents ?? this.agents,
    hooks: hooks ?? this.hooks,
    selectedTab: selectedTab ?? this.selectedTab,
    generatedPreview: generatedPreview != null
        ? generatedPreview()
        : this.generatedPreview,
  );
}

class _WorkflowEditorNotifier extends Notifier<_WorkflowEditorState> {
  @override
  _WorkflowEditorState build() => _WorkflowEditorState(
    skills: List.of(_defaultSkills),
    agents: List.of(_defaultAgents),
    hooks: List.of(_defaultHooks),
  );

  void setTab(int tab) => state = state.copyWith(selectedTab: tab);

  void toggleSkill(int index) {
    final updated = List<SkillConfig>.of(state.skills);
    updated[index] = updated[index].copyWith(enabled: !updated[index].enabled);
    state = state.copyWith(skills: updated);
  }

  void toggleAgent(int index) {
    final updated = List<AgentConfig>.of(state.agents);
    updated[index] = updated[index].copyWith(enabled: !updated[index].enabled);
    state = state.copyWith(agents: updated);
  }

  void toggleHook(int index) {
    final updated = List<HookConfig>.of(state.hooks);
    updated[index] = updated[index].copyWith(enabled: !updated[index].enabled);
    state = state.copyWith(hooks: updated);
  }

  void reorderSkills(int oldIndex, int newIndex) {
    final updated = List<SkillConfig>.of(state.skills);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(skills: updated);
  }

  void reorderAgents(int oldIndex, int newIndex) {
    final updated = List<AgentConfig>.of(state.agents);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(agents: updated);
  }

  void reorderHooks(int oldIndex, int newIndex) {
    final updated = List<HookConfig>.of(state.hooks);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(hooks: updated);
  }

  void generate() {
    const gen = WorkflowGenerator();
    const project = ProjectInfo(
      name: 'Orchestra Agents',
      description: 'AI-powered project management framework',
      toolCount: 290,
      promptCount: 5,
    );
    final md = gen.generateClaudeMd(
      skills: state.skills,
      agents: state.agents,
      hooks: state.hooks,
      project: project,
    );
    state = state.copyWith(generatedPreview: () => md);
  }

  void clearPreview() => state = state.copyWith(generatedPreview: () => null);
}

final _workflowEditorProvider =
    NotifierProvider<_WorkflowEditorNotifier, _WorkflowEditorState>(
      _WorkflowEditorNotifier.new,
    );

// ── Screen ──────────────────────────────────────────────────────────────────

/// Editor UI for workflow configuration (skills, agents, hooks) with
/// markdown generation and export.
class WorkflowEditorScreen extends ConsumerWidget {
  const WorkflowEditorScreen({super.key});

  List<String> _tabs(AppLocalizations l10n) => [
    l10n.skills,
    l10n.agents,
    l10n.hooks,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final editorState = ref.watch(_workflowEditorProvider);
    final tabs = _tabs(l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.workflowEditor,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ActionButton(
                label: l10n.generate,
                icon: Icons.auto_awesome_rounded,
                color: tokens.accent,
                tokens: tokens,
                onTap: () =>
                    ref.read(_workflowEditorProvider.notifier).generate(),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: l10n.export,
                icon: Icons.file_download_outlined,
                color: tokens.accentAlt,
                tokens: tokens,
                onTap: () => _exportToClipboard(context, editorState),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.configureWorkflowDesc,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Tab bar ───────────────────────────────────────────────
          Row(
            children: [
              for (int i = 0; i < tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TabChip(
                    label: tabs[i],
                    count: i == 0
                        ? editorState.skills.length
                        : i == 1
                        ? editorState.agents.length
                        : editorState.hooks.length,
                    isSelected: editorState.selectedTab == i,
                    tokens: tokens,
                    onTap: () =>
                        ref.read(_workflowEditorProvider.notifier).setTab(i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Tab content ───────────────────────────────────────────
          if (editorState.selectedTab == 0)
            _SkillsList(
              skills: editorState.skills,
              tokens: tokens,
              onToggle: (i) =>
                  ref.read(_workflowEditorProvider.notifier).toggleSkill(i),
              onReorder: (old, nu) => ref
                  .read(_workflowEditorProvider.notifier)
                  .reorderSkills(old, nu),
            ),
          if (editorState.selectedTab == 1)
            _AgentsList(
              agents: editorState.agents,
              tokens: tokens,
              onToggle: (i) =>
                  ref.read(_workflowEditorProvider.notifier).toggleAgent(i),
              onReorder: (old, nu) => ref
                  .read(_workflowEditorProvider.notifier)
                  .reorderAgents(old, nu),
            ),
          if (editorState.selectedTab == 2)
            _HooksList(
              hooks: editorState.hooks,
              tokens: tokens,
              onToggle: (i) =>
                  ref.read(_workflowEditorProvider.notifier).toggleHook(i),
              onReorder: (old, nu) => ref
                  .read(_workflowEditorProvider.notifier)
                  .reorderHooks(old, nu),
            ),

          // ── Preview ───────────────────────────────────────────────
          if (editorState.generatedPreview != null) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                Text(
                  l10n.generatedPreview,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: tokens.fgMuted,
                    size: 18,
                  ),
                  onPressed: () =>
                      ref.read(_workflowEditorProvider.notifier).clearPreview(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                editorState.generatedPreview!,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _exportToClipboard(BuildContext context, _WorkflowEditorState state) {
    const gen = WorkflowGenerator();
    const project = ProjectInfo(
      name: 'Orchestra Agents',
      description: 'AI-powered project management framework',
      toolCount: 290,
      promptCount: 5,
    );
    final md = gen.generateClaudeMd(
      skills: state.skills,
      agents: state.agents,
      hooks: state.hooks,
      project: project,
    );
    Clipboard.setData(ClipboardData(text: md));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).claudeMdCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Skills list ─────────────────────────────────────────────────────────────

class _SkillsList extends StatelessWidget {
  const _SkillsList({
    required this.skills,
    required this.tokens,
    required this.onToggle,
    required this.onReorder,
  });

  final List<SkillConfig> skills;
  final OrchestraColorTokens tokens;
  final ValueChanged<int> onToggle;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: skills.length,
      onReorder: onReorder,
      proxyDecorator: (child, _, __) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (ctx, i) {
        final skill = skills[i];
        return _ConfigItemTile(
          key: ValueKey('skill-${skill.command}'),
          icon: Icons.bolt_rounded,
          title: '/${skill.command}',
          subtitle: skill.description,
          trailing: skill.path,
          enabled: skill.enabled,
          tokens: tokens,
          onToggle: () => onToggle(i),
        );
      },
    );
  }
}

// ── Agents list ─────────────────────────────────────────────────────────────

class _AgentsList extends StatelessWidget {
  const _AgentsList({
    required this.agents,
    required this.tokens,
    required this.onToggle,
    required this.onReorder,
  });

  final List<AgentConfig> agents;
  final OrchestraColorTokens tokens;
  final ValueChanged<int> onToggle;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: agents.length,
      onReorder: onReorder,
      proxyDecorator: (child, _, __) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (ctx, i) {
        final agent = agents[i];
        return _ConfigItemTile(
          key: ValueKey('agent-${agent.name}'),
          icon: Icons.smart_toy_outlined,
          title: agent.name,
          subtitle: agent.description,
          trailing: agent.file,
          enabled: agent.enabled,
          tokens: tokens,
          onToggle: () => onToggle(i),
        );
      },
    );
  }
}

// ── Hooks list ──────────────────────────────────────────────────────────────

class _HooksList extends StatelessWidget {
  const _HooksList({
    required this.hooks,
    required this.tokens,
    required this.onToggle,
    required this.onReorder,
  });

  final List<HookConfig> hooks;
  final OrchestraColorTokens tokens;
  final ValueChanged<int> onToggle;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hooks.length,
      onReorder: onReorder,
      proxyDecorator: (child, _, __) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (ctx, i) {
        final hook = hooks[i];
        return _ConfigItemTile(
          key: ValueKey('hook-${hook.name}'),
          icon: Icons.webhook_rounded,
          title: hook.name,
          subtitle: hook.description,
          trailing: hook.file,
          enabled: hook.enabled,
          tokens: tokens,
          onToggle: () => onToggle(i),
        );
      },
    );
  }
}

// ── Reusable config tile ────────────────────────────────────────────────────

class _ConfigItemTile extends StatelessWidget {
  const _ConfigItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.enabled,
    required this.tokens,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool enabled;
  final OrchestraColorTokens tokens;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Drag handle.
            Icon(Icons.drag_indicator_rounded, color: tokens.fgDim, size: 18),
            const SizedBox(width: 12),
            // Icon.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (enabled ? tokens.accent : tokens.fgDim).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled ? tokens.accent : tokens.fgDim,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Text.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? tokens.fgBright : tokens.fgDim,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: enabled ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Path.
            Text(
              trailing,
              style: TextStyle(
                color: tokens.fgDim,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 12),
            // Toggle.
            Switch.adaptive(
              value: enabled,
              onChanged: (_) => onToggle(),
              activeColor: tokens.accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab chip ────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accent.withValues(alpha: 0.18)
              : tokens.bgAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.5)
                : tokens.borderFaint,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? tokens.accent : tokens.fgMuted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.accent.withValues(alpha: 0.25)
                    : tokens.fgDim.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? tokens.accent : tokens.fgDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action button ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
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
