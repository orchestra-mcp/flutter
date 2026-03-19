import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
  }

  String? _validateName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.nameRequired;
    if (value.trim().length < 2) return l10n.nameTooShort;
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.emailRequired;
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return l10n.enterValidEmail;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.passwordRequired;
    if (value.length < 8) return l10n.passwordTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.hasError ? authState.error.toString() : null;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createAccount,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.joinSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // Glass card
                  _AuthCard(
                    tokens: tokens,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error banner
                          if (errorMessage != null) ...[
                            _ErrorBanner(message: errorMessage, tokens: tokens),
                            const SizedBox(height: 16),
                          ],

                          // Name field
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: tokens.fgBright),
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              hintText: l10n.yourName,
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: tokens.fgDim,
                                size: 20,
                              ),
                            ),
                            validator: (v) => _validateName(v, l10n),
                          ),
                          const SizedBox(height: 16),

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: TextStyle(color: tokens.fgBright),
                            decoration: InputDecoration(
                              labelText: l10n.email,
                              hintText: l10n.emailHint,
                              prefixIcon: Icon(
                                Icons.mail_outline_rounded,
                                color: tokens.fgDim,
                                size: 20,
                              ),
                            ),
                            validator: (v) => _validateEmail(v, l10n),
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                isLoading ? null : _submit(),
                            style: TextStyle(color: tokens.fgBright),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              hintText: l10n.minEightCharacters,
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: tokens.fgDim,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: tokens.fgDim,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) => _validatePassword(v, l10n),
                          ),
                          const SizedBox(height: 24),

                          // Register button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.accent,
                                foregroundColor: tokens.isLight
                                    ? Colors.white
                                    : Colors.black,
                                disabledBackgroundColor: tokens.accent
                                    .withValues(alpha: 0.4),
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
                                      l10n.createAccount,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.accent,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          l10n.signIn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared card ───────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.tokens, required this.child});

  final OrchestraColorTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

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
