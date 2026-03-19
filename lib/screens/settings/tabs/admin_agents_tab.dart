import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin agents tab — default AI model, system prompt, max tokens, temperature.
class AdminAgentsTab extends ConsumerStatefulWidget {
  const AdminAgentsTab({super.key});

  @override
  ConsumerState<AdminAgentsTab> createState() => _AdminAgentsTabState();
}

class _AdminAgentsTabState extends ConsumerState<AdminAgentsTab> {
  String _selectedModel = 'claude-opus-4-6';
  final _systemPromptCtrl = TextEditingController();
  final _maxTokensCtrl = TextEditingController();
  double _temperature = 0.7;
  bool _saving = false;
  bool _initialized = false;

  static const _models = [
    'claude-opus-4-6',
    'claude-sonnet-4',
    'gpt-4o',
    'gemini-2.0-flash',
    'llama-3.3-70b',
    'deepseek-v3',
  ];

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _selectedModel = data['default_model'] as String? ?? 'claude-opus-4-6';
    if (!_models.contains(_selectedModel)) _selectedModel = _models.first;
    _maxTokensCtrl.text = (data['max_tokens']?.toString()) ?? '4096';
    _temperature = (data['temperature'] as num?)?.toDouble() ?? 0.7;
    _systemPromptCtrl.text = data['system_prompt'] as String? ?? '';
  }

  @override
  void dispose() {
    _systemPromptCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('agents', {
        'default_model': _selectedModel,
        'max_tokens': int.tryParse(_maxTokensCtrl.text) ?? 4096,
        'temperature': _temperature,
        'system_prompt': _systemPromptCtrl.text,
      });
      ref.invalidate(adminSettingProvider('agents'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
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

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('agents'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context).failedToLoad}: $e'),
      ),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminAiConfig),
            const SizedBox(height: 12),

            // Default Model
            _fieldLabel(tokens, l10n.adminDefaultModel),
            const SizedBox(height: 6),
            _buildDropdown(tokens),
            const SizedBox(height: 16),

            // System Prompt
            _fieldLabel(tokens, l10n.adminSystemPrompt),
            const SizedBox(height: 6),
            _field(
              tokens,
              _systemPromptCtrl,
              hint: l10n.adminSystemPromptHint,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Max Tokens
            _fieldLabel(tokens, l10n.adminMaxTokens),
            const SizedBox(height: 6),
            _field(tokens, _maxTokensCtrl, hint: '4096'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Temperature
            _fieldLabel(tokens, l10n.adminTemperature),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _temperature,
                    min: 0.0,
                    max: 2.0,
                    divisions: 20,
                    activeColor: tokens.accent,
                    inactiveColor: tokens.border,
                    onChanged: (v) => setState(() => _temperature = v),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Text(
                    _temperature.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.fgBright,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
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

  Widget _buildDropdown(OrchestraColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModel,
          isExpanded: true,
          dropdownColor: tokens.bgAlt,
          style: TextStyle(fontSize: 14, color: tokens.fgBright),
          icon: Icon(
            Icons.expand_more_rounded,
            color: tokens.fgMuted,
            size: 20,
          ),
          items: _models
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedModel = v);
          },
        ),
      ),
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

  Widget _fieldLabel(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.fgDim,
      letterSpacing: 0.4,
    ),
  );

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
