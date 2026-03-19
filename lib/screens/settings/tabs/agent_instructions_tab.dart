import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/config/user_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// A parsed section from a markdown file (## Header + body content).
class _Section {
  _Section({required this.header, required this.body});
  String header;
  String body;
}

/// Represents one of the managed agent instruction files.
class _ManagedFile {
  const _ManagedFile({
    required this.label,
    required this.icon,
    required this.filename,
    required this.settingsKey,
    this.subdirectory,
  });

  final String label;
  final IconData icon;

  /// Filename relative to workspace root (e.g. 'CLAUDE.md') or
  /// relative to [subdirectory] (e.g. 'agents.md' inside '.claude/').
  final String filename;

  /// Key used to store content in user_settings for mobile access.
  final String settingsKey;

  /// Optional subdirectory inside workspace (e.g. '.claude').
  final String? subdirectory;

  String filePath(String workspace) {
    if (subdirectory != null) {
      return '$workspace/$subdirectory/$filename';
    }
    return '$workspace/$filename';
  }
}

const _managedFiles = [
  _ManagedFile(
    label: 'CLAUDE.md',
    icon: Icons.smart_toy_outlined,
    filename: 'CLAUDE.md',
    settingsKey: 'claude_md_sections',
  ),
  _ManagedFile(
    label: 'Agents',
    icon: Icons.group_outlined,
    filename: 'agents.md',
    settingsKey: 'agents_md_sections',
    subdirectory: '.claude',
  ),
  _ManagedFile(
    label: 'Context',
    icon: Icons.description_outlined,
    filename: 'context.md',
    settingsKey: 'context_md_sections',
    subdirectory: '.claude',
  ),
];

String _resolveFileLabel(AppLocalizations l10n, String label) => switch (label) {
  'Agents' => l10n.agentInstructionsAgents,
  'Context' => l10n.agentInstructionsContext,
  _ => label,
};

/// Settings tab for editing agent instruction files as structured entries.
///
/// Manages three files: CLAUDE.md, .claude/agents.md, .claude/context.md.
/// On desktop: reads/writes files directly from the workspace.
/// On mobile: reads from `user_settings` PowerSync table.
class AgentInstructionsTab extends ConsumerStatefulWidget {
  const AgentInstructionsTab({super.key});

  @override
  ConsumerState<AgentInstructionsTab> createState() =>
      _AgentInstructionsTabState();
}

