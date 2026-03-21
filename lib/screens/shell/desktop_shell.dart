import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/health/health_brief_generator.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/state/selection_state.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/storage/local_database.dart';
import 'package:orchestra/core/storage/repositories/note_repository.dart';
import 'package:orchestra/core/storage/pin_store.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/team/team_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/theme/theme_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';
import 'package:orchestra/features/devtools/providers/database_browser_provider.dart';
import 'package:orchestra/features/devtools/providers/devtools_selection_provider.dart';
import 'package:orchestra/features/devtools/providers/devtools_startup_provider.dart';
import 'package:orchestra/features/devtools/providers/log_runner_provider.dart';
import 'package:orchestra/features/devtools/providers/prompts_provider.dart';
import 'package:orchestra/features/devtools/providers/secrets_provider.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/projects/projects_screen.dart';
import 'package:orchestra/screens/tray/workspace_switcher.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/smart_action_dialog.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/spotlight_search.dart';
import 'package:orchestra/widgets/update_banner.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _kRailWidth = 64.0;
const _kSidebarWidth = 260.0;
const _kHeaderHeight = 52.0;

// ── Sidebar state ───────────────────────────────────────────────────────────

/// Tracks whether the sidebar panel is open.
class _SidebarVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final sidebarVisibleProvider = NotifierProvider<_SidebarVisible, bool>(
  _SidebarVisible.new,
);

/// Tracks which sidebar section is currently shown (independent of route).
class _SidebarSection extends Notifier<_SidebarType> {
  @override
  _SidebarType build() => _SidebarType.dashboard;
  void set(_SidebarType value) => state = value;
}

final _sidebarSectionProvider = NotifierProvider<_SidebarSection, _SidebarType>(
  _SidebarSection.new,
);

// ── Icon rail destinations ───────────────────────────────────────────────────

class _RailDest {
  const _RailDest({
    required this.icon,
    required this.label,
    required this.route,
    required this.sidebar,
  });
  final IconData icon;
  final String label;
  final String route;
  final _SidebarType sidebar;
}

const _railDestinations = [
  _RailDest(
    icon: Icons.home_rounded,
    label: 'Summary',
    route: Routes.summary,
    sidebar: _SidebarType.dashboard,
  ),
  _RailDest(
    icon: Icons.sticky_note_2_rounded,
    label: 'Notes',
    route: Routes.notes,
    sidebar: _SidebarType.notes,
  ),
  _RailDest(
    icon: Icons.folder_rounded,
    label: 'Projects',
    route: Routes.projects,
    sidebar: _SidebarType.projects,
  ),
  _RailDest(
    icon: Icons.smart_toy_rounded,
    label: 'Agents',
    route: Routes.agents,
    sidebar: _SidebarType.agents,
  ),
  _RailDest(
    icon: Icons.bolt_rounded,
    label: 'Skills',
    route: Routes.skills,
    sidebar: _SidebarType.skills,
  ),
  _RailDest(
    icon: Icons.account_tree_rounded,
    label: 'Workflows',
    route: Routes.workflows,
    sidebar: _SidebarType.workflows,
  ),
  _RailDest(
    icon: Icons.menu_book_rounded,
    label: 'Docs',
    route: Routes.docs,
    sidebar: _SidebarType.docs,
  ),
  _RailDest(
    icon: Icons.sync_alt_rounded,
    label: 'Delegations',
    route: Routes.delegations,
    sidebar: _SidebarType.delegations,
  ),
  _RailDest(
    icon: Icons.api_rounded,
    label: 'API',
    route: Routes.devtoolsApi,
    sidebar: _SidebarType.apiCollections,
  ),
  _RailDest(
    icon: Icons.storage_rounded,
    label: 'Database',
    route: Routes.devtoolsDatabase,
    sidebar: _SidebarType.database,
  ),
  _RailDest(
    icon: Icons.receipt_long_rounded,
    label: 'Log Runner',
    route: Routes.devtoolsLogs,
    sidebar: _SidebarType.logRunner,
  ),
  _RailDest(
    icon: Icons.vpn_key_rounded,
    label: 'Secrets',
    route: Routes.devtoolsSecrets,
    sidebar: _SidebarType.secrets,
  ),
  _RailDest(
    icon: Icons.chat_bubble_outline_rounded,
    label: 'Prompts',
    route: Routes.devtoolsPrompts,
    sidebar: _SidebarType.prompts,
  ),
  _RailDest(
    icon: Icons.terminal_rounded,
    label: 'Terminal',
    route: Routes.terminal,
    sidebar: _SidebarType.terminal,
  ),
  _RailDest(
    icon: Icons.favorite_rounded,
    label: 'Health',
    route: Routes.health,
    sidebar: _SidebarType.health,
  ),
];

// Footer rail items (settings, admin)
const _railFooterDestinations = [
  _RailDest(
    icon: Icons.settings_rounded,
    label: 'Settings',
    route: Routes.settings,
    sidebar: _SidebarType.settings,
  ),
  _RailDest(
    icon: Icons.admin_panel_settings,
    label: 'Admin',
    route: Routes.admin,
    sidebar: _SidebarType.admin,
  ),
];

String _localizedRailLabel(
  AppLocalizations l10n,
  int index, {
  bool isFooter = false,
}) {
  if (isFooter) {
    const footerKeys = ['settings', 'admin'];
    final labels = [l10n.settings, l10n.admin];
    return index < labels.length ? labels[index] : footerKeys[index];
  }
  final labels = [
    l10n.summary,
    l10n.notes,
    l10n.projects,
    l10n.agents,
    l10n.skills,
    l10n.workflows,
    l10n.docs,
    l10n.delegations,
    'API',
    'Database',
    'Log Runner',
    'Secrets',
    'Prompts',
    l10n.terminal,
    l10n.health,
  ];
  return index < labels.length ? labels[index] : _railDestinations[index].label;
}

int _railIndexFromLocation(String location) {
  for (int i = 0; i < _railDestinations.length; i++) {
    if (location.startsWith(_railDestinations[i].route)) return i;
  }
  // Check footer destinations (offset by main count)
  for (int i = 0; i < _railFooterDestinations.length; i++) {
    if (location.startsWith(_railFooterDestinations[i].route)) {
      return _railDestinations.length + i;
    }
  }
  return 0;
}

int _railIndexFromSidebarType(_SidebarType type) {
  for (int i = 0; i < _railDestinations.length; i++) {
    if (_railDestinations[i].sidebar == type) return i;
  }
  for (int i = 0; i < _railFooterDestinations.length; i++) {
    if (_railFooterDestinations[i].sidebar == type) {
      return _railDestinations.length + i;
    }
  }
  return -1; // no match — don't highlight any rail icon
}

// ── Sidebar type detection ───────────────────────────────────────────────────

enum _SidebarType {
  dashboard,
  notes,
  projects,
  agents,
  skills,
  workflows,
  docs,
  delegations,
  apiCollections,
  database,
  logRunner,
  secrets,
  prompts,
  terminal,
  health,
  settings,
  admin,
  none,
}

// ── DesktopShell ─────────────────────────────────────────────────────────────

class DesktopShell extends ConsumerWidget {
  const DesktopShell({
    super.key,
    required this.child,
    this.canShowSidebar = true,
  });

  final Widget child;

  /// Whether the viewport is wide enough to show a sidebar (>= 900 px).
  /// Actual visibility also depends on [sidebarVisibleProvider].
  final bool canShowSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final sidebarSection = ref.watch(_sidebarSectionProvider);
    final sidebarOpen = ref.watch(sidebarVisibleProvider);
    final showSidebar = canShowSidebar && sidebarOpen;

    // Prefetch DevTools data at shell startup so sidebar counts and screens
    // are instantly ready when the user navigates to DevTools.
    ref.watch(devtoolsPrefetchProvider);

    // Rail highlights the sidebar section (not the route).
    final railIndex = sidebarOpen
        ? _railIndexFromSidebarType(sidebarSection)
        : _railIndexFromLocation(location);

