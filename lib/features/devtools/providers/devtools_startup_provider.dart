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
  // Wait for each provider and log any errors so they surface in Flutter logs.
  Future<T> _load<T>(Future<T> f, T fallback) =>
      f.catchError((e, st) {
        // ignore: avoid_print
        print('[DevTools] prefetch error: $e');
        return fallback;
      });

  await Future.wait([
    _load(ref.watch(apiCollectionProvider.future), <ApiCollection>[]),
    _load(ref.watch(secretsProvider.future), <Secret>[]),
    _load(ref.watch(databaseBrowserProvider.future), <DbConnection>[]),
    _load(ref.watch(logRunnerProvider.future), <LogProcess>[]),
    _load(ref.watch(promptsProvider.future), <Prompt>[]),
  ]);
  return true;
});
