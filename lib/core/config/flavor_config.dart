import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:orchestra/core/config/env.dart';

/// Sets up FlutterFlavor with values from compile-time Env constants.
/// Call this once in each main_*.dart entrypoint before runApp().
void initFlavor() {
  FlavorConfig(
    name: Env.appName,
    color: switch (Env.current) {
      AppEnvironment.local => Colors.deepPurple,
      AppEnvironment.staging => Colors.orange,
      AppEnvironment.production => Colors.transparent,
    },
    location: switch (Env.current) {
      AppEnvironment.production => BannerLocation.topEnd,
      _ => BannerLocation.topStart,
    },
    variables: {
      'apiBaseUrl': Env.apiBaseUrl,
      'wsBaseUrl': Env.wsBaseUrl,
      'mcpHost': Env.mcpHost,
      'mcpPort': Env.mcpPort,
      'enableFirebase': Env.enableFirebase,
      'enableAnalytics': Env.enableAnalytics,
      'enableCrashlytics': Env.enableCrashlytics,
    },
  );
}
