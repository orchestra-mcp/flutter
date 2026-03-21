import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/features/health/health_notification_service.dart';
import 'package:orchestra/platform/web/web_token_handler.dart'
    if (dart.library.io) 'package:orchestra/platform/stub/web_token_handler_stub.dart';
import 'package:orchestra/screens/auth/auth_callback_screen.dart';
import 'package:orchestra/screens/auth/forgot_password_screen.dart';
import 'package:orchestra/screens/auth/login_screen.dart';
import 'package:orchestra/screens/auth/magic_callback_screen.dart';
import 'package:orchestra/screens/auth/magic_login_screen.dart';
import 'package:orchestra/screens/auth/passkey_screen.dart';
import 'package:orchestra/screens/auth/register_screen.dart';
import 'package:orchestra/screens/auth/reset_password_screen.dart';
import 'package:orchestra/screens/auth/two_factor_screen.dart';
import 'package:orchestra/screens/health/health_page_wrapper.dart';
import 'package:orchestra/screens/health/health_screen.dart';
import 'package:orchestra/screens/health/tabs/caffeine_tab.dart';
import 'package:orchestra/screens/health/tabs/daily_flow_tab.dart';
import 'package:orchestra/screens/health/tabs/health_score_tab.dart';
import 'package:orchestra/screens/health/tabs/hydration_tab.dart';
import 'package:orchestra/screens/health/tabs/nutrition_tab.dart';
import 'package:orchestra/screens/health/tabs/pomodoro_tab.dart';
import 'package:orchestra/screens/health/tabs/shutdown_tab.dart';
import 'package:orchestra/screens/health/tabs/sleep_tab.dart';
import 'package:orchestra/screens/health/tabs/vitals_tab.dart';
import 'package:orchestra/screens/health/tabs/weight_tab.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/screens/installer/installer_screen.dart';
import 'package:orchestra/screens/setup_desktop/file_access_screen.dart';
import 'package:orchestra/screens/setup_desktop/setup_desktop_screen.dart';
import 'package:orchestra/screens/welcome/welcome_screen.dart';
import 'package:orchestra/screens/notifications/notifications_screen.dart';
import 'package:orchestra/screens/onboarding/onboarding_screen.dart';
import 'package:orchestra/screens/settings/report_issue_screen.dart';
import 'package:orchestra/screens/settings/settings_screen.dart';
import 'package:orchestra/screens/shell/app_shell.dart';
import 'package:orchestra/screens/activity/mcp_activity_screen.dart';
import 'package:orchestra/screens/library/agents_screen.dart';
import 'package:orchestra/screens/library/delegations_screen.dart';
import 'package:orchestra/screens/library/docs_screen.dart';
import 'package:orchestra/screens/library/library_detail_screen.dart';
import 'package:orchestra/screens/library/delegation_detail_screen.dart';
import 'package:orchestra/screens/library/note_detail_screen.dart';
import 'package:orchestra/screens/library/note_editor_screen.dart';
import 'package:orchestra/screens/library/mcp_entity_editor.dart';
import 'package:orchestra/screens/library/notes_screen.dart';
import 'package:orchestra/screens/library/skills_screen.dart';
import 'package:orchestra/screens/library/workflows_screen.dart';
import 'package:orchestra/screens/workflow/workflow_builder_screen.dart';
import 'package:orchestra/screens/projects/feature_detail_screen.dart';
import 'package:orchestra/screens/projects/person_detail_screen.dart';
import 'package:orchestra/screens/projects/plan_detail_screen.dart';
import 'package:orchestra/screens/projects/project_detail_screen.dart';
import 'package:orchestra/screens/projects/projects_screen.dart';
import 'package:orchestra/screens/projects/request_detail_screen.dart';
import 'package:orchestra/screens/splash/splash_screen.dart';
import 'package:orchestra/screens/summary/summary_screen.dart';
import 'package:orchestra/screens/devtools/api_collections_screen.dart';
import 'package:orchestra/screens/devtools/database_browser_screen.dart';
import 'package:orchestra/screens/devtools/log_runner_screen.dart';
import 'package:orchestra/screens/devtools/prompts_screen.dart';
import 'package:orchestra/screens/devtools/secrets_screen.dart';
import 'package:orchestra/screens/terminal/terminal_screen.dart';
import 'package:orchestra/screens/web/admin/admin_overview_page.dart';
import 'package:orchestra/screens/web/admin/categories_page.dart';
import 'package:orchestra/screens/web/admin/community_page.dart';
import 'package:orchestra/screens/web/admin/contact_admin_page.dart';
import 'package:orchestra/screens/web/admin/docs_admin_page.dart';
import 'package:orchestra/screens/web/admin/issues_page.dart';
import 'package:orchestra/screens/web/admin/marketplace_page.dart';
import 'package:orchestra/screens/web/admin/notifications_admin_page.dart';
import 'package:orchestra/screens/web/admin/pages_admin_page.dart';
import 'package:orchestra/screens/web/admin/posts_page.dart';
import 'package:orchestra/screens/web/admin/roles_page.dart';
import 'package:orchestra/screens/web/admin/sponsors_page.dart';
import 'package:orchestra/screens/web/admin/team_detail_page.dart';
import 'package:orchestra/screens/web/admin/teams_page.dart';
import 'package:orchestra/screens/web/admin/user_detail_page.dart';
import 'package:orchestra/screens/web/admin/users_page.dart';

