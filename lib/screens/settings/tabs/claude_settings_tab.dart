import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/config/user_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Settings tab for managing `.claude/settings.json`.
///
/// On desktop: reads/writes the file directly.
/// On mobile: reads from `user_settings` table (key: `claude_settings_json`).
class ClaudeSettingsTab extends ConsumerStatefulWidget {
  const ClaudeSettingsTab({super.key});

  @override
  ConsumerState<ClaudeSettingsTab> createState() => _ClaudeSettingsTabState();
}

class _ClaudeSettingsTabState extends ConsumerState<ClaudeSettingsTab> {
  bool _loading = true;
  String? _error;
  String? _workspacePath;

  // Known settings fields.
  String _model = 'claude-sonnet-4-20250514';
  int _maxTurns = 10;
  bool _allowEdit = true;
  bool _allowBash = true;
  bool _allowRead = true;
  bool _allowWrite = true;
  bool _allowGlob = true;
  bool _allowGrep = true;
  bool _allowAgent = true;
  List<String> _allowedTools = [];

  // Raw JSON for unknown fields.
  Map<String, dynamic> _rawJson = {};

  static const _modelOptions = [
    'claude-opus-4-6',
    'claude-sonnet-4-6',
    'claude-sonnet-4-20250514',
    'claude-haiku-4-5-20251001',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      String? jsonStr;

      if (isDesktop && !kIsWeb) {
        _workspacePath = Platform.environment['ORCHESTRA_WORKSPACE'] ??
            Directory.current.path;
        final file = File('$_workspacePath/.claude/settings.json');
        if (file.existsSync()) {
          jsonStr = file.readAsStringSync();
        }
      } else {
        final settings = ref.read(userSettingsProvider.notifier);
        jsonStr = settings.get('claude_settings_json') as String?;
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        _rawJson = jsonDecode(jsonStr) as Map<String, dynamic>;
        _applyFromJson(_rawJson);
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() => _loading = false);
  }

  void _applyFromJson(Map<String, dynamic> json) {
    _model = json['model'] as String? ?? _model;
    _maxTurns = json['maxTurns'] as int? ?? _maxTurns;

    final permissions = json['permissions'] as Map<String, dynamic>? ?? {};
    _allowEdit = permissions['Edit'] as bool? ?? true;
    _allowBash = permissions['Bash'] as bool? ?? true;
    _allowRead = permissions['Read'] as bool? ?? true;
    _allowWrite = permissions['Write'] as bool? ?? true;
    _allowGlob = permissions['Glob'] as bool? ?? true;
    _allowGrep = permissions['Grep'] as bool? ?? true;
    _allowAgent = permissions['Agent'] as bool? ?? true;

    final tools = json['allowedTools'] as List<dynamic>?;
    if (tools != null) {
      _allowedTools = tools.map((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> _toJson() {
    final json = Map<String, dynamic>.from(_rawJson);
    json['model'] = _model;
    json['maxTurns'] = _maxTurns;
    json['permissions'] = {
      'Edit': _allowEdit,
      'Bash': _allowBash,
      'Read': _allowRead,
      'Write': _allowWrite,
      'Glob': _allowGlob,
      'Grep': _allowGrep,
      'Agent': _allowAgent,
    };
    if (_allowedTools.isNotEmpty) {
      json['allowedTools'] = _allowedTools;
    } else {
      json.remove('allowedTools');
    }
    return json;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    try {
      final json = _toJson();
      final encoded = const JsonEncoder.withIndent('  ').convert(json);

      if (isDesktop && !kIsWeb && _workspacePath != null) {
        final dir = Directory('$_workspacePath/.claude');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        File('${dir.path}/settings.json').writeAsStringSync('$encoded\n');
      }

      // Sync to user_settings for cross-device access.
      final settings = ref.read(userSettingsProvider.notifier);
      await settings.set('claude_settings_json', encoded);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.claudeSettingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
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
        child: Text(l10n.errorWithDetails(_error!), style: const TextStyle(color: Colors.redAccent)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ───────────────────────────────────────────────────
        Row(
          children: [
            Text(
              l10n.claudeSettingsTitle,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.save_rounded, color: tokens.accent),
              tooltip: l10n.save,
              onPressed: _save,
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: tokens.fgMuted),
              tooltip: l10n.reload,
              onPressed: _load,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Model ────────────────────────────────────────────────────
        _buildSection(tokens, l10n.claudeSettingsModel, [
          _buildDropdown(tokens, l10n.claudeSettingsDefaultModel, _model, _modelOptions,
              (v) => setState(() => _model = v!)),
        ]),
        const SizedBox(height: 16),

        // ── Max turns ────────────────────────────────────────────────
        _buildSection(tokens, l10n.claudeSettingsLimits, [
          _buildSlider(
            tokens,
            l10n.claudeSettingsMaxTurns,
            _maxTurns.toDouble(),
            1,
            50,
            (v) => setState(() => _maxTurns = v.round()),
          ),
        ]),
        const SizedBox(height: 16),

        // ── Permissions ──────────────────────────────────────────────
        _buildSection(tokens, l10n.claudeSettingsToolPermissions, [
          _buildToggle(tokens, 'Edit', _allowEdit,
              (v) => setState(() => _allowEdit = v)),
          _buildToggle(tokens, 'Bash', _allowBash,
              (v) => setState(() => _allowBash = v)),
          _buildToggle(tokens, 'Read', _allowRead,
              (v) => setState(() => _allowRead = v)),
          _buildToggle(tokens, 'Write', _allowWrite,
              (v) => setState(() => _allowWrite = v)),
          _buildToggle(tokens, 'Glob', _allowGlob,
              (v) => setState(() => _allowGlob = v)),
          _buildToggle(tokens, 'Grep', _allowGrep,
              (v) => setState(() => _allowGrep = v)),
          _buildToggle(tokens, 'Agent', _allowAgent,
              (v) => setState(() => _allowAgent = v)),
        ]),
        const SizedBox(height: 16),

        // ── Allowed tools list ───────────────────────────────────────
        _buildSection(tokens, l10n.claudeSettingsAllowedTools, [
          if (_allowedTools.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.claudeSettingsNoRestrictions,
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            )
          else
            ..._allowedTools.asMap().entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e.value,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, color: Colors.redAccent, size: 16),
                    onPressed: () {
                      setState(() => _allowedTools.removeAt(e.key));
                    },
                  ),
                )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.claudeSettingsAddTool),
              onPressed: _showAddToolDialog,
            ),
          ),
        ]),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSection(
      OrchestraColorTokens t, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: t.bgAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                color: t.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToggle(
      OrchestraColorTokens t, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      title: Text(label, style: TextStyle(color: t.fgBright, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: t.accent,
    );
  }

  Widget _buildDropdown(OrchestraColorTokens t, String label,
      String value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: t.fgBright, fontSize: 14)),
          const Spacer(),
          DropdownButton<String>(
            value: options.contains(value) ? value : options.first,
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            style: TextStyle(color: t.accent, fontSize: 13),
            dropdownColor: t.bgAlt,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(OrchestraColorTokens t, String label, double value,
      double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: t.fgBright, fontSize: 14)),
          const SizedBox(width: 12),
          Text('${value.round()}',
              style: TextStyle(color: t.accent, fontSize: 13)),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
              activeColor: t.accent,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToolDialog() {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.claudeSettingsAddToolTitle),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: l10n.claudeSettingsAddToolHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final tool = ctrl.text.trim();
              if (tool.isNotEmpty) {
                setState(() => _allowedTools.add(tool));
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
