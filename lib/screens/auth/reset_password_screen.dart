import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  /// Optional deep-link token passed via route parameters.
  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Missing reset token. Please use the link from your email.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(
        Endpoints.authResetPassword,
        data: {
          'token': token,
          'password': _passwordController.text,
        },
      );
      if (mounted) setState(() => _success = true);
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error =
            e.response?.data?['error']?.toString() ?? 'Failed to reset password');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.passwordRequired;
    if (value.length < 8) return l10n.passwordTooShort;
    return null;
  }

  String? _validateConfirm(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.pleaseConfirmPassword;
    if (value != _passwordController.text) return l10n.passwordMismatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.fgMuted),
          onPressed: () => context.go('/login'),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _success
                    ? _SuccessView(
                        key: const ValueKey('success'),
                        tokens: tokens,
                        onContinue: () => context.go('/login'),
                      )
                    : _FormView(
                        key: const ValueKey('form'),
                        formKey: _formKey,
                        passwordController: _passwordController,
                        confirmController: _confirmController,
                        obscurePassword: _obscurePassword,
                        obscureConfirm: _obscureConfirm,
                        isLoading: _isLoading,
                        error: _error,
                        tokens: tokens,
                        validatePassword: (v) => _validatePassword(v, AppLocalizations.of(context)),
                        validateConfirm: (v) => _validateConfirm(v, AppLocalizations.of(context)),
                        onTogglePassword: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        onToggleConfirm: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                        onSubmit: _submit,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.error,
    required this.tokens,
    required this.validatePassword,
    required this.validateConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final String? error;
  final OrchestraColorTokens tokens;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.key_rounded, size: 48, color: tokens.accent),
        const SizedBox(height: 16),
        Text(
          l10n.setNewPassword,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.newPasswordHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.bg.withValues(alpha: tokens.isLight ? 0.85 : 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderFaint),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  _ErrorBanner(message: error!, tokens: tokens),
                  const SizedBox(height: 16),
                ],

                // New password
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: tokens.fgBright),
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    hintText: l10n.minEightCharacters,
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: tokens.fgDim, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: tokens.fgDim,
                        size: 20,
                      ),
                      onPressed: onTogglePassword,
                    ),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 16),

                // Confirm password
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
                  style: TextStyle(color: tokens.fgBright),
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                    hintText: l10n.repeatPassword,
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: tokens.fgDim, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: tokens.fgDim,
                        size: 20,
                      ),
                      onPressed: onToggleConfirm,
                    ),
                  ),
                  validator: validateConfirm,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor:
                          tokens.isLight ? Colors.white : Colors.black,
                      disabledBackgroundColor:
                          tokens.accent.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.isLight
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          )
                        : Text(
                            l10n.resetPassword,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.tokens,
    required this.onContinue,
  });

  final OrchestraColorTokens tokens;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.passwordResetSuccess,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.passwordResetSuccessSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.isLight ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.signIn,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.tokens});

  final String message;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
