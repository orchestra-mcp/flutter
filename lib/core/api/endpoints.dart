/// All Orchestra API endpoint path constants.
abstract final class Endpoints {
  // ── Auth ──────────────────────────────────────────────────────────────
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authLogout = '/api/auth/logout';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authMagicLinkSend = '/api/auth/magic-link/send';
  static const String authMagicLinkVerify = '/api/auth/magic-link/verify';
  static const String auth2faSetup = '/api/auth/2fa/setup';
  static const String auth2faConfirm = '/api/auth/2fa/confirm';
  static const String auth2faDisable = '/api/auth/2fa/disable';
  static const String auth2faVerify = '/api/auth/2fa/verify';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authDeleteAccount = '/api/auth/account';

  // ── Passkeys ─────────────────────────────────────────────────────────
  static const String settingsPasskeys = '/api/settings/passkeys';
  static String settingsPasskey(int id) => '/api/settings/passkeys/$id';

  // ── OAuth ────────────────────────────────────────────────────────────
  static String authOAuth(String provider) => '/api/auth/oauth/$provider';

  // ── OAuth2 Provider (Orchestra as auth server) ─────────────────────
  static const String adminOAuthApps = '/api/admin/oauth-apps';
  static String adminOAuthApp(int id) => '/api/admin/oauth-apps/$id';
  static const String settingsConnectedApps = '/api/settings/connected-apps';
  static String settingsRevokeApp(String appId) =>
      '/api/settings/connected-apps/$appId';

  // ── Devices ───────────────────────────────────────────────────────────
  static const String devicesRegister = '/api/sync/devices/register';

  // ── Profile ───────────────────────────────────────────────────────────
  static const String profile = '/api/auth/me';
  static const String updateProfile = '/api/auth/profile';

  // ── Dashboard ────────────────────────────────────────────────────────
  static const String dashboard = '/api/dashboard';

  // ── Projects ──────────────────────────────────────────────────────────
  static const String projects = '/api/projects';
  static String project(String slug) => '/api/projects/$slug';
  static String projectTree(String slug) => '/api/projects/$slug/tree';
  static String projectStats(String slug) => '/api/projects/$slug/stats';

  // ── Features ──────────────────────────────────────────────────────────
  static String projectFeatures(String projectSlug) =>
      '/api/projects/$projectSlug/features';
  static String feature(String id) => '/api/features/$id';

  // ── Plans ──────────────────────────────────────────────────────────────
  static String projectPlans(String projectSlug) =>
      '/api/projects/$projectSlug/plans';
  static String projectPlan(String projectSlug, String planId) =>
      '/api/projects/$projectSlug/plans/$planId';

  // ── Requests ─────────────────────────────────────────────────────────
  static String projectRequests(String projectSlug) =>
      '/api/projects/$projectSlug/requests';
  static String request(String id) => '/api/requests/$id';

  // ── Persons ─────────────────────────────────────────────────────────
  static const String persons = '/api/persons';
  static String projectPersons(String projectSlug) =>
      '/api/projects/$projectSlug/persons';
  static String person(String id) => '/api/persons/$id';

  // ── Notes ─────────────────────────────────────────────────────────────
  static const String notes = '/api/notes';
  static String note(String id) => '/api/notes/$id';

  // ── Agents ────────────────────────────────────────────────────────────
  static const String agents = '/api/agents';
  static String agent(String id) => '/api/agents/$id';

  // ── Skills ────────────────────────────────────────────────────────────
  static const String skills = '/api/skills';
  static String skill(String id) => '/api/skills/$id';

  // ── Workflows ─────────────────────────────────────────────────────────
  static const String workflows = '/api/workflows';
  static String workflow(String id) => '/api/workflows/$id';

  // ── Docs ──────────────────────────────────────────────────────────────
  static const String docs = '/api/docs';
  static String doc(String id) => '/api/docs/$id';

  // ── AI Sessions ──────────────────────────────────────────────────────
  static const String sessions = '/api/ai/sessions';
  static String session(String id) => '/api/ai/sessions/$id';