class _AgentInstructionsTabState extends ConsumerState<AgentInstructionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, List<_Section>> _fileSections = {};
  bool _loading = true;
  String? _error;
  String? _workspacePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _managedFiles.length, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      if (isDesktop && !kIsWeb) {
        _workspacePath = Platform.environment['ORCHESTRA_WORKSPACE'] ??
            Directory.current.path;
      }

      for (int i = 0; i < _managedFiles.length; i++) {
        _fileSections[i] = await _loadFile(_managedFiles[i]);
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() => _loading = false);
  }

  Future<List<_Section>> _loadFile(_ManagedFile mf) async {
    if (isDesktop && !kIsWeb && _workspacePath != null) {
      final file = File(mf.filePath(_workspacePath!));
      if (file.existsSync()) {
        return _parseSections(file.readAsStringSync());
      }
      return [];
    } else {
      // Mobile: read from user_settings.
      final settings = ref.read(userSettingsProvider.notifier);
      final content = settings.get(mf.settingsKey) as String?;
      if (content != null) {
        return _parseSections(content);
      }
      return [];
    }
  }

  List<_Section> _parseSections(String content) {
    final sections = <_Section>[];
    final lines = content.split('\n');
    String currentHeader = '';
    final bodyLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        if (currentHeader.isNotEmpty || bodyLines.isNotEmpty) {
          sections.add(_Section(
            header: currentHeader.isEmpty ? 'Introduction' : currentHeader,
            body: bodyLines.join('\n').trim(),
          ));
        }
        currentHeader = line.substring(3).trim();
        bodyLines.clear();
      } else {
        bodyLines.add(line);
      }
    }

    if (currentHeader.isNotEmpty || bodyLines.isNotEmpty) {
      sections.add(_Section(
        header: currentHeader.isEmpty ? 'Introduction' : currentHeader,
        body: bodyLines.join('\n').trim(),
      ));
    }

    return sections;
  }

  String _reconstructMarkdown(List<_Section> sections) {
    final buffer = StringBuffer();
    for (int i = 0; i < sections.length; i++) {
      final s = sections[i];
      if (i == 0 && s.header == 'Introduction') {
        buffer.writeln(s.body);
      } else {
        buffer.writeln('## ${s.header}');
        buffer.writeln();
        buffer.writeln(s.body);
      }
      buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> _saveCurrentFile() async {
    final idx = _tabController.index;
    final mf = _managedFiles[idx];
    final sections = _fileSections[idx] ?? [];

    try {
      final content = _reconstructMarkdown(sections);

      if (isDesktop && !kIsWeb && _workspacePath != null) {
        final file = File(mf.filePath(_workspacePath!));
        // Ensure parent directory exists.
        final dir = file.parent;
        if (!dir.existsSync()) dir.createSync(recursive: true);
        file.writeAsStringSync(content);
      }

      // Push to user_settings for mobile access.
      final settings = ref.read(userSettingsProvider.notifier);
      await settings.set(mf.settingsKey, content);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.agentInstructionsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToSave}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Text(l10n.errorWithDetails(_error!),
            style: const TextStyle(color: Colors.redAccent)),
      );
    }

    return Column(
      children: [
        // ── Tab bar for file selection ────────────────────────────────
        Container(
          color: tokens.bgAlt,
          child: TabBar(
            controller: _tabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgMuted,
            indicatorColor: tokens.accent,
            tabs: _managedFiles
                .map((mf) => Tab(icon: Icon(mf.icon, size: 18), text: _resolveFileLabel(l10n, mf.label)))
                .toList(),
          ),
        ),

        // ── Toolbar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text(
                l10n.agentInstructionsTitle,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add_rounded, color: tokens.accent, size: 20),
                tooltip: l10n.agentInstructionsAddSection,
                onPressed: () {
                  final idx = _tabController.index;
                  setState(() {
                    _fileSections[idx] ??= [];
                    _fileSections[idx]!
                        .add(_Section(header: l10n.agentInstructionsNewSection, body: ''));
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.save_rounded, color: tokens.accent, size: 20),
                tooltip: l10n.save,
                onPressed: _saveCurrentFile,
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: tokens.fgMuted, size: 20),
                tooltip: l10n.reload,
                onPressed: _loadAll,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Sections list per tab ────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(_managedFiles.length, (idx) {
              final sections = _fileSections[idx] ?? [];
              if (sections.isEmpty) {
                return Center(
                  child: Text(
                    l10n.agentInstructionsEmpty,
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sections.length,
                itemBuilder: (context, i) => _SectionCard(
                  section: sections[i],
                  tokens: tokens,
                  onDelete: () {
                    setState(() => sections.removeAt(i));
                  },
                  onChanged: () => setState(() {}),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.section,
    required this.tokens,
    required this.onDelete,
    required this.onChanged,
  });

  final _Section section;
  final OrchestraColorTokens tokens;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;
  late TextEditingController _headerCtrl;
  late TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = TextEditingController(text: widget.section.header);
    _bodyCtrl = TextEditingController(text: widget.section.body);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final l10n = AppLocalizations.of(context);

    return Card(
      color: t.bgAlt,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          // ── Header row (tap to expand) ───────────────────────────
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: t.fgMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.section.header,
                      style: TextStyle(
                        color: t.fgBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable editor ────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: t.borderFaint),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _headerCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.agentInstructionsSectionTitle,
                      labelStyle: TextStyle(color: t.fgMuted, fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(color: t.fgBright, fontSize: 14),
                    onChanged: (v) {
                      widget.section.header = v;
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bodyCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.agentInstructionsContent,
                      labelStyle: TextStyle(color: t.fgMuted, fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      color: t.fgBright,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 12,
                    minLines: 4,
                    onChanged: (v) {
                      widget.section.body = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
