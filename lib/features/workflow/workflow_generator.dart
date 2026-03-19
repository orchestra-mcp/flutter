// ── Workflow configuration models & markdown generator ───────────────────────

/// A skill (slash command) definition.
class SkillConfig {
  const SkillConfig({
    required this.command,
    required this.path,
    this.description = '',
    this.enabled = true,
  });

  final String command;
  final String path;
  final String description;
  final bool enabled;

  SkillConfig copyWith({
    String? command,
    String? path,
    String? description,
    bool? enabled,
  }) =>
      SkillConfig(
        command: command ?? this.command,
        path: path ?? this.path,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
      );
}

/// An agent definition.
class AgentConfig {
  const AgentConfig({
    required this.name,
    required this.file,
    this.description = '',
    this.enabled = true,
  });

  final String name;
  final String file;
  final String description;
  final bool enabled;

  AgentConfig copyWith({
    String? name,
    String? file,
    String? description,
    bool? enabled,
  }) =>
      AgentConfig(
        name: name ?? this.name,
        file: file ?? this.file,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
      );
}

/// A hook definition.
class HookConfig {
  const HookConfig({
    required this.name,
    required this.file,
    this.description = '',
    this.enabled = true,
  });

  final String name;
  final String file;
  final String description;
  final bool enabled;

  HookConfig copyWith({
    String? name,
    String? file,
    String? description,
    bool? enabled,
  }) =>
      HookConfig(
        name: name ?? this.name,
        file: file ?? this.file,
        description: description ?? this.description,
        enabled: enabled ?? this.enabled,
      );
}

/// Project metadata for markdown generation.
class ProjectInfo {
  const ProjectInfo({
    required this.name,
    required this.description,
    this.version = '',
    this.toolCount = 0,
    this.promptCount = 0,
  });

  final String name;
  final String description;
  final String version;
  final int toolCount;
  final int promptCount;
}

/// Feature info for context markdown generation.
class FeatureInfo {
  const FeatureInfo({
    required this.id,
    required this.title,
    required this.status,
    this.kind = 'feature',
  });

  final String id;
  final String title;
  final String status;
  final String kind;
}

/// Note info for context markdown generation.
class NoteInfo {
  const NoteInfo({
    required this.id,
    required this.title,
    required this.summary,
  });

  final String id;
  final String title;
  final String summary;
}

// ── Generator service ───────────────────────────────────────────────────────

class WorkflowGenerator {
  const WorkflowGenerator();

  /// Generates a CLAUDE.md file from the given configuration.
  String generateClaudeMd({
    required List<SkillConfig> skills,
    required List<AgentConfig> agents,
    required List<HookConfig> hooks,
    required ProjectInfo project,
  }) {
    final buf = StringBuffer();

    buf.writeln('# CLAUDE.md');
    buf.writeln();
    buf.writeln(
        'This project uses [Orchestra MCP](https://github.com/orchestra-mcp/framework) for AI-powered project management.');
    buf.writeln();

    // Available tools.
    if (project.toolCount > 0 || project.promptCount > 0) {
      buf.writeln('## Available Tools');
      buf.writeln();
      buf.writeln(
          'Orchestra provides **${project.toolCount} tools** via MCP and **${project.promptCount} prompts**.');
      buf.writeln();
      buf.writeln(
          'Run `orchestra serve` to start the MCP server. IDE config is in `.mcp.json`.');
      buf.writeln();
    }

    // Skills.
    final enabledSkills = skills.where((s) => s.enabled).toList();
    if (enabledSkills.isNotEmpty) {
      buf.writeln('## Skills (Slash Commands)');
      buf.writeln();
      buf.writeln('| Command | Source |');
      buf.writeln('|---------|--------|');
      for (final skill in enabledSkills) {
        buf.writeln('| `/${skill.command}` | ${skill.path} |');
      }
      buf.writeln();
    }

    // Agents.
    final enabledAgents = agents.where((a) => a.enabled).toList();
    if (enabledAgents.isNotEmpty) {
      buf.writeln('## Agents');
      buf.writeln();
      buf.writeln(
          'Specialized agents in `.claude/agents/` auto-delegate based on task context.');
      buf.writeln();
      buf.writeln('| Agent | File |');
      buf.writeln('|-------|------|');
      for (final agent in enabledAgents) {
        buf.writeln('| `${agent.name}` | ${agent.file} |');
      }
      buf.writeln();
    }

    // Hooks.
    final enabledHooks = hooks.where((h) => h.enabled).toList();
    if (enabledHooks.isNotEmpty) {
      buf.writeln('## Hooks');
      buf.writeln();
      buf.writeln('| Hook | File |');
      buf.writeln('|------|------|');
      for (final hook in enabledHooks) {
        buf.writeln('| `${hook.name}` | ${hook.file} |');
      }
      buf.writeln();
    }

    return buf.toString();
  }

