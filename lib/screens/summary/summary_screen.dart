import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/features/health/health_provider.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/sync/sync_event_handler.dart';
import 'package:orchestra/features/hooks/agent_notification_service.dart';
import 'package:orchestra/features/hooks/mcp_event_handler.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/summary/widgets/api_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/caffeine_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/health_score_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/hydration_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/notes_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/nutrition_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/pomodoro_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/projects_widget_card.dart';
import 'package:orchestra/screens/summary/widgets/widget_grid.dart';
import 'package:orchestra/screens/tray/workspace_switcher.dart';
import 'package:orchestra/widgets/team_updates_banner.dart';

// ── All dashboard widget configs ────────────────────────────────────────────

final allDashWidgets = <DashWidgetConfig>[
  DashWidgetConfig(
    id: 'health_score',
    label: 'Health Score',
    icon: Icons.favorite_rounded,
    span: GridSpan.full,
    builder: () => const HealthScoreWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'hydration',
    label: 'Hydration',
    icon: Icons.water_drop_rounded,
    span: GridSpan.half,
    builder: () => const HydrationWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'nutrition',
    label: 'Nutrition',
    icon: Icons.restaurant_rounded,
    span: GridSpan.half,
    builder: () => const NutritionWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'caffeine',
    label: 'Caffeine',
    icon: Icons.coffee_rounded,
    span: GridSpan.full,
    builder: () => const CaffeineWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'projects',
    label: 'Projects',
    icon: Icons.folder_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFF38BDF8),
    builder: () => const ProjectsWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'notes',
    label: 'Notes',
    icon: Icons.sticky_note_2_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFFFBBF24),
    builder: () => const NotesWidgetCard(),
  ),
  DashWidgetConfig(
    id: 'agents',
    label: 'Agents',
    icon: Icons.smart_toy_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFF4ADE80),
    builder: () => ApiWidgetCard(
      icon: Icons.smart_toy_rounded,
      label: 'Agents',
      route: Routes.agents,
      color: const Color(0xFF4ADE80),
      asyncDataBuilder: (ref) => ref.watch(agentsProvider),
      secondaryLabel: 'active',
      secondaryFilter: (a) => a['status'] == 'active',
    ),
  ),
  DashWidgetConfig(
    id: 'skills',
    label: 'Skills',
    icon: Icons.bolt_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFFF97316),
    builder: () => ApiWidgetCard(
      icon: Icons.bolt_rounded,
      label: 'Skills',
      route: Routes.skills,
      color: const Color(0xFFF97316),
      asyncDataBuilder: (ref) => ref.watch(skillsProvider),
    ),
  ),
  DashWidgetConfig(
    id: 'workflows',
    label: 'Workflows',
    icon: Icons.account_tree_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFF818CF8),
    builder: () => ApiWidgetCard(
      icon: Icons.account_tree_rounded,
      label: 'Workflows',
      route: Routes.workflows,
      color: const Color(0xFF818CF8),
      asyncDataBuilder: (ref) => ref.watch(workflowsProvider),
      secondaryLabel: 'active',
      secondaryFilter: (w) => w['status'] == 'active',
    ),
  ),
  DashWidgetConfig(
    id: 'docs',
    label: 'Docs',
    icon: Icons.menu_book_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFF06B6D4),
    builder: () => ApiWidgetCard(
      icon: Icons.menu_book_rounded,
      label: 'Docs',
      route: Routes.docs,
      color: const Color(0xFF06B6D4),
      asyncDataBuilder: (ref) => ref.watch(docsProvider),
    ),
  ),
  DashWidgetConfig(
    id: 'delegations',
    label: 'Delegations',
    icon: Icons.sync_alt_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFFA78BFA),
    builder: () => ApiWidgetCard(
      icon: Icons.sync_alt_rounded,
      label: 'Delegations',
      route: Routes.delegations,
      color: const Color(0xFFA78BFA),
      asyncDataBuilder: (ref) => ref.watch(delegationsProvider),
      secondaryLabel: 'pending',
      secondaryFilter: (d) => d['status'] == 'pending',
    ),
  ),
  DashWidgetConfig(
    id: 'pomodoro',
    label: 'Pomodoro',
    icon: Icons.timer_rounded,
    span: GridSpan.half,
    iconColor: const Color(0xFFF97316),
    builder: () => const PomodoroWidgetCard(),
  ),
];

final _widgetMap = {for (final w in allDashWidgets) w.id: w};

// ── Widget visibility state ─────────────────────────────────────────────────

class _WidgetVisibility extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {for (final w in allDashWidgets) w.id: true};

  void toggle(String id) {
    state = {...state, id: !(state[id] ?? true)};
  }

  void show(String id) {
    state = {...state, id: true};
  }
}

final widgetVisibilityProvider =
    NotifierProvider<_WidgetVisibility, Map<String, bool>>(
      _WidgetVisibility.new,
    );

// ── Widget order state ──────────────────────────────────────────────────────

class _WidgetOrder extends Notifier<List<String>> {
  @override
  List<String> build() => allDashWidgets.map((w) => w.id).toList();

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }
}

final widgetOrderProvider = NotifierProvider<_WidgetOrder, List<String>>(
  _WidgetOrder.new,
);

// ── Helpers ─────────────────────────────────────────────────────────────────

String _greeting(AppLocalizations l10n) {
  final hour = DateTime.now().hour;
  if (hour < 12) return l10n.goodMorning;
  if (hour < 17) return l10n.goodAfternoon;
  return l10n.goodEvening;
}

