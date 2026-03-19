import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Extracts the `token` query parameter from the browser URL.
/// Returns null on non-web platforms or if no token param is present.
/// Cleans the token from the URL via history.replaceState.
String? extractTokenFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.parse(web.window.location.href);
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      // Remove the token from the URL so it's not visible or bookmarked
      final params = Map<String, String>.from(uri.queryParameters)
        ..remove('token');
      final clean = uri.replace(
        queryParameters: params.isEmpty ? null : params,
      );
      web.window.history.replaceState(
        null,
        '',
        clean.toString(),
      );
      return token;
    }
  } catch (e) {
    debugPrint('[WebTokenHandler] Failed to read URL token: $e');
  }
  return null;
}

/// Redirects the browser to the marketing site login page.
/// Only works on web platform. No-op elsewhere.
void redirectToMarketingLogin() {
  if (!kIsWeb) return;
  const loginUrl = String.fromEnvironment(
    'MARKETING_LOGIN_URL',
    defaultValue: 'https://orchestra-mcp.dev/login',
  );
  web.window.location.href = loginUrl;
}