// ── Route paths ─────────────────────────────────────────────────────────────

abstract final class Routes {
  // Public / auth
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const twoFactor = '/two-factor';
  static const magicLogin = '/magic-login';
  static const passkey = '/passkey';
  static const authCallback = '/auth/callback';
  static const authMagic = '/auth/magic';

  // Shell tabs
  static const summary = '/summary';
  static const notifications = '/notifications';

  // Modal
  static const search = '/search';

  // Projects
  static const projects = '/projects';
  static String project(String id) => '/projects/$id';
  static String projectFeature(String projectId, String featureId) =>
      '/projects/$projectId/features/$featureId';
  static String projectPlan(String projectId, String planId) =>
      '/projects/$projectId/plans/$planId';
  static String projectRequest(String projectId, String requestId) =>
      '/projects/$projectId/requests/$requestId';
  static String projectPerson(String projectId, String personId) =>
      '/projects/$projectId/persons/$personId';

  // Library
  static const notes = '/library/notes';
  static String note(String id) => '/library/notes/$id';
  static const agents = '/library/agents';
  static String agent(String id) => '/library/agents/$id';
  static const skills = '/library/skills';
  static String skill(String id) => '/library/skills/$id';
  static const workflows = '/library/workflows';
  static String workflow(String id) => '/library/workflows/$id';
  static const docs = '/library/docs';
  static String doc(String id) => '/library/docs/$id';
  static const delegations = '/library/delegations';
  static String delegation(String id) => '/library/delegations/$id';

  // DevTools
  static const devtoolsApi = '/devtools/api';
  static const devtoolsDatabase = '/devtools/database';
  static const devtoolsLogs = '/devtools/logs';
  static const devtoolsSecrets = '/devtools/secrets';
  static const devtoolsPrompts = '/devtools/prompts';

  // Terminal
  static const terminal = '/terminal';

  // Activity
  static const activity = '/activity';

  // Health
  static const health = '/health';
  static const healthScore = '/health/score';
  static const healthVitals = '/health/vitals';
  static const healthFlow = '/health/flow';
  static const healthHydration = '/health/hydration';
  static const healthCaffeine = '/health/caffeine';
  static const healthNutrition = '/health/nutrition';
  static const healthPomodoro = '/health/pomodoro';
  static const healthShutdown = '/health/shutdown';
  static const healthWeight = '/health/weight';
  static const healthSleep = '/health/sleep';

  // Installer / startup gates
  static const installer = '/installer';
  static const welcome = '/welcome';
  static const setupDesktop = '/setup-desktop';
  static const fileAccess = '/file-access';

