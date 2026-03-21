import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.emailRequired;
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return l10n.enterValidEmail;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.passwordRequired;
    if (value.length < 6) return l10n.passwordTooShortSix;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Pick up error from AsyncValue error OR from AuthUnauthenticated.error
    String? errorMessage;
    if (authState.hasError) {
      errorMessage = authState.error.toString();
    } else if (authState.value is AuthUnauthenticated) {
      errorMessage = (authState.value as AuthUnauthenticated).error;
    }

    // Show toast on error
    ref.listen(authProvider, (prev, next) {
      final msg = next.value is AuthUnauthenticated
          ? (next.value as AuthUnauthenticated).error
          : null;
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const SizedBox(height: 16),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.signInToAccount,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 32),

                  // Glass card
                  _GlassCard(
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
                              hintText: l10n.yourPassword,
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

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              style: TextButton.styleFrom(
                                foregroundColor: tokens.accent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                              child: Text(
                                l10n.forgotPassword,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sign In button
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
                                      l10n.signIn,
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

                  // ── OAuth divider ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Divider(color: tokens.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.orContinueWith,
                          style: TextStyle(color: tokens.fgDim, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: tokens.border)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── OAuth buttons ──────────────────────────────────────
                  const _OAuthButtonRow(),
                  const SizedBox(height: 24),

                  // Bottom links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.accent,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          l10n.createAccount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/magic-login'),
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.accentAlt,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: Text(
                        l10n.signInWithMagicLink,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.go('/passkey'),
                      icon: Icon(
                        Icons.fingerprint_rounded,
                        size: 18,
                        color: tokens.accent,
                      ),
                      label: Text(
                        l10n.signInWithPasskey,
                        style: TextStyle(fontSize: 14, color: tokens.accent),
                      ),
                      style: TextButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ),
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

// ── OAuth button row ──────────────────────────────────────────────────────────

class _OAuthProvider {
  const _OAuthProvider(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const _oauthProviders = [
  _OAuthProvider('google', 'Google', Icons.g_mobiledata_rounded),
  _OAuthProvider('github', 'GitHub', Icons.code_rounded),
  _OAuthProvider('apple', 'Apple', Icons.apple_rounded),
  _OAuthProvider('discord', 'Discord', Icons.discord_rounded),
  _OAuthProvider('slack', 'Slack', Icons.tag_rounded),
];

class _OAuthButtonRow extends StatelessWidget {
  const _OAuthButtonRow();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _oauthProviders.map((p) {
        return _OAuthButton(provider: p, tokens: tokens);
      }).toList(),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({required this.provider, required this.tokens});
  final _OAuthProvider provider;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sign in with ${provider.label}',
      child: InkWell(
        onTap: () => _launchOAuth(provider.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Icon(provider.icon, size: 22, color: tokens.fgMuted),
        ),
      ),
    );
  }

  Future<void> _launchOAuth(String providerId) async {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    final url = Uri.parse(
      '$baseUrl/api/auth/oauth/$providerId?redirect=${Uri.encodeComponent('orchestra://auth/callback')}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── Shared glass card ─────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.tokens, required this.child});

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
