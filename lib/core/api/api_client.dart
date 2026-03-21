/// Abstract API client — implemented by [RestClient] (REST/Dio) and
/// [McpTcpClient] (local orchestrator subprocess via JSON-RPC 2.0).
abstract class ApiClient {
  // ── Auth ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(Map<String, dynamic> body);
  Future<Map<String, dynamic>> register(Map<String, dynamic> body);
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body);

  // ── Profile ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateSettingsProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>> uploadAvatar(String filePath);

  // ── Projects ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listProjects();
  Future<Map<String, dynamic>> getProject(String id);
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateProject(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteProject(String id);

  // ── Features ──────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listFeatures({String? projectId});
  Future<Map<String, dynamic>> getFeature(String id);
  Future<Map<String, dynamic>> createFeature(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateFeature(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteFeature(String id);

  // ── Plans ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listPlans({required String projectSlug});
  Future<Map<String, dynamic>> getPlan(String projectSlug, String planId);
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updatePlan(String id, Map<String, dynamic> body);
  Future<void> deletePlan(String id);

  // ── Requests ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listRequests({String? projectSlug});
  Future<Map<String, dynamic>> getRequest(String id);
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateRequest(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteRequest(String id);

  // ── Persons ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listPersons({String? projectSlug});
  Future<Map<String, dynamic>> getPerson(String id);
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updatePerson(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deletePerson(String id);

  // ── Notes ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listNotes();
  Future<Map<String, dynamic>> getNote(String id);
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateNote(String id, Map<String, dynamic> body);
  Future<void> deleteNote(String id);

  // ── Library ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listAgents();
  Future<Map<String, dynamic>> getAgent(String id);
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateAgent(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAgent(String id);

  Future<List<Map<String, dynamic>>> listSkills();
  Future<Map<String, dynamic>> getSkill(String id);
  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateSkill(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteSkill(String id);

  Future<List<Map<String, dynamic>>> listWorkflows();
  Future<Map<String, dynamic>> getWorkflow(String id);
  Future<Map<String, dynamic>> createWorkflow(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateWorkflow(
    String id,
    Map<String, dynamic> body,
  );
  Future<void> deleteWorkflow(String id);

  Future<List<Map<String, dynamic>>> listDocs();
  Future<Map<String, dynamic>> getDoc(String id);
  Future<Map<String, dynamic>> createDoc(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateDoc(String id, Map<String, dynamic> body);
  Future<void> deleteDoc(String id);

  Future<List<Map<String, dynamic>>> listSessions();
  Future<List<Map<String, dynamic>>> listDelegations();
  Future<Map<String, dynamic>> respondDelegation(String id, String response);

  // ── Teams ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listTeams();
  Future<Map<String, dynamic>> getMyTeam();
  Future<List<Map<String, dynamic>>> listTeamMembers(String teamId);
  Future<Map<String, dynamic>> createTeam(String name);
  Future<Map<String, dynamic>> updateTeam(Map<String, dynamic> body);
  Future<void> deleteTeam(String teamId);
  Future<Map<String, dynamic>> inviteTeamMember(
    String teamId,
    String email, {
    String role = 'member',
  });
  Future<void> removeTeamMember(String memberId);
  Future<Map<String, dynamic>> updateMemberRole(String memberId, String role);

  // ── Settings ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPreferences();
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body);
  Future<List<Map<String, dynamic>>> listSettingsSessions();
  Future<void> revokeSession(String id);
  Future<List<Map<String, dynamic>>> listApiKeys();
  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body);
  Future<void> revokeApiKey(String id);
  Future<List<Map<String, dynamic>>> listConnectedAccounts();
  Future<void> unlinkAccount(String provider);
  Future<void> changePassword(Map<String, dynamic> body);

  // ── Admin ───────────────────────────────────────────────────────────

  // Dashboard
  Future<Map<String, dynamic>> getAdminStats();

  // Users
  Future<Map<String, dynamic>> listAdminUsers({
    String? search,
    String? role,
    String? status,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> getAdminUser(int id);
  Future<Map<String, dynamic>> updateAdminUser(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminUser(int id);
  Future<Map<String, dynamic>> updateAdminUserRole(
    int id,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> updateAdminUserStatus(
    int id,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> listAdminUserProjects(int id);
  Future<Map<String, dynamic>> listAdminUserNotes(int id);
  Future<Map<String, dynamic>> listAdminUserSessions(int id);
  Future<Map<String, dynamic>> listAdminUserTeams(int id);
  Future<Map<String, dynamic>> listAdminUserIssues(int id);
  Future<Map<String, dynamic>> listAdminUserMemberships(int id);
  Future<void> removeAdminUserMembership(int userId, int teamId);
  Future<Map<String, dynamic>> changeAdminUserPassword(
    int id,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> sendAdminUserNotification(
    int id,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> impersonateAdminUser(int id);
  Future<Map<String, dynamic>> suspendAdminUser(int id);
  Future<Map<String, dynamic>> unsuspendAdminUser(int id);
  Future<Map<String, dynamic>> verifyAdminUser(int id);
  Future<Map<String, dynamic>> unverifyAdminUser(int id);

  // Teams
  Future<Map<String, dynamic>> listAdminTeams({
    String? search,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> getAdminTeam(int id);
  Future<Map<String, dynamic>> createAdminTeam(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateAdminTeam(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminTeam(int id);
  Future<Map<String, dynamic>> listAdminTeamMembers(int teamId);
  Future<Map<String, dynamic>> addAdminTeamMember(
    int teamId,
    Map<String, dynamic> body,
  );
  Future<void> removeAdminTeamMember(int teamId, int userId);

  // Settings
  Future<Map<String, dynamic>> listAdminSettings({
    String? search,
    String? category,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> upsertAdminSetting(Map<String, dynamic> body);
  Future<Map<String, dynamic>> getAdminSetting(String key);
  Future<Map<String, dynamic>> patchAdminSetting(
    String key,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> updateAdminSetting(
    String key,
    Map<String, dynamic> value,
  );
  Future<void> deleteAdminSetting(String key);
  Future<Map<String, dynamic>> testEmail();

  // ── Marketplace Admin ────────────────────────────────────────────────
  Future<Map<String, dynamic>> listPendingMarketplace();
  Future<Map<String, dynamic>> approveMarketplaceItem(int id);
  Future<Map<String, dynamic>> rejectMarketplaceItem(
    int id, {
    String reason = '',
  });

  // ── User Gamification (Admin) ────────────────────────────────────────
  Future<Map<String, dynamic>> listUserBadges(int userId);
  Future<Map<String, dynamic>> awardUserBadge(
    int userId,
    Map<String, dynamic> body,
  );
  Future<void> revokeUserBadge(int userId, String badgeId);
  Future<Map<String, dynamic>> getUserPoints(int userId);
  Future<Map<String, dynamic>> addUserPoints(
    int userId,
    Map<String, dynamic> body,
  );

  // ── Verification Admin ───────────────────────────────────────────────
  Future<Map<String, dynamic>> listVerificationTypes();
  Future<Map<String, dynamic>> createVerificationType(
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> updateVerificationType(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteVerificationType(int id);

  // ── Badge Admin ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> listBadgeDefinitions();
  Future<Map<String, dynamic>> createBadgeDefinition(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateBadgeDefinition(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteBadgeDefinition(int id);

  // Pages
  Future<Map<String, dynamic>> listAdminPages({
    String? search,
    String? status,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> getAdminPage(int id);
  Future<Map<String, dynamic>> createAdminPage(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateAdminPage(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminPage(int id);

  // Categories
  Future<Map<String, dynamic>> listAdminCategories({
    String? search,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateAdminCategory(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminCategory(int id);

  // Contact
  Future<Map<String, dynamic>> listAdminContact({
    String? search,
    String? status,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> updateAdminContactStatus(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminContactMessage(int id);

  // Issues
  Future<Map<String, dynamic>> listAdminIssues({
    String? search,
    String? status,
    String? priority,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> updateAdminIssueStatus(
    int id,
    Map<String, dynamic> body,
  );

  // Notifications
  Future<Map<String, dynamic>> listAdminNotifications({
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> createAdminNotification(
    Map<String, dynamic> body,
  );

  // Sponsors
  Future<Map<String, dynamic>> listAdminSponsors({
    String? search,
    String? tier,
    String? status,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> createAdminSponsor(Map<String, dynamic> body);
  Future<Map<String, dynamic>> updateAdminSponsor(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminSponsor(int id);

  // Community
  Future<Map<String, dynamic>> listAdminCommunityPosts({
    String? search,
    String? status,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> updateAdminCommunityPost(
    int id,
    Map<String, dynamic> body,
  );
  Future<void> deleteAdminCommunityPost(int id);

  // GitHub
  Future<Map<String, dynamic>> listAdminGitHubIssues({
    String? repo,
    String? state,
    String? type,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>> syncAdminGitHub({String? repo});
  Future<void> deleteAdminGitHubIssue(int id);
  Future<Map<String, dynamic>> listAdminGitHubRepos();

  // ── Health ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getHealthProfile();
  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> body);
  Future<Map<String, dynamic>> logWater(Map<String, dynamic> body);
  Future<List<Map<String, dynamic>>> listWaterLogs({String? date});
  Future<Map<String, dynamic>> getHydrationStatus();
  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> body);
  Future<List<Map<String, dynamic>>> listMealLogs({String? date});
  Future<Map<String, dynamic>> logCaffeine(Map<String, dynamic> body);
  Future<List<Map<String, dynamic>>> listCaffeineLogs({String? date});
  Future<Map<String, dynamic>> getCaffeineScore();
  Future<Map<String, dynamic>> startPomodoro();
  Future<Map<String, dynamic>> endPomodoro(String id);
  Future<List<Map<String, dynamic>>> listPomodoroSessions({String? date});
  Future<Map<String, dynamic>> getShutdownStatus();
  Future<Map<String, dynamic>> startShutdown();
  Future<Map<String, dynamic>> upsertSnapshot(Map<String, dynamic> body);
  Future<List<Map<String, dynamic>>> listSnapshots({String? from, String? to});
  Future<Map<String, dynamic>> getHealthSummary();

  // ── Search ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> search(String query, {String? scope});

  // ── Sync ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> body);
  Future<Map<String, dynamic>> pullSync({String? since});

  // ── Tools (MCP passthrough — only used by McpTcpClient) ─────────────
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  });
}
