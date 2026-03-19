import 'dart:io';

/// Scope classification for workspace items.
enum ItemScope {
  /// Item belongs to the current workspace.
  workspace,

  /// Item is global (shared across all workspaces).
  global,
}

/// Resolves whether an item is workspace-scoped or global.
///
/// Global items live in:
/// - `~/.orchestra/global/` (user-level global)
/// - `.projects/.global/` (workspace-level global section)
///
/// Only Notes, Skills, Agents, and Workflows can be global.
class ScopeResolver {
  ScopeResolver._();

  /// Real user home (handles macOS sandbox).
  static String get _realHome {
    final env = Platform.environment['HOME'] ?? '/tmp';
    final containerMatch =
        RegExp(r'^(/Users/[^/]+)/Library/Containers/.+/Data$');
    final match = containerMatch.firstMatch(env);
    if (match != null) return match.group(1)!;
    return env;
  }

  /// Global directory for user-level shared items.
  static String get globalDir => '${_realHome}/.orchestra/global';

  /// Checks if a note is global.
  ///
  /// A note is global if:
  /// - Its `project_id` is null/empty AND it's in `.projects/.global/notes/`
  /// - OR it's explicitly in the global directory
  static ItemScope resolveNote({String? projectId, String? sourceDir}) {
    if (projectId == null || projectId.isEmpty) {
      if (sourceDir != null && sourceDir.contains('.global')) {
        return ItemScope.global;
      }
      // Notes without a project are workspace-level but non-project-scoped
      return ItemScope.workspace;
    }
    if (projectId == '.global') return ItemScope.global;
    return ItemScope.workspace;
  }

  /// Checks if an agent file is global.
  ///
  /// Global agents also exist in `~/.orchestra/global/agents/`.
  static ItemScope resolveAgent(String slug) {
    final globalAgentFile = File('$globalDir/agents/$slug.md');
    if (globalAgentFile.existsSync()) return ItemScope.global;
    return ItemScope.workspace;
  }

  /// Checks if a skill directory is global.
  static ItemScope resolveSkill(String slug) {
    final globalSkillDir = Directory('$globalDir/skills/$slug');
    if (globalSkillDir.existsSync()) return ItemScope.global;
    return ItemScope.workspace;
  }

  /// Checks if a workflow is global.
  static ItemScope resolveWorkflow(String slug) {
    final globalWorkflowFile = File('$globalDir/workflows/$slug.md');
    if (globalWorkflowFile.existsSync()) return ItemScope.global;
    return ItemScope.workspace;
  }

  /// Returns scope label for display.
  static String label(ItemScope scope) {
    switch (scope) {
      case ItemScope.global:
        return 'Global';
      case ItemScope.workspace:
        return 'Workspace';
    }
  }
}
