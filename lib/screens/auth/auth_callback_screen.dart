import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// OAuth callback screen — receives the JWT token from the OAuth deep link
/// (orchestra://auth/callback?token=xxx) and completes authentication.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key, this.token, this.error});

  final String? token;
  final String? error;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    // Check for error from OAuth provider
    if (widget.error != null && widget.error!.isNotEmpty) {
      setState(() {
        _loading = false;
        _error = 'OAuth error: ${widget.error}';
      });
      return;
    }

    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No authentication token received.';
      });
      return;
    }

    try {
      // Store the JWT and refresh auth state
      final storage = ref.read(tokenStorageProvider);
      await storage.saveTokens(accessToken: token, refreshToken: '');
      await ref.read(authProvider.notifier).fetchMe();

      if (mounted) context.go('/summary');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to complete sign-in: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: tokens.accent),
                      const SizedBox(height: 20),
                      Text(
                        'Completing sign-in...',
                        style: TextStyle(color: tokens.fgMuted, fontSize: 15),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Authentication failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: tokens.fgBright, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor: tokens.isLight
                              ? Colors.white
                              : Colors.black,
                        ),
                        child: Text(l10n.backToSignIn),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
