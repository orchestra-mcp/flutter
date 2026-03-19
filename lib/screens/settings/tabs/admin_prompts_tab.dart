import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin prompts tab — manage smart action system prompts for each entity type.
class AdminPromptsTab extends ConsumerStatefulWidget {
  const AdminPromptsTab({super.key});

  @override
  ConsumerState<AdminPromptsTab> createState() => _AdminPromptsTabState();
}

class _AdminPromptsTabState extends ConsumerState<AdminPromptsTab> {
  List<_PromptEntry> _prompts = [];
  bool _saving = false;
  bool _initialized = false;
  int? _expandedIndex;

  void _populatePrompts(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    // API returns {"key": "smart_prompts", "value": {"prompts": [...]}}
    final value = data['value'];
    final raw = value is Map ? value['prompts'] : data['prompts'];
    if (raw is List) {
      _prompts = raw.map((e) {
        final m = e as Map<String, dynamic>;
        return _PromptEntry(
          key: m['key'] as String? ?? '',
          label: m['label'] as String? ?? '',
          description: m['description'] as String? ?? '',
          promptCtrl: TextEditingController(text: m['prompt'] as String? ?? ''),
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    for (final p in _prompts) {
      p.promptCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final promptsData = _prompts
          .map(
            (p) => {
              'key': p.key,
              'label': p.label,
              'description': p.description,
              'prompt': p.promptCtrl.text,
            },
          )
          .toList();

      await ref.read(apiClientProvider).updateAdminSetting('smart_prompts', {
        'prompts': promptsData,
      });
      ref.invalidate(adminSettingProvider('smart_prompts'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).promptsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToSave}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addPrompt() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _prompts.add(
        _PromptEntry(
          key: 'new_prompt_${_prompts.length}',
          label: l10n.adminNewPrompt,
          description: '',
          promptCtrl: TextEditingController(),
        ),
      );
      _expandedIndex = _prompts.length - 1;
    });
  }

  void _removePrompt(int index) {
    setState(() {
      _prompts[index].promptCtrl.dispose();
      _prompts.removeAt(index);
      _expandedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('smart_prompts'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context).failedToLoad}: $e'),
      ),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populatePrompts(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminSmartActionPrompts),
            const SizedBox(height: 4),
            Text(
              l10n.adminPromptsDesc,
              style: TextStyle(fontSize: 12, color: tokens.fgDim),
            ),
            const SizedBox(height: 16),

            // Prompt cards
            for (var i = 0; i < _prompts.length; i++) ...[
              _PromptCard(
                tokens: tokens,
                entry: _prompts[i],
                expanded: _expandedIndex == i,
                onToggle: () {
                  setState(() {
                    _expandedIndex = _expandedIndex == i ? null : i;
                  });
                },
                onRemove: () => _removePrompt(i),
                onKeyChanged: (v) => setState(() => _prompts[i].key = v),
                onLabelChanged: (v) => setState(() => _prompts[i].label = v),
                onDescChanged: (v) =>
                    setState(() => _prompts[i].description = v),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 12),

            // Add button
            OutlinedButton.icon(
              onPressed: _addPrompt,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppLocalizations.of(context).addPrompt),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.accent,
                side: BorderSide(color: tokens.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );
}

class _PromptEntry {
  _PromptEntry({
    required this.key,
    required this.label,
    required this.description,
    required this.promptCtrl,
  });

  String key;
  String label;
  String description;
  final TextEditingController promptCtrl;
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.tokens,
    required this.entry,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
    required this.onKeyChanged,
    required this.onLabelChanged,
    required this.onDescChanged,
  });

  final OrchestraColorTokens tokens;
  final _PromptEntry entry;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<String> onDescChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: expanded ? tokens.accent : tokens.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(top: const Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: tokens.fgMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.accent,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.fgBright,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: tokens.fgDim,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (expanded) ...[
            Divider(height: 1, color: tokens.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key
                  _label(tokens, l10n.adminPromptKey),
                  const SizedBox(height: 6),
                  _textField(
                    tokens,
                    entry.key,
                    onKeyChanged,
                    hint: l10n.adminPromptKeyHint,
                  ),
                  const SizedBox(height: 14),

                  // Label
                  _label(tokens, l10n.adminPromptLabel),
                  const SizedBox(height: 6),
                  _textField(
                    tokens,
                    entry.label,
                    onLabelChanged,
                    hint: l10n.adminPromptLabelHint,
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _label(tokens, l10n.adminPromptDescription),
                  const SizedBox(height: 6),
                  _textField(
                    tokens,
                    entry.description,
                    onDescChanged,
                    hint: l10n.adminPromptDescHint,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),

                  // Prompt
                  _label(tokens, l10n.adminPromptSystemPrompt),
                  const SizedBox(height: 6),
                  TextField(
                    controller: entry.promptCtrl,
                    maxLines: 10,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.adminPromptSystemPromptHint,
                      hintStyle: TextStyle(color: tokens.fgDim),
                      filled: true,
                      fillColor: tokens.bg,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.fgDim,
      letterSpacing: 0.4,
    ),
  );

  Widget _textField(
    OrchestraColorTokens tokens,
    String value,
    ValueChanged<String> onChanged, {
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: maxLines,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
