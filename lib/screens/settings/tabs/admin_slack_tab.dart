import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin Slack tab — bot token, signing secret, channel ID, webhook URL, test.
class AdminSlackTab extends ConsumerStatefulWidget {
  const AdminSlackTab({super.key});

  @override
  ConsumerState<AdminSlackTab> createState() => _AdminSlackTabState();
}

class _AdminSlackTabState extends ConsumerState<AdminSlackTab> {
  final _botTokenCtrl = TextEditingController();
  final _signingSecretCtrl = TextEditingController();
  final _channelIdCtrl = TextEditingController();
  final _webhookUrlCtrl = TextEditingController();
  bool _enabled = false;
  bool _saving = false;
  bool _testing = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _botTokenCtrl.text = data['bot_token'] as String? ?? '';
    _signingSecretCtrl.text = data['signing_secret'] as String? ?? '';
    _channelIdCtrl.text = data['channel_id'] as String? ?? '';
    _webhookUrlCtrl.text = data['webhook_url'] as String? ?? '';
    _enabled = data['enabled'] as bool? ?? false;
  }

  @override
  void dispose() {
    _botTokenCtrl.dispose();
    _signingSecretCtrl.dispose();
    _channelIdCtrl.dispose();
    _webhookUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('slack', {
        'bot_token': _botTokenCtrl.text,
        'signing_secret': _signingSecretCtrl.text,
        'channel_id': _channelIdCtrl.text,
        'webhook_url': _webhookUrlCtrl.text,
        'enabled': _enabled,
      });
      ref.invalidate(adminSettingProvider('slack'));
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

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('slack', {
        'bot_token': _botTokenCtrl.text,
        'signing_secret': _signingSecretCtrl.text,
        'channel_id': _channelIdCtrl.text,
        'webhook_url': _webhookUrlCtrl.text,
        'enabled': _enabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).testSuccessful)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).testFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('slack'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminSlackIntegration),
            const SizedBox(height: 12),

            // Enable toggle
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.tag_rounded, color: tokens.fgMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.adminEnableSlackBot,
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

            // Bot Token
            _fieldLabel(tokens, l10n.adminBotToken),
            const SizedBox(height: 6),
            _field(tokens, _botTokenCtrl,
                hint: l10n.adminSlackBotTokenHint, obscure: true),
            const SizedBox(height: 16),

            // Signing Secret
            _fieldLabel(tokens, l10n.adminSigningSecret),
            const SizedBox(height: 6),
            _field(tokens, _signingSecretCtrl,
                hint: l10n.adminSigningSecretHint, obscure: true),
            const SizedBox(height: 16),

            // Default Channel ID
            _fieldLabel(tokens, l10n.adminDefaultChannelId),
            const SizedBox(height: 6),
            _field(tokens, _channelIdCtrl, hint: 'C0123456789'),
            const SizedBox(height: 16),

            // Webhook URL
            _fieldLabel(tokens, l10n.adminWebhookUrl),
            const SizedBox(height: 6),
            _field(tokens, _webhookUrlCtrl,
                hint: l10n.adminSlackWebhookHint),

            const SizedBox(height: 24),

            // Test button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _test,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.accent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _testing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: tokens.accent),
                      )
                    : Text(AppLocalizations.of(context).test, style: TextStyle(color: tokens.accent)),
              ),
            ),
            const SizedBox(height: 12),

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
}
