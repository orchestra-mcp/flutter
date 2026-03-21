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
  // Use ref.watch so providers stay alive and data is accessible via .value
  await Future.wait([
    ref.watch(apiCollectionProvider.future).catchError((_) => <ApiCollection>[]),
    ref.watch(secretsProvider.future).catchError((_) => <Secret>[]),
    ref.watch(databaseBrowserProvider.future).catchError((_) => <DbConnection>[]),
    ref.watch(logRunnerProvider.future).catchError((_) => <LogProcess>[]),
    ref.watch(promptsProvider.future).catchError((_) => <Prompt>[]),
  ]);
  return true;
});
