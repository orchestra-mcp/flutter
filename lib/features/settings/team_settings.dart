import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Team & Workspace settings — switch teams, switch workspaces.
class TeamSettingsScreen extends ConsumerWidget {
  const TeamSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(l10n.teamAndWorkspace),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.teams,
              style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          // Placeholder — populated from API in full implementation.
          ListTile(
            leading: Icon(Icons.group_outlined, color: tokens.accent),
            title:
                Text(l10n.myTeam, style: TextStyle(color: tokens.fgBright)),
            trailing:
                Icon(Icons.check_rounded, color: tokens.accent, size: 18),
            tileColor: tokens.accentSurface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 16),
          Text(l10n.workspaces,
              style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1)),
          const SizedBox(height: 8),
          ListTile(
            leading:
                Icon(Icons.folder_outlined, color: tokens.accent),
            title: Text(l10n.defaultWorkspace,
                style: TextStyle(color: tokens.fgBright)),
            trailing:
                Icon(Icons.check_rounded, color: tokens.accent, size: 18),
            tileColor: tokens.accentSurface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }
}
