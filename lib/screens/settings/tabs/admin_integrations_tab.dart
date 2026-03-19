import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Integration definition for UI rendering.
class _IntegrationDef {
  _IntegrationDef({
    required this.key,
    required this.name,
    required this.icon,
    required this.callbackUrl,
  });

  final String key;
  final String name;
  final IconData icon;
  final String callbackUrl;
}

/// Admin integrations tab — OAuth providers (Google, GitHub, Discord, Slack).
class AdminIntegrationsTab extends ConsumerStatefulWidget {
  const AdminIntegrationsTab({super.key});

  @override
  ConsumerState<AdminIntegrationsTab> createState() =>
      _AdminIntegrationsTabState();
}

class _AdminIntegrationsTabState extends ConsumerState<AdminIntegrationsTab> {
  static final _definitions = [
    _IntegrationDef(key: 'github', name: 'GitHub', icon: Icons.code_rounded, callbackUrl: 'https://orchestra.dev/auth/callback/github'),
    _IntegrationDef(key: 'slack', name: 'Slack', icon: Icons.tag_rounded, callbackUrl: 'https://orchestra.dev/auth/callback/slack'),
    _IntegrationDef(key: 'discord', name: 'Discord', icon: Icons.discord_rounded, callbackUrl: 'https://orchestra.dev/auth/callback/discord'),
    _IntegrationDef(key: 'figma', name: 'Figma', icon: Icons.draw_rounded, callbackUrl: 'https://orchestra.dev/auth/callback/figma'),
    _IntegrationDef(key: 'sentry', name: 'Sentry', icon: Icons.bug_report_rounded, callbackUrl: 'https://orchestra.dev/auth/callback/sentry'),
  ];

  final Map<String, bool> _enabled = {};
  final Map<String, TextEditingController> _clientIdCtrls = {};
  final Map<String, TextEditingController> _clientSecretCtrls = {};
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    for (final def in _definitions) {
      final section = data[def.key] as Map<String, dynamic>? ?? {};
      _enabled[def.key] = section['enabled'] as bool? ?? false;
      _clientIdCtrls[def.key] = TextEditingController(
          text: section['client_id'] as String? ?? '');
      _clientSecretCtrls[def.key] = TextEditingController(
          text: section['client_secret'] as String? ?? '');
    }
  }

  @override
  void dispose() {
    for (final ctrl in _clientIdCtrls.values) {
      ctrl.dispose();
    }
    for (final ctrl in _clientSecretCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      for (final def in _definitions) {
        payload[def.key] = {
          'enabled': _enabled[def.key] ?? false,
          'client_id': _clientIdCtrls[def.key]?.text ?? '',
          'client_secret': _clientSecretCtrls[def.key]?.text ?? '',
        };
      }
      await ref.read(apiClientProvider).updateAdminSetting('integrations', payload);
      ref.invalidate(adminSettingProvider('integrations'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSave}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('integrations'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminOauthProviders),
            const SizedBox(height: 4),
            Text(
              l10n.adminOauthProvidersDesc,
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < _definitions.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildProviderCard(tokens, _definitions[i]),
            ],
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
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProviderCard(OrchestraColorTokens tokens, _IntegrationDef def) {
    final l10n = AppLocalizations.of(context);
    final isEnabled = _enabled[def.key] ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? tokens.accent : tokens.border,
          width: isEnabled ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(def.icon, size: 18, color: tokens.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  def.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.fgBright,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: tokens.accent,
                onChanged: (v) =>
                    setState(() => _enabled[def.key] = v),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Client ID
          _fieldLabel(tokens, l10n.adminClientId),
          const SizedBox(height: 6),
          _inlineField(tokens,
              ctrl: _clientIdCtrls[def.key]!,
              hint: l10n.adminEnterClientId),
          const SizedBox(height: 12),

          // Client Secret
          _fieldLabel(tokens, l10n.adminClientSecret),
          const SizedBox(height: 6),
          _inlineField(tokens,
              ctrl: _clientSecretCtrls[def.key]!,
              hint: l10n.adminEnterClientSecret,
              obscure: true),
          const SizedBox(height: 12),

          // Callback URL (read-only)
          _fieldLabel(tokens, l10n.adminCallbackUrl),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border),
            ),
            child: SelectableText(
              def.callbackUrl,
              style: TextStyle(
                  fontSize: 13, color: tokens.fgDim, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineField(
    OrchestraColorTokens tokens, {
    required TextEditingController ctrl,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}
