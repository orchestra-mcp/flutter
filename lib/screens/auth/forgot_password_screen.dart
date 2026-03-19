import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(
        Endpoints.authForgotPassword,
        data: {'email': _emailController.text.trim()},
      );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.emailRequired;
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return l10n.enterValidEmail;
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
                child: _submitted
                    ? _SuccessView(
                        key: const ValueKey('success'),
                        email: _emailController.text.trim(),
                        tokens: tokens,
                        onBack: () => context.go('/login'),
                      )
                    : _FormView(
                        key: const ValueKey('form'),
                        formKey: _formKey,
                        emailController: _emailController,
                        isLoading: _isLoading,
                        error: _error,
                        tokens: tokens,
                        validateEmail: (v) =>
                            _validateEmail(v, AppLocalizations.of(context)),
                        onSubmit: _submit,
                        onBack: () => context.go('/login'),
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
    required this.emailController,
    required this.isLoading,
    required this.error,
    required this.tokens,
    required this.validateEmail,
    required this.onSubmit,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final String? error;
  final OrchestraColorTokens tokens;
  final String? Function(String?) validateEmail;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_reset_rounded, size: 48, color: tokens.accent),
        const SizedBox(height: 16),
        Text(
          l10n.forgotPasswordTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.forgotPasswordSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 28),

        // Card
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

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  style: TextStyle(color: tokens.fgBright),
                  decoration: InputDecoration(
                    labelText: l10n.emailAddress,
                    hintText: l10n.emailHint,
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: tokens.fgDim,
                      size: 20,
                    ),
                  ),
                  validator: validateEmail,
                  onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: tokens.isLight
                          ? Colors.white
                          : Colors.black,
                      disabledBackgroundColor: tokens.accent.withValues(
                        alpha: 0.4,
                      ),
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
                            l10n.sendMagicLink,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: onBack,
            style: TextButton.styleFrom(
              foregroundColor: tokens.fgMuted,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              l10n.backToSignIn,
              style: const TextStyle(fontSize: 14),
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
    required this.email,
    required this.tokens,
    required this.onBack,
  });

  final String email;
  final OrchestraColorTokens tokens;
  final VoidCallback onBack;

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
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Colors.green,
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.checkEmail,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.magicLinkSentTo,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgMuted, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.accent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.magicLinkExpiry,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgDim, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.isLight ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              l10n.backToSignIn,
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
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18,
          ),
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
