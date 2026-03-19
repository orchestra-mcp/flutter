import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin GitHub tab — app ID, client ID, client secret, webhook secret, enabled toggle.
class AdminGithubTab extends ConsumerStatefulWidget {
  const AdminGithubTab({super.key});

  @override
  ConsumerState<AdminGithubTab> createState() => _AdminGithubTabState();
}

class _AdminGithubTabState extends ConsumerState<AdminGithubTab> {
  final _appIdCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  final _webhookSecretCtrl = TextEditingController();
  bool _enabled = false;
  bool _saving = false;
  bool _testing = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _appIdCtrl.text = data['app_id'] as String? ?? '';
    _clientIdCtrl.text = data['client_id'] as String? ?? '';
    _clientSecretCtrl.text = data['client_secret'] as String? ?? '';
    _webhookSecretCtrl.text = data['webhook_secret'] as String? ?? '';
    _enabled = data['enabled'] as bool? ?? false;
  }

  @override
  void dispose() {
    _appIdCtrl.dispose();
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _webhookSecretCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('github', {
        'app_id': _appIdCtrl.text,
        'client_id': _clientIdCtrl.text,
        'client_secret': _clientSecretCtrl.text,
        'webhook_secret': _webhookSecretCtrl.text,
        'enabled': _enabled,
      });
      ref.invalidate(adminSettingProvider('github'));
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

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('github', {
        'app_id': _appIdCtrl.text,
        'client_id': _clientIdCtrl.text,
        'client_secret': _clientSecretCtrl.text,
        'webhook_secret': _webhookSecretCtrl.text,
        'enabled': _enabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).connectionTestSuccessful,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).testFailed}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('github'));

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
            _sectionHeader(tokens, l10n.adminGithubIntegration),
            const SizedBox(height: 12),

            // Enable toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.code_rounded, color: tokens.fgMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.adminEnableGithub,
                      style: TextStyle(fontSize: 14, color: tokens.fgBright),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    activeThumbColor: tokens.accent,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App ID
            _fieldLabel(tokens, l10n.adminAppId),
            const SizedBox(height: 6),
            _field(tokens, _appIdCtrl, hint: l10n.adminAppIdHint),
            const SizedBox(height: 16),

            // Client ID
            _fieldLabel(tokens, l10n.adminClientId),
            const SizedBox(height: 6),
            _field(tokens, _clientIdCtrl, hint: 'Iv1.abc123...'),
            const SizedBox(height: 16),

            // Client Secret
            _fieldLabel(tokens, l10n.adminClientSecret),
            const SizedBox(height: 6),
            _field(
              tokens,
              _clientSecretCtrl,
              hint: l10n.adminClientSecretHint,
              obscure: true,
            ),
            const SizedBox(height: 16),

            // Webhook Secret
            _fieldLabel(tokens, l10n.adminWebhookSecret),
            const SizedBox(height: 6),
            _field(
              tokens,
              _webhookSecretCtrl,
              hint: l10n.adminWebhookSecretHint,
              obscure: true,
            ),

            const SizedBox(height: 24),

            // Test Connection
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.accent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _testing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.accent,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context).testConnection,
                        style: TextStyle(color: tokens.accent),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Save
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
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      obscureText: obscure,
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
