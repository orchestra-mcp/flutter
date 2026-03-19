import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

class TwoFactorScreen extends ConsumerStatefulWidget {
  const TwoFactorScreen({super.key, this.email});

  /// Email the code was sent to, used for display and resend purposes.
  final String? email;

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _error;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = AppLocalizations.of(context).enterFullCode);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Placeholder: wire to actual 2FA verify API call when available.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isLoading = false);
      // On success, navigate to home / dashboard.
      // context.go('/');
    }
  }

  Future<void> _resendCode() async {
    if (_isResending || _resendCooldown > 0) return;
    setState(() {
      _isResending = true;
      _error = null;
    });
    // Placeholder: wire to actual resend API call when available.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isResending = false;
        _resendCooldown = 30;
      });
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final displayEmail = widget.email ?? l10n.email;

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
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.accentSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, size: 32, color: tokens.accent),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    l10n.twoStepVerification,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          color: tokens.fgMuted, fontSize: 14, height: 1.5),
                      children: [
                        TextSpan(text: l10n.enterCodeSentTo),
                        TextSpan(
                          text: displayEmail,
                          style: TextStyle(
                            color: tokens.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: '.'), // punctuation is language-neutral here
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: tokens.bg
                          .withValues(alpha: tokens.isLight ? 0.85 : 0.72),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          _ErrorBanner(message: _error!, tokens: tokens),
                          const SizedBox(height: 16),
                        ],

                        // OTP input
                        Semantics(
                          label: l10n.otpInputLabel,
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 12,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 28,
                                letterSpacing: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              if (_error != null) {
                                setState(() => _error = null);
                              }
                              if (value.length == 6 && !_isLoading) {
                                _verify();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Verify button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verify,
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
                            child: _isLoading
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
                                    l10n.verify,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Resend code
                        Center(
                          child: _isResending
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tokens.fgMuted,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: _resendCooldown > 0
                                      ? null
                                      : _resendCode,
                                  style: TextButton.styleFrom(
                                    foregroundColor: tokens.accent,
                                    disabledForegroundColor: tokens.fgDim,
                                    tapTargetSize:
                                        MaterialTapTargetSize.padded,
                                  ),
                                  child: Text(
                                    _resendCooldown > 0
                                        ? l10n.resendCodeIn(_resendCooldown)
                                        : l10n.resendCode,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
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
              ),
            ),
          ),
        ),
      ),
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
