import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin email tab — SMTP configuration, test connection.
class AdminEmailTab extends ConsumerStatefulWidget {
  const AdminEmailTab({super.key});

  @override
  ConsumerState<AdminEmailTab> createState() => _AdminEmailTabState();
}

class _AdminEmailTabState extends ConsumerState<AdminEmailTab> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fromNameCtrl = TextEditingController();
  final _fromEmailCtrl = TextEditingController();
  bool _tlsEnabled = true;
  bool _saving = false;
  bool _testing = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _hostCtrl.text = data['host'] as String? ?? '';
    _portCtrl.text = (data['port']?.toString()) ?? '587';
    _usernameCtrl.text = data['username'] as String? ?? '';
    _passwordCtrl.text = data['password'] as String? ?? '';
    _fromNameCtrl.text = data['from_name'] as String? ?? '';
    _fromEmailCtrl.text = data['from_email'] as String? ?? '';
    _tlsEnabled = data['tls_enabled'] as bool? ?? true;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _fromNameCtrl.dispose();
    _fromEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('smtp', {
        'host': _hostCtrl.text,
        'port': int.tryParse(_portCtrl.text) ?? 587,
        'username': _usernameCtrl.text,
        'password': _passwordCtrl.text,
        'from_name': _fromNameCtrl.text,
        'from_email': _fromEmailCtrl.text,
        'tls_enabled': _tlsEnabled,
      });
      ref.invalidate(adminSettingProvider('smtp'));
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

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      await ref.read(apiClientProvider).testEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).testEmailSent)),
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
    final settingAsync = ref.watch(adminSettingProvider('smtp'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminSmtpConfig),
            const SizedBox(height: 12),

            // Host
            _fieldLabel(tokens, l10n.adminSmtpHost),
            const SizedBox(height: 6),
            _field(tokens, _hostCtrl, hint: l10n.adminSmtpHostHint),
            const SizedBox(height: 16),

            // Port
            _fieldLabel(tokens, l10n.adminPort),
            const SizedBox(height: 6),
            _field(tokens, _portCtrl, hint: '587'),
            const SizedBox(height: 16),

            // Username
            _fieldLabel(tokens, l10n.adminUsername),
            const SizedBox(height: 6),
            _field(tokens, _usernameCtrl, hint: l10n.adminUsernameHint),
            const SizedBox(height: 16),

            // Password
            _fieldLabel(tokens, l10n.adminPasswordLabel),
            const SizedBox(height: 6),
            _field(tokens, _passwordCtrl,
                hint: l10n.adminPasswordHint, obscure: true),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            _sectionHeader(tokens, l10n.adminSender),
            const SizedBox(height: 12),

            // From Name
            _fieldLabel(tokens, l10n.adminFromName),
            const SizedBox(height: 6),
            _field(tokens, _fromNameCtrl, hint: 'Orchestra'),
            const SizedBox(height: 16),

            // From Email
            _fieldLabel(tokens, l10n.adminFromEmail),
            const SizedBox(height: 6),
            _field(tokens, _fromEmailCtrl, hint: l10n.adminFromEmailHint),
            const SizedBox(height: 16),

            // TLS Toggle
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
                  Icon(Icons.lock_outline_rounded,
                      color: tokens.fgMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.adminEnableTls,
                      style: TextStyle(fontSize: 14, color: tokens.fgBright),
                    ),
                  ),
                  Switch(
                    value: _tlsEnabled,
                    activeThumbColor: tokens.accent,
                    onChanged: (v) => setState(() => _tlsEnabled = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test Connection
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _testConnection,
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
                    : Text(AppLocalizations.of(context).testConnection,
                        style: TextStyle(color: tokens.accent)),
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
