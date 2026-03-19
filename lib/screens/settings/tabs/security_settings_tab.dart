import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Security settings tab — password, 2FA toggle, passkeys.
class SecuritySettingsTab extends ConsumerStatefulWidget {
  const SecuritySettingsTab({super.key});

  @override
  ConsumerState<SecuritySettingsTab> createState() =>
      _SecuritySettingsTabState();
}

class _SecuritySettingsTabState extends ConsumerState<SecuritySettingsTab> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _twoFaEnabled = false;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Change password ──────────────────────────────────────────────
        _sectionHeader(tokens, 'Change Password'),
        const SizedBox(height: 12),
        _passwordField(tokens, _currentPwCtrl, 'Current password'),
        const SizedBox(height: 10),
        _passwordField(tokens, _newPwCtrl, 'New password'),
        const SizedBox(height: 10),
        _passwordField(tokens, _confirmPwCtrl, 'Confirm new password'),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context).updatePassword),
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── 2FA ──────────────────────────────────────────────────────────
        _sectionHeader(tokens, 'Two-Factor Authentication'),
        const SizedBox(height: 12),
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
                child: Text(
                  'Authenticator app (TOTP)',
                  style: TextStyle(fontSize: 14, color: tokens.fgBright),
                ),
              ),
              Switch(
                value: _twoFaEnabled,
                activeThumbColor: tokens.accent,
                onChanged: (v) => setState(() => _twoFaEnabled = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Passkeys ─────────────────────────────────────────────────────
        _sectionHeader(tokens, 'Passkeys'),
        const SizedBox(height: 12),
        // Placeholder passkey list — no registered passkeys
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No passkeys registered',
                style: TextStyle(fontSize: 13, color: tokens.fgDim),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(
                  Icons.fingerprint_rounded,
                  size: 16,
                  color: tokens.accent,
                ),
                label: Text(
                  AppLocalizations.of(context).registerPasskey,
                  style: TextStyle(color: tokens.accent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Connected Apps ──────────────────────────────────────────────
        _sectionHeader(tokens, 'Connected Apps'),
        const SizedBox(height: 4),
        Text(
          'Third-party apps you have authorized to access your Orchestra account.',
          style: TextStyle(fontSize: 12, color: tokens.fgDim),
        ),
        const SizedBox(height: 12),
        _ConnectedAppsList(tokens: tokens),
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

  Widget _passwordField(
    OrchestraColorTokens tokens,
    TextEditingController ctrl,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
}

// ── Connected Apps Widget ───────────────────────────────────────────────────

class _ConnectedAppsList extends ConsumerStatefulWidget {
  const _ConnectedAppsList({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_ConnectedAppsList> createState() => _ConnectedAppsListState();
}

class _ConnectedAppsListState extends ConsumerState<_ConnectedAppsList> {
  List<Map<String, dynamic>> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>(
        Endpoints.settingsConnectedApps,
      );
      final items = res.data?['apps'];
      if (mounted) {
        setState(() {
          _apps = items is List ? items.cast<Map<String, dynamic>>() : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revokeApp(String appId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete<dynamic>(Endpoints.settingsRevokeApp(appId));
      setState(() => _apps.removeWhere((a) => a['app_id'].toString() == appId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App access revoked')));
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to revoke access')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: tokens.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Icon(Icons.apps_rounded, size: 32, color: tokens.fgDim),
            const SizedBox(height: 8),
            Text(
              'No connected apps',
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _apps.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: tokens.border.withValues(alpha: 0.4),
              ),
            _ConnectedAppRow(
              app: _apps[i],
              tokens: tokens,
              onRevoke: () => _revokeApp(_apps[i]['app_id'].toString()),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedAppRow extends StatelessWidget {
  const _ConnectedAppRow({
    required this.app,
    required this.tokens,
    required this.onRevoke,
  });

  final Map<String, dynamic> app;
  final OrchestraColorTokens tokens;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final name = (app['app_name'] ?? 'Unknown App').toString();
    final scopes = (app['scopes'] ?? '').toString();
    final authorizedAt = app['authorized_at']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.apps_rounded, size: 18, color: tokens.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                if (scopes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Scopes: $scopes',
                    style: TextStyle(fontSize: 10, color: tokens.fgDim),
                  ),
                ],
                if (authorizedAt.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Authorized: $authorizedAt',
                    style: TextStyle(fontSize: 10, color: tokens.fgDim),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Revoke',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
