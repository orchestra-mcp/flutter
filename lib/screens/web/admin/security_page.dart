import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Providers ────────────────────────────────────────────────────────────────

/// Fetches the list of active sessions from the settings API.
final _sessionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.listSettingsSessions();
});

/// Fetches security-related admin settings (category = "security").
final _securitySettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.listAdminSettings(category: 'security');
});

// ── Security page ───────────────────────────────────────────────────────────

/// Admin security settings page.
///
/// Loads active sessions from [ApiClient.listSettingsSessions] and security
/// settings from [ApiClient.listAdminSettings].  Session revocation uses
/// [ApiClient.revokeSession].  Setting toggles use [ApiClient.upsertAdminSetting].
class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final sessionsAsync = ref.watch(_sessionsProvider);
    final settingsAsync = ref.watch(_securitySettingsProvider);

    return ColoredBox(
      color: tokens.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text(
              AppLocalizations.of(context).securityTitle,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // ── Settings section ────────────────────────────────────────────
          _SectionHeader(tokens: tokens, title: AppLocalizations.of(context).authentication),
          const SizedBox(height: 12),
          settingsAsync.when(
            loading: () => _LoadingRow(tokens: tokens),
            error: (e, _) => _InlineError(tokens: tokens, message: '$e'),
            data: (data) => _SecuritySettings(tokens: tokens, data: data, ref: ref),
          ),
          const SizedBox(height: 32),

          // ── Active sessions ─────────────────────────────────────────────
          _SectionHeader(tokens: tokens, title: AppLocalizations.of(context).activeSessionsTitle),
          const SizedBox(height: 12),
          sessionsAsync.when(
            loading: () => _LoadingRow(tokens: tokens),
            error: (e, _) => _InlineError(tokens: tokens, message: '$e'),
            data: (sessions) {
              if (sessions.isEmpty) {
                return _EmptyRow(
                  tokens: tokens,
                  message: AppLocalizations.of(context).noActiveSessionsFound,
                );
              }
              return Column(
                children: [
                  ...sessions.map((s) => _SessionTile(
                        tokens: tokens,
                        session: s,
                        onRevoke: () => _revokeSession(ref, s),
                      )),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _revokeAllOtherSessions(ref, sessions),
                      icon: Icon(Icons.logout, size: 14, color: tokens.fgDim),
                      label: Text(
                        AppLocalizations.of(context).revokeAllOtherSessions,
                        style: TextStyle(color: tokens.fgDim, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _revokeSession(
      WidgetRef ref, Map<String, dynamic> session) async {
    final id = session['id']?.toString();
    if (id == null) return;
    try {
      await ref.read(apiClientProvider).revokeSession(id);
      ref.invalidate(_sessionsProvider);
    } catch (_) {
      // Silently fail — the user will see the session still listed.
    }
  }

  Future<void> _revokeAllOtherSessions(
      WidgetRef ref, List<Map<String, dynamic>> sessions) async {
    final client = ref.read(apiClientProvider);
    for (final s in sessions) {
      final isCurrent = s['is_current'] == true;
      if (isCurrent) continue;
      final id = s['id']?.toString();
      if (id != null) {
        try {
          await client.revokeSession(id);
        } catch (_) {}
      }
    }
    ref.invalidate(_sessionsProvider);
  }
}

// ── Security settings (from API) ────────────────────────────────────────────

class _SecuritySettings extends StatelessWidget {
  const _SecuritySettings({
    required this.tokens,
    required this.data,
    required this.ref,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> data;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // The admin settings endpoint returns { "settings": [...], ... }.
    // Each setting has "key", "value", "category".
    final settings = (data['settings'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    bool getBool(String key, {bool fallback = false}) {
      final entry = settings.where((s) => s['key'] == key).firstOrNull;
      if (entry == null) return fallback;
      final v = entry['value'];
      if (v is bool) return v;
      if (v is String) return v == 'true';
      return fallback;
    }

    final enforce2fa = getBool('enforce_2fa');
    final ssoEnabled = getBool('sso_enabled');

    return Column(
      children: [
        _SettingRow(
          tokens: tokens,
          title: AppLocalizations.of(context).enforceTwoFactor,
          subtitle:
              AppLocalizations.of(context).requireAll2fa,
          trailing: Switch.adaptive(
            value: enforce2fa,
            onChanged: (_) => _toggleSetting('enforce_2fa', !enforce2fa),
            activeTrackColor: tokens.accent,
          ),
        ),
        const SizedBox(height: 8),
        _SettingRow(
          tokens: tokens,
          title: AppLocalizations.of(context).singleSignOnSso,
          subtitle: AppLocalizations.of(context).enableSamlSso,
          trailing: Switch.adaptive(
            value: ssoEnabled,
            onChanged: (_) => _toggleSetting('sso_enabled', !ssoEnabled),
            activeTrackColor: tokens.accent,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSetting(String key, bool value) async {
    try {
      await ref.read(apiClientProvider).upsertAdminSetting({
        'key': key,
        'value': value.toString(),
        'category': 'security',
      });
      ref.invalidate(_securitySettingsProvider);
    } catch (_) {}
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.tokens, required this.title});
  final OrchestraColorTokens tokens;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final OrchestraColorTokens tokens;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.fgDim, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.tokens,
    required this.session,
    required this.onRevoke,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final isCurrent = session['is_current'] == true;
    final device = session['device'] as String? ??
        session['user_agent'] as String? ??
        AppLocalizations.of(context).unknownDevice;
    final ip = session['ip'] as String? ?? '';
    final lastActive = session['last_active'] as String? ??
        session['last_active_at'] as String? ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? tokens.accent.withValues(alpha: 0.3)
              : tokens.border,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.devices_outlined, size: 18, color: tokens.fgDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context).currentLabel,
                          style: TextStyle(
                            color: tokens.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (ip.isNotEmpty || lastActive.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [ip, lastActive].where((s) => s.isNotEmpty).join('  -  '),
                    style: TextStyle(color: tokens.fgDim, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: Icon(Icons.logout, size: 16, color: tokens.fgDim),
              tooltip: AppLocalizations.of(context).revokeSessionTooltip,
              onPressed: onRevoke,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.accent,
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        message,
        style: TextStyle(color: tokens.fgDim, fontSize: 12),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.tokens, required this.message});
  final OrchestraColorTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      ),
    );
  }
}
