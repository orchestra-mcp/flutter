import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/features/devtools/providers/api_collection_provider.dart';
import 'package:orchestra/features/devtools/providers/database_browser_provider.dart';
import 'package:orchestra/features/devtools/providers/log_runner_provider.dart';
import 'package:orchestra/features/devtools/providers/prompts_provider.dart';
import 'package:orchestra/features/devtools/providers/secrets_provider.dart';

// ── DevTools Startup Prefetch ────────────────────────────────────────────────
//
// Eagerly warms all five DevTools providers so data is available immediately
// when the user navigates to any DevTools sub-section.
//
// Usage: watch [devtoolsPrefetchProvider] in the app shell or splash screen.

/// Prefetches all DevTools data in parallel at startup.
/// Returns true when all five providers have loaded (regardless of errors).
final devtoolsPrefetchProvider = FutureProvider<bool>((ref) async {
  // Use ref.read (not ref.watch) inside FutureProvider — ref.watch inside an
  // async provider causes '_dependents.isEmpty' assertion errors in Flutter.
  // The sidebars watch their own providers directly; this just triggers the
  // initial load so data is ready before the user navigates.
  Future<void> load(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      // ignore: avoid_print
      print('[DevTools] prefetch error: $e');
    }
  }

  await Future.wait([
    load(() => ref.read(apiCollectionProvider.future).then((_) {})),
    load(() => ref.read(secretsProvider.future).then((_) {})),
    load(() => ref.read(databaseBrowserProvider.future).then((_) {})),
    load(() => ref.read(logRunnerProvider.future).then((_) {})),
    load(() => ref.read(promptsProvider.future).then((_) {})),
  ]);
  return true;
});
