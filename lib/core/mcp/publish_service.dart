import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/mcp/scope_resolver.dart';
import 'package:orchestra/core/storage/local_database.dart';

/// Publish status for an item.
enum PublishStatus {
  /// Never published — local only.
  unpublished,

  /// Published and up-to-date with backend.
  published,

  /// Local changes since last publish.
  modified,
}

/// Manual per-item publish service.
///
/// Items are created/edited locally first. The user explicitly triggers
/// publish to push to the backend. No auto-sync.
class PublishService {
  PublishService({
    required this.client,
    required this.db,
    required this.workspacePath,
  });

  final ApiClient client;
  final LocalDatabase db;
  final String workspacePath;

  // ── Notes ────────────────────────────────────────────────────────────

  Future<bool> publishNote(String id) async {
    try {
      final notes = await (db.select(db.localNotes)
            ..where((n) => n.id.equals(id)))
          .get();
      if (notes.isEmpty) return false;
      final note = notes.first;

      await client.createNote({
        'id': note.id,
        'title': note.title,
        'content': note.content,
        if (note.projectId != null) 'project_id': note.projectId,
        'is_pinned': note.pinned,
        'tags': note.tags,
      });

      // Mark as synced
      await (db.update(db.localNotes)..where((n) => n.id.equals(id)))
          .write(const LocalNotesCompanion(synced: Value(true)));

      debugPrint('[Publish] Note $id published');
      return true;
    } catch (e) {
      debugPrint('[Publish] Note $id failed: $e');
      return false;
    }
  }

  // ── Agents ───────────────────────────────────────────────────────────

  Future<bool> publishAgent(String id) async {
    try {
      final agents = await (db.select(db.localAgents)
            ..where((a) => a.id.equals(id)))
          .get();
      if (agents.isEmpty) return false;
      final agent = agents.first;

      await client.callTool('create_agent', {
        'id': agent.id,
        'name': agent.name,
        if (agent.description != null) 'description': agent.description,
        'provider': agent.provider,
        'model': agent.model,
        if (agent.systemPrompt != null) 'system_prompt': agent.systemPrompt,
        'tools': agent.tools,
      });

      await (db.update(db.localAgents)..where((a) => a.id.equals(id)))
          .write(const LocalAgentsCompanion(synced: Value(true)));

      debugPrint('[Publish] Agent $id published');
      return true;
    } catch (e) {
      debugPrint('[Publish] Agent $id failed: $e');
      return false;
    }
  }

  // ── Skills ───────────────────────────────────────────────────────────

  Future<bool> publishSkill(String id) async {
    try {
      final skills = await (db.select(db.localSkills)
            ..where((s) => s.id.equals(id)))
          .get();
      if (skills.isEmpty) return false;
      final skill = skills.first;

      await client.callTool('create_skill', {
        'id': skill.id,
        'name': skill.name,
        'command': skill.command,
        if (skill.description != null) 'description': skill.description,
        if (skill.source != null) 'source': skill.source,
      });

      await (db.update(db.localSkills)..where((s) => s.id.equals(id)))
          .write(const LocalSkillsCompanion(synced: Value(true)));

      debugPrint('[Publish] Skill $id published');
      return true;
    } catch (e) {
      debugPrint('[Publish] Skill $id failed: $e');
      return false;
    }
  }

  // ── Workflows ────────────────────────────────────────────────────────

  Future<bool> publishWorkflow(String id) async {
    try {
      final workflows = await (db.select(db.localWorkflows)
            ..where((w) => w.id.equals(id)))
          .get();
      if (workflows.isEmpty) return false;
      final workflow = workflows.first;

      await client.callTool('define_workflow', {
        'id': workflow.id,
        'name': workflow.name,
        if (workflow.description != null) 'description': workflow.description,
        'steps': workflow.steps,
        'status': workflow.status,
      });

      await (db.update(db.localWorkflows)..where((w) => w.id.equals(id)))
          .write(const LocalWorkflowsCompanion(synced: Value(true)));

      debugPrint('[Publish] Workflow $id published');
      return true;
    } catch (e) {
      debugPrint('[Publish] Workflow $id failed: $e');
      return false;
    }
  }

  // ── Export global to workspace ────────────────────────────────────────

  /// Copies a global item into the current workspace.
  Future<bool> exportGlobalToWorkspace({
    required String type,
    required String slug,
  }) async {
    final globalDir = ScopeResolver.globalDir;

    try {
      switch (type) {
        case 'agent':
          final src = File('$globalDir/agents/$slug.md');
          final dst = File('$workspacePath/.claude/agents/$slug.md');
          if (src.existsSync()) {
            await dst.parent.create(recursive: true);
            await src.copy(dst.path);
            return true;
          }
        case 'skill':
          final srcDir = Directory('$globalDir/skills/$slug');
          final dstDir = Directory('$workspacePath/.claude/skills/$slug');
          if (srcDir.existsSync()) {
            await dstDir.create(recursive: true);
            await for (final entity in srcDir.list(recursive: true)) {
              if (entity is File) {
                final relative = entity.path.substring(srcDir.path.length);
                final dstFile = File('${dstDir.path}$relative');
                await dstFile.parent.create(recursive: true);
                await entity.copy(dstFile.path);
              }
            }
            return true;
          }
        case 'workflow':
          final src = File('$globalDir/workflows/$slug.md');
          final dst = File('$workspacePath/.orchestra/workflows/$slug.md');
          if (src.existsSync()) {
            await dst.parent.create(recursive: true);
            await src.copy(dst.path);
            return true;
          }
      }
    } catch (e) {
      debugPrint('[Export] Failed to export $type/$slug: $e');
    }
    return false;
  }
}
