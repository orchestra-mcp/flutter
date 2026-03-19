import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

/// Desktop-only service that writes synced agents/skills to disk.
///
/// After PowerSync pulls agent/skill rows from PostgreSQL, this service
/// ensures the corresponding `.claude/agents/*.md` and
/// `.claude/skills/*/SKILL.md` files exist on the local filesystem so the
/// MCP CLI can discover them.
class FileSyncService {
  FileSyncService(this._db, this._workspacePath);

  final PowerSyncDatabase _db;

  /// Root path of the current workspace (e.g. `/Users/me/Sites/my-project`).
  final String _workspacePath;

  /// Sync all agents and skills from PowerSync to disk.
  /// Call after initial sync completes or when workspace changes.
  Future<void> syncAll() async {
    if (kIsWeb) return; // No filesystem on web.
    await Future.wait([_syncAgents(), _syncSkills()]);
  }

  /// Write each agent row to `.claude/agents/{slug}.md`.
  Future<void> _syncAgents() async {
    try {
      final rows = await _db.getAll(
        'SELECT slug, name, description, content, version FROM agents',
      );

      final agentsDir = Directory('$_workspacePath/.claude/agents');
      if (!agentsDir.existsSync()) {
        agentsDir.createSync(recursive: true);
      }

      for (final row in rows) {
        final slug = row['slug'] as String?;
        final content = row['content'] as String?;
        if (slug == null || slug.isEmpty || content == null) continue;

        final file = File('${agentsDir.path}/$slug.md');

        // Skip if local file is newer (user may have edited directly).
        if (file.existsSync()) {
          final dbVersion = row['version'] as int? ?? 0;
          final localMod = file.lastModifiedSync();
          // Simple heuristic: if file was modified in the last 5 seconds,
          // the user likely just edited it — don't overwrite.
          if (DateTime.now().difference(localMod).inSeconds < 5) continue;
          // If we have a version, check comment in file header.
          if (dbVersion > 0 && _fileHasVersion(file, dbVersion)) continue;
        }

        final name = row['name'] as String? ?? slug;
        final description = row['description'] as String? ?? '';
        final version = row['version'] as int? ?? 1;

        final md = StringBuffer();
        md.writeln('---');
        md.writeln('name: $name');
        md.writeln('description: $description');
        md.writeln('version: $version');
        md.writeln('---');
        md.writeln();
        md.write(content);

        file.writeAsStringSync(md.toString());
        debugPrint('[FileSync] Wrote agent: $slug.md (v$version)');
      }
    } catch (e) {
      debugPrint('[FileSync] Failed to sync agents: $e');
    }
  }

  /// Write each skill row to `.claude/skills/{slug}/SKILL.md`.
  Future<void> _syncSkills() async {
    try {
      final rows = await _db.getAll(
        'SELECT slug, name, description, content, version FROM skills',
      );

      final skillsDir = Directory('$_workspacePath/.claude/skills');
      if (!skillsDir.existsSync()) {
        skillsDir.createSync(recursive: true);
      }

      for (final row in rows) {
        final slug = row['slug'] as String?;
        final content = row['content'] as String?;
        if (slug == null || slug.isEmpty || content == null) continue;

        final skillDir = Directory('${skillsDir.path}/$slug');
        if (!skillDir.existsSync()) {
          skillDir.createSync(recursive: true);
        }

        final file = File('${skillDir.path}/SKILL.md');

        if (file.existsSync()) {
          final dbVersion = row['version'] as int? ?? 0;
          final localMod = file.lastModifiedSync();
          if (DateTime.now().difference(localMod).inSeconds < 5) continue;
          if (dbVersion > 0 && _fileHasVersion(file, dbVersion)) continue;
        }

        final name = row['name'] as String? ?? slug;
        final description = row['description'] as String? ?? '';
        final version = row['version'] as int? ?? 1;

        final md = StringBuffer();
        md.writeln('---');
        md.writeln('name: $name');
        md.writeln('description: $description');
        md.writeln('version: $version');
        md.writeln('---');
        md.writeln();
        md.write(content);

        file.writeAsStringSync(md.toString());
        debugPrint('[FileSync] Wrote skill: $slug/SKILL.md (v$version)');
      }
    } catch (e) {
      debugPrint('[FileSync] Failed to sync skills: $e');
    }
  }

  /// Check if a file already has a frontmatter `version:` matching the given version.
  bool _fileHasVersion(File file, int version) {
    try {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('version:')) {
          final fileVersion = int.tryParse(line.split(':').last.trim());
          return fileVersion == version;
        }
        // Stop scanning after frontmatter ends.
        if (line == '---' && lines.indexOf(line) > 0) break;
      }
    } catch (_) {}
    return false;
  }
}
