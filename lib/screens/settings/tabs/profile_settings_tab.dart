import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/api/endpoints.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/auth/user_model.dart';
import 'package:orchestra/core/i18n/locale_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Profile settings tab — name, phone, email, bio, position, timezone, language.
class ProfileSettingsTab extends ConsumerStatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  ConsumerState<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends ConsumerState<ProfileSettingsTab> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  String _language = 'en';
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Fill from cached user first (instant).
    final user = ref.read(authProvider.notifier).currentUser;
    if (user != null) _applyUser(user);

    // Then fetch fresh data from API.
    try {
      final data = await ref.read(apiClientProvider).getProfile();
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      final prefs = settings['preferences'] as Map<String, dynamic>? ?? {};

      _nameCtrl.text = data['name']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';
      _phoneCtrl.text = settings['phone']?.toString() ?? '';
      _bioCtrl.text = settings['bio']?.toString() ?? '';
      _positionCtrl.text = settings['position']?.toString() ?? '';
      _timezoneCtrl.text = settings['timezone']?.toString() ?? '';
      _handleCtrl.text = settings['handle']?.toString() ?? '';
      _language = prefs['language']?.toString() ?? 'en';
    } catch (_) {
      // Already filled from cache above.
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyUser(User user) {
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    _bioCtrl.text = user.bio ?? '';
    _positionCtrl.text = user.position ?? '';
    _timezoneCtrl.text = user.timezone ?? '';
    _handleCtrl.text = user.handle ?? '';
    _language = user.language ?? 'en';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _positionCtrl.dispose();
    _timezoneCtrl.dispose();
    _handleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateSettingsProfile({
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'bio': _bioCtrl.text,
        'position': _positionCtrl.text,
        'timezone': _timezoneCtrl.text,
        'handle': _handleCtrl.text,
        'language': _language,
      });
      ref.invalidate(authProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).profileUpdatedSuccessfully,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToUpdateProfile}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final avatarUrl = user is AuthAuthenticated
        ? resolveAvatarUrl(user.user.avatarUrl)
        : null;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.accent));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Avatar ───────────────────────────────────────────────────
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: tokens.accent.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(Icons.person_rounded, size: 44, color: tokens.accent)
                    : null,
              ),
              Container(
                decoration: BoxDecoration(
                  color: tokens.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.bg, width: 2),
                ),
                padding: const EdgeInsets.all(5),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Name ─────────────────────────────────────────────────────
        _label(tokens, l10n.adminProfileName),
        const SizedBox(height: 6),
        _field(tokens, _nameCtrl, hint: l10n.adminProfileNameHint),
        const SizedBox(height: 16),

        // ── Handle ───────────────────────────────────────────────────
        _label(tokens, '@${l10n.handle}'),
        const SizedBox(height: 6),
        _field(tokens, _handleCtrl, hint: '@username'),
        const SizedBox(height: 16),

        // ── Email (read-only) ────────────────────────────────────────
        _label(tokens, l10n.adminProfileEmail),
        const SizedBox(height: 6),
        _field(
          tokens,
          _emailCtrl,
          hint: l10n.adminProfileEmail,
          readOnly: true,
        ),
        const SizedBox(height: 16),

        // ── Phone ────────────────────────────────────────────────────
        _label(tokens, l10n.phone),
        const SizedBox(height: 6),
        _field(
          tokens,
          _phoneCtrl,
          hint: '+1 234 567 890',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // ── Position ─────────────────────────────────────────────────
        _label(tokens, l10n.position),
        const SizedBox(height: 6),
        _field(tokens, _positionCtrl, hint: 'Senior Developer'),
        const SizedBox(height: 16),

        // ── Bio ──────────────────────────────────────────────────────
        _label(tokens, l10n.adminProfileBio),
        const SizedBox(height: 6),
        _field(tokens, _bioCtrl, hint: l10n.adminProfileBioHint, maxLines: 3),
        const SizedBox(height: 16),

        // ── Timezone ─────────────────────────────────────────────────
        _label(tokens, l10n.timezone),
        const SizedBox(height: 6),
        _field(tokens, _timezoneCtrl, hint: 'Africa/Cairo'),
        const SizedBox(height: 16),

        // ── Language ─────────────────────────────────────────────────
        _label(tokens, l10n.language),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              dropdownColor: tokens.bgAlt,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _language = v);
                  // Change the app locale immediately.
                  ref.read(localeProvider.notifier).setLocale(Locale(v));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Save button ──────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.save),
          ),
        ),
        // ── Danger zone: Delete Account ──────────────────────────
        const SizedBox(height: 12),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently delete your account and all associated data. '
          'After requesting deletion, you have 7 days to log in and cancel.',
          style: TextStyle(fontSize: 12, color: tokens.fgDim, height: 1.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteDialog(tokens),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _showDeleteDialog(OrchestraColorTokens tokens) async {
    final passwordCtrl = TextEditingController();
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: tokens.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(color: tokens.fgBright, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account will be deactivated immediately. After 7 days, '
                'all data will be permanently deleted. Log in again within '
                '7 days to cancel.',
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                style: TextStyle(color: tokens.fgBright),
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  labelStyle: TextStyle(color: tokens.fgDim),
                  filled: true,
                  fillColor: tokens.bgAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordCtrl.text.isEmpty) {
                  setDialogState(() => error = 'Password is required');
                  return;
                }
                try {
                  final dio = ref.read(dioProvider);
                  await dio.delete<Map<String, dynamic>>(
                    Endpoints.authDeleteAccount,
                    data: {'password': passwordCtrl.text},
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on DioException catch (e) {
                  setDialogState(() {
                    error = e.response?.data?['error']?.toString() ?? 'Failed';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
    passwordCtrl.dispose();
  }

  Widget _label(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.fgDim,
      letterSpacing: 0.4,
    ),
  );

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