    // Total width for the animated sidebar region (panel + divider).
    final sidebarTargetWidth = showSidebar ? _kSidebarWidth + 1.0 : 0.0;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              showSpotlightSearch(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              showSpotlightSearch(context, ref),
        },
        child: Focus(
          autofocus: true,
          child: Row(
            children: [
              // Icon rail
              _IconRail(
                tokens: tokens,
                selectedIndex: railIndex,
                onSelect: (i) {
                  final dest = i < _railDestinations.length
                      ? _railDestinations[i]
                      : _railFooterDestinations[i - _railDestinations.length];
                  final section = dest.sidebar;
                  final sidebar = ref.read(sidebarVisibleProvider.notifier);

                  // Home icon: always navigate to dashboard, no sidebar
                  if (section == _SidebarType.dashboard) {
                    sidebar.set(false);
                    context.go(dest.route);
                    return;
                  }

                  // Always navigate to the route
                  context.go(dest.route);

                  final currentSection = ref.read(_sidebarSectionProvider);
                  if (section == currentSection && sidebarOpen) {
                    // Same icon clicked again: toggle sidebar
                    sidebar.toggle();
                  } else {
                    // Different icon: open its sidebar
                    ref.read(_sidebarSectionProvider.notifier).set(section);
                    sidebar.set(true);
                  }
                },
              ),
              VerticalDivider(thickness: 1, width: 1, color: tokens.border),
              // Sidebar (animated slide)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: sidebarTargetWidth,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    maxWidth: _kSidebarWidth + 1.0,
                    minWidth: _kSidebarWidth + 1.0,
                    child: Row(
                      children: [
                        _SidebarPanel(
                          tokens: tokens,
                          type: sidebarSection,
                          location: location,
                        ),
                        VerticalDivider(
                          thickness: 1,
                          width: 1,
                          color: tokens.border,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Header + content
              Expanded(
                child: Column(
                  children: [
                    _HeaderBar(tokens: tokens),
                    Divider(height: 1, color: tokens.borderFaint),
                    const UpdateBanner(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon Rail ────────────────────────────────────────────────────────────────

class _IconRail extends ConsumerWidget {
  const _IconRail({
    required this.tokens,
    required this.selectedIndex,
    required this.onSelect,
  });

  final OrchestraColorTokens tokens;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';
    final footerDests = isAdmin
        ? _railFooterDestinations
        : _railFooterDestinations
              .where((d) => d.route != Routes.admin)
              .toList();

    return Container(
      width: _kRailWidth,
      color: tokens.bg,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // App logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nav items
          Expanded(
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (int i = 0; i < _railDestinations.length; i++)
                      _IconRailItem(
                        tokens: tokens,
                        icon: _railDestinations[i].icon,
                        label: _localizedRailLabel(l10n, i),
                        isSelected: i == selectedIndex,
                        onTap: () => onSelect(i),
                      ),
                  ],
                );
              },
            ),
          ),
          // Footer items (settings, admin only for admin role)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      height: 1,
                      indent: 12,
                      endIndent: 12,
                      color: tokens.border,
                    ),
                    const SizedBox(height: 4),
                    for (int i = 0; i < footerDests.length; i++)
                      _IconRailItem(
                        tokens: tokens,
                        icon: footerDests[i].icon,
                        label: _localizedRailLabel(l10n, i, isFooter: true),
                        isSelected:
                            (_railDestinations.length + i) == selectedIndex,
                        onTap: () => onSelect(_railDestinations.length + i),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IconRailItem extends StatelessWidget {
  const _IconRailItem({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final OrchestraColorTokens tokens;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: Material(
          color: isSelected ? tokens.accentSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: tokens.border.withValues(alpha: 0.2),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? tokens.accent : tokens.fgMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header Bar ───────────────────────────────────────────────────────────────

void _handleUniversalCreate(
  BuildContext context,
  WidgetRef ref,
  UniversalActionType type,
  String title,
  String content,
) {
  switch (type) {
    case UniversalActionType.note:
      if (content.isNotEmpty) {
        ref.read(noteRepositoryProvider).create(title: title, content: content);
        ref.read(notesRefreshProvider.notifier).refresh();
      } else {
        context.push('${Routes.notes}/new');
      }
    case UniversalActionType.agent:
      if (content.isNotEmpty) {
        ref.read(apiClientProvider).createAgent({
          'name': title,
          'content': content,
        });
        ref.invalidate(agentsProvider);
      } else {
        context.push('/library/agents/new');
      }
    case UniversalActionType.skill:
      if (content.isNotEmpty) {
        ref.read(apiClientProvider).createSkill({
          'name': title,
          'description': content,
        });
        ref.invalidate(skillsProvider);
      } else {
        context.push('/library/skills/new');
      }
    case UniversalActionType.workflow:
      context.push('/library/workflows/new');
    case UniversalActionType.doc:
      if (content.isNotEmpty) {
        ref.read(apiClientProvider).createDoc({
          'title': title,
          'content': content,
        });
        ref.invalidate(docsProvider);
      } else {
        context.push('/library/docs/new');
      }
    case UniversalActionType.feature:
      context.push('/library/features/new');
    case UniversalActionType.plan:
      context.push('/library/plans/new');
    case UniversalActionType.request:
      context.push('/library/requests/new');
    case UniversalActionType.person:
      context.push('/library/persons/new');
    case UniversalActionType.healthBrief:
      final generator = HealthBriefGenerator(ref as Ref);
      generator.generateAndSave().then((noteId) {
        if (noteId != null && context.mounted) {
          context.push('${Routes.notes}/$noteId');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating health brief...'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _HeaderBar extends ConsumerWidget {
  const _HeaderBar({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tokens.bg.withValues(alpha: 0.72),
                tokens.bg.withValues(alpha: 0.56),
              ],
            ),
          ),
          child: Row(
            children: [
              // Workspace name
              Text(
                'Orchestra',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Search pill
              GestureDetector(
                onTap: () => showSpotlightSearch(context, ref),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.borderFaint),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, size: 16, color: tokens.fgDim),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context).searchDotDotDot,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.border.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '\u2318K',
                          style: TextStyle(color: tokens.fgDim, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Universal create (+)
              _HeaderIcon(
                tokens: tokens,
                icon: Icons.add_rounded,
                onTap: () => showUniversalCreateMenu(
                  context,
                  ref,
                  onCreate: (type, title, content) {
                    _handleUniversalCreate(context, ref, type, title, content);
                  },
                ),
              ),
              const SizedBox(width: 4),
              // Refresh
              _HeaderIcon(
                tokens: tokens,
                icon: Icons.refresh_rounded,
                onTap: () {
                  ref.invalidate(agentsProvider);
                  ref.invalidate(skillsProvider);
                  ref.invalidate(workflowsProvider);
                  ref.invalidate(docsProvider);
                  ref.invalidate(projectsProvider);
                  ref.invalidate(delegationsProvider);
                  ref.invalidate(_sidebarNotesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // Notification bell
              _HeaderIcon(
                tokens: tokens,
                icon: Icons.notifications_outlined,
                onTap: () => context.go(Routes.notifications),
              ),
              const SizedBox(width: 4),
              // Theme toggle
              _HeaderIcon(
                tokens: tokens,
                icon: theme.isLight
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                onTap: () {
                  final newId = theme.isLight ? 'midnight' : 'github-light';
                  ref.read(themeProvider.notifier).setTheme(newId);
                },
              ),
              const SizedBox(width: 8),
              // User avatar with dropdown
              _HeaderProfileDropdown(tokens: tokens, authState: authState),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header profile dropdown ─────────────────────────────────────────────────

class _HeaderProfileDropdown extends ConsumerWidget {
  const _HeaderProfileDropdown({required this.tokens, required this.authState});

  final OrchestraColorTokens tokens;
  final AsyncValue<AuthState> authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = authState.value;
    String fullName = 'User';
    String initials = 'U';
    String? avatarUrl;
    if (user is AuthAuthenticated) {
      fullName = user.user.name;
      initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
      avatarUrl = resolveAvatarUrl(user.user.avatarUrl);
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.go(Routes.settings);
          case 'logout':
            ref.read(authProvider.notifier).logout();
            context.go(Routes.login);
          case 'switch_team':
            showTeamSwitcher(context);
          case 'switch_workspace':
            showWorkspaceSwitcher(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: tokens.accent.withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: tokens.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).personalWorkspace,
                    style: TextStyle(color: tokens.fgDim, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        _popupItem(
          'settings',
          Icons.settings_outlined,
          AppLocalizations.of(context).settings,
        ),
        _popupItem(
          'switch_team',
          Icons.group_outlined,
          AppLocalizations.of(context).switchTeam,
        ),
        _popupItem(
          'switch_workspace',
          Icons.folder_outlined,
          AppLocalizations.of(context).switchWorkspace,
        ),
        const PopupMenuDivider(),
        _popupItem(
          'logout',
          Icons.logout_rounded,
          AppLocalizations.of(context).signOut,
          isDestructive: true,
        ),
      ],
      child: CircleAvatar(
        radius: 14,
        backgroundColor: tokens.accent.withValues(alpha: 0.2),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                initials,
                style: TextStyle(
                  color: tokens.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  PopupMenuEntry<String> _popupItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : tokens.fgBright;
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.tokens,
    required this.icon,
    required this.onTap,
  });

  final OrchestraColorTokens tokens;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: tokens.border.withValues(alpha: 0.2),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: tokens.fgMuted),
        ),
      ),
    );
  }
}

// ── Sidebar Panel ────────────────────────────────────────────────────────────

class _SidebarPanel extends ConsumerWidget {
  const _SidebarPanel({
    required this.tokens,
    required this.type,
    required this.location,
  });

  final OrchestraColorTokens tokens;
  final _SidebarType type;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: _kSidebarWidth,
      color: tokens.bgAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeamSwitcherBar(tokens: tokens),
          Divider(height: 1, color: tokens.borderFaint),
          _buildHeader(context, ref),
          Divider(height: 1, color: tokens.border),
          Expanded(child: _buildContent(ref, context)),
        ],
      ),
    );
  }

  void _onAdd(BuildContext context, WidgetRef ref) {
    switch (type) {
      case _SidebarType.notes:
        context.go('/library/notes/new');
      case _SidebarType.projects:
        context.go('/projects/new');
      case _SidebarType.agents:
        context.go('/library/agents/new');
      case _SidebarType.skills:
        context.go('/library/skills/new');
      case _SidebarType.workflows:
        context.go('/library/workflows/new');
      case _SidebarType.docs:
        context.go('/library/docs/new');
      case _SidebarType.apiCollections:
        _showNewCollectionDialog(context, ref);
      case _SidebarType.database:
        _showConnectDatabaseDialog(context, ref);
      case _SidebarType.logRunner:
        _showRunCommandDialog(context, ref);
      case _SidebarType.secrets:
        _showNewSecretDialog(context, ref);
      case _SidebarType.prompts:
        _showNewPromptDialog(context, ref);
      case _SidebarType.terminal:
        break; // handled by PopupMenuButton in header
      default:
        break;
    }
  }

  // ── DevTools inline dialogs ───────────────────────────────────────────────

  void _showNewCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('New Collection', style: TextStyle(color: tokens.fgBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              ctrl: nameCtrl,
              label: 'Name',
              hint: 'My API',
              tokens: tokens,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _DialogField(
              ctrl: urlCtrl,
              label: 'Base URL (optional)',
              hint: 'https://api.example.com',
              tokens: tokens,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(apiCollectionProvider.notifier)
                  .saveRequest(
                    collectionName: name,
                    name: 'Example Request',
                    method: 'GET',
                    url: urlCtrl.text.trim().isEmpty
                        ? 'https://api.example.com'
                        : urlCtrl.text.trim(),
                  );
              if (context.mounted) context.go(Routes.devtoolsApi);
            },
            child: Text('Create', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      urlCtrl.dispose();
    });
  }

  void _showConnectDatabaseDialog(BuildContext context, WidgetRef ref) {
    const drivers = ['postgres', 'sqlite', 'mysql', 'mongodb', 'redis'];
    var selectedDriver = drivers.first;
    final dsnCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text(
            'Connect Database',
            style: TextStyle(color: tokens.fgBright),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDriver,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Driver',
                  labelStyle: TextStyle(color: tokens.fgDim),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: tokens.borderFaint),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: tokens.accent),
                  ),
                ),
                items: drivers
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) =>
                    setS(() => selectedDriver = v ?? drivers.first),
              ),
              const SizedBox(height: 12),
              _DialogField(
                ctrl: dsnCtrl,
                label: 'Connection String',
                hint: 'postgres://user:pass@localhost/db',
                tokens: tokens,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
            ),
            TextButton(
              onPressed: () async {
                final dsn = dsnCtrl.text.trim();
                if (dsn.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(databaseBrowserProvider.notifier)
                      .connect(driver: selectedDriver, dsn: dsn);
                  if (context.mounted) context.go(Routes.devtoolsDatabase);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Connection failed: $e')),
                    );
                  }
                }
              },
              child: Text('Connect', style: TextStyle(color: tokens.accent)),
            ),
          ],
        ),
      ),
    ).then((_) => dsnCtrl.dispose());
  }

  void _showRunCommandDialog(BuildContext context, WidgetRef ref) {
    final cmdCtrl = TextEditingController();
    final wdCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('Run Command', style: TextStyle(color: tokens.fgBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              ctrl: cmdCtrl,
              label: 'Command',
              hint: 'npm run dev',
              tokens: tokens,
              autofocus: true,
              monospace: true,
            ),
            const SizedBox(height: 12),
            _DialogField(
              ctrl: wdCtrl,
              label: 'Working Directory (optional)',
              hint: '/path/to/project',
              tokens: tokens,
              monospace: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () async {
              final cmd = cmdCtrl.text.trim();
              if (cmd.isEmpty) return;
              Navigator.pop(ctx);
              final wd = wdCtrl.text.trim();
              final process = await ref
                  .read(logRunnerProvider.notifier)
                  .run(cmd, workingDirectory: wd.isEmpty ? null : wd);
              ref.read(selectedProcessIdProvider.notifier).select(process.id);
              if (context.mounted) context.go(Routes.devtoolsLogs);
            },
            child: Text('Run', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    ).then((_) {
      cmdCtrl.dispose();
      wdCtrl.dispose();
    });
  }

  void _showNewSecretDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('New Secret', style: TextStyle(color: tokens.fgBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              ctrl: nameCtrl,
              label: 'Name',
              hint: 'MY_API_KEY',
              tokens: tokens,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _DialogField(
              ctrl: valueCtrl,
              label: 'Value',
              hint: '••••••••',
              tokens: tokens,
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final value = valueCtrl.text;
              if (name.isEmpty || value.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(secretsProvider.notifier)
                  .createSecret(name: name, value: value);
              if (context.mounted) context.go(Routes.devtoolsSecrets);
            },
            child: Text('Save', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      valueCtrl.dispose();
    });
  }

  void _showNewPromptDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('New Prompt', style: TextStyle(color: tokens.fgBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              ctrl: titleCtrl,
              label: 'Title',
              hint: 'Daily standup',
              tokens: tokens,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            _DialogField(
              ctrl: promptCtrl,
              label: 'Prompt',
              hint: 'Summarize my tasks for today...',
              tokens: tokens,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () async {
              final t = titleCtrl.text.trim();
              final p = promptCtrl.text.trim();
              if (t.isEmpty || p.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(promptsProvider.notifier)
                  .createPrompt(title: t, prompt: p);
              if (context.mounted) context.go(Routes.devtoolsPrompts);
            },
            child: Text('Create', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    ).then((_) {
      titleCtrl.dispose();
      promptCtrl.dispose();
    });
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final title = switch (type) {
      _SidebarType.dashboard => 'Dashboard',
      _SidebarType.notes => 'Notes',
      _SidebarType.projects => 'Projects',
      _SidebarType.agents => 'Agents',
      _SidebarType.skills => 'Skills',
      _SidebarType.workflows => 'Workflows',
      _SidebarType.docs => 'Docs',
      _SidebarType.delegations => 'Delegations',
      _SidebarType.apiCollections => 'API Collections',
      _SidebarType.database => 'Database',
      _SidebarType.logRunner => 'Log Runner',
      _SidebarType.secrets => 'Secrets',
      _SidebarType.prompts => 'Prompts',
      _SidebarType.health => 'Health',
      _SidebarType.settings => 'Settings',
      _SidebarType.admin => 'Admin',
      _SidebarType.terminal => 'Terminal',
      _SidebarType.none => '',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (type == _SidebarType.terminal)
            _TerminalAddButton(tokens: tokens)
          else if (type != _SidebarType.dashboard &&
              type != _SidebarType.health &&
              type != _SidebarType.settings &&
              type != _SidebarType.none)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _onAdd(context, ref),
                borderRadius: BorderRadius.circular(6),
                hoverColor: tokens.border.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: tokens.fgMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(WidgetRef ref, BuildContext context) {
    return switch (type) {
      _SidebarType.notes => _NotesSidebar(tokens: tokens),
      _SidebarType.projects => _ProjectsSidebar(tokens: tokens),
      _SidebarType.agents => _AsyncListSidebar(
        tokens: tokens,
        provider: agentsProvider,
        nameKey: 'name',
        iconData: Icons.smart_toy_rounded,
        emptyMessage: 'No agents',
        selectionProvider: agentsSelectionProvider,
        pinProvider: agentsPinProvider,
        descriptionKey: 'description',
        basePath: '/library/agents',
        entityType: 'agent',
        onTap: (item) => context.go('/library/agents/${item['id']}'),
      ),
      _SidebarType.skills => _AsyncListSidebar(
        tokens: tokens,
        provider: skillsProvider,
        nameKey: 'name',
        iconData: Icons.bolt_rounded,
        emptyMessage: 'No skills',
        selectionProvider: skillsSelectionProvider,
        pinProvider: skillsPinProvider,
        descriptionKey: 'description',
        basePath: '/library/skills',
        entityType: 'skill',
        onTap: (item) => context.go('/library/skills/${item['id']}'),
      ),
      _SidebarType.workflows => _AsyncListSidebar(
        tokens: tokens,
        provider: workflowsProvider,
        nameKey: 'description',
        iconData: Icons.account_tree_rounded,
        emptyMessage: 'No workflows',
        selectionProvider: workflowsSelectionProvider,
        pinProvider: workflowsPinProvider,
        descriptionKey: 'name',
        basePath: '/library/workflows',
        entityType: 'workflow',
        onTap: (item) => context.go('/library/workflows/${item['id']}'),
      ),
      _SidebarType.docs => _AsyncListSidebar(
        tokens: tokens,
        provider: docsProvider,
        nameKey: 'title',
        iconData: Icons.menu_book_rounded,
        emptyMessage: 'No docs',
        selectionProvider: docsSelectionProvider,
        pinProvider: docsPinProvider,
        descriptionKey: 'path',
        basePath: '/library/docs',
        entityType: 'doc',
        onTap: (item) => context.go('/library/docs/${item['id']}'),
      ),
      _SidebarType.delegations => _AsyncListSidebar(
        tokens: tokens,
        provider: delegationsProvider,
        nameKey: 'question',
        iconData: Icons.sync_alt_rounded,
        emptyMessage: 'No delegations',
        selectionProvider: delegationsSelectionProvider,
        pinProvider: delegationsPinProvider,
        basePath: '/library/delegations',
        onTap: (item) => context.go('/library/delegations/${item['id'] ?? ''}'),
      ),
      _SidebarType.dashboard => _DashboardSidebar(tokens: tokens),
      _SidebarType.apiCollections => _ApiCollectionsSidebar(tokens: tokens),
      _SidebarType.database => _DatabaseSidebar(tokens: tokens),
      _SidebarType.logRunner => _LogRunnerSidebar(tokens: tokens),
      _SidebarType.secrets => _SecretsSidebar(tokens: tokens),
      _SidebarType.prompts => _PromptsSidebar(tokens: tokens),
      _SidebarType.health => _HealthSidebar(tokens: tokens),
      _SidebarType.settings => _SettingsSidebar(tokens: tokens),
      _SidebarType.admin => _AdminSidebar(tokens: tokens),
      _SidebarType.terminal => _TerminalSidebar(tokens: tokens),
      _SidebarType.none => const SizedBox.shrink(),
    };
  }
}

// ── Team Switcher Bar ────────────────────────────────────────────────────────

class _TeamSwitcherBar extends ConsumerWidget {
  const _TeamSwitcherBar({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final activeTeam = ref.watch(activeTeamProvider);

    return teamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (teams) {
        if (teams.length <= 1 && teams.first.id == 'personal') {
          return _teamTile(activeTeam, showChevron: false);
        }
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: tokens.bgAlt,
          surfaceTintColor: Colors.transparent,
          onSelected: (id) {
            ref.read(activeTeamIdProvider.notifier).set(id);
          },
          itemBuilder: (_) => [
            for (final team in teams)
              PopupMenuItem<String>(
                value: team.id,
                child: Row(
                  children: [
                    buildTeamAvatar(team, size: 24, tokens: tokens),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team.name,
                        style: TextStyle(
                          color: team.id == activeTeam.id
                              ? tokens.fgBright
                              : tokens.fgMuted,
                          fontSize: 13,
                          fontWeight: team.id == activeTeam.id
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (team.id == activeTeam.id)
                      Icon(Icons.check_rounded, size: 16, color: tokens.accent),
                  ],
                ),
              ),
          ],
          child: _teamTile(activeTeam, showChevron: true),
        );
      },
    );
  }

  Widget _teamTile(Team team, {required bool showChevron}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          buildTeamAvatar(team, size: 28, tokens: tokens),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              team.name,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showChevron)
            Icon(Icons.unfold_more_rounded, size: 16, color: tokens.fgDim),
        ],
      ),
    );
  }
}

// ── Sidebar item ─────────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.tokens,
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.isSelected = false,
    this.isChecked = false,
    this.isPinned = false,
    required this.onTap,
    this.onSelect,
    this.contextMenuActions = const [],
    this.onPin,
    this.onDelete,
  });

  final OrchestraColorTokens tokens;
  final IconData icon;
  final String label;
  final String? subtitle;

  /// Optional accent colour for the leading icon background.
  final Color? iconColor;

  /// Whether this item matches the current route (highlight).
  final bool isSelected;

  /// Whether this item is in multi-select mode (checkbox shown).
  final bool isChecked;

  /// Whether this item is pinned (gold pin badge).
  final bool isPinned;

  final VoidCallback onTap;

  /// Called to toggle selection (desktop/web long-press).
  final VoidCallback? onSelect;

  /// Context menu actions shown on right-click and mobile long-press.
  final List<GlassListTileAction> contextMenuActions;

  /// Called on swipe-right (pin gesture).
  final VoidCallback? onPin;

  /// Called on swipe-left + confirm (delete gesture).
  final VoidCallback? onDelete;

  void _handleLongPress(BuildContext context) {
    if (isMobile) {
      if (contextMenuActions.isNotEmpty) {
        _showMobileContextSheet(context);
      }
    } else {
      onSelect?.call();
    }
  }

  void _showContextMenuAt(BuildContext context, Offset position) {
    if (contextMenuActions.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: contextMenuActions.map((a) {
        final color = a.isDestructive
            ? const Color(0xFFDC2626)
            : tokens.fgBright;
        return PopupMenuItem<void>(
          onTap: a.onTap,
          child: Row(
            children: [
              Icon(a.icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(a.label, style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
      color: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showMobileContextSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            ...contextMenuActions.map((a) {
              final color = a.isDestructive
                  ? const Color(0xFFDC2626)
                  : tokens.fgBright;
              return ListTile(
                leading: Icon(a.icon, color: color, size: 20),
                title: Text(a.label, style: TextStyle(color: color)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  a.onTap();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(
          AppLocalizations.of(context).deleteItemTitle(label),
          style: TextStyle(color: tokens.fgBright),
        ),
        content: Text(
          AppLocalizations.of(context).deleteConfirm,
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: tokens.fgMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: GestureDetector(
        onLongPress: contextMenuActions.isNotEmpty || onSelect != null
            ? () => _handleLongPress(context)
            : null,
        onSecondaryTapUp: contextMenuActions.isNotEmpty
            ? (details) => _showContextMenuAt(context, details.globalPosition)
            : null,
        child: Material(
          color: isChecked
              ? tokens.accent.withValues(alpha: 0.12)
              : isSelected
              ? tokens.accentSurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: tokens.border.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Leading: checkbox in selection mode, icon otherwise
                  if (isChecked)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: tokens.accent,
                      ),
                    )
                  else
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                (isSelected
                                        ? tokens.accent
                                        : iconColor ?? tokens.fgMuted)
                                    .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            icon,
                            size: 15,
                            color: isSelected
                                ? tokens.accent
                                : iconColor ?? tokens.fgMuted,
                          ),
                        ),
                        if (isPinned)
                          const Positioned(
                            top: -3,
                            right: -3,
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 8,
                              color: Color(0xFFD97706),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: subtitle != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? tokens.accent
                                      : tokens.fgBright,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: tokens.fgDim,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? tokens.accent
                                  : tokens.fgBright,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-pin / swipe-to-delete
    if (onPin != null || onDelete != null) {
      content = Dismissible(
        key: ValueKey('sidebar_$label'),
        direction: onDelete != null && onPin != null
            ? DismissDirection.horizontal
            : onPin != null
            ? DismissDirection.startToEnd
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: Color(0xFFD97706),
          ),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete_rounded,
            size: 16,
            color: Color(0xFFDC2626),
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onPin?.call();
            return false;
          }
          // Perform deletion inside confirmDismiss and return false so the
          // Dismissible never enters the "dismissed but still in tree" state.
          // The parent rebuild from removeSession() removes the widget.
          final confirmed = await _confirmDelete(context);
          if (confirmed) onDelete?.call();
          return false;
        },
        child: content,
      );
    }

    return content;
  }
}

// ── Sidebar selection header ─────────────────────────────────────────────────

class _SidebarSelectionHeader extends StatelessWidget {
  const _SidebarSelectionHeader({
    required this.tokens,
    required this.count,
    required this.onClear,
    this.onSelectAll,
    this.onDelete,
  });

  final OrchestraColorTokens tokens;
  final int count;
  final VoidCallback onClear;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: tokens.borderFaint)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: tokens.fgMuted),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          Text(
            '$count selected',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onSelectAll != null)
            IconButton(
              icon: Icon(
                Icons.select_all_rounded,
                size: 16,
                color: tokens.fgMuted,
              ),
              onPressed: onSelectAll,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: AppLocalizations.of(context).selectAll,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: AppLocalizations.of(context).deleteSelected,
            ),
        ],
      ),
    );
  }
}

// ── Notes list provider (reactive) ────────────────────────────────────────────

/// Reactive provider for the notes list. Uses PowerSync watch query so it
/// auto-updates when data changes locally or via sync from other devices.
/// On desktop, watches [notesRefreshProvider] so MCP events trigger a re-fetch.
final _sidebarNotesProvider = StreamProvider<List<Note>>((ref) {
  ref.watch(notesRefreshProvider);
  return ref.watch(noteRepositoryProvider).watchAll();
});

// ── Notes sidebar ────────────────────────────────────────────────────────────

class _NotesSidebar extends ConsumerStatefulWidget {
  const _NotesSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends ConsumerState<_NotesSidebar> {
  String _search = '';

  Future<void> _deleteNote(String id) async {
    await ref.read(noteRepositoryProvider).delete(id);
  }

  Future<void> _togglePin(String id) async {
    await ref.read(noteRepositoryProvider).togglePin(id);
  }

  Future<void> _renameNote(String id, String newTitle) async {
    await ref.read(noteRepositoryProvider).update(id, title: newTitle);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final asyncNotes = ref.watch(_sidebarNotesProvider);
    final Set<String> selectedIds = ref.watch(notesSelectionProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return asyncNotes.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (_, _) => Center(
        child: Text(
          AppLocalizations.of(context).failedToLoad,
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      ),
      data: (notes) {
        final filtered = notes
            .where(
              (n) =>
                  _search.isEmpty ||
                  n.title.toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();

        // Sort pinned first, then by updated
        filtered.sort((Note a, Note b) {
          if (a.pinned && !b.pinned) return -1;
          if (!a.pinned && b.pinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });

        return Column(
          children: [
            // Selection header
            if (inSelectionMode)
              _SidebarSelectionHeader(
                tokens: tokens,
                count: selectedIds.length,
                onClear: () =>
                    ref.read(notesSelectionProvider.notifier).clear(),
                onSelectAll: () => ref
                    .read(notesSelectionProvider.notifier)
                    .selectAll(filtered.map((n) => n.id).toSet()),
                onDelete: () async {
                  for (final id in selectedIds) {
                    await _deleteNote(id);
                  }
                  ref.read(notesSelectionProvider.notifier).clear();
                },
              ),
            // Search
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    cursorColor: tokens.accent,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchNotes,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: tokens.fgDim,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      filled: true,
                      fillColor: tokens.bg,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: tokens.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noNotes,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final note = filtered[i];
                        final cust = ref.watch(
                          entityCustomizationProvider,
                        )[note.id];
                        final location = GoRouterState.of(
                          context,
                        ).matchedLocation;
                        final isActive =
                            location == '/library/notes/${note.id}';
                        return _SidebarItem(
                          tokens: tokens,
                          icon: cust?.icon ?? Icons.sticky_note_2_outlined,
                          iconColor: cust?.color,
                          label: note.title,
                          subtitle: note.content.length > 50
                              ? '${note.content.substring(0, 50)}...'
                              : note.content,
                          isPinned: note.pinned,
                          isSelected: isActive && !inSelectionMode,
                          isChecked: selectedIds.contains(note.id),
                          onTap: inSelectionMode
                              ? () => ref
                                    .read(notesSelectionProvider.notifier)
                                    .toggle(note.id)
                              : () => context.go('/library/notes/${note.id}'),
                          onSelect: () => ref
                              .read(notesSelectionProvider.notifier)
                              .toggle(note.id),
                          onPin: () => _togglePin(note.id),
                          onDelete: () => _deleteNote(note.id),
                          contextMenuActions: buildEntityContextActions(
                            l10n: AppLocalizations.of(context),
                            onRename: () async {
                              final newName = await showRenameDialog(
                                context,
                                currentName: note.title,
                              );
                              if (newName != null)
                                await _renameNote(note.id, newName);
                            },
                            onChangeIcon: () => pickAndSaveIcon(
                              context,
                              ref,
                              note.id,
                              currentCodePoint: cust?.iconCodePoint,
                            ),
                            onChangeColor: () => pickAndSaveColor(
                              context,
                              ref,
                              note.id,
                              currentColor: cust?.color,
                            ),
                            onSelect: () => ref
                                .read(notesSelectionProvider.notifier)
                                .toggle(note.id),
                            onEdit: () => context.push(Routes.note(note.id)),
                            onPin: () => _togglePin(note.id),
                            isPinned: note.pinned,
                            onSync: () => openSyncDialog(
                              context,
                              entityType: 'note',
                              entityId: note.id,
                              ref: ref,
                              entityData: {
                                'title': note.title,
                                'content': note.content,
                              },
                            ),
                            onExportMarkdown: () => exportAsMarkdown(
                              title: note.title,
                              content: note.content,
                            ),
                            onDelete: () => _deleteNote(note.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Projects sidebar ────────────────────────────────────────────────────────

class _ProjectsSidebar extends ConsumerStatefulWidget {
  const _ProjectsSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_ProjectsSidebar> createState() => _ProjectsSidebarState();
}

class _ProjectsSidebarState extends ConsumerState<_ProjectsSidebar> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final asyncProjects = ref.watch(projectsProvider);
    final Set<String> selectedIds = ref.watch(projectsSelectionProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return asyncProjects.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (_, _) => Center(
        child: Text(
          AppLocalizations.of(context).failedToLoad,
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).noProjects,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
          );
        }

        final q = _search.toLowerCase();
        final filtered = q.isEmpty
            ? projects
            : projects
                  .where(
                    (p) =>
                        p.name.toLowerCase().contains(q) ||
                        (p.description ?? '').toLowerCase().contains(q) ||
                        (p.mode ?? '').toLowerCase().contains(q),
                  )
                  .toList();

        return Column(
          children: [
            if (inSelectionMode)
              _SidebarSelectionHeader(
                tokens: tokens,
                count: selectedIds.length,
                onClear: () =>
                    ref.read(projectsSelectionProvider.notifier).clear(),
                onSelectAll: () => ref
                    .read(projectsSelectionProvider.notifier)
                    .selectAll(filtered.map((p) => p.id).toSet()),
                onDelete: () async {
                  for (final id in selectedIds) {
                    await ref.read(projectRepositoryProvider).delete(id);
                  }
                  ref.read(projectsSelectionProvider.notifier).clear();
                  ref.invalidate(projectsProvider);
                },
              ),
            // Search
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    cursorColor: tokens.accent,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchProjects,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: tokens.fgDim,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      filled: true,
                      fillColor: tokens.bg,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: tokens.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noSearchResults(_search),
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final cust = ref.watch(
                          entityCustomizationProvider,
                        )[p.id];
                        final location = GoRouterState.of(
                          context,
                        ).matchedLocation;
                        final isActive = location == '/projects/${p.id}';
                        return _SidebarItem(
                          tokens: tokens,
                          icon: cust?.icon ?? Icons.folder_rounded,
                          iconColor: cust?.color,
                          label: p.name,
                          subtitle: p.mode,
                          isSelected: isActive && !inSelectionMode,
                          isChecked: selectedIds.contains(p.id),
                          onTap: inSelectionMode
                              ? () => ref
                                    .read(projectsSelectionProvider.notifier)
                                    .toggle(p.id)
                              : () => context.go('/projects/${p.id}'),
                          onSelect: () => ref
                              .read(projectsSelectionProvider.notifier)
                              .toggle(p.id),
                          onDelete: () async {
                            await ref
                                .read(projectRepositoryProvider)
                                .delete(p.id);
                            ref.invalidate(projectsProvider);
                          },
                          contextMenuActions: buildEntityContextActions(
                            l10n: AppLocalizations.of(context),
                            onRename: () async {
                              final newName = await showRenameDialog(
                                context,
                                currentName: p.name,
                              );
                              if (newName != null) {
                                await ref
                                    .read(projectRepositoryProvider)
                                    .update(p.id, name: newName);
                                ref.invalidate(projectsProvider);
                              }
                            },
                            onChangeIcon: () => pickAndSaveIcon(
                              context,
                              ref,
                              p.id,
                              currentCodePoint: cust?.iconCodePoint,
                            ),
                            onChangeColor: () => pickAndSaveColor(
                              context,
                              ref,
                              p.id,
                              currentColor: cust?.color,
                            ),
                            onSelect: () => ref
                                .read(projectsSelectionProvider.notifier)
                                .toggle(p.id),
                            onEdit: () => context.push(Routes.project(p.id)),
                            onSync: () => openSyncDialog(
                              context,
                              entityType: 'project',
                              entityId: p.id,
                              ref: ref,
                              entityData: {
                                'name': p.name,
                                'description': p.description ?? '',
                              },
                            ),
                            onExportMarkdown: () => exportAsMarkdown(
                              title: p.name,
                              content: p.description ?? '',
                            ),
                            onDelete: () async {
                              await ref
                                  .read(projectRepositoryProvider)
                                  .delete(p.id);
                              ref.invalidate(projectsProvider);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Generic async list sidebar ───────────────────────────────────────────────

class _AsyncListSidebar extends ConsumerStatefulWidget {
  const _AsyncListSidebar({
    required this.tokens,
    required this.provider,
    required this.nameKey,
    required this.iconData,
    required this.emptyMessage,
    required this.onTap,
    required this.selectionProvider,
    required this.pinProvider,
    this.descriptionKey,
    this.basePath,
    this.entityType,
    this.searchHint,
  });

  final OrchestraColorTokens tokens;

  /// Provider that returns AsyncValue<List<Map<String, dynamic>>>.
  /// Accepts both FutureProvider and StreamProvider.
  final dynamic provider;
  final String nameKey;
  final IconData iconData;
  final String emptyMessage;
  final void Function(Map<String, dynamic>) onTap;
  final NotifierProvider<SelectionNotifier, Set<String>> selectionProvider;
  final NotifierProvider<PinStoreNotifier, Set<String>> pinProvider;

  /// Key for the subtitle/description. If null, no subtitle is shown.
  final String? descriptionKey;

  /// Base route path for active-item detection (e.g. '/library/agents').
  final String? basePath;

  /// Entity type for sync (e.g. 'agent', 'skill', 'workflow'). If null, sync is hidden.
  final String? entityType;

  /// Hint text for the search field. If null, a generic "Search..." is used.
  final String? searchHint;

  @override
  ConsumerState<_AsyncListSidebar> createState() => _AsyncListSidebarState();
}

class _AsyncListSidebarState extends ConsumerState<_AsyncListSidebar> {
  String _search = '';

  String _itemId(Map<String, dynamic> item) {
    return (item[widget.nameKey] ?? item['name'] ?? item['title'] ?? '')
        .toString();
  }

  String _itemName(Map<String, dynamic> item) {
    return (item[widget.nameKey] ?? item['title'] ?? 'Untitled').toString();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final AsyncValue<List<Map<String, dynamic>>> asyncData;
    if (widget.provider is StreamProvider<List<Map<String, dynamic>>>) {
      asyncData = ref.watch(
        widget.provider as StreamProvider<List<Map<String, dynamic>>>,
      );
    } else {
      asyncData = ref.watch(
        widget.provider as FutureProvider<List<Map<String, dynamic>>>,
      );
    }
    final Set<String> selectedIds = ref.watch(widget.selectionProvider);
    final Set<String> pinnedIds = ref.watch(widget.pinProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    return asyncData.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (_, _) => Center(
        child: Text(
          AppLocalizations.of(context).failedToLoad,
          style: TextStyle(color: tokens.fgDim, fontSize: 13),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Text(
              widget.emptyMessage,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
          );
        }

        // Client-side search filtering
        final q = _search.toLowerCase();
        final filtered = q.isEmpty
            ? items
            : items.where((item) {
                final name = _itemName(item).toLowerCase();
                final desc = widget.descriptionKey != null
                    ? ((item[widget.descriptionKey] as String?) ?? '')
                          .toLowerCase()
                    : '';
                return name.contains(q) || desc.contains(q);
              }).toList();

        // Sort pinned first
        final sorted = List<Map<String, dynamic>>.from(filtered)
          ..sort((a, b) {
            final bool aPin = pinnedIds.contains(_itemId(a));
            final bool bPin = pinnedIds.contains(_itemId(b));
            if (aPin && !bPin) return -1;
            if (!aPin && bPin) return 1;
            return 0;
          });

        return Column(
          children: [
            if (inSelectionMode)
              _SidebarSelectionHeader(
                tokens: tokens,
                count: selectedIds.length,
                onClear: () =>
                    ref.read(widget.selectionProvider.notifier).clear(),
                onSelectAll: () => ref
                    .read(widget.selectionProvider.notifier)
                    .selectAll(sorted.map(_itemId).toSet()),
              ),
            // Search field
            if (!inSelectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    cursorColor: tokens.accent,
                    decoration: InputDecoration(
                      hintText:
                          widget.searchHint ??
                          AppLocalizations.of(context).search,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: tokens.fgDim,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      filled: true,
                      fillColor: tokens.bg,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: tokens.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: sorted.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noSearchResults(_search),
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      itemCount: sorted.length,
                      itemBuilder: (context, i) {
                        final item = sorted[i];
                        final id = _itemId(item);
                        final name = _itemName(item);
                        final bool isPinned = pinnedIds.contains(id);
                        final cust = ref.watch(entityCustomizationProvider)[id];
                        final String? desc = widget.descriptionKey != null
                            ? (item[widget.descriptionKey] as String?)
                            : null;
                        final itemRouteId = item['id']?.toString() ?? id;
                        final location = GoRouterState.of(
                          context,
                        ).matchedLocation;
                        final isActive =
                            widget.basePath != null &&
                            location == '${widget.basePath}/$itemRouteId';
                        return _SidebarItem(
                          tokens: tokens,
                          icon: cust?.icon ?? widget.iconData,
                          iconColor: cust?.color,
                          label: name,
                          subtitle: desc,
                          isPinned: isPinned,
                          isSelected: isActive && !inSelectionMode,
                          isChecked: selectedIds.contains(id),
                          onTap: inSelectionMode
                              ? () => ref
                                    .read(widget.selectionProvider.notifier)
                                    .toggle(id)
                              : () => widget.onTap(item),
                          onSelect: () => ref
                              .read(widget.selectionProvider.notifier)
                              .toggle(id),
                          onPin: () =>
                              ref.read(widget.pinProvider.notifier).toggle(id),
                          contextMenuActions: buildEntityContextActions(
                            l10n: AppLocalizations.of(context),
                            onChangeIcon: () => pickAndSaveIcon(
                              context,
                              ref,
                              id,
                              currentCodePoint: cust?.iconCodePoint,
                            ),
                            onChangeColor: () => pickAndSaveColor(
                              context,
                              ref,
                              id,
                              currentColor: cust?.color,
                            ),
                            onSelect: () => ref
                                .read(widget.selectionProvider.notifier)
                                .toggle(id),
                            onPin: () => ref
                                .read(widget.pinProvider.notifier)
                                .toggle(id),
                            isPinned: isPinned,
                            onSync: widget.entityType != null
                                ? () => openSyncDialog(
                                    context,
                                    entityType: widget.entityType!,
                                    entityId: id,
                                    ref: ref,
                                    entityData: Map<String, dynamic>.from(item),
                                  )
                                : null,
                            onExportMarkdown: () => exportAsMarkdown(
                              title: name,
                              content: desc ?? '',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shared dialog field ──────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.tokens,
    this.autofocus = false,
    this.obscure = false,
    this.monospace = false,
    this.maxLines = 1,
  });

  final TextEditingController ctrl;
  final String label;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool autofocus;
  final bool obscure;
  final bool monospace;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 13,
        fontFamily: monospace ? 'JetBrains Mono' : null,
        fontFamilyFallback: monospace ? const ['monospace'] : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(
          color: tokens.fgDim.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}

// ── Dashboard sidebar ────────────────────────────────────────────────────────

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Projects', Icons.folder_rounded, Routes.projects),
      ('Notes', Icons.sticky_note_2_rounded, Routes.notes),
      ('Agents', Icons.smart_toy_rounded, Routes.agents),
      ('Skills', Icons.bolt_rounded, Routes.skills),
      ('Workflows', Icons.account_tree_rounded, Routes.workflows),
      ('Docs', Icons.menu_book_rounded, Routes.docs),
      ('Delegations', Icons.sync_alt_rounded, Routes.delegations),
    ];

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        for (final (label, icon, route) in items)
          _SidebarItem(
            tokens: tokens,
            icon: icon,
            label: label,
            onTap: () => context.go(route),
          ),
      ],
    );
  }
}

// ── DevTools individual sidebars ─────────────────────────────────────────────

class _ApiCollectionsSidebar extends ConsumerStatefulWidget {
  const _ApiCollectionsSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_ApiCollectionsSidebar> createState() =>
      _ApiCollectionsSidebarState();
}

class _ApiCollectionsSidebarState
    extends ConsumerState<_ApiCollectionsSidebar> {
  final Set<String> _expanded = {};

  OrchestraColorTokens get tokens => widget.tokens;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apiCollectionProvider);
    final selectedCollId = ref.watch(selectedCollectionIdProvider);
    final selectedEp = ref.watch(selectedEndpointProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (collections) {
        if (collections.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No collections.\nTap + to create one.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final c in collections) ...[
              // Collection header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (_expanded.contains(c.id)) {
                        _expanded.remove(c.id);
                      } else {
                        _expanded.add(c.id);
                      }
                    });
                    ref
                        .read(selectedCollectionIdProvider.notifier)
                        .select(c.id);
                    ref.read(selectedEndpointProvider.notifier).select(null);
                    context.go(Routes.devtoolsApi);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: c.id == selectedCollId
                          ? tokens.accentSurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _expanded.contains(c.id)
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.chevron_right_rounded,
                          size: 16,
                          color: tokens.fgDim,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.folder_rounded,
                          size: 14,
                          color: c.id == selectedCollId
                              ? tokens.accent
                              : const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              color: c.id == selectedCollId
                                  ? tokens.accent
                                  : tokens.fgBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.fgDim.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${c.endpoints.length}',
                            style: TextStyle(
                              color: tokens.fgDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Endpoints (expanded)
              if (_expanded.contains(c.id))
                for (final ep in c.endpoints)
                  Padding(
                    padding: const EdgeInsets.only(left: 28, right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        ref
                            .read(selectedCollectionIdProvider.notifier)
                            .select(c.id);
                        ref.read(selectedEndpointProvider.notifier).select(ep);
                        context.go(Routes.devtoolsApi);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color:
                              ep.id == selectedEp?.id && c.id == selectedCollId
                              ? tokens.accent.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            _MethodTag(method: ep.method, tokens: tokens),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ep.name,
                                style: TextStyle(
                                  color:
                                      ep.id == selectedEp?.id &&
                                          c.id == selectedCollId
                                      ? tokens.accent
                                      : tokens.fgBright,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _MethodTag extends StatelessWidget {
  const _MethodTag({required this.method, required this.tokens});
  final String method;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = switch (method.toUpperCase()) {
      'GET' => const Color(0xFF22C55E),
      'POST' => const Color(0xFF3B82F6),
      'PUT' => const Color(0xFFF59E0B),
      'PATCH' => const Color(0xFF8B5CF6),
      'DELETE' => const Color(0xFFEF4444),
      _ => const Color(0xFF6B7280),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        method.toUpperCase().length > 3
            ? method.toUpperCase().substring(0, 3)
            : method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DatabaseSidebar extends ConsumerWidget {
  const _DatabaseSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(databaseBrowserProvider);
    final selectedId = ref.watch(selectedConnectionIdProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (connections) {
        if (connections.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No connections.\nTap + to connect.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final c in connections)
              _SidebarItem(
                tokens: tokens,
                icon: Icons.storage_rounded,
                label: c.driver.toUpperCase(),
                subtitle: c.dsn.length > 30
                    ? '${c.dsn.substring(0, 30)}…'
                    : c.dsn,
                isSelected: c.id == selectedId,
                onTap: () {
                  ref.read(selectedConnectionIdProvider.notifier).select(c.id);
                  context.go(Routes.devtoolsDatabase);
                },
              ),
          ],
        );
      },
    );
  }
}

class _LogRunnerSidebar extends ConsumerWidget {
  const _LogRunnerSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(logRunnerProvider);
    final selectedId = ref.watch(selectedProcessIdProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (processes) {
        if (processes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No processes.\nTap + to run a command.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final p in processes)
              _SidebarItem(
                tokens: tokens,
                icon: p.isRunning
                    ? Icons.play_circle_filled_rounded
                    : Icons.check_circle_rounded,
                iconColor: p.isRunning ? const Color(0xFF22C55E) : tokens.fgDim,
                label: p.command.length > 28
                    ? '${p.command.substring(0, 28)}…'
                    : p.command,
                subtitle: p.isRunning
                    ? 'PID ${p.pid ?? '—'}${p.uptime != null ? ' · ${p.uptime}' : ''}'
                    : p.status,
                isSelected: p.id == selectedId,
                onTap: () {
                  ref.read(selectedProcessIdProvider.notifier).select(p.id);
                  context.go(Routes.devtoolsLogs);
                },
              ),
          ],
        );
      },
    );
  }
}

class _SecretsSidebar extends ConsumerWidget {
  const _SecretsSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(secretsProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (secrets) {
        if (secrets.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No secrets.\nTap + to add one.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final s in secrets)
              _SidebarItem(
                tokens: tokens,
                icon: Icons.vpn_key_rounded,
                label: s.name,
                subtitle: s.category,
                onTap: () => context.go(Routes.devtoolsSecrets),
              ),
          ],
        );
      },
    );
  }
}

class _PromptsSidebar extends ConsumerWidget {
  const _PromptsSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(promptsProvider);

    return async.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.accent, strokeWidth: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $e',
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (prompts) {
        if (prompts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No prompts.\nTap + to create one.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final p in prompts)
              _SidebarItem(
                tokens: tokens,
                icon: Icons.chat_bubble_outline_rounded,
                label: p.title,
                subtitle: p.trigger,
                onTap: () => context.go(Routes.devtoolsPrompts),
              ),
          ],
        );
      },
    );
  }
}

// ── Health sidebar ───────────────────────────────────────────────────────────

class _HealthSidebar extends StatelessWidget {
  const _HealthSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        // ── Overview ──
        _SidebarItem(
          tokens: tokens,
          icon: Icons.dashboard_rounded,
          label: l10n.overview,
          isSelected: location == Routes.health,
          onTap: () => context.go(Routes.health),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          label: l10n.healthScore,
          isSelected: location == Routes.healthScore,
          onTap: () => context.go(Routes.healthScore),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.monitor_heart_rounded,
          iconColor: const Color(0xFFF43F5E),
          label: l10n.vitals,
          isSelected: location == Routes.healthVitals,
          onTap: () => context.go(Routes.healthVitals),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.auto_graph_rounded,
          iconColor: const Color(0xFF818CF8),
          label: l10n.dailyFlow,
          isSelected: location == Routes.healthFlow,
          onTap: () => context.go(Routes.healthFlow),
        ),
        // ── Tracking ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.tracking),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF38BDF8),
          label: l10n.hydration,
          isSelected: location == Routes.healthHydration,
          onTap: () => context.go(Routes.healthHydration),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.coffee_rounded,
          iconColor: const Color(0xFFF97316),
          label: l10n.caffeine,
          isSelected: location == Routes.healthCaffeine,
          onTap: () => context.go(Routes.healthCaffeine),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFF4ADE80),
          label: l10n.nutrition,
          isSelected: location == Routes.healthNutrition,
          onTap: () => context.go(Routes.healthNutrition),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.monitor_weight_rounded,
          iconColor: const Color(0xFF14B8A6),
          label: l10n.weight,
          isSelected: location == Routes.healthWeight,
          onTap: () => context.go(Routes.healthWeight),
        ),
        // ── Wellness ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.wellness),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.timer_rounded,
          iconColor: const Color(0xFFF97316),
          label: l10n.pomodoro,
          isSelected: location == Routes.healthPomodoro,
          onTap: () => context.go(Routes.healthPomodoro),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.nightlight_rounded,
          iconColor: const Color(0xFF6366F1),
          label: l10n.shutdown,
          isSelected: location == Routes.healthShutdown,
          onTap: () => context.go(Routes.healthShutdown),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF8B5CF6),
          label: l10n.sleep,
          isSelected: location == Routes.healthSleep,
          onTap: () => context.go(Routes.healthSleep),
        ),
      ],
    );
  }
}

// ── Sidebar group label ──────────────────────────────────────────────────────

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel({required this.tokens, required this.label});
  final OrchestraColorTokens tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: tokens.fgDim,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Settings sidebar ─────────────────────────────────────────────────────────

class _SettingsSidebar extends ConsumerWidget {
  const _SettingsSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider).value;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        // ── Account ──
        _SidebarItem(
          tokens: tokens,
          icon: Icons.person_rounded,
          label: l10n.settingsProfile,
          isSelected:
              location == Routes.settingsProfile || location == Routes.settings,
          onTap: () => context.go(Routes.settingsProfile),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.lock_rounded,
          label: l10n.settingsPasswordNav,
          isSelected: location == Routes.settingsPassword,
          onTap: () => context.go(Routes.settingsPassword),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.palette_rounded,
          label: l10n.settingsAppearance,
          isSelected: location == Routes.settingsAppearance,
          onTap: () => context.go(Routes.settingsAppearance),
        ),
        // ── Security ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.settingsSecurity),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.shield_rounded,
          label: l10n.settingsTwoFactor,
          isSelected: location == Routes.settingsTwoFactor,
          onTap: () => context.go(Routes.settingsTwoFactor),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.fingerprint_rounded,
          label: l10n.settingsPasskeys,
          isSelected: location == Routes.settingsPasskeys,
          onTap: () => context.go(Routes.settingsPasskeys),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.devices_rounded,
          label: l10n.settingsSessions,
          isSelected: location == Routes.settingsSessions,
          onTap: () => context.go(Routes.settingsSessions),
        ),
        // ── Developer ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.settingsDeveloper),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.key_rounded,
          label: l10n.settingsApiTokens,
          isSelected: location == Routes.settingsApiTokens,
          onTap: () => context.go(Routes.settingsApiTokens),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.power_rounded,
          label: l10n.settingsIntegrations,
          isSelected: location == Routes.settingsIntegrations,
          onTap: () => context.go(Routes.settingsIntegrations),
        ),
        // ── Notifications ──
        _SidebarGroupLabel(
          tokens: tokens,
          label: l10n.settingsNotificationsNav,
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.notifications_rounded,
          label: l10n.settingsNotificationsNav,
          isSelected: location == Routes.settingsNotifications,
          onTap: () => context.go(Routes.settingsNotifications),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.favorite_rounded,
          label: l10n.settingsHealthNav,
          isSelected: location == Routes.settingsHealth,
          onTap: () => context.go(Routes.settingsHealth),
        ),
        // ── Other ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.settingsOther),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.share_rounded,
          label: l10n.settingsSocialNav,
          isSelected: location == Routes.settingsSocial,
          onTap: () => context.go(Routes.settingsSocial),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.desktop_mac_rounded,
          label: l10n.settingsDesktop,
          isSelected: location == Routes.settingsDesktop,
          onTap: () => context.go(Routes.settingsDesktop),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.info_rounded,
          label: l10n.settingsAbout,
          isSelected: location == Routes.settingsAbout,
          onTap: () => context.go(Routes.settingsAbout),
        ),
        // ── Administration (admin only) ──
        if (isAdmin) ...[
          _SidebarGroupLabel(
            tokens: tokens,
            label: l10n.settingsAdministration,
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.settings_rounded,
            label: l10n.settingsGeneral,
            isSelected: location == Routes.settingsAdminGeneral,
            onTap: () => context.go(Routes.settingsAdminGeneral),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.toggle_on_rounded,
            label: l10n.settingsFeatures,
            isSelected: location == Routes.settingsAdminFeatures,
            onTap: () => context.go(Routes.settingsAdminFeatures),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.home_rounded,
            label: l10n.settingsHomepage,
            isSelected: location == Routes.settingsAdminHomepage,
            onTap: () => context.go(Routes.settingsAdminHomepage),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.smart_toy_rounded,
            label: l10n.settingsAiAgents,
            isSelected: location == Routes.settingsAdminAgents,
            onTap: () => context.go(Routes.settingsAdminAgents),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.email_rounded,
            label: l10n.settingsEmail,
            isSelected: location == Routes.settingsAdminEmail,
            onTap: () => context.go(Routes.settingsAdminEmail),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.message_rounded,
            label: l10n.settingsContact,
            isSelected: location == Routes.settingsAdminContact,
            onTap: () => context.go(Routes.settingsAdminContact),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.attach_money_rounded,
            label: l10n.settingsPricing,
            isSelected: location == Routes.settingsAdminPricing,
            onTap: () => context.go(Routes.settingsAdminPricing),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.download_rounded,
            label: l10n.settingsDownloads,
            isSelected: location == Routes.settingsAdminDownload,
            onTap: () => context.go(Routes.settingsAdminDownload),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.power_rounded,
            label: l10n.settingsIntegrations,
            isSelected: location == Routes.settingsAdminIntegrations,
            onTap: () => context.go(Routes.settingsAdminIntegrations),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.search_rounded,
            label: l10n.settingsSeo,
            isSelected: location == Routes.settingsAdminSeo,
            onTap: () => context.go(Routes.settingsAdminSeo),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.discord,
            label: 'Discord',
            isSelected: location == Routes.settingsAdminDiscord,
            onTap: () => context.go(Routes.settingsAdminDiscord),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.chat_rounded,
            label: 'Slack',
            isSelected: location == Routes.settingsAdminSlack,
            onTap: () => context.go(Routes.settingsAdminSlack),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.code_rounded,
            label: 'GitHub',
            isSelected: location == Routes.settingsAdminGithub,
            onTap: () => context.go(Routes.settingsAdminGithub),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.share_rounded,
            label: l10n.settingsSocialNav,
            isSelected: location == Routes.settingsAdminSocial,
            onTap: () => context.go(Routes.settingsAdminSocial),
          ),
          _SidebarItem(
            tokens: tokens,
            icon: Icons.auto_awesome_rounded,
            label: l10n.settingsSmartPrompts,
            isSelected: location == Routes.settingsAdminPrompts,
            onTap: () => context.go(Routes.settingsAdminPrompts),
          ),
        ],
      ],
    );
  }
}

// ── Admin sidebar ────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        // ── Overview ──
        _SidebarItem(
          tokens: tokens,
          icon: Icons.grid_view_rounded,
          label: l10n.adminOverview,
          isSelected: location == Routes.admin,
          onTap: () => context.go(Routes.admin),
        ),
        // ── People ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.adminPeople),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.people_rounded,
          label: l10n.adminUsers,
          isSelected: location.startsWith(Routes.adminUsers),
          onTap: () => context.go(Routes.adminUsers),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.key_rounded,
          label: l10n.adminRolesPermissions,
          isSelected: location == Routes.adminRoles,
          onTap: () => context.go(Routes.adminRoles),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.business_rounded,
          label: l10n.adminTeams,
          isSelected: location.startsWith(Routes.adminTeams),
          onTap: () => context.go(Routes.adminTeams),
        ),
        // ── Content ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.adminContent),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.article_rounded,
          label: l10n.adminPosts,
          isSelected: location == Routes.adminPosts,
          onTap: () => context.go(Routes.adminPosts),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.insert_drive_file_rounded,
          label: l10n.adminPages,
          isSelected: location == Routes.adminPages,
          onTap: () => context.go(Routes.adminPages),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.menu_book_rounded,
          label: l10n.adminDocumentation,
          isSelected: location == Routes.adminDocs,
          onTap: () => context.go(Routes.adminDocs),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.category_rounded,
          label: l10n.adminCategories,
          isSelected: location == Routes.adminCategories,
          onTap: () => context.go(Routes.adminCategories),
        ),
        // ── Community ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.adminCommunity),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.forum_rounded,
          label: l10n.adminCommunity,
          isSelected: location == Routes.adminCommunity,
          onTap: () => context.go(Routes.adminCommunity),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.mail_rounded,
          label: l10n.adminContactNav,
          isSelected: location == Routes.adminContact,
          onTap: () => context.go(Routes.adminContact),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.bug_report_rounded,
          label: l10n.adminIssues,
          isSelected: location == Routes.adminIssues,
          onTap: () => context.go(Routes.adminIssues),
        ),
        // ── Marketplace ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.adminMarketplaceNav),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.store_rounded,
          label: l10n.adminMarketplaceNav,
          isSelected: location == Routes.adminMarketplace,
          onTap: () => context.go(Routes.adminMarketplace),
        ),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.favorite_rounded,
          label: l10n.adminSponsors,
          isSelected: location == Routes.adminSponsors,
          onTap: () => context.go(Routes.adminSponsors),
        ),
        // ── System ──
        _SidebarGroupLabel(tokens: tokens, label: l10n.adminSystem),
        _SidebarItem(
          tokens: tokens,
          icon: Icons.notifications_rounded,
          label: l10n.adminNotifications,
          isSelected: location == Routes.adminNotifications,
          onTap: () => context.go(Routes.adminNotifications),
        ),
      ],
    );
  }
}

