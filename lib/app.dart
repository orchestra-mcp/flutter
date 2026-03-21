import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/i18n/locale_provider.dart';
import 'package:orchestra/core/notifications/notification_listener.dart';
import 'package:orchestra/core/router/router_provider.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/core/theme/app_theme.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/theme/theme_provider.dart';
import 'package:orchestra/core/workspace/workspace_bridge_provider.dart';
import 'package:orchestra/features/health/notification_scheduler.dart';
import 'package:orchestra/l10n/app_localizations.dart';

class OrchestraApp extends ConsumerWidget {
  const OrchestraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only spawn the MCP subprocess once the startup gate confirms the
    // binary is installed and a workspace is selected.
    final gate = ref.watch(startupGateProvider).value;
    if (gate == StartupGate.ready) {
      ref.read(mcpClientProvider);
      // Initialize workspace bridge: scan files → SQLite + start file watcher.
      ref.watch(workspaceBridgeInitProvider);
      // Sync health notifications whenever the profile changes.
      ref.watch(notificationSyncProvider);
      // Start MCP notification listener for real-time event delivery.
      ref.read(notificationListenerProvider).start();
    }

    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final GoRouter router = ref.watch(routerProvider);
    final tokens = OrchestraColorTokens.fromTheme(theme);

    return ThemeTokens(
      tokens: tokens,
      child: MaterialApp.router(
        title: Env.appName,
        debugShowCheckedModeBanner: Env.isLocal,
        routerConfig: router,
        theme: AppThemeBuilder.build(theme),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: kSupportedLocales,
        builder: (context, child) => Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
