import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Handles `orchestra://` deep links.
///
/// Supported URIs:
/// - `orchestra://install/pack/{slug}` — install a pack
/// - `orchestra://install/plugin/{slug}` — install a plugin
class DeepLinkHandler {
  DeepLinkHandler._();
  static final instance = DeepLinkHandler._();

  final _installController = StreamController<DeepLinkInstall>.broadcast();

  /// Stream of install requests from deep links.
  Stream<DeepLinkInstall> get installRequests => _installController.stream;

  AppLinks? _appLinks;

  /// Initialize deep link listening. Call once during app startup.
  Future<void> init() async {
    if (kIsWeb) return; // Web doesn't use custom URL schemes.

    _appLinks = AppLinks();

    // Handle initial link (app opened via deep link).
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (e) {
      debugPrint('[DeepLink] Failed to get initial link: $e');
    }

    // Handle subsequent links while app is running.
    _appLinks!.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('[DeepLink] Stream error: $e'),
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLink] Received: $uri');

    if (uri.scheme != 'orchestra') return;

    // orchestra://install/{type}/{slug}
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'install') {
      final type = segments[1]; // 'pack' or 'plugin'
      final slug = segments.length >= 3 ? segments[2] : '';

      if ((type == 'pack' || type == 'plugin') && slug.isNotEmpty) {
        _installController.add(DeepLinkInstall(type: type, slug: slug));
        debugPrint('[DeepLink] Install request: $type/$slug');
      }
    }
  }

  void dispose() {
    _installController.close();
  }
}

/// Represents a deep link install request.
class DeepLinkInstall {
  const DeepLinkInstall({required this.type, required this.slug});

  /// 'pack' or 'plugin'
  final String type;

  /// Package slug (e.g., 'essentials', 'engine-rag')
  final String slug;
}
