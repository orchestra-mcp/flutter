import 'dart:io';

import 'package:flutter/foundation.dart';

/// Scans the workspace `.projects/` directory for markdown entity files
/// and returns their parsed content.
///
/// This runs on app startup (desktop only) to ensure the UI reflects
/// changes made outside the app — e.g., by Claude Code, text editors,
/// or the `orchestra` CLI.
class WorkspaceScanner {
  WorkspaceScanner({required this.workspacePath});

  final String workspacePath;

  /// Scan all entity files and return them grouped by type.
  ///
  /// Returns a map: `{ 'features': [...], 'plans': [...], ... }`
  Future<Map<String, List<Map<String, dynamic>>>> scanAll() async {
    final results = <String, List<Map<String, dynamic>>>{};

    final projectsDir = Directory('$workspacePath/.projects');
    if (!projectsDir.existsSync()) {
      debugPrint('[WorkspaceScanner] .projects/ not found at $workspacePath');
      return results;
    }

    int totalFiles = 0;

    // Scan each project subdirectory.
    for (final projectDir in projectsDir.listSync().whereType<Directory>()) {
      final projectSlug = projectDir.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .last;

      // Skip hidden/meta directories.
      if (projectSlug.startsWith('.')) continue;

      // Scan entity subdirectories (features/, plans/, requests/, persons/).
      for (final entityType in ['features', 'plans', 'requests', 'persons']) {
        final entityDir = Directory('${projectDir.path}/$entityType');
        if (!entityDir.existsSync()) continue;

        results[entityType] ??= [];

        for (final file in entityDir.listSync().whereType<File>()) {
          if (!file.path.endsWith('.md')) continue;

          try {
            final content = file.readAsStringSync();
            final parsed = _parseMarkdownEntity(
              content,
              file.path,
              projectSlug,
              entityType,
            );
            if (parsed != null) {
              results[entityType]!.add(parsed);
              totalFiles++;
            }
          } catch (e) {
            debugPrint('[WorkspaceScanner] Failed to parse ${file.path}: $e');
          }
        }
      }
    }

    // Scan .claude/agents/ — flat .md files.
    _scanFlatMdDir('$workspacePath/.claude/agents', 'agents', results);

    // Scan .claude/skills/ — each skill is a subdirectory with SKILL.md.
    final skillsDir = Directory('$workspacePath/.claude/skills');
    if (skillsDir.existsSync()) {
      results['skills'] ??= [];
      for (final subdir in skillsDir.listSync().whereType<Directory>()) {
        final skillFile = File('${subdir.path}/SKILL.md');
        final slug = subdir.uri.pathSegments.where((s) => s.isNotEmpty).last;
        try {
          final content = skillFile.existsSync()
              ? skillFile.readAsStringSync()
              : '';
          results['skills']!.add({
            'name': slug.replaceAll('-', ' '),
            'slug': slug,
            'filename': 'SKILL.md',
            'path': subdir.path,
            'content': content,
            'updated_at':
                (skillFile.existsSync()
                        ? skillFile.lastModifiedSync()
                        : subdir.statSync().modified)
                    .toIso8601String(),
          });
          totalFiles++;
        } catch (e) {
          debugPrint('[WorkspaceScanner] Failed to read skill $slug: $e');
        }
      }
    }

    // Scan .claude/hooks/ — shell scripts.
    _scanFlatDir('$workspacePath/.claude/hooks', 'hooks', '.sh', results);

    // Scan docs/ — markdown documentation files.
    final docsDir = Directory('$workspacePath/docs');
    if (docsDir.existsSync()) {
      results['docs'] ??= [];
      for (final file in docsDir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.md')) continue;
        try {
          final relativePath = file.path.substring(docsDir.path.length + 1);
          final content = file.readAsStringSync();
          final basename = file.uri.pathSegments.last;
          results['docs']!.add({
            'name': basename.replaceAll('.md', '').replaceAll('-', ' '),
            'slug': basename.replaceAll('.md', ''),
            'filename': basename,
            'path': relativePath,
            'content': content,
            'updated_at': file.lastModifiedSync().toIso8601String(),
          });
          totalFiles++;
        } catch (e) {
          debugPrint('[WorkspaceScanner] Failed to read doc ${file.path}: $e');
        }
      }
    }

    // Scan root config files: CLAUDE.md, AGENTS.md, CONTEXT.md.
    results['config'] ??= [];
    for (final configFile in [
      MapEntry('CLAUDE.md', '$workspacePath/CLAUDE.md'),
      MapEntry('AGENTS.md', '$workspacePath/AGENTS.md'),
      MapEntry('CONTEXT.md', '$workspacePath/CONTEXT.md'),
      MapEntry('.claude/agents.md', '$workspacePath/.claude/agents.md'),
      MapEntry('.claude/context.md', '$workspacePath/.claude/context.md'),
      MapEntry('.claude/settings.json', '$workspacePath/.claude/settings.json'),
    ]) {
      final file = File(configFile.value);
      if (!file.existsSync()) continue;
      try {
        results['config']!.add({
          'name': configFile.key,
          'path': configFile.key,
          'content': file.readAsStringSync(),
          'updated_at': file.lastModifiedSync().toIso8601String(),
        });
        totalFiles++;
      } catch (e) {
        debugPrint('[WorkspaceScanner] Failed to read ${configFile.key}: $e');
      }
    }

    debugPrint(
      '[WorkspaceScanner] Scanned $totalFiles files across ${results.keys.length} entity types',
    );
    return results;
  }