// ── Terminal sidebar ──────────────────────────────────────────────────────────

// ── Terminal add button (dropdown: Terminal / SSH / Claude) ──────────────────

class _TerminalAddButton extends ConsumerWidget {
  const _TerminalAddButton({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<TerminalSessionType>(
      onSelected: (kind) => _create(context, ref, kind),
      tooltip: AppLocalizations.of(context).terminalTabNewSession,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      icon: Icon(Icons.add_rounded, size: 18, color: tokens.fgMuted),
      color: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.borderFaint),
      ),
      offset: const Offset(0, 32),
      itemBuilder: (_) => [
        if (isDesktop)
          _menuItem(
            TerminalSessionType.terminal,
            Icons.terminal_rounded,
            'Terminal',
          ),
        _menuItem(TerminalSessionType.ssh, Icons.public_rounded, 'SSH'),
        _menuItem(
          TerminalSessionType.claude,
          Icons.smart_toy_rounded,
          'Claude',
        ),
      ],
    );
  }

  PopupMenuItem<TerminalSessionType> _menuItem(
    TerminalSessionType value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<TerminalSessionType>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.fgMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    TerminalSessionType kind,
  ) async {
    final notifier = ref.read(terminalSessionsProvider.notifier);
    final TerminalSessionModel session;
    switch (kind) {
      case TerminalSessionType.terminal:
        session = await notifier.createTerminalSession();
      case TerminalSessionType.ssh:
        final sshParams = await _showSshDialog(context, tokens);
        if (sshParams == null) return;
        session = await notifier.createSshSession(
          host: sshParams.host,
          user: sshParams.user,
          port: sshParams.port,
          password: sshParams.password,
          keyFile: sshParams.keyFile,
        );
      case TerminalSessionType.claude:
        session = await notifier.createClaudeSession();
      case TerminalSessionType.remote:
        return; // Remote sessions are created from the tunnel connection screen.
    }
    ref.read(activeTerminalIdProvider.notifier).set(session.id);
    if (context.mounted) context.go(Routes.terminal);
  }

  static Future<_SshParams?> _showSshDialog(
    BuildContext context,
    OrchestraColorTokens tokens,
  ) {
    final hostCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '22');
    final passwordCtrl = TextEditingController();
    final keyFileCtrl = TextEditingController();
    bool obscurePassword = true;

    return showDialog<_SshParams>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text(
            AppLocalizations.of(context).sshConnection,
            style: TextStyle(color: tokens.fgBright),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sshField(tokens, hostCtrl, 'Host', 'e.g. 192.168.1.10'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _sshField(tokens, userCtrl, 'User', 'e.g. root'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _sshField(
                        tokens,
                        portCtrl,
                        'Port',
                        '22',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  style: TextStyle(color: tokens.fgBright, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).password,
                    labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                    hintText: AppLocalizations.of(context).leaveEmptyForKeyAuth,
                    hintStyle: TextStyle(
                      color: tokens.fgDim.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.borderFaint),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                        color: tokens.fgDim,
                      ),
                      onPressed: () => setDialogState(
                        () => obscurePassword = !obscurePassword,
                      ),
                    ),
                  ),
                  cursorColor: tokens.accent,
                ),
                const SizedBox(height: 10),
                _sshField(
                  tokens,
                  keyFileCtrl,
                  'Key File (optional)',
                  '~/.ssh/id_rsa',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(color: tokens.fgMuted),
              ),
            ),
            TextButton(
              onPressed: () {
                final host = hostCtrl.text.trim();
                final user = userCtrl.text.trim();
                if (host.isEmpty || user.isEmpty) return;
                Navigator.of(ctx).pop(
                  _SshParams(
                    host: host,
                    user: user,
                    port: int.tryParse(portCtrl.text.trim()) ?? 22,
                    password: passwordCtrl.text.isEmpty
                        ? null
                        : passwordCtrl.text,
                    keyFile: keyFileCtrl.text.trim().isEmpty
                        ? null
                        : keyFileCtrl.text.trim(),
                  ),
                );
              },
              child: Text(
                AppLocalizations.of(context).connect,
                style: TextStyle(color: tokens.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextField _sshField(
    OrchestraColorTokens tokens,
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: tokens.fgBright, fontSize: 13),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(
          color: tokens.fgDim.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
      cursorColor: tokens.accent,
    );
  }
}

/// SSH connection parameters returned by the dialog.
class _SshParams {
  const _SshParams({
    required this.host,
    required this.user,
    this.port = 22,
    this.password,
    this.keyFile,
  });
  final String host;
  final String user;
  final int port;
  final String? password;
  final String? keyFile;
}

// ── Terminal sidebar ──────────────────────────────────────────────────────────

class _TerminalSidebar extends ConsumerStatefulWidget {
  const _TerminalSidebar({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_TerminalSidebar> createState() => _TerminalSidebarState();
}

class _TerminalSidebarState extends ConsumerState<_TerminalSidebar> {
  static IconData _typeIcon(TerminalSessionType type) {
    return switch (type) {
      TerminalSessionType.terminal => Icons.terminal_rounded,
      TerminalSessionType.ssh => Icons.public_rounded,
      TerminalSessionType.claude => Icons.smart_toy_rounded,
      TerminalSessionType.remote => Icons.cloud_rounded,
    };
  }

  static String _statusLabel(TerminalSessionStatus status) {
    return switch (status) {
      TerminalSessionStatus.connected => 'Connected',
      TerminalSessionStatus.connecting => 'Connecting...',
      TerminalSessionStatus.error => 'Error',
      TerminalSessionStatus.disconnected => 'Disconnected',
    };
  }

  void _rename(String id, String currentLabel) {
    // Delay until after popup menu overlay finishes disposing to avoid
    // _dependents.isEmpty assertion when the dialog accesses InheritedWidgets.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final newName = await showRenameDialog(
        context,
        currentName: currentLabel,
      );
      if (newName != null) {
        ref.read(terminalSessionsProvider.notifier).renameSession(id, newName);
      }
    });
  }

  void _togglePin(String id) {
    ref.read(terminalSessionsProvider.notifier).togglePin(id);
  }

  void _close(String id) {
    ref.read(terminalSessionsProvider.notifier).removeSession(id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final sessions = ref.watch(terminalSessionsProvider);
    final activeId = ref.watch(activeTerminalIdProvider);
    final Set<String> selectedIds = ref.watch(terminalSelectionProvider);
    final bool inSelectionMode = selectedIds.isNotEmpty;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded, size: 32, color: tokens.fgDim),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).noSessions,
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Sort: pinned first, then by creation date (newest first).
    final sorted = List<TerminalSessionModel>.from(sessions);
    sorted.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Column(
      children: [
        if (inSelectionMode)
          _SidebarSelectionHeader(
            tokens: tokens,
            count: selectedIds.length,
            onClear: () => ref.read(terminalSelectionProvider.notifier).clear(),
            onSelectAll: () => ref
                .read(terminalSelectionProvider.notifier)
                .selectAll(sorted.map((s) => s.id).toSet()),
            onDelete: () {
              for (final id in selectedIds) {
                _close(id);
              }
              ref.read(terminalSelectionProvider.notifier).clear();
            },
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final session = sorted[index];
              final isActive = session.id == activeId;
              final cust = ref.watch(entityCustomizationProvider)[session.id];

              return _SidebarItem(
                tokens: tokens,
                icon: cust?.icon ?? _typeIcon(session.type),
                iconColor: cust?.color,
                label: session.label,
                subtitle: _statusLabel(session.status),
                isSelected: isActive && !inSelectionMode,
                isChecked: selectedIds.contains(session.id),
                isPinned: session.pinned,
                onTap: inSelectionMode
                    ? () => ref
                          .read(terminalSelectionProvider.notifier)
                          .toggle(session.id)
                    : () {
                        ref
                            .read(activeTerminalIdProvider.notifier)
                            .set(session.id);
                        context.go(Routes.terminal);
                      },
                onSelect: () => ref
                    .read(terminalSelectionProvider.notifier)
                    .toggle(session.id),
                onPin: () => _togglePin(session.id),
                onDelete: () => _close(session.id),
                contextMenuActions: buildEntityContextActions(
                  l10n: AppLocalizations.of(context),
                  onRename: () => _rename(session.id, session.label),
                  onChangeIcon: () => pickAndSaveIcon(
                    context,
                    ref,
                    session.id,
                    currentCodePoint: cust?.iconCodePoint,
                  ),
                  onChangeColor: () => pickAndSaveColor(
                    context,
                    ref,
                    session.id,
                    currentColor: cust?.color,
                  ),
                  onSelect: () => ref
                      .read(terminalSelectionProvider.notifier)
                      .toggle(session.id),
                  onPin: () => _togglePin(session.id),
                  isPinned: session.pinned,
                  onDelete: () => _close(session.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