  /// Generates an AGENTS.md file describing agent capabilities.
  String generateAgentsMd({required List<AgentConfig> agents}) {
    final buf = StringBuffer();

    buf.writeln('# AGENTS.md');
    buf.writeln();
    buf.writeln('## Agent Registry');
    buf.writeln();
    buf.writeln(
        'This file documents the specialized agents available in this project.');
    buf.writeln();

    final enabledAgents = agents.where((a) => a.enabled).toList();
    if (enabledAgents.isEmpty) {
      buf.writeln('No agents configured.');
      return buf.toString();
    }

    buf.writeln('| Agent | File | Description |');
    buf.writeln('|-------|------|-------------|');
    for (final agent in enabledAgents) {
      final desc =
          agent.description.isNotEmpty ? agent.description : 'No description';
      buf.writeln('| `${agent.name}` | `${agent.file}` | $desc |');
    }
    buf.writeln();

    buf.writeln('## Usage');
    buf.writeln();
    buf.writeln(
        'Agents are automatically selected based on task context. Each agent has a dedicated markdown file in `.claude/agents/` that defines its system prompt, capabilities, and delegation rules.');
    buf.writeln();

    for (final agent in enabledAgents) {
      buf.writeln('### ${agent.name}');
      buf.writeln();
      buf.writeln('- **File**: `${agent.file}`');
      if (agent.description.isNotEmpty) {
        buf.writeln('- **Role**: ${agent.description}');
      }
      buf.writeln();
    }

    return buf.toString();
  }

  /// Generates a CONTEXT.md file with project state summary.
  String generateContextMd({
    required ProjectInfo project,
    required List<FeatureInfo> features,
    required List<NoteInfo> notes,
  }) {
    final buf = StringBuffer();

    buf.writeln('# Project Context');
    buf.writeln();
    buf.writeln('## ${project.name}');
    buf.writeln();
    buf.writeln(project.description);
    if (project.version.isNotEmpty) {
      buf.writeln();
      buf.writeln('**Version**: ${project.version}');
    }
    buf.writeln();

    // Features summary.
    if (features.isNotEmpty) {
      buf.writeln('## Active Features');
      buf.writeln();
      buf.writeln('| ID | Title | Status | Kind |');
      buf.writeln('|----|-------|--------|------|');
      for (final f in features) {
        buf.writeln('| ${f.id} | ${f.title} | ${f.status} | ${f.kind} |');
      }
      buf.writeln();

      // Status counts.
      final grouped = <String, int>{};
      for (final f in features) {
        grouped[f.status] = (grouped[f.status] ?? 0) + 1;
      }
      buf.writeln('### Status Summary');
      buf.writeln();
      for (final entry in grouped.entries) {
        buf.writeln('- **${entry.key}**: ${entry.value}');
      }
      buf.writeln();
    }

    // Notes.
    if (notes.isNotEmpty) {
      buf.writeln('## Notes');
      buf.writeln();
      for (final note in notes) {
        buf.writeln('### ${note.title}');
        buf.writeln();
        buf.writeln(note.summary);
        buf.writeln();
      }
    }

    return buf.toString();
  }
}
