import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/api/endpoints.dart';

/// REST implementation of [ApiClient] using Dio.
/// Dio instance (with interceptors) is injected — see [DioProvider].
class RestClient implements ApiClient {
  RestClient({required this.dio});

  final Dio dio;

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    final r = await dio.post<Map<String, dynamic>>(path, data: data);
    return r.data!;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final r = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: params,
    );
    return r.data!;
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> data,
  ) async {
    final r = await dio.put<Map<String, dynamic>>(path, data: data);
    return r.data!;
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    final r = await dio.patch<Map<String, dynamic>>(path, data: data);
    return r.data!;
  }

  Future<void> _delete(String path) => dio.delete<void>(path);

  List<Map<String, dynamic>> _list(dynamic data) =>
      (data as List).cast<Map<String, dynamic>>();

  /// Extract a list from an API response that may be a raw array or a wrapped
  /// object like `{"data": [...]}` or `{"items": [...]}`.
  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) return _list(data);
    if (data is Map) {
      for (final key in ['data', 'items', 'logs', 'sessions']) {
        final v = data[key];
        if (v is List) return _list(v);
      }
    }
    return [];
  }

  /// Call an MCP tool via the web-gate proxy at `/api/mcp/tools/call`.
  /// Returns the JSON-RPC result map.
  Future<Map<String, dynamic>> _mcpTool(
    String name, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    final r = await dio.post<Map<String, dynamic>>(
      Endpoints.mcpToolsCall,
      data: {'name': name, 'arguments': arguments},
    );
    return r.data ?? {};
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> body) =>
      _post(Endpoints.authLogin, body);

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      _post(Endpoints.authRegister, body);

  @override
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) =>
      _post(Endpoints.devicesRegister, body);

  // ── Profile ───────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getProfile() => _get(Endpoints.profile);

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _patch(Endpoints.updateProfile, body);

  @override
  Future<Map<String, dynamic>> updateSettingsProfile(
    Map<String, dynamic> body,
  ) => _patch(Endpoints.settingsProfile, body);

  @override
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final r = await dio.post<Map<String, dynamic>>(
      Endpoints.settingsAvatar,
      data: formData,
    );
    return r.data!;
  }

  // ── Projects ──────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listProjects() async {
    final r = await dio.get<List<dynamic>>(Endpoints.projects);
    return _list(r.data);
  }

  @override
  Future<Map<String, dynamic>> getProject(String id) =>
      _get(Endpoints.project(id));

  @override
  Future<Map<String, dynamic>> createProject(Map<String, dynamic> body) =>
      _post(Endpoints.projects, body);

  @override
  Future<Map<String, dynamic>> updateProject(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.project(id), body);

  @override
  Future<void> deleteProject(String id) => _delete(Endpoints.project(id));

  // ── Features ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listFeatures({String? projectId}) async {
    if (projectId == null) return [];
    final r = await dio.get<List<dynamic>>(
      Endpoints.projectFeatures(projectId),
    );
    return _list(r.data);
  }

  @override
  Future<Map<String, dynamic>> getFeature(String id) =>
      _get(Endpoints.feature(id));

  @override
  Future<Map<String, dynamic>> createFeature(Map<String, dynamic> body) =>
      _mcpTool('create_feature', body);

  @override
  Future<Map<String, dynamic>> updateFeature(
    String id,
    Map<String, dynamic> body,
  ) => _patch(Endpoints.feature(id), body);

  @override
  Future<void> deleteFeature(String id) => _delete(Endpoints.feature(id));

  // ── Plans ────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listPlans({
    required String projectSlug,
  }) async {
    try {
      final r = await dio.get<List<dynamic>>(
        Endpoints.projectPlans(projectSlug),
      );
      return _list(r.data);
    } catch (e) {
      debugPrint('[RestClient] listPlans failed (offline-safe): $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPlan(String projectSlug, String planId) =>
      _get(Endpoints.projectPlan(projectSlug, planId));

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> body) =>
      _mcpTool('create_plan', body);

  @override
  Future<Map<String, dynamic>> updatePlan(
    String id,
    Map<String, dynamic> body,
  ) => _mcpTool('update_plan', {'id': id, ...body});

  @override
  Future<void> deletePlan(String id) => _mcpTool('delete_plan', {'id': id});

  // ── Requests ─────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listRequests({String? projectSlug}) async {
    if (projectSlug == null) return [];
    try {
      final r = await dio.get<List<dynamic>>(
        Endpoints.projectRequests(projectSlug),
      );
      return _list(r.data);
    } catch (e) {
      debugPrint('[RestClient] listRequests failed (offline-safe): $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getRequest(String id) =>
      _get(Endpoints.request(id));

  @override
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> body) =>
      _mcpTool('create_request', body);

  @override
  Future<Map<String, dynamic>> updateRequest(
    String id,
    Map<String, dynamic> body,
  ) => _mcpTool('update_request', {'id': id, ...body});

  @override
  Future<void> deleteRequest(String id) =>
      _mcpTool('delete_request', {'id': id});

  // ── Persons ──────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listPersons({String? projectSlug}) async {
    try {
      final endpoint = projectSlug != null
          ? Endpoints.projectPersons(projectSlug)
          : Endpoints.persons;
      final r = await dio.get<List<dynamic>>(endpoint);
      return _list(r.data);
    } catch (e) {
      debugPrint('[RestClient] listPersons failed (offline-safe): $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getPerson(String id) =>
      _get(Endpoints.person(id));

  @override
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body) =>
      _mcpTool('create_person', body);

  @override
  Future<Map<String, dynamic>> updatePerson(
    String id,
    Map<String, dynamic> body,
  ) => _mcpTool('update_person', {'id': id, ...body});

  @override
  Future<void> deletePerson(String id) => _mcpTool('delete_person', {'id': id});

  // ── Notes ─────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listNotes() async {
    // Backend returns raw array [...]
    final r = await dio.get<List<dynamic>>(Endpoints.notes);
    return _list(r.data);
  }

  @override
  Future<Map<String, dynamic>> getNote(String id) => _get(Endpoints.note(id));

  @override
  Future<Map<String, dynamic>> createNote(Map<String, dynamic> body) =>
      _post(Endpoints.notes, body);

  @override
  Future<Map<String, dynamic>> updateNote(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.note(id), body);

  @override
  Future<void> deleteNote(String id) => _delete(Endpoints.note(id));

  // ── Library ───────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listAgents() async =>
      _list((await dio.get<List<dynamic>>(Endpoints.agents)).data);

  @override
  Future<Map<String, dynamic>> getAgent(String id) => _get(Endpoints.agent(id));

  @override
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> body) =>
      _post(Endpoints.agents, body);

  @override
  Future<Map<String, dynamic>> updateAgent(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.agent(id), body);

  @override
  Future<void> deleteAgent(String id) => _delete(Endpoints.agent(id));

  @override
  Future<List<Map<String, dynamic>>> listSkills() async =>
      _list((await dio.get<List<dynamic>>(Endpoints.skills)).data);

  @override
  Future<Map<String, dynamic>> getSkill(String id) => _get(Endpoints.skill(id));

  @override
  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> body) =>
      _post(Endpoints.skills, body);

  @override
  Future<Map<String, dynamic>> updateSkill(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.skill(id), body);

  @override
  Future<void> deleteSkill(String id) => _delete(Endpoints.skill(id));

  @override
  Future<List<Map<String, dynamic>>> listWorkflows() async {
    // Backend returns {"items": [...], "meta": {...}} — extract items.
    final r = await dio.get<Map<String, dynamic>>(Endpoints.workflows);
    final items = r.data?['items'];
    if (items is List) return _list(items);
    return [];
  }

  @override
  Future<Map<String, dynamic>> getWorkflow(String id) =>
      _get(Endpoints.workflow(id));

  @override
  Future<Map<String, dynamic>> createWorkflow(Map<String, dynamic> body) =>
      _post(Endpoints.workflows, body);

  @override
  Future<Map<String, dynamic>> updateWorkflow(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.workflow(id), body);

  @override
  Future<void> deleteWorkflow(String id) => _delete(Endpoints.workflow(id));

  @override
  Future<List<Map<String, dynamic>>> listDocs() async =>
      _list((await dio.get<List<dynamic>>(Endpoints.docs)).data);

  @override
  Future<Map<String, dynamic>> getDoc(String id) => _get(Endpoints.doc(id));

  @override
  Future<Map<String, dynamic>> createDoc(Map<String, dynamic> body) =>
      _post(Endpoints.docs, body);

  @override
  Future<Map<String, dynamic>> updateDoc(
    String id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.doc(id), body);

  @override
  Future<void> deleteDoc(String id) => _delete(Endpoints.doc(id));

  @override
  Future<List<Map<String, dynamic>>> listSessions() async {
    // Backend returns raw array from /api/ai/sessions
    final r = await dio.get<List<dynamic>>(Endpoints.sessions);
    return _list(r.data);
  }

  @override
  Future<List<Map<String, dynamic>>> listDelegations() async {
    // Backend returns {"delegations": [...]} — extract the list.
    final r = await dio.get<Map<String, dynamic>>(Endpoints.delegations);
    final items = r.data?['delegations'];
    if (items is List) return _list(items);
    return [];
  }

  @override
  Future<Map<String, dynamic>> respondDelegation(String id, String response) async {
    final r = await dio.post<Map<String, dynamic>>(
      Endpoints.delegationRespond(id),
      data: {'response': response},
    );
    return r.data ?? {};
  }

  // ── Teams ────────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> listTeams() async {
    final r = await dio.get<dynamic>(Endpoints.teams);
    final data = r.data;
    if (data is List) return _list(data);
    if (data is Map) {
      final teams = data['teams'];
      if (teams is List) return _list(teams);
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getMyTeam() => _get(Endpoints.myTeam);

  @override
  Future<List<Map<String, dynamic>>> listTeamMembers(String teamId) async {
    final r = await dio.get<dynamic>(
      '${Endpoints.myTeamMembers}?team_id=$teamId',
    );
    final data = r.data;
    if (data is List) return _list(data);
    if (data is Map) {
      final members = data['members'];
      if (members is List) return _list(members);
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> createTeam(String name) =>
      _post(Endpoints.teams, {'name': name});

  @override
  Future<Map<String, dynamic>> updateTeam(Map<String, dynamic> body) =>
      _patch(Endpoints.myTeam, body);

  @override
  Future<void> deleteTeam(String teamId) => _delete(Endpoints.teamShow(teamId));

  @override
  Future<Map<String, dynamic>> inviteTeamMember(
    String teamId,
    String email, {
    String role = 'member',
  }) => _post(Endpoints.teamInvite(teamId), {'email': email, 'role': role});

  @override
  Future<void> removeTeamMember(String memberId) =>
      _delete(Endpoints.teamMemberRemove(memberId));

  @override
  Future<Map<String, dynamic>> updateMemberRole(String memberId, String role) =>
      _patch(Endpoints.teamMemberRole(memberId), {'role': role});

  // ── Settings ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    final r = await dio.get<Map<String, dynamic>>(
      Endpoints.settingsPreferences,
    );
    return r.data?['preferences'] as Map<String, dynamic>? ?? r.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) =>
      _patch(Endpoints.settingsPreferences, body);

  @override
  Future<List<Map<String, dynamic>>> listSettingsSessions() async {
    final r = await dio.get<Map<String, dynamic>>(Endpoints.settingsSessions);
    final items = r.data?['sessions'];
    if (items is List) return _list(items);
    return [];
  }

  @override
  Future<void> revokeSession(String id) =>
      _delete(Endpoints.settingsSession(id));

  @override
  Future<List<Map<String, dynamic>>> listApiKeys() async {
    final r = await dio.get<Map<String, dynamic>>(Endpoints.settingsApiKeys);
    final items = r.data?['api_keys'];
    if (items is List) return _list(items);
    return [];
  }

  @override
  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body) =>
      _post(Endpoints.settingsApiKeys, body);

  @override
  Future<void> revokeApiKey(String id) => _delete(Endpoints.settingsApiKey(id));

  @override
  Future<List<Map<String, dynamic>>> listConnectedAccounts() async {
    final r = await dio.get<Map<String, dynamic>>(
      Endpoints.settingsConnectedAccounts,
    );
    final items = r.data?['accounts'];
    if (items is List) return _list(items);
    return [];
  }

  @override
  Future<void> unlinkAccount(String provider) =>
      _delete(Endpoints.settingsUnlinkAccount(provider));

  @override
  Future<void> changePassword(Map<String, dynamic> body) async {
    await dio.post<Map<String, dynamic>>(Endpoints.changePassword, data: body);
  }

  // ── Admin ───────────────────────────────────────────────────────────

  Map<String, dynamic> _adminParams({
    String? search,
    String? status,
    String? role,
    String? priority,
    String? tier,
    String? category,
    String? repo,
    String? state,
    String? type,
    int? limit,
    int? offset,
  }) => {
    if (search != null) 'search': search,
    if (status != null) 'status': status,
    if (role != null) 'role': role,
    if (priority != null) 'priority': priority,
    if (tier != null) 'tier': tier,
    if (category != null) 'category': category,
    if (repo != null) 'repo': repo,
    if (state != null) 'state': state,
    if (type != null) 'type': type,
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
  };

  // Dashboard
  @override
  Future<Map<String, dynamic>> getAdminStats() => _get(Endpoints.adminStats);

  // Users
  @override
  Future<Map<String, dynamic>> listAdminUsers({
    String? search,
    String? role,
    String? status,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminUsers,
    params: _adminParams(
      search: search,
      role: role,
      status: status,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> getAdminUser(int id) =>
      _get(Endpoints.adminUser(id));

  @override
  Future<Map<String, dynamic>> updateAdminUser(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminUser(id), body);

  @override
  Future<void> deleteAdminUser(int id) => _delete(Endpoints.adminUser(id));

  @override
  Future<Map<String, dynamic>> updateAdminUserRole(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminUserRole(id), body);

  @override
  Future<Map<String, dynamic>> updateAdminUserStatus(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminUserStatus(id), body);

  @override
  Future<Map<String, dynamic>> listAdminUserProjects(int id) =>
      _get(Endpoints.adminUserProjects(id));

  @override
  Future<Map<String, dynamic>> listAdminUserNotes(int id) =>
      _get(Endpoints.adminUserNotes(id));

  @override
  Future<Map<String, dynamic>> listAdminUserSessions(int id) =>
      _get(Endpoints.adminUserSessions(id));

  @override
  Future<Map<String, dynamic>> listAdminUserTeams(int id) =>
      _get(Endpoints.adminUserTeams(id));

  @override
  Future<Map<String, dynamic>> listAdminUserIssues(int id) =>
      _get(Endpoints.adminUserIssues(id));

  @override
  Future<Map<String, dynamic>> listAdminUserMemberships(int id) =>
      _get(Endpoints.adminUserMemberships(id));

  @override
  Future<void> removeAdminUserMembership(int userId, int teamId) =>
      _delete(Endpoints.adminUserMembership(userId, teamId));

  @override
  Future<Map<String, dynamic>> changeAdminUserPassword(
    int id,
    Map<String, dynamic> body,
  ) => _post(Endpoints.adminUserPassword(id), body);

  @override
  Future<Map<String, dynamic>> sendAdminUserNotification(
    int id,
    Map<String, dynamic> body,
  ) => _post(Endpoints.adminUserNotify(id), body);

  @override
  Future<Map<String, dynamic>> impersonateAdminUser(int id) =>
      _post(Endpoints.adminUserImpersonate(id), {});

  @override
  Future<Map<String, dynamic>> suspendAdminUser(int id) =>
      _patch(Endpoints.adminUserSuspend(id), {});

  @override
  Future<Map<String, dynamic>> unsuspendAdminUser(int id) =>
      _patch(Endpoints.adminUserUnsuspend(id), {});

  @override
  Future<Map<String, dynamic>> verifyAdminUser(int id) =>
      _patch(Endpoints.adminUserVerify(id), {});

  @override
  Future<Map<String, dynamic>> unverifyAdminUser(int id) =>
      _patch(Endpoints.adminUserUnverify(id), {});

  // Teams
  @override
  Future<Map<String, dynamic>> listAdminTeams({
    String? search,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminTeams,
    params: _adminParams(search: search, limit: limit, offset: offset),
  );

  @override
  Future<Map<String, dynamic>> getAdminTeam(int id) =>
      _get(Endpoints.adminTeam(id));

  @override
  Future<Map<String, dynamic>> createAdminTeam(Map<String, dynamic> body) =>
      _post(Endpoints.adminTeams, body);

  @override
  Future<Map<String, dynamic>> updateAdminTeam(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminTeam(id), body);

  @override
  Future<void> deleteAdminTeam(int id) => _delete(Endpoints.adminTeam(id));

  @override
  Future<Map<String, dynamic>> listAdminTeamMembers(int teamId) =>
      _get(Endpoints.adminTeamMembers(teamId));

  @override
  Future<Map<String, dynamic>> addAdminTeamMember(
    int teamId,
    Map<String, dynamic> body,
  ) => _post(Endpoints.adminTeamMembers(teamId), body);

  @override
  Future<void> removeAdminTeamMember(int teamId, int userId) =>
      _delete(Endpoints.adminTeamMember(teamId, userId));

  // Settings
  @override
  Future<Map<String, dynamic>> listAdminSettings({
    String? search,
    String? category,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminSettings,
    params: _adminParams(
      search: search,
      category: category,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> upsertAdminSetting(Map<String, dynamic> body) =>
      _put(Endpoints.adminSettings, body);

  @override
  Future<Map<String, dynamic>> getAdminSetting(String key) =>
      _get(Endpoints.adminSetting(key));

  @override
  Future<Map<String, dynamic>> patchAdminSetting(
    String key,
    Map<String, dynamic> body,
  ) => _patch(Endpoints.adminSetting(key), body);

  @override
  Future<Map<String, dynamic>> updateAdminSetting(
    String key,
    Map<String, dynamic> value,
  ) => patchAdminSetting(key, value);

  @override
  Future<void> deleteAdminSetting(String key) =>
      _delete(Endpoints.adminSetting(key));

  @override
  Future<Map<String, dynamic>> testEmail() =>
      _post(Endpoints.adminTestEmail, {});

  // Marketplace Admin
  @override
  Future<Map<String, dynamic>> listPendingMarketplace() =>
      _get('/api/admin/marketplace/pending');

  @override
  Future<Map<String, dynamic>> approveMarketplaceItem(int id) =>
      _post('/api/admin/marketplace/$id/approve', {});

  @override
  Future<Map<String, dynamic>> rejectMarketplaceItem(
    int id, {
    String reason = '',
  }) => _post('/api/admin/marketplace/$id/reject', {'reason': reason});

  // User Gamification
  @override
  Future<Map<String, dynamic>> listUserBadges(int userId) =>
      _get('/api/admin/users/$userId/badges');
  @override
  Future<Map<String, dynamic>> awardUserBadge(
    int userId,
    Map<String, dynamic> body,
  ) => _post('/api/admin/users/$userId/badges', body);
  @override
  Future<void> revokeUserBadge(int userId, String badgeId) =>
      _delete('/api/admin/users/$userId/badges/$badgeId');
  @override
  Future<Map<String, dynamic>> getUserPoints(int userId) =>
      _get('/api/admin/users/$userId/points');
  @override
  Future<Map<String, dynamic>> addUserPoints(
    int userId,
    Map<String, dynamic> body,
  ) => _post('/api/admin/users/$userId/points', body);

  // Verification Admin
  @override
  Future<Map<String, dynamic>> listVerificationTypes() =>
      _get('/api/admin/verifications');
  @override
  Future<Map<String, dynamic>> createVerificationType(
    Map<String, dynamic> body,
  ) => _post('/api/admin/verifications', body);
  @override
  Future<Map<String, dynamic>> updateVerificationType(
    int id,
    Map<String, dynamic> body,
  ) => _put('/api/admin/verifications/$id', body);
  @override
  Future<void> deleteVerificationType(int id) =>
      _delete('/api/admin/verifications/$id');

  // Badge Admin
  @override
  Future<Map<String, dynamic>> listBadgeDefinitions() =>
      _get('/api/admin/badges');

  @override
  Future<Map<String, dynamic>> createBadgeDefinition(
    Map<String, dynamic> body,
  ) => _post('/api/admin/badges', body);

  @override
  Future<Map<String, dynamic>> updateBadgeDefinition(
    int id,
    Map<String, dynamic> body,
  ) => _put('/api/admin/badges/$id', body);

  @override
  Future<void> deleteBadgeDefinition(int id) =>
      _delete('/api/admin/badges/$id');

  // Pages
  @override
  Future<Map<String, dynamic>> listAdminPages({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminPages,
    params: _adminParams(
      search: search,
      status: status,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> getAdminPage(int id) =>
      _get(Endpoints.adminPage(id));

  @override
  Future<Map<String, dynamic>> createAdminPage(Map<String, dynamic> body) =>
      _post(Endpoints.adminPages, body);

  @override
  Future<Map<String, dynamic>> updateAdminPage(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminPage(id), body);

  @override
  Future<void> deleteAdminPage(int id) => _delete(Endpoints.adminPage(id));

  // Categories
  @override
  Future<Map<String, dynamic>> listAdminCategories({
    String? search,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminCategories,
    params: _adminParams(search: search, limit: limit, offset: offset),
  );

  @override
  Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> body) =>
      _post(Endpoints.adminCategories, body);

  @override
  Future<Map<String, dynamic>> updateAdminCategory(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminCategory(id), body);

  @override
  Future<void> deleteAdminCategory(int id) =>
      _delete(Endpoints.adminCategory(id));

  // Contact
  @override
  Future<Map<String, dynamic>> listAdminContact({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminContact,
    params: _adminParams(
      search: search,
      status: status,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> updateAdminContactStatus(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminContactStatus(id), body);

  @override
  Future<void> deleteAdminContactMessage(int id) =>
      _delete(Endpoints.adminContactMessage(id));

  // Issues
  @override
  Future<Map<String, dynamic>> listAdminIssues({
    String? search,
    String? status,
    String? priority,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminIssues,
    params: _adminParams(
      search: search,
      status: status,
      priority: priority,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> updateAdminIssueStatus(
    int id,
    Map<String, dynamic> body,
  ) => _patch(Endpoints.adminIssue(id), body);

  // Notifications
  @override
  Future<Map<String, dynamic>> listAdminNotifications({
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminNotifications,
    params: _adminParams(limit: limit, offset: offset),
  );

  @override
  Future<Map<String, dynamic>> createAdminNotification(
    Map<String, dynamic> body,
  ) {
    // Backend send handler is at /send, not the list endpoint.
    // Backend expects user_ids (array), not user_id (int).
    final payload = Map<String, dynamic>.from(body);
    if (payload.containsKey('user_id') && !payload.containsKey('user_ids')) {
      payload['user_ids'] = [payload.remove('user_id')];
    }
    return _post(Endpoints.adminNotificationSend, payload);
  }

  // Sponsors
  @override
  Future<Map<String, dynamic>> listAdminSponsors({
    String? search,
    String? tier,
    String? status,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminSponsors,
    params: _adminParams(
      search: search,
      tier: tier,
      status: status,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> createAdminSponsor(Map<String, dynamic> body) =>
      _post(Endpoints.adminSponsors, body);

  @override
  Future<Map<String, dynamic>> updateAdminSponsor(
    int id,
    Map<String, dynamic> body,
  ) => _put(Endpoints.adminSponsor(id), body);

  @override
  Future<void> deleteAdminSponsor(int id) =>
      _delete(Endpoints.adminSponsor(id));

  // Community
  @override
  Future<Map<String, dynamic>> listAdminCommunityPosts({
    String? search,
    String? status,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminCommunityPosts,
    params: _adminParams(
      search: search,
      status: status,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> updateAdminCommunityPost(
    int id,
    Map<String, dynamic> body,
  ) => _patch(Endpoints.adminCommunityPost(id), body);

  @override
  Future<void> deleteAdminCommunityPost(int id) =>
      _delete(Endpoints.adminCommunityPost(id));

  // GitHub
  @override
  Future<Map<String, dynamic>> listAdminGitHubIssues({
    String? repo,
    String? state,
    String? type,
    int? limit,
    int? offset,
  }) => _get(
    Endpoints.adminGitHubIssues,
    params: _adminParams(
      repo: repo,
      state: state,
      type: type,
      limit: limit,
      offset: offset,
    ),
  );

  @override
  Future<Map<String, dynamic>> syncAdminGitHub({String? repo}) =>
      _post(Endpoints.adminGitHubSync, {if (repo != null) 'repo': repo});

  @override
  Future<void> deleteAdminGitHubIssue(int id) =>
      _delete(Endpoints.adminGitHubIssue(id));

  @override
  Future<Map<String, dynamic>> listAdminGitHubRepos() =>
      _get(Endpoints.adminGitHubRepos);

  // ── Health ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getHealthProfile() =>
      _get(Endpoints.healthProfile);

  @override
  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> body) =>
      _put(Endpoints.healthProfile, body);

  @override
  Future<Map<String, dynamic>> logWater(Map<String, dynamic> body) =>
      _post(Endpoints.healthWater, body);

  @override
  Future<List<Map<String, dynamic>>> listWaterLogs({String? date}) async {
    final r = await dio.get<dynamic>(
      Endpoints.healthWater,
      queryParameters: {if (date != null) 'date': date},
    );
    return _extractList(r.data);
  }

  @override
  Future<Map<String, dynamic>> getHydrationStatus() =>
      _get(Endpoints.healthWaterStatus);

  @override
  Future<Map<String, dynamic>> logMeal(Map<String, dynamic> body) =>
      _post(Endpoints.healthMeals, body);

  @override
  Future<List<Map<String, dynamic>>> listMealLogs({String? date}) async {
    final r = await dio.get<dynamic>(
      Endpoints.healthMeals,
      queryParameters: {if (date != null) 'date': date},
    );
    return _extractList(r.data);
  }

  @override
  Future<Map<String, dynamic>> logCaffeine(Map<String, dynamic> body) =>
      _post(Endpoints.healthCaffeine, body);

  @override
  Future<List<Map<String, dynamic>>> listCaffeineLogs({String? date}) async {
    final r = await dio.get<dynamic>(
      Endpoints.healthCaffeine,
      queryParameters: {if (date != null) 'date': date},
    );
    return _extractList(r.data);
  }

  @override
  Future<Map<String, dynamic>> getCaffeineScore() =>
      _get(Endpoints.healthCaffeineScore);

  @override
  Future<Map<String, dynamic>> startPomodoro() =>
      _post(Endpoints.healthPomodoroStart, {});

  @override
  Future<Map<String, dynamic>> endPomodoro(String id) =>
      _post(Endpoints.healthPomodoroEnd(id), {});

  @override
  Future<List<Map<String, dynamic>>> listPomodoroSessions({
    String? date,
  }) async {
    final r = await dio.get<dynamic>(
      Endpoints.healthPomodoro,
      queryParameters: {if (date != null) 'date': date},
    );
    return _extractList(r.data);
  }

  @override
  Future<Map<String, dynamic>> getShutdownStatus() =>
      _get(Endpoints.healthShutdownStatus);

  @override
  Future<Map<String, dynamic>> startShutdown() =>
      _post(Endpoints.healthShutdownStart, {});

  @override
  Future<Map<String, dynamic>> upsertSnapshot(Map<String, dynamic> body) =>
      _post(Endpoints.healthSnapshots, body);

  @override
  Future<List<Map<String, dynamic>>> listSnapshots({
    String? from,
    String? to,
  }) async {
    final r = await dio.get<dynamic>(
      Endpoints.healthSnapshots,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return _extractList(r.data);
  }

  @override
  Future<Map<String, dynamic>> getHealthSummary() =>
      _get(Endpoints.healthSummary);

  // ── Search ────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> search(String query, {String? scope}) => _get(
    Endpoints.search,
    params: {'q': query, if (scope != null) 'scope': scope},
  );

  // ── Sync ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> body) =>
      _post(Endpoints.syncPush, body);

  @override
  Future<Map<String, dynamic>> pullSync({String? since}) =>
      _get(Endpoints.syncPull, params: {if (since != null) 'since': since});

  // ── Tools (not available over REST — only via MCP TCP client) ────────

  @override
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    throw UnsupportedError('callTool is only available via McpTcpClient');
  }
}