  // Settings — account
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsPassword = '/settings/password';
  static const settingsAppearance = '/settings/appearance';
  // Settings — security
  static const settingsTwoFactor = '/settings/two-factor';
  static const settingsPasskeys = '/settings/passkeys';
  static const settingsSessions = '/settings/sessions';
  // Settings — developer
  static const settingsApiTokens = '/settings/api-tokens';
  static const settingsIntegrations = '/settings/integrations';
  // Settings — notifications
  static const settingsNotifications = '/settings/notifications';
  // Settings — health
  static const settingsHealth = '/settings/health';
  // Settings — other
  static const settingsTeam = '/settings/team';
  static const settingsSecurity = '/settings/security';
  static const settingsDesktop = '/settings/desktop';
  static const settingsAbout = '/settings/about';
  static const settingsSocial = '/settings/social';
  static const settingsReportIssue = '/settings/report-issue';
  // Settings — Claude / AI
  static const settingsAgentInstructions = '/settings/agent-instructions';
  static const settingsClaudeSettings = '/settings/claude-settings';
  // Settings — admin-only
  static const settingsAdminGeneral = '/settings/admin-general';
  static const settingsAdminFeatures = '/settings/admin-features';
  static const settingsAdminHomepage = '/settings/admin-homepage';
  static const settingsAdminAgents = '/settings/admin-agents';
  static const settingsAdminEmail = '/settings/admin-email';
  static const settingsAdminContact = '/settings/admin-contact';
  static const settingsAdminPricing = '/settings/admin-pricing';
  static const settingsAdminDownload = '/settings/admin-download';
  static const settingsAdminIntegrations = '/settings/admin-integrations';
  static const settingsAdminSeo = '/settings/admin-seo';
  static const settingsAdminDiscord = '/settings/admin-discord';
  static const settingsAdminSlack = '/settings/admin-slack';
  static const settingsAdminGithub = '/settings/admin-github';
  static const settingsAdminSocial = '/settings/admin-social';
  static const settingsAdminPrompts = '/settings/admin-prompts';

  // Admin panel
  static const admin = '/admin';
  static const adminUsers = '/admin/users';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static const adminRoles = '/admin/roles';
  static const adminTeams = '/admin/teams';
  static String adminTeamDetail(String id) => '/admin/teams/$id';
  static const adminPosts = '/admin/posts';
  static const adminPages = '/admin/pages';
  static const adminDocs = '/admin/docs';
  static const adminCategories = '/admin/categories';
  static const adminCommunity = '/admin/community';
  static const adminContact = '/admin/contact';
  static const adminIssues = '/admin/issues';
  static const adminMarketplace = '/admin/marketplace';
  static const adminSponsors = '/admin/sponsors';
  static const adminNotifications = '/admin/notifications';
}

// ── Auth-guarded routes ───────────────────────────────────────────────────────

const _authRoutes = {
  Routes.login,
  Routes.register,
  Routes.forgotPassword,
  Routes.resetPassword,
  Routes.twoFactor,
  Routes.magicLogin,
  Routes.passkey,
  Routes.authCallback,
  Routes.authMagic,
  Routes.onboarding,
  Routes.splash,
  Routes.installer,
  Routes.welcome,
  Routes.setupDesktop,
  Routes.fileAccess,
};

String? _authRedirect(AuthState? authState, GoRouterState state) {
  if (authState == null) return null; // still loading

  final isAuthRoute =
      _authRoutes.contains(state.matchedLocation) ||
      state.matchedLocation.startsWith('/auth/');

  if (authState is AuthUnauthenticated && !isAuthRoute) {
    // On web, redirect to marketing site login instead of Flutter login screen.
    if (kIsWeb) {
      redirectToMarketingLogin();
      return Routes.splash; // show splash while browser redirects
    }
    return Routes.login;
  }
  if (authState is AuthAuthenticated &&
      (state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register)) {
    // Consume any pending notification deep link.
    final deepLink = HealthNotificationService.pendingDeepLink;
    if (deepLink != null) {
      HealthNotificationService.pendingDeepLink = null;
      return deepLink;
    }
    return Routes.summary;
  }
  return null;
}