  /// Scan a flat directory of .md files into results.
  void _scanFlatMdDir(
    String dirPath,
    String key,
    Map<String, List<Map<String, dynamic>>> results,
  ) {
    _scanFlatDir(dirPath, key, '.md', results);
  }

  /// Scan a flat directory of files with a given extension.
  void _scanFlatDir(
    String dirPath,
    String key,
    String ext,
    Map<String, List<Map<String, dynamic>>> results,
  ) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    results[key] ??= [];
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith(ext)) continue;
      try {
        final content = file.readAsStringSync();
        final basename = file.uri.pathSegments.last;
        final name = basename.replaceAll(ext, '').replaceAll('-', ' ');
        results[key]!.add({
          'name': name,
          'slug': basename.replaceAll(ext, ''),
          'filename': basename,
          'content': content,
          'updated_at': file.lastModifiedSync().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[WorkspaceScanner] Failed to read ${file.path}: $e');
      }
    }
  }

  /// Parse a markdown entity file with YAML frontmatter.
  ///
  /// Expected format:
  /// ```
  /// ---
  /// title: Feature Title
  /// status: in-progress
  /// ...
  /// ---
  /// Body content here
  /// ```
  Map<String, dynamic>? _parseMarkdownEntity(
    String content,
    String filePath,
    String projectSlug,
    String entityType,
  ) {
    final basename = File(filePath).uri.pathSegments.last;
    final id = basename.replaceAll('.md', '');

    // Split frontmatter from body.
    if (!content.startsWith('---')) {
      return {'id': id, 'project_slug': projectSlug, 'body': content};
    }

    final endIndex = content.indexOf('---', 3);
    if (endIndex == -1) {
      return {'id': id, 'project_slug': projectSlug, 'body': content};
    }

    final frontmatter = content.substring(3, endIndex).trim();
    final body = content.substring(endIndex + 3).trim();

    // Parse YAML frontmatter as simple key: value pairs.
    final data = <String, dynamic>{
      'id': id,
      'project_slug': projectSlug,
      'body': body,
    };

    for (final line in frontmatter.split('\n')) {
      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;

      final key = line.substring(0, colonIndex).trim();
      var value = line.substring(colonIndex + 1).trim();

      // Strip surrounding quotes.
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }

      // Map common frontmatter keys.
      switch (key) {
        case 'title':
        case 'status':
        case 'priority':
        case 'kind':
        case 'assignee':
        case 'estimate':
        case 'description':
        case 'name':
        case 'email':
        case 'role':
          data[key] = value;
        case 'labels':
          data[key] = value
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        case 'version':
          data[key] = int.tryParse(value) ?? 1;
        case 'created_at':
        case 'updated_at':
          data[key] = value;
      }
    }

    // Default timestamps from file metadata.
    final fileStat = File(filePath).statSync();
    data['updated_at'] ??= fileStat.modified.toIso8601String();
    data['created_at'] ??= fileStat.modified.toIso8601String();

    return data;
  }
}
