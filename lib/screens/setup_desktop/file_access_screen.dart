import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Shown when the macOS sandbox needs file access permission.
/// Prompts the user to grant access to their home directory so the app
/// can read workspaces and `~/.orchestra/` configuration.
class FileAccessScreen extends ConsumerStatefulWidget {
  const FileAccessScreen({super.key});

  @override
  ConsumerState<FileAccessScreen> createState() => _FileAccessScreenState();
}

class _FileAccessScreenState extends ConsumerState<FileAccessScreen> {
  bool _requesting = false;

  Future<void> _requestAccess() async {
    setState(() => _requesting = true);
    final granted = await FileAccessService.instance.requestHomeAccess();
    if (!mounted) return;
    setState(() => _requesting = false);

    if (granted) {
      ref.read(startupGateProvider.notifier).recheck();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fileAccessRequiredToContinue)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 36,
                    color: tokens.accent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.fileAccessRequiredTitle,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.fileAccessDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _requesting ? null : _requestAccess,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _requesting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.fgBright,
                            ),
                          )
                        : Text(
                            l10n.grantFileAccess,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