// ── Placeholder for routes without real screens yet ─────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

// ── Router factory ────────────────────────────────────────────────────────────

// Routes that correspond to startup gate screens.
const _gateRoutes = {Routes.fileAccess, Routes.installer, Routes.welcome};

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      // ── Startup gate redirect (runs before auth) ──────────────────────
      final gate = ref.read(startupGateProvider).value;
      if (gate != null && gate != StartupGate.checking) {
        final loc = state.matchedLocation;
        final isGateRoute = _gateRoutes.contains(loc);

        switch (gate) {
          case StartupGate.needsInstall:
            if (loc != Routes.installer) return Routes.installer;
          case StartupGate.needsFileAccess:
            if (loc != Routes.fileAccess) return Routes.fileAccess;
          case StartupGate.needsWorkspace:
            if (loc != Routes.welcome) return Routes.welcome;
          case StartupGate.needsDesktop:
            // Mobile/web: don't block the app globally. Desktop gate only
            // applies to sync-dependent screens (projects, library, terminal).
            break;
          case StartupGate.ready:
            // If user is on a gate route but gate is now ready, bounce to splash.
            if (isGateRoute) return Routes.splash;
          case StartupGate.checking:
            break;
        }
      }

      // ── Auth redirect ─────────────────────────────────────────────────
      final authState = ref.read(authProvider).value;
      return _authRedirect(authState, state);
    },
    routes: [
      // ── Public routes (no shell) ────────────────────────────────────────
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: Routes.twoFactor,
        builder: (_, __) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: Routes.magicLogin,
        builder: (_, __) => const MagicLoginScreen(),
      ),
      GoRoute(path: Routes.passkey, builder: (_, __) => const PasskeyScreen()),
      GoRoute(
        path: Routes.authCallback,
        builder: (_, state) => AuthCallbackScreen(
          token: state.uri.queryParameters['token'],
          error: state.uri.queryParameters['error'],
        ),
      ),
      GoRoute(
        path: Routes.authMagic,
        builder: (_, state) =>
            MagicCallbackScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: Routes.fileAccess,
        builder: (_, __) => const FileAccessScreen(),
      ),
      GoRoute(
        path: Routes.installer,
        builder: (_, __) => const InstallerScreen(),
      ),
      GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: Routes.setupDesktop,
        builder: (_, __) => const SetupDesktopScreen(),
      ),

      // ── Shell routes (nav bar visible) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Summary (home)
          GoRoute(
            path: Routes.summary,
            builder: (_, __) => const SummaryScreen(),
          ),

          // Health
          GoRoute(
            path: Routes.health,
            builder: (_, __) => const HealthScreen(),
            routes: [
              GoRoute(
                path: 'score',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.healthScore,
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                  child: const HealthScoreTab(),
                ),
              ),
              GoRoute(
                path: 'vitals',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.vitals,
                  icon: Icons.monitor_heart_rounded,
                  iconColor: const Color(0xFFF43F5E),
                  child: const VitalsTab(),
                ),
              ),
              GoRoute(
                path: 'flow',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.dailyFlow,
                  icon: Icons.auto_graph_rounded,
                  iconColor: const Color(0xFF818CF8),
                  child: const DailyFlowTab(),
                ),
              ),
              GoRoute(
                path: 'hydration',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.hydration,
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  child: const HydrationTab(),
                ),
              ),
              GoRoute(
                path: 'caffeine',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.caffeine,
                  icon: Icons.coffee_rounded,
                  iconColor: const Color(0xFFF97316),
                  child: const CaffeineTab(),
                ),
              ),
              GoRoute(
                path: 'nutrition',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.nutrition,
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF4ADE80),
                  child: const NutritionTab(),
                ),
              ),
              GoRoute(
                path: 'pomodoro',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.pomodoro,
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFFF97316),
                  child: const PomodoroTab(),
                ),
              ),
              GoRoute(
                path: 'shutdown',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.shutdown,
                  icon: Icons.nightlight_rounded,
                  iconColor: const Color(0xFF6366F1),
                  child: const ShutdownTab(),
                ),
              ),
              GoRoute(
                path: 'weight',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.weight,
                  icon: Icons.monitor_weight_rounded,
                  iconColor: const Color(0xFF14B8A6),
                  child: const WeightTab(),
                ),
              ),
              GoRoute(
                path: 'sleep',
                builder: (_, __) => HealthPageWrapper(
                  titleResolver: (l10n) => l10n.sleep,
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  child: const SleepTab(),
                ),
              ),
            ],
          ),

          // Notifications
          GoRoute(
            path: Routes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),

          // Projects
          GoRoute(
            path: Routes.projects,
            builder: (_, _) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => ProjectDetailScreen(
                  projectId: s.pathParameters['id'] ?? '',
                ),
                routes: [
                  GoRoute(
                    path: 'features/new',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.feature,
                      projectId: s.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'features/:featureId',
                    builder: (_, s) => FeatureDetailScreen(
                      featureId: s.pathParameters['featureId'] ?? '',
                      projectId: s.pathParameters['id'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, s) => McpEntityEditorScreen(
                          entityType: McpEntityType.feature,
                          entityId: s.pathParameters['featureId'],
                          projectId: s.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'plans/new',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.plan,
                      projectId: s.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'plans/:planId',
                    builder: (_, s) => PlanDetailScreen(
                      projectId: s.pathParameters['id'] ?? '',
                      planId: s.pathParameters['planId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, s) => McpEntityEditorScreen(
                          entityType: McpEntityType.plan,
                          entityId: s.pathParameters['planId'],
                          projectId: s.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'requests/new',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.request,
                      projectId: s.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'requests/:requestId',
                    builder: (_, s) => RequestDetailScreen(
                      projectId: s.pathParameters['id'] ?? '',
                      requestId: s.pathParameters['requestId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, s) => McpEntityEditorScreen(
                          entityType: McpEntityType.request,
                          entityId: s.pathParameters['requestId'],
                          projectId: s.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'persons/new',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.person,
                      projectId: s.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'persons/:personId',
                    builder: (_, s) => PersonDetailScreen(
                      projectId: s.pathParameters['id'] ?? '',
                      personId: s.pathParameters['personId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, s) => McpEntityEditorScreen(
                          entityType: McpEntityType.person,
                          entityId: s.pathParameters['personId'],
                          projectId: s.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Library — notes
          GoRoute(
            path: Routes.notes,
            builder: (_, _) => const NotesScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, _) => const NoteEditorScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    NoteDetailScreen(noteId: s.pathParameters['id'] ?? ''),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) =>
                        NoteEditorScreen(noteId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),

          // Library — agents
          GoRoute(
            path: Routes.agents,
            builder: (_, _) => const AgentsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const McpEntityEditorScreen(
                  entityType: McpEntityType.agent,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) => LibraryDetailScreen(
                  itemId: s.pathParameters['id'] ?? '',
                  itemType: LibraryItemType.agent,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.agent,
                      entityId: s.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Library — skills
          GoRoute(
            path: Routes.skills,
            builder: (_, _) => const SkillsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const McpEntityEditorScreen(
                  entityType: McpEntityType.skill,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) => LibraryDetailScreen(
                  itemId: s.pathParameters['id'] ?? '',
                  itemType: LibraryItemType.skill,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.skill,
                      entityId: s.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Library — workflows
          GoRoute(
            path: Routes.workflows,
            builder: (_, _) => const WorkflowsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const WorkflowBuilderScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) => LibraryDetailScreen(
                  itemId: s.pathParameters['id'] ?? '',
                  itemType: LibraryItemType.workflow,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.workflow,
                      entityId: s.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'build',
                    builder: (_, s) => WorkflowBuilderScreen(
                      workflowId: s.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Library — docs
          GoRoute(
            path: Routes.docs,
            builder: (_, _) => const DocsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) =>
                    const McpEntityEditorScreen(entityType: McpEntityType.doc),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) => LibraryDetailScreen(
                  itemId: s.pathParameters['id'] ?? '',
                  itemType: LibraryItemType.doc,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => McpEntityEditorScreen(
                      entityType: McpEntityType.doc,
                      entityId: s.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: Routes.delegations,
            builder: (_, _) => const DelegationsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => DelegationDetailScreen(
                  delegationId: s.pathParameters['id'] ?? '',
                ),
              ),
            ],
          ),

          // DevTools
          GoRoute(
            path: '/devtools',
            redirect: (_, __) => Routes.devtoolsApi,
          ),
          GoRoute(
            path: Routes.devtoolsApi,
            builder: (_, _) => const ApiCollectionsScreen(),
          ),
          GoRoute(
            path: Routes.devtoolsDatabase,
            builder: (_, _) => const DatabaseBrowserScreen(),
          ),
          GoRoute(
            path: Routes.devtoolsLogs,
            builder: (_, _) => const LogRunnerScreen(),
          ),
          GoRoute(
            path: Routes.devtoolsSecrets,
            builder: (_, _) => const SecretsScreen(),
          ),
          GoRoute(
            path: Routes.devtoolsPrompts,
            builder: (_, _) => const PromptsScreen(),
          ),

          // Terminal
          GoRoute(
            path: Routes.terminal,
            builder: (_, _) => const TerminalScreen(),
          ),

          // Activity — MCP action log
          GoRoute(
            path: Routes.activity,
            builder: (_, _) => const McpActivityScreen(),
          ),

          // Settings (inside shell so desktop wraps it)
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
            routes: [
              // Account
              GoRoute(
                path: 'profile',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'password',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'appearance',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Security
              GoRoute(
                path: 'two-factor',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'passkeys',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'sessions',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'security',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Developer
              GoRoute(
                path: 'api-tokens',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'integrations',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Notifications
              GoRoute(
                path: 'notifications',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Health
              GoRoute(
                path: 'health',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Other
              GoRoute(path: 'team', builder: (_, _) => const SettingsScreen()),
              GoRoute(
                path: 'desktop',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(path: 'about', builder: (_, _) => const SettingsScreen()),
              GoRoute(
                path: 'social',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'report-issue',
                builder: (_, _) => const ReportIssueScreen(),
              ),
              // Claude / AI
              GoRoute(
                path: 'agent-instructions',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'claude-settings',
                builder: (_, _) => const SettingsScreen(),
              ),
              // Admin settings
              GoRoute(
                path: 'admin-general',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-features',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-homepage',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-agents',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-email',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-contact',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-pricing',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-download',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-integrations',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-seo',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-discord',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-slack',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-github',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-social',
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'admin-prompts',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),

          // Admin panel — NoTransitionPage prevents bleed-through between pages
          GoRoute(
            path: Routes.admin,
            pageBuilder: (_, s) =>
                const NoTransitionPage(child: AdminOverviewPage()),
            routes: [
              GoRoute(
                path: 'users',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: UsersPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, s) => NoTransitionPage(
                      child: UserDetailPage(
                        userId: s.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'roles',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: RolesPage()),
              ),
              GoRoute(
                path: 'teams',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: TeamsPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (_, s) => NoTransitionPage(
                      child: TeamDetailPage(
                        teamId: s.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'posts',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: PostsPage()),
              ),
              GoRoute(
                path: 'pages',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: PagesAdminPage()),
              ),
              GoRoute(
                path: 'docs',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: DocsAdminPage()),
              ),
              GoRoute(
                path: 'categories',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: CategoriesPage()),
              ),
              GoRoute(
                path: 'community',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: CommunityPage()),
              ),
              GoRoute(
                path: 'contact',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: ContactAdminPage()),
              ),
              GoRoute(
                path: 'issues',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: IssuesPage()),
              ),
              GoRoute(
                path: 'marketplace',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: MarketplacePage()),
              ),
              GoRoute(
                path: 'sponsors',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: SponsorsPage()),
              ),
              GoRoute(
                path: 'notifications',
                pageBuilder: (_, s) =>
                    const NoTransitionPage(child: NotificationsAdminPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ── Auth state listenable ─────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(startupGateProvider, (_, __) => notifyListeners());
  }
}
