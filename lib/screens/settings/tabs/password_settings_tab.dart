import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Password settings tab — change password with current/new/confirm fields.
class PasswordSettingsTab extends ConsumerStatefulWidget {
  const PasswordSettingsTab({super.key});

  @override
  ConsumerState<PasswordSettingsTab> createState() =>
      _PasswordSettingsTabState();
}

class _PasswordSettingsTabState extends ConsumerState<PasswordSettingsTab> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).newPasswordsDoNotMatch),
        ),
      );
      return;
    }
    if (_currentPwCtrl.text.isEmpty || _newPwCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseAllPasswordFields),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).changePassword({
        'current_password': _currentPwCtrl.text,
        'new_password': _newPwCtrl.text,
        'confirm_password': _confirmPwCtrl.text,
      });
      if (mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).passwordUpdatedSuccessfully,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToUpdatePassword}: $e',
            ),
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // -- Change Password -------------------------------------------------
        _sectionHeader(tokens, 'Change Password'),
        const SizedBox(height: 12),
        _label(tokens, 'Current Password'),
        const SizedBox(height: 6),
        _passwordField(
          tokens,
          _currentPwCtrl,
          'Enter your current password',
          obscure: _obscureCurrent,
          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 16),
        _label(tokens, 'New Password'),
        const SizedBox(height: 6),
        _passwordField(
          tokens,
          _newPwCtrl,
          'Enter a new password',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 16),
        _label(tokens, 'Confirm New Password'),
        const SizedBox(height: 6),
        _passwordField(
          tokens,
          _confirmPwCtrl,
          'Re-enter the new password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        const SizedBox(height: 14),

        // -- Password requirements hint --------------------------------------
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password requirements',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.fgBright,
                ),
              ),
              const SizedBox(height: 6),
              _requirementRow(tokens, 'At least 8 characters'),
              const SizedBox(height: 4),
              _requirementRow(tokens, 'One uppercase and one lowercase letter'),
              const SizedBox(height: 4),
              _requirementRow(tokens, 'One number'),
              const SizedBox(height: 4),
              _requirementRow(tokens, 'One special character (!@#\$%^&*)'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // -- Update button ---------------------------------------------------
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _updatePassword,
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
                : Text(AppLocalizations.of(context).updatePassword),
          ),
        ),
      ],
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

  Widget _label(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.fgDim,
      letterSpacing: 0.4,
    ),
  );

  Widget _requirementRow(OrchestraColorTokens tokens, String text) => Row(
    children: [
      Icon(Icons.check_circle_outline_rounded, size: 14, color: tokens.fgDim),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 11, color: tokens.fgMuted)),
    ],
  );

  Widget _passwordField(
    OrchestraColorTokens tokens,
    TextEditingController ctrl,
    String hint, {
    required bool obscure,
    required VoidCallback onToggle,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18,
            color: tokens.fgDim,
          ),
          onPressed: onToggle,
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