  // ── Delegations ───────────────────────────────────────────────────────
  static const String delegations = '/api/delegations';
  static String delegation(String id) => '/api/delegations/$id';
  static String delegationRespond(String id) => '/api/delegations/$id/respond';

  // ── Notifications ────────────────────────────────────────────────────
  static const String notifications = '/api/notifications';
  static const String notificationsReadAll = '/api/notifications/read-all';
  static String notificationRead(String id) => '/api/notifications/$id/read';

  // ── MCP Tools Proxy ──────────────────────────────────────────────────
  static const String mcpToolsCall = '/api/mcp/tools/call';

  // ── Search ────────────────────────────────────────────────────────────
  static const String search = '/api/search';
  static const String searchSuggestions = '/api/search/suggestions';

  // ── Teams ─────────────────────────────────────────────────────────────
  static const String teams = '/api/teams';
  static const String myTeam = '/api/team';
  static const String myTeamMembers = '/api/team/members';
  static const String teamAvatar = '/api/team/avatar';
  static String teamShow(String id) => '/api/teams/$id';
  static String teamInvite(String id) => '/api/teams/$id/invite';
  static String teamFeatures(String teamId) => '/api/teams/$teamId/features';
  static String teamProjects(String teamId) => '/api/teams/$teamId/projects';
  static String teamAnalytics(String teamId) => '/api/teams/$teamId/analytics';
  static String teamMembers(String teamId) => '/api/teams/$teamId/members';
  static String teamMemberRole(String memberId) =>
      '/api/team/members/$memberId/role';
  static String teamMemberRemove(String memberId) =>
      '/api/team/members/$memberId';

  // ── Workspaces ───────────────────────────────────────────────────────
  static const String workspaces = '/api/workspaces';
  static String workspace(String id) => '/api/workspaces/$id';

  // ── Tunnels ──────────────────────────────────────────────────────────
  static const String tunnels = '/api/tunnels';
  static String tunnel(String id) => '/api/tunnels/$id';
  static String tunnelActions(String id) => '/api/tunnels/$id/actions';
  static String tunnelStatus(String id) => '/api/tunnels/$id/status';
  static String tunnelWs(String id) => '/api/tunnels/$id/ws';

  // ── Health ───────────────────────────────────────────────────────────
  static const String healthProfile = '/api/health/profile';
  static const String healthSummary = '/api/health/summary';
  static const String healthWater = '/api/health/water';
  static const String healthWaterStatus = '/api/health/water/status';
  static const String healthMeals = '/api/health/meals';
  static const String healthCaffeine = '/api/health/caffeine';
  static const String healthCaffeineScore = '/api/health/caffeine/score';
  static const String healthPomodoro = '/api/health/pomodoro';
  static const String healthPomodoroStart = '/api/health/pomodoro/start';
  static String healthPomodoroEnd(String id) => '/api/health/pomodoro/$id/end';
  static const String healthShutdownStatus = '/api/health/shutdown/status';
  static const String healthShutdownStart = '/api/health/shutdown/start';
  static const String healthSnapshots = '/api/health/snapshots';

  // ── Sync ──────────────────────────────────────────────────────────────
  static const String syncPush = '/api/sync/push';
  static const String syncPull = '/api/sync/pull';
  static const String syncStatus = '/api/sync/status';

  // ── Settings ─────────────────────────────────────────────────────────
  static const String settingsPreferences = '/api/settings/preferences';
  static const String settingsSessions = '/api/settings/sessions';
  static String settingsSession(String id) => '/api/settings/sessions/$id';
  static const String settingsApiKeys = '/api/settings/api-keys';
  static String settingsApiKey(String id) => '/api/settings/api-keys/$id';
  static const String settingsConnectedAccounts =
      '/api/settings/connected-accounts';
  static String settingsUnlinkAccount(String provider) =>
      '/api/settings/connected-accounts/$provider';
  static const String settingsProfile = '/api/settings/profile';
  static const String settingsAvatar = '/api/settings/avatar';
  static const String settingsCover = '/api/settings/cover';
  static const String changePassword = '/api/auth/password';

