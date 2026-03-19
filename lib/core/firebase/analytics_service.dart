import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:orchestra/core/config/env.dart';

/// Wraps FirebaseAnalytics with typed Orchestra events.
abstract final class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  static Future<void> init() async {
    if (!Env.enableAnalytics) return;
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  static FirebaseAnalyticsObserver? get observer => _observer;

  // ─── User properties ──────────────────────────────────────────────────────

  static Future<void> setUserProperties({
    required String userId,
    String? teamId,
    String? workspaceId,
    String? role,
  }) async {
    final a = _analytics;
    if (a == null) return;
    await a.setUserId(id: userId);
    if (teamId != null) await a.setUserProperty(name: 'team_id', value: teamId);
    if (workspaceId != null) {
      await a.setUserProperty(name: 'workspace_id', value: workspaceId);
    }
    if (role != null) await a.setUserProperty(name: 'role', value: role);
  }

  static Future<void> clearUser() async {
    await _analytics?.setUserId(id: null);
  }

  // ─── Custom events ────────────────────────────────────────────────────────

  static Future<void> logLogin({required String method}) async {
    await _analytics?.logLogin(loginMethod: method);
  }

  static Future<void> logLogout() async {
    await _analytics?.logEvent(name: 'logout');
  }

  static Future<void> logFeatureCreated({
    required String featureId,
    required String kind,
  }) async {
    await _analytics?.logEvent(
      name: 'feature_created',
      parameters: {'feature_id': featureId, 'kind': kind},
    );
  }

  static Future<void> logProjectOpened({required String projectId}) async {
    await _analytics?.logEvent(
      name: 'project_opened',
      parameters: {'project_id': projectId},
    );
  }

  static Future<void> logHealthLogged({required String category}) async {
    await _analytics?.logEvent(
      name: 'health_logged',
      parameters: {'category': category},
    );
  }

  static Future<void> logThemeChanged({required String themeName}) async {
    await _analytics?.logEvent(
      name: 'theme_changed',
      parameters: {'theme_name': themeName},
    );
  }

  static Future<void> logLanguageChanged({required String locale}) async {
    await _analytics?.logEvent(
      name: 'language_changed',
      parameters: {'locale': locale},
    );
  }

  static Future<void> logSearchPerformed({
    required String query,
    required int resultCount,
  }) async {
    await _analytics?.logSearch(searchTerm: query);
    await _analytics?.logEvent(
      name: 'search_performed',
      parameters: {'query': query, 'result_count': resultCount},
    );
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }
}

/// NavigatorObserver that reports screen views to Analytics.
class OrchestraAnalyticsObserver extends NavigatorObserver {
  OrchestraAnalyticsObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _reportScreen(newRoute);
  }

  void _reportScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null) return;
    AnalyticsService.logScreenView(screenName: name);
  }
}
