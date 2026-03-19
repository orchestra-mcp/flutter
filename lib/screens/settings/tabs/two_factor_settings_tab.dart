import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Two-factor authentication settings tab — enable/disable TOTP, QR code, recovery.
class TwoFactorSettingsTab extends ConsumerStatefulWidget {
  const TwoFactorSettingsTab({super.key});

  @override
  ConsumerState<TwoFactorSettingsTab> createState() =>
      _TwoFactorSettingsTabState();
}

class _TwoFactorSettingsTabState extends ConsumerState<TwoFactorSettingsTab> {
  final _verificationCtrl = TextEditingController();
  final _disablePasswordCtrl = TextEditingController();
  bool _verifying = false;
  bool _disabling = false;
  String? _error;
  String? _successMsg;

  // Setup state
  String? _qrUrl;
  String? _secret;
  bool _setupInProgress = false;

  @override
  void dispose() {
    _verificationCtrl.dispose();
    _disablePasswordCtrl.dispose();
    super.dispose();
  }

  bool get _twoFaEnabled {
    final authState = ref.read(authProvider).value;
    if (authState is AuthAuthenticated) {
      return authState.user.twoFactorEnabled;
    }
    return false;
  }

  Future<void> _startSetup() async {
    setState(() {
      _setupInProgress = true;
      _error = null;
      _successMsg = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(Endpoints.auth2faSetup);
      if (mounted) {
        setState(() {
          _qrUrl = res.data?['qr_url'] as String?;
          _secret = res.data?['secret'] as String?;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response?.data?['error']?.toString() ?? 'Setup failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _setupInProgress = false);
    }
  }

  Future<void> _confirmSetup() async {
    final code = _verificationCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter a 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(
        Endpoints.auth2faConfirm,
        data: {'code': code},
      );
      if (mounted) {
        _verificationCtrl.clear();
        setState(() {
          _qrUrl = null;
          _secret = null;
          _successMsg = '2FA enabled successfully';
        });
        // Refresh user state to pick up two_factor_enabled
        await ref.read(authProvider.notifier).fetchMe();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response?.data?['error']?.toString() ?? 'Verification failed');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _disable() async {
    final password = _disablePasswordCtrl.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _disabling = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post<Map<String, dynamic>>(
        Endpoints.auth2faDisable,
        data: {'password': password},
      );
      if (mounted) {
        _disablePasswordCtrl.clear();
        setState(() => _successMsg = '2FA disabled');
        await ref.read(authProvider.notifier).fetchMe();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = e.response?.data?['error']?.toString() ?? 'Failed to disable 2FA');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _disabling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final enabled = _twoFaEnabled;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        _sectionHeader(tokens, 'Two-Factor Authentication'),
        const SizedBox(height: 4),
        Text(
          'Add an extra layer of security to your account using a '
          'time-based one-time password (TOTP) from an authenticator app '
          'like Google Authenticator or Authy.',
          style: TextStyle(fontSize: 12, color: tokens.fgDim, height: 1.5),
        ),
        const SizedBox(height: 20),

        // ── Status + action ─────────────────────────────────────────────
        if (_error != null) ...[
          _errorBanner(tokens, _error!),
          const SizedBox(height: 12),
        ],
        if (_successMsg != null) ...[
          _successBanner(tokens, _successMsg!),
          const SizedBox(height: 12),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: tokens.fgMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authenticator App (TOTP)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.fgBright,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled ? 'Enabled' : 'Disabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled
                            ? const Color(0xFF22C55E)
                            : tokens.fgDim,
                      ),
                    ),
                  ],
                ),
              ),
              if (!enabled && _qrUrl == null)
                ElevatedButton(
                  onPressed: _setupInProgress ? null : _startSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _setupInProgress
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enable', style: TextStyle(fontSize: 13)),
                ),
              if (enabled)
                const Text('Active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    )),
            ],
          ),
        ),

        // ── Setup flow (QR + verify) ────────────────────────────────────
        if (_qrUrl != null && !enabled) ...[
          const SizedBox(height: 24),
          Divider(color: tokens.border.withValues(alpha: 0.4)),
          const SizedBox(height: 20),

          _sectionHeader(tokens, 'Scan QR Code'),
          const SizedBox(height: 4),
          Text(
            'Scan this code with your authenticator app to link your account.',
            style: TextStyle(fontSize: 12, color: tokens.fgDim),
          ),
          const SizedBox(height: 16),

          // QR code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _qrUrl!,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Manual entry secret
          if (_secret != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual entry key:',
                    style: TextStyle(fontSize: 11, color: tokens.fgDim),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _secret!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.fgBright,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy_rounded,
                            size: 16, color: tokens.accent),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _secret!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Secret copied')),
                          );
                        },
                        tooltip: 'Copy',
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Verification code input
          _sectionHeader(tokens, 'Verify Code'),
          const SizedBox(height: 4),
          Text(
            'Enter the 6-digit code from your authenticator app to confirm setup.',
            style: TextStyle(fontSize: 12, color: tokens.fgDim),
          ),
          const SizedBox(height: 12),
          _field(tokens, _verificationCtrl, hint: '000000'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verifying ? null : _confirmSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _verifying
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(AppLocalizations.of(context).verifyAndEnable),
            ),
          ),
        ],

        // ── Disable 2FA (when enabled) ──────────────────────────────────
        if (enabled) ...[
          const SizedBox(height: 24),
          Divider(color: tokens.border.withValues(alpha: 0.4)),
          const SizedBox(height: 20),

          _sectionHeader(tokens, 'Disable Two-Factor Authentication'),
          const SizedBox(height: 4),
          Text(
            'Enter your password to disable 2FA. This will remove the extra security layer.',
            style: TextStyle(fontSize: 12, color: tokens.fgDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _disablePasswordCtrl,
            obscureText: true,
            style: TextStyle(color: tokens.fgBright),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: tokens.fgDim),
              filled: true,
              fillColor: tokens.bgAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _disabling ? null : _disable,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _disabling
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Disable 2FA',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tokens.fgBright,
        ),
      );

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle: TextStyle(
          color: tokens.fgDim,
          letterSpacing: 8,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }

  Widget _errorBanner(OrchestraColorTokens tokens, String message) => Container(
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
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _successBanner(OrchestraColorTokens tokens, String message) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF22C55E), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Color(0xFF22C55E), fontSize: 13)),
            ),
          ],
        ),
      );
}
