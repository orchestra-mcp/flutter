import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Magic-link login screen.
///
/// Shows an email field and a "Send magic link" button.  On success the UI
/// switches to a confirmation view via [AnimatedSwitcher].  The actual
/// deep-link is handled by the `/auth/magic` GoRouter route which exchanges
/// the token and navigates to `/summary` or `/onboarding`.
class MagicLoginScreen extends ConsumerStatefulWidget {
  const MagicLoginScreen({super.key});

  @override
  ConsumerState<MagicLoginScreen> createState() => _MagicLoginScreenState();
}

class _MagicLoginScreenState extends ConsumerState<MagicLoginScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterYourEmail);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(
        Endpoints.authMagicLinkSend,
        data: {'email': email},
      );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: tokens.fgBright,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
          tooltip: AppLocalizations.of(context).backToSignIn,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _sent
                    ? _ConfirmationView(
                        key: const ValueKey('confirmation'),
                        email: _emailCtrl.text.trim(),
                        tokens: tokens,
                        onBack: () => context.go('/login'),
                      )
                    : _EmailFormView(
                        key: const ValueKey('form'),
                        emailCtrl: _emailCtrl,
                        loading: _loading,
                        error: _error,
                        tokens: tokens,
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

// ── Email form view ───────────────────────────────────────────────────────────

class _EmailFormView extends StatelessWidget {
  const _EmailFormView({
    super.key,
    required this.emailCtrl,
    required this.loading,
    required this.error,
    required this.tokens,
    required this.onSubmit,
    required this.onBack,
  });

  final TextEditingController emailCtrl;
  final bool loading;
  final String? error;
  final OrchestraColorTokens tokens;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.signInWithoutPassword,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.magicLinkSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.fgMuted, fontSize: 15),
        ),
        const SizedBox(height: 32),
        _GlassCard(
          tokens: tokens,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                _ErrorBanner(message: error!, tokens: tokens),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onSubmitted: (_) => loading ? null : onSubmit(),
                style: TextStyle(color: tokens.fgBright),
                decoration: InputDecoration(
                  labelText: l10n.email,
                  hintText: l10n.emailHint,
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      color: tokens.fgDim, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor:
                        tokens.isLight ? Colors.white : Colors.black,
                    disabledBackgroundColor:
                        tokens.accent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.isLight ? Colors.white : Colors.black,
                          ),
                        )
                      : Text(l10n.sendMagicLink,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Confirmation view ─────────────────────────────────────────────────────────

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({
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
        const SizedBox(height: 16),
        _GlassCard(
          tokens: tokens,
          child: Column(
            children: [
              // Check icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.accent.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    size: 32, color: tokens.accent),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.checkEmail,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.magicLinkSentTo,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  color: tokens.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.tapMagicLinkExpiry,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(foregroundColor: tokens.accentAlt),
                child: Text(l10n.backToSignIn),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.tokens, required this.child});
  final OrchestraColorTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.tokens});
  final String message;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
      );
}