String _resolveWidgetLabel(AppLocalizations l10n, String id) => switch (id) {
  'health_score' => l10n.healthScore,
  'hydration' => l10n.hydration,
  'nutrition' => l10n.nutrition,
  'caffeine' => l10n.caffeine,
  'projects' => l10n.projects,
  'notes' => l10n.notes,
  'agents' => l10n.agents,
  'skills' => l10n.skills,
  'workflows' => l10n.workflows,
  'docs' => l10n.docs,
  'delegations' => l10n.delegations,
  'pomodoro' => l10n.pomodoro,
  _ => id,
};

// ── Summary screen ──────────────────────────────────────────────────────────

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _editMode = false;

  Future<void> _onRefresh() async {
    // Reset banner dismissed state and re-check for updates.
    ref.read(bannerDismissedProvider.notifier).reset();
    ref.invalidate(teamUpdatesProvider);

    // Reload all health data from the server so dashboard reflects latest state
    // across all devices (iPhone, Android, Desktop).
    ref.invalidate(hydrationProvider);
    ref.invalidate(caffeineProvider);
    ref.invalidate(nutritionProvider);
    ref.invalidate(pomodoroProvider);
    ref.invalidate(shutdownProvider);
    ref.invalidate(healthProvider);

    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  void _showHiddenWidgets() {
    final visibility = ref.read(widgetVisibilityProvider);
    final hidden = allDashWidgets
        .where((w) => visibility[w.id] != true)
        .toList();
    if (hidden.isEmpty) return;

    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.bgAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.hiddenWidgets,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hidden.map((w) {
                final color = w.iconColor ?? tokens.accent;
                return GestureDetector(
                  onTap: () {
                    ref.read(widgetVisibilityProvider.notifier).show(w.id);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(w.icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          _resolveWidgetLabel(l10n, w.id),
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Activate WebSocket connection, sync event handler, MCP event handler,
    // and agent desktop notifications.
    ref.watch(syncRealtimeProvider);
    ref.watch(mcpRealtimeProvider);
    ref.watch(agentNotificationsProvider);

    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final authState = ref.watch(authProvider).value;
    final fullName = authState is AuthAuthenticated
        ? authState.user.name
        : l10n.summaryUser;
    final avatarUrl = authState is AuthAuthenticated
        ? resolveAvatarUrl(authState.user.avatarUrl)
        : null;

    final visibility = ref.watch(widgetVisibilityProvider);
    final order = ref.watch(widgetOrderProvider);
    final visibleCards = order
        .where((id) => visibility[id] == true && _widgetMap.containsKey(id))
        .map((id) => _widgetMap[id]!)
        .toList();

    final hasHidden = allDashWidgets.any((w) => visibility[w.id] != true);

    return ColoredBox(
      color: tokens.bg,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: tokens.accent,
          backgroundColor: tokens.bgAlt,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header: Dashboard <-> User ────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        l10n.dashboard,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      _ProfileDropdown(
                        fullName: fullName,
                        avatarUrl: avatarUrl,
                        tokens: tokens,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Team updates banner ────────────────────────────
              const SliverToBoxAdapter(child: TeamUpdatesBanner()),

              // ── Edit bar (only when editing) ─────────────────────
              if (_editMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _editMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: tokens.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.done,
                                  style: TextStyle(
                                    color: tokens.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasHidden) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showHiddenWidgets,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: tokens.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.add,
                                    style: TextStyle(
                                      color: tokens.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Widget grid ──────────────────────────────────────
              WidgetGrid(
                cards: visibleCards,
                editMode: _editMode,
                onLongPress: () {
                  if (!_editMode) {
                    HapticFeedback.mediumImpact();
                    setState(() => _editMode = true);
                  }
                },
                onReorder: (oldIdx, newIdx) {
                  final fullOrder = ref.read(widgetOrderProvider);
                  final oldId = visibleCards[oldIdx].id;
                  final adjNew = newIdx >= visibleCards.length
                      ? visibleCards.length - 1
                      : newIdx;
                  final newId = visibleCards[adjNew].id;
                  final oldFull = fullOrder.indexOf(oldId);
                  final newFull = fullOrder.indexOf(newId);
                  if (oldFull != -1 && newFull != -1) {
                    ref
                        .read(widgetOrderProvider.notifier)
                        .reorder(oldFull, newFull);
                  }
                },
                onRemove: (id) {
                  ref.read(widgetVisibilityProvider.notifier).toggle(id);
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile dropdown ────────────────────────────────────────────────────────

class _ProfileDropdown extends ConsumerWidget {
  const _ProfileDropdown({
    required this.fullName,
    required this.avatarUrl,
    required this.tokens,
  });

  final String fullName;
  final String? avatarUrl;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: tokens.bgAlt,
        surfaceTintColor: Colors.transparent,
        onSelected: (value) {
          switch (value) {
            case 'settings':
              context.push(Routes.settings);
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
          _buildHeader(l10n),
          const PopupMenuDivider(),
          _buildItem('settings', Icons.settings_outlined, l10n.settings),
          _buildItem('switch_team', Icons.group_outlined, l10n.switchTeam),
          _buildItem(
            'switch_workspace',
            Icons.folder_outlined,
            l10n.switchWorkspace,
          ),
          const PopupMenuDivider(),
          _buildItem(
            'logout',
            Icons.logout_rounded,
            l10n.signOut,
            isDestructive: true,
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _greeting(l10n),
                  style: TextStyle(color: tokens.fgDim, fontSize: 12),
                ),
                Text(
                  fullName,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: tokens.accent.withValues(alpha: 0.2),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: tokens.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildHeader(AppLocalizations l10n) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tokens.accent.withValues(alpha: 0.2),
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: tokens.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.personalWorkspace,
                style: TextStyle(color: tokens.fgDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildItem(
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
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