  // ── Admin ────────────────────────────────────────────────────────────

  // Dashboard
  static const String adminStats = '/api/admin/stats';

  // Users
  static const String adminUsers = '/api/admin/users';
  static String adminUser(int id) => '/api/admin/users/$id';
  static String adminUserRole(int id) => '/api/admin/users/$id/role';
  static String adminUserStatus(int id) => '/api/admin/users/$id/status';
  static String adminUserProjects(int id) => '/api/admin/users/$id/projects';
  static String adminUserNotes(int id) => '/api/admin/users/$id/notes';
  static String adminUserSessions(int id) => '/api/admin/users/$id/sessions';
  static String adminUserTeams(int id) => '/api/admin/users/$id/teams';
  static String adminUserIssues(int id) => '/api/admin/users/$id/issues';
  static String adminUserMemberships(int id) =>
      '/api/admin/users/$id/memberships';
  static String adminUserMembership(int id, int teamId) =>
      '/api/admin/users/$id/memberships/$teamId';
  static String adminUserPassword(int id) => '/api/admin/users/$id/password';
  static String adminUserNotify(int id) => '/api/admin/users/$id/notify';
  static String adminUserImpersonate(int id) =>
      '/api/admin/users/$id/impersonate';
  static String adminUserSuspend(int id) => '/api/admin/users/$id/suspend';
  static String adminUserUnsuspend(int id) => '/api/admin/users/$id/unsuspend';
  static String adminUserVerify(int id) => '/api/admin/users/$id/verify';
  static String adminUserUnverify(int id) => '/api/admin/users/$id/unverify';

  // Teams
  static const String adminTeams = '/api/admin/teams';
  static String adminTeam(int id) => '/api/admin/teams/$id';
  static String adminTeamMembers(int id) => '/api/admin/teams/$id/members';
  static String adminTeamMember(int teamId, int userId) =>
      '/api/admin/teams/$teamId/members/$userId';

  // Settings
  static const String adminSettings = '/api/admin/settings';
  static String adminSetting(String key) => '/api/admin/settings/$key';
  static const String adminTestEmail = '/api/admin/settings/test-email';
  static const String adminGenerateSitemap =
      '/api/admin/settings/generate-sitemap';

  // Pages
  static const String adminPages = '/api/admin/pages';
  static String adminPage(int id) => '/api/admin/pages/$id';

  // Categories
  static const String adminCategories = '/api/admin/categories';
  static String adminCategory(int id) => '/api/admin/categories/$id';

  // Contact
  static const String adminContact = '/api/admin/contact';
  static String adminContactStatus(int id) => '/api/admin/contact/$id/status';
  static String adminContactMessage(int id) => '/api/admin/contact/$id';

  // Issues
  static const String adminIssues = '/api/admin/issues';
  static String adminIssue(int id) => '/api/admin/issues/$id';

  // Notifications
  static const String adminNotifications = '/api/admin/notifications';
  static const String adminNotificationSend = '/api/admin/notifications/send';

  // Sponsors
  static const String adminSponsors = '/api/admin/sponsors';
  static String adminSponsor(int id) => '/api/admin/sponsors/$id';

  // Community
  static const String adminCommunityPosts = '/api/admin/community/posts';
  static String adminCommunityPost(int id) => '/api/admin/community/posts/$id';

  // GitHub
  static const String adminGitHubIssues = '/api/admin/github/issues';
  static const String adminGitHubSync = '/api/admin/github/sync';
  static String adminGitHubIssue(int id) => '/api/admin/github/issues/$id';
  static const String adminGitHubRepos = '/api/admin/github/repos';

  // ── Hook Events (MCP event log) ─────────────────────────────────────
  static const String hookEvents = '/api/hooks/events';

  // ── Issues ───────────────────────────────────────────────────────────
  static const String issues = '/api/issues';
}
