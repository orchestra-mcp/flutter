import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/screens/settings/tabs/about_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_agents_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_contact_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_discord_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_download_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_email_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_features_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_general_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_github_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_homepage_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_integrations_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_pricing_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_prompts_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_seo_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_slack_tab.dart';
import 'package:orchestra/screens/settings/tabs/admin_social_tab.dart';
import 'package:orchestra/screens/settings/tabs/api_tokens_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/appearance_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/desktop_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/health_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/integrations_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/notifications_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/passkeys_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/password_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/profile_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/security_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/sessions_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/social_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/team_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/agent_instructions_tab.dart';
import 'package:orchestra/screens/settings/tabs/claude_settings_tab.dart';
import 'package:orchestra/screens/settings/tabs/two_factor_settings_tab.dart';

/// Route-based settings screen.
///
/// On mobile, `/settings` shows an Apple Health-style grouped menu with a
/// profile card at the top. Tapping an item pushes to the sub-route.
///
/// On desktop/web, the sidebar drives navigation to sub-routes like
/// `/settings/profile`. This screen renders the matching tab widget.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    // On mobile, if the route is exactly /settings (no sub-route), show menu.
    final showMobileMenu = isMobile && location == Routes.settings;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: tokens.fgMuted, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.summary);
            }
          },
        ),
        title: Text(
          _titleForRoute(location, AppLocalizations.of(context)),
          style: TextStyle(
            color: tokens.fgBright,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: showMobileMenu ? const _MobileSettingsMenu() : _tabForRoute(location),
    );
  }

  String _titleForRoute(String location, AppLocalizations l10n) {
    if (location == Routes.settings) return l10n.settings;
    if (location.startsWith('/settings/admin-')) return l10n.settingsAdministration;
    if (location == Routes.settingsProfile) return l10n.settingsProfile;
    if (location == Routes.settingsPassword) return l10n.settingsPasswordNav;
    if (location == Routes.settingsAppearance) return l10n.settingsAppearance;
    if (location == Routes.settingsTwoFactor) return l10n.settingsTwoFactor;
    if (location == Routes.settingsPasskeys) return l10n.settingsPasskeys;
    if (location == Routes.settingsSessions) return l10n.settingsSessions;
    if (location == Routes.settingsSecurity) return l10n.settingsSecurity;
    if (location == Routes.settingsApiTokens) return l10n.settingsApiTokens;
    if (location == Routes.settingsIntegrations) return l10n.settingsIntegrations;
    if (location == Routes.settingsNotifications) return l10n.settingsNotificationsNav;
    if (location == Routes.settingsHealth) return l10n.settingsHealthNav;
    if (location == Routes.settingsDesktop) return l10n.settingsDesktop;
    if (location == Routes.settingsAbout) return l10n.settingsAbout;
    if (location == Routes.settingsTeam) return l10n.settingsTeam;
    if (location == Routes.settingsSocial) return l10n.settingsSocialNav;
    if (location == Routes.settingsAgentInstructions) return l10n.settingsAgentInstructions;
    if (location == Routes.settingsClaudeSettings) return l10n.settingsClaudeSettings;
    return l10n.settings;
  }

  Widget _tabForRoute(String location) {
    return switch (location) {
      Routes.settingsProfile => const ProfileSettingsTab(),
      Routes.settingsPassword => const PasswordSettingsTab(),
      Routes.settingsAppearance => const AppearanceSettingsTab(),
      Routes.settingsTwoFactor => const TwoFactorSettingsTab(),
      Routes.settingsPasskeys => const PasskeysSettingsTab(),
      Routes.settingsSessions => const SessionsSettingsTab(),
      Routes.settingsSecurity => const SecuritySettingsTab(),
      Routes.settingsApiTokens => const ApiTokensSettingsTab(),
      Routes.settingsIntegrations => const IntegrationsSettingsTab(),
      Routes.settingsNotifications => const NotificationsSettingsTab(),
      Routes.settingsHealth => const HealthSettingsTab(),
      Routes.settingsTeam => const TeamSettingsTab(),
      Routes.settingsDesktop => const DesktopSettingsTab(),
      Routes.settingsAbout => const AboutSettingsTab(),
      Routes.settingsSocial => const SocialSettingsTab(),
      Routes.settingsAdminGeneral => const AdminGeneralTab(),
      Routes.settingsAdminFeatures => const AdminFeaturesTab(),
      Routes.settingsAdminHomepage => const AdminHomepageTab(),
      Routes.settingsAdminAgents => const AdminAgentsTab(),
      Routes.settingsAdminEmail => const AdminEmailTab(),
      Routes.settingsAdminContact => const AdminContactTab(),
      Routes.settingsAdminPricing => const AdminPricingTab(),
      Routes.settingsAdminDownload => const AdminDownloadTab(),
      Routes.settingsAdminIntegrations => const AdminIntegrationsTab(),
      Routes.settingsAdminSeo => const AdminSeoTab(),
      Routes.settingsAdminDiscord => const AdminDiscordTab(),
      Routes.settingsAdminSlack => const AdminSlackTab(),
      Routes.settingsAdminGithub => const AdminGithubTab(),
      Routes.settingsAdminSocial => const AdminSocialTab(),
      Routes.settingsAdminPrompts => const AdminPromptsTab(),
      Routes.settingsAgentInstructions => const AgentInstructionsTab(),
      Routes.settingsClaudeSettings => const ClaudeSettingsTab(),
      _ => const ProfileSettingsTab(),
    };
  }
}

