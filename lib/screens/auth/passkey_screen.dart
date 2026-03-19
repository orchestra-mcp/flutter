import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Passkey / biometric authentication screen.
///
/// Two-step flow:
/// 1. User enters email to identify their account
/// 2. Platform biometric prompt confirms identity (Face ID / fingerprint)
/// 3. Backend verifies the user has registered passkeys and issues a JWT
///
/// Note: Full WebAuthn credential signing requires platform-specific packages.
/// This screen uses local_auth as a biometric confirmation step.
class PasskeyScreen extends ConsumerStatefulWidget {
  const PasskeyScreen({super.key});

  @override
  ConsumerState<PasskeyScreen> createState() => _PasskeyScreenState();
}

class _PasskeyScreenState extends ConsumerState<PasskeyScreen> {
  final _localAuth = LocalAuthentication();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  final bool _succeeded = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
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
      // Step 1: Local biometric confirmation
      final authenticated = await _localAuth.authenticate(
        localizedReason: AppLocalizations.of(context).signInToOrchestra,
      );

      if (!mounted) return;
      if (!authenticated) {
        setState(() => _error = AppLocalizations.of(context).authCancelled);
        return;
      }

      // Step 2: Call backend passkey authenticate begin
      final dio = ref.read(dioProvider);
      final beginRes = await dio.post<Map<String, dynamic>>(
        '/api/auth/passkey/authenticate/begin',
        data: {'email': email},
      );

      final publicKey = beginRes.data?['publicKey'] as Map<String, dynamic>?;
      final sessionId = beginRes.data?['session_id'] as String?;

      if (publicKey == null || sessionId == null) {
        setState(
          () => _error =
              'No passkeys found for this account. Register one from the web app.',
        );
        return;
      }

      // Step 3: On mobile, we can't perform real WebAuthn signing without
      // platform-specific packages. Show success for the biometric step
      // and inform the user about the limitation.
      // For web platform (Flutter web), navigator.credentials would work here.
      setState(
        () => _error =
            'Passkey login requires the web app. Use password or magic link on mobile.',
      );
    } on DioException catch (e) {
      if (mounted) {
        final msg =
            e.response?.data?['error']?.toString() ?? 'Authentication failed';
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              child: _GlassCard(
                tokens: tokens,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _succeeded
                              ? Colors.green.withValues(alpha: 0.15)
                              : tokens.accentSurface,
                        ),
                        child: Icon(
                          _succeeded ? Icons.check_rounded : Icons.fingerprint,
                          size: 40,
                          color: _succeeded ? Colors.green : tokens.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      l10n.signInWithPasskey,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.passkeySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 28),

                    // Error banner
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!, tokens: tokens),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onSubmitted: (_) => _loading ? null : _authenticate(),
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
                    ),
                    const SizedBox(height: 20),

                    // Authenticate button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_loading || _succeeded)
                            ? null
                            : _authenticate,
                        icon: _loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.isLight
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              )
                            : const Icon(Icons.fingerprint, size: 22),
                        label: Text(
                          _succeeded
                              ? l10n.authenticated
                              : l10n.authenticateWithPasskey,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _succeeded
                              ? Colors.green
                              : tokens.accent,
                          foregroundColor: tokens.isLight
                              ? Colors.white
                              : Colors.black,
                          disabledBackgroundColor:
                              (_succeeded ? Colors.green : tokens.accent)
                                  .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back link
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.fgMuted,
                      ),
                      child: Text(
                        l10n.useDifferentMethod,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    padding: const EdgeInsets.all(28),
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
