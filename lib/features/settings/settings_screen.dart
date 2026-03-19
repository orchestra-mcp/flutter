import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Root settings screen — a full-screen list of section groups.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(l10n.account, tokens: tokens),
          _SettingsTile(
            label: l10n.profile,
            icon: Icons.person_outline,
            onTap: () => context.push('/settings/profile'),
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.teamAndWorkspace,
            icon: Icons.group_outlined,
            onTap: () => context.push('/settings/team'),
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.notifications,
            icon: Icons.notifications_outlined,
            onTap: () => context.push('/settings/notifications'),
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _SectionHeader(l10n.appearance, tokens: tokens),
          _SettingsTile(
            label: l10n.themes,
            icon: Icons.palette_outlined,
            onTap: () => context.push('/settings/appearance'),
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _SectionHeader(l10n.security, tokens: tokens),
          _SettingsTile(
            label: l10n.password,
            icon: Icons.lock_outline,
            onTap: () => context.push('/settings/security'),
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.twoFactorAuth,
            icon: Icons.security,
            onTap: () {},
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.passkeys,
            icon: Icons.fingerprint,
            onTap: () {},
            tokens: tokens,
          ),
          const SizedBox(height: 8),
          _SectionHeader(l10n.about, tokens: tokens),
          _SettingsTile(
            label: l10n.version,
            icon: Icons.info_outline,
            onTap: () {},
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.help,
            icon: Icons.help_outline,
            onTap: () {},
            tokens: tokens,
          ),
          _SettingsTile(
            label: l10n.privacy,
            icon: Icons.privacy_tip_outlined,
            onTap: () {},
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {required this.tokens});
  final String title;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: tokens.fgDim,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.tokens,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: tokens.accent, size: 22),
    title: Text(label, style: TextStyle(color: tokens.fgBright, fontSize: 15)),
    trailing: Icon(Icons.chevron_right, color: tokens.fgDim, size: 18),
    onTap: onTap,
  );
}
