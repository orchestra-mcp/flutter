import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Result returned when the user submits the SSH connection dialog.
@immutable
class SshConnectResult {
  const SshConnectResult({
    required this.host,
    required this.user,
    required this.port,
    this.password,
    this.keyFile,
  });

  final String host;
  final String user;
  final int port;
  final String? password;
  final String? keyFile;
}

/// Authentication method for SSH connections.
enum _SshAuthMethod { password, keyFile }

/// Dialog that collects SSH connection parameters from the user.
///
/// Returns an [SshConnectResult] when submitted, or `null` if cancelled.
///
/// ```dart
/// final result = await showDialog<SshConnectResult>(
///   context: context,
///   builder: (_) => const SshConnectDialog(),
/// );
/// ```
class SshConnectDialog extends StatefulWidget {
  const SshConnectDialog({super.key});

  @override
  State<SshConnectDialog> createState() => _SshConnectDialogState();
}

class _SshConnectDialogState extends State<SshConnectDialog> {
  final _formKey = GlobalKey<FormState>();

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _passwordController = TextEditingController();
  final _keyFileController = TextEditingController();

  _SshAuthMethod _authMethod = _SshAuthMethod.password;

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    _keyFileController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final result = SshConnectResult(
      host: _hostController.text.trim(),
      user: _userController.text.trim(),
      port: port,
      password: _authMethod == _SshAuthMethod.password
          ? _passwordController.text
          : null,
      keyFile: _authMethod == _SshAuthMethod.keyFile
          ? _keyFileController.text.trim()
          : null,
    );

    Navigator.of(context).pop(result);
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        l10n.sshConnection,
        style: TextStyle(
          color: tokens.fgBright,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  tokens: tokens,
                  controller: _hostController,
                  label: l10n.host,
                  hint: l10n.hostHint,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.hostRequired
                      : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  tokens: tokens,
                  controller: _userController,
                  label: l10n.user,
                  hint: 'root',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.userRequired
                      : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  tokens: tokens,
                  controller: _portController,
                  label: l10n.port,
                  hint: '22',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.portRequired;
                    final port = int.tryParse(v.trim());
                    if (port == null || port < 1 || port > 65535) {
                      return l10n.invalidPort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.authentication,
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _buildAuthRadio(tokens),
                const SizedBox(height: 12),
                if (_authMethod == _SshAuthMethod.password)
                  _buildTextField(
                    tokens: tokens,
                    controller: _passwordController,
                    label: l10n.password,
                    hint: l10n.enterPassword,
                    obscureText: true,
                  )
                else
                  _buildKeyFileField(tokens),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(l10n.cancel, style: TextStyle(color: tokens.fgMuted)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: tokens.accent),
          child: Text(l10n.connect, style: TextStyle(color: tokens.fgBright)),
        ),
      ],
    );
  }

  Widget _buildAuthRadio(OrchestraColorTokens tokens) {
    return RadioGroup<_SshAuthMethod>(
      groupValue: _authMethod,
      onChanged: (v) {
        if (v != null) setState(() => _authMethod = v);
      },
      child: Row(
        children: [
          _AuthRadioOption(
            tokens: tokens,
            label: AppLocalizations.of(context).password,
            value: _SshAuthMethod.password,
          ),
          const SizedBox(width: 16),
          _AuthRadioOption(
            tokens: tokens,
            label: AppLocalizations.of(context).keyFile,
            value: _SshAuthMethod.keyFile,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFileField(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            tokens: tokens,
            controller: _keyFileController,
            label: l10n.keyFile,
            hint: l10n.keyFileHint,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: IconButton(
            onPressed: () {
              // File picker would be wired here via a platform channel or
              // file_picker package. For now this is a placeholder.
            },
            icon: Icon(Icons.folder_open_rounded, color: tokens.accent),
            tooltip: l10n.browse,
            style: IconButton.styleFrom(
              backgroundColor: tokens.accent.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required OrchestraColorTokens tokens,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: tokens.fgMuted, fontSize: 13),
        hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
        filled: true,
        fillColor: tokens.bg,
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
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class _AuthRadioOption extends StatelessWidget {
  const _AuthRadioOption({
    required this.tokens,
    required this.label,
    required this.value,
  });

  final OrchestraColorTokens tokens;
  final String label;
  final _SshAuthMethod value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<_SshAuthMethod>(
          value: value,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return tokens.accent;
            }
            return tokens.fgDim;
          }),
        ),
        Text(label, style: TextStyle(color: tokens.fgBright, fontSize: 13)),
      ],
    );
  }
}
