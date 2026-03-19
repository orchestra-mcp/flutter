import 'package:flutter/foundation.dart';

/// OAuth redirect service for web platform.
class WebAuthService {
  Future<void> signInWithGoogle() async {
    if (!kIsWeb) return;
    debugPrint('[WebAuth] signInWithGoogle redirect (stub)');
  }

  Future<void> signInWithGitHub() async {
    if (!kIsWeb) return;
    debugPrint('[WebAuth] signInWithGitHub redirect (stub)');
  }

  Future<void> signInWithDiscord() async {
    if (!kIsWeb) return;
    debugPrint('[WebAuth] signInWithDiscord redirect (stub)');
  }

  Future<void> signInWithSlack() async {
    if (!kIsWeb) return;
    debugPrint('[WebAuth] signInWithSlack redirect (stub)');
  }

  Future<bool> handleOAuthCallback(String code, String state) async {
    if (!kIsWeb) return false;
    debugPrint('[WebAuth] handleOAuthCallback code=$code (stub)');
    return false;
  }
}