// ── Mobile settings menu (Apple Health style) ────────────────────────────────

class _MobileSettingsMenu extends ConsumerWidget {
  const _MobileSettingsMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider).value;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final fullName = user?.name ?? 'User';
    final avatarUrl = resolveAvatarUrl(user?.avatarUrl);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),

        // ── Profile card ─────────────────────────────────────────
        _ProfileCard(
          name: fullName,
          avatarUrl: avatarUrl,
          onTap: () => context.push(Routes.settingsProfile),
        ),

        const SizedBox(height: 28),

        // ── Account ──────────────────────────────────────────────
        _SectionHeader(label: l10n.settingsAccount, tokens: tokens),
        const SizedBox(height: 6),
        _SettingsGroup(tokens: tokens, items: [
          _SettingsItem(Icons.person_outline_rounded, l10n.settingsProfile, Routes.settingsProfile),
          _SettingsItem(Icons.palette_outlined, l10n.settingsAppearance, Routes.settingsAppearance),
          _SettingsItem(Icons.lock_outline_rounded, l10n.settingsPasswordNav, Routes.settingsPassword),
          _SettingsItem(Icons.share_outlined, l10n.settingsSocialNav, Routes.settingsSocial),
        ]),

        const SizedBox(height: 28),

        // ── Security ─────────────────────────────────────────────
        _SectionHeader(label: l10n.settingsSecurity, tokens: tokens),
        const SizedBox(height: 6),
        _SettingsGroup(tokens: tokens, items: [
          _SettingsItem(Icons.security_rounded, l10n.settingsSecurity, Routes.settingsSecurity),
          _SettingsItem(Icons.phonelink_lock_rounded, l10n.settingsTwoFactor, Routes.settingsTwoFactor),
          _SettingsItem(Icons.fingerprint_rounded, l10n.settingsPasskeys, Routes.settingsPasskeys),
          _SettingsItem(Icons.devices_rounded, l10n.settingsSessions, Routes.settingsSessions),
        ]),

        const SizedBox(height: 28),

        // ── Features ─────────────────────────────────────────────
        _SectionHeader(label: l10n.settingsFeatures, tokens: tokens),
        const SizedBox(height: 6),
        _SettingsGroup(tokens: tokens, items: [
          _SettingsItem(Icons.notifications_outlined, l10n.settingsNotificationsNav, Routes.settingsNotifications),
          _SettingsItem(Icons.favorite_outline_rounded, l10n.settingsHealthNav, Routes.settingsHealth),
          _SettingsItem(Icons.extension_outlined, l10n.settingsIntegrations, Routes.settingsIntegrations),
          if (isDesktop)
            _SettingsItem(Icons.desktop_mac_outlined, l10n.settingsDesktop, Routes.settingsDesktop),
        ]),

        const SizedBox(height: 28),

        // ── Developer ────────────────────────────────────────────
        _SectionHeader(label: l10n.settingsDeveloper, tokens: tokens),
        const SizedBox(height: 6),
        _SettingsGroup(tokens: tokens, items: [
          _SettingsItem(Icons.vpn_key_outlined, l10n.settingsApiTokens, Routes.settingsApiTokens),
          _SettingsItem(Icons.psychology_outlined, l10n.settingsAgentInstructions, Routes.settingsAgentInstructions),
          _SettingsItem(Icons.tune_outlined, l10n.settingsClaudeSettings, Routes.settingsClaudeSettings),
        ]),

        const SizedBox(height: 28),

        // ── About ────────────────────────────────────────────────
        _SettingsGroup(tokens: tokens, items: [
          _SettingsItem(Icons.info_outline_rounded, l10n.settingsAbout, Routes.settingsAbout),
          _SettingsItem(Icons.bug_report_outlined, l10n.settingsReportIssue, Routes.settingsReportIssue),
        ]),

        const SizedBox(height: 28),

        // ── Sign out ─────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            ref.read(authProvider.notifier).logout();
            context.go(Routes.login);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 60),
      ],
    );
  }
}

// ── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, this.avatarUrl, required this.onTap});

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: tokens.accent.withValues(alpha: 0.15),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: tokens.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tokens});

  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: tokens.fgBright,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ── Settings group (rounded card with rows) ──────────────────────────────────

class _SettingsItem {
  const _SettingsItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.tokens, required this.items});

  final OrchestraColorTokens tokens;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SettingsRow(item: items[i], tokens: tokens),
            if (i < items.length - 1)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 52,
                color: tokens.borderFaint,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item, required this.tokens});

  final _SettingsItem item;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(item.icon, color: tokens.fgMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(color: tokens.fgBright, fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.fgDim, size: 20),
          ],
        ),
      ),
    );
  }
}

