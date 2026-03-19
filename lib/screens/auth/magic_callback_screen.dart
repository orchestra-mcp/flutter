import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Magic link callback screen — verifies the token from the deep link
/// and logs the user in automatically.
class MagicCallbackScreen extends ConsumerStatefulWidget {
  const MagicCallbackScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<MagicCallbackScreen> createState() =>
      _MagicCallbackScreenState();
}

class _MagicCallbackScreenState extends ConsumerState<MagicCallbackScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No magic link token provided.';
      });
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        Endpoints.authMagicLinkVerify,
        data: {'token': token},
      );

      final jwt = (res.data?['token'] ?? res.data?['access_token'] ?? '') as String;
      if (jwt.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Invalid response from server.';
        });
        return;
      }

      // Store token and refresh auth state
      final storage = ref.read(tokenStorageProvider);
      await storage.saveTokens(accessToken: jwt, refreshToken: '');
      await ref.read(authProvider.notifier).fetchMe();

      if (mounted) context.go('/summary');
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.response?.data?['error']?.toString() ??
              'Magic link verification failed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
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
                        'Verifying magic link...',
                        style: TextStyle(color: tokens.fgMuted, fontSize: 15),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Verification failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: tokens.fgBright, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor:
                              tokens.isLight ? Colors.white : Colors.black,
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
