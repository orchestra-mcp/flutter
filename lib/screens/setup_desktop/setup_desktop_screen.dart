import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown on mobile/web when the desktop Orchestra app is not reachable.
class SetupDesktopScreen extends ConsumerWidget {
  const SetupDesktopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.desktop_mac_rounded, size: 56, color: tokens.accent),
                const SizedBox(height: 16),
                Text(
                  l10n.desktopRequired,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: tokens.fgBright,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.desktopRequiredDescription,
                  style: TextStyle(fontSize: 14, color: tokens.fgMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse('https://orchestra.dev/download')),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l10n.downloadDesktopApp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(startupGateProvider.notifier).recheck(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retryConnection),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.fgMuted,
                      side: BorderSide(color: tokens.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
