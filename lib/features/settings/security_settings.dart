import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Security settings — change password, 2FA, and passkey management.
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _twoFaEnabled = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(l10n.security),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.changePassword,
              style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          TextField(
            controller: _currentCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.currentPassword,
              labelStyle: TextStyle(color: tokens.fgMuted),
            ),
            style: TextStyle(color: tokens.fgBright),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.newPassword,
              labelStyle: TextStyle(color: tokens.fgMuted),
            ),
            style: TextStyle(color: tokens.fgBright),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.confirmNewPassword,
              labelStyle: TextStyle(color: tokens.fgMuted),
            ),
            style: TextStyle(color: tokens.fgBright),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: Text(l10n.updatePassword),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.twoFactorAuth,
              style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
          SwitchListTile(
            value: _twoFaEnabled,
            onChanged: (v) => setState(() => _twoFaEnabled = v),
            title:
                Text(l10n.enable2FA, style: TextStyle(color: tokens.fgBright)),
            activeColor: tokens.accent,
          ),
          const SizedBox(height: 24),
          Text(l10n.passkeys,
              style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: Text(l10n.addPasskey),
          ),
        ],
      ),
    );
  }
}
