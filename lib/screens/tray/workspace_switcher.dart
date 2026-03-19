import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/mcp/workspace_initializer.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/team/team_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Shows the workspace switcher in a centered dialog.
void showWorkspaceSwitcher(BuildContext context) {
  final tokens = ThemeTokens.of(context);
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: WorkspaceSwitcher(
          onSwitch: (_) => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

/// Shows the team switcher in a centered dialog.
void showTeamSwitcher(BuildContext context) {
  final tokens = ThemeTokens.of(context);
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: const TeamSwitcher(),
      ),
    ),
  );
}

// ── Helpers ─────────────────────────────────────────────────────────────────

Widget buildTeamAvatar(
  Team team, {
  required double size,
  required OrchestraColorTokens tokens,
}) {
  final url = resolveAvatarUrl(team.avatarUrl);
  if (url != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _fallbackAvatar(team, size: size, tokens: tokens),
      ),
    );
  }
  return _fallbackAvatar(team, size: size, tokens: tokens);
}

Widget _fallbackAvatar(
  Team team, {
  required double size,
  required OrchestraColorTokens tokens,
}) {
  final initial = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tokens.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: tokens.accent,
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Workspace Switcher
// ══════════════════════════════════════════════════════════════════════════════

class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key, this.onSwitch});

  final void Function(String path)? onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final currentPath = ref.watch(workspacePathProvider);
    final recentAsync = ref.watch(recentWorkspacesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            AppLocalizations.of(context).workspaces,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.fgDim,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const Divider(height: 1, indent: 0, endIndent: 0),
        recentAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context).failedToLoadWorkspaces,
                style: TextStyle(color: tokens.fgDim, fontSize: 13)),
          ),
          data: (workspaces) {
            if (workspaces.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(AppLocalizations.of(context).noRecentWorkspaces,
                    style: TextStyle(color: tokens.fgDim, fontSize: 13)),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final ws in workspaces)
                  _WorkspaceRow(
                    name: ws.name,
                    isActive: ws.path == currentPath,
                    onTap: () async {
                      if (ws.path != currentPath) {
                        await switchWorkspace(ref, ws.path);
                      }
                      onSwitch?.call(ws.path);
                    },
                  ),
              ],
            );
          },
        ),
        const Divider(height: 1),
        _OpenFolderButton(
          onSwitch: onSwitch,
        ),
        _CloseWorkspaceButton(
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class _OpenFolderButton extends ConsumerWidget {
  const _OpenFolderButton({this.onSwitch});
  final void Function(String path)? onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    return InkWell(
      onTap: () => _pickFolder(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.folder_open_rounded,
                  size: 14, color: tokens.fgMuted),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).openFolderAction,
              style: TextStyle(
                fontSize: 13,
                color: tokens.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final result = await FileAccessService.instance.pickDirectory(
      message: AppLocalizations.of(context).chooseWorkspaceFolder,
    );
    if (result == null) return;

    // Ensure .orchestra/ exists — run orchestra init if needed
    if (!WorkspaceInitializer.isInitialized(result)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).initializingWorkspace)),
        );
      }
      final ok = await WorkspaceInitializer.ensureInitialized(result);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).failedToInitWorkspace)),
        );
        return;
      }
    }

    await switchWorkspace(ref, result);
    onSwitch?.call(result);
  }
}

class _CloseWorkspaceButton extends ConsumerWidget {
  const _CloseWorkspaceButton({this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    return InkWell(
      onTap: () async {
        await closeWorkspace(ref);
        onClose?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).closeWorkspace,
              style: TextStyle(
                fontSize: 13,
                color: tokens.fgMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.name,
    required this.isActive,
    required this.onTap,
  });

  final String name;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? tokens.fgBright : tokens.fgMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Icon(Icons.check_rounded, size: 16, color: tokens.accent),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Team Switcher
// ══════════════════════════════════════════════════════════════════════════════

class TeamSwitcher extends ConsumerWidget {
  const TeamSwitcher({super.key, this.onSwitch});

  final void Function(String id)? onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final teamsAsync = ref.watch(teamsProvider);
    final activeId = ref.watch(activeTeamIdProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            AppLocalizations.of(context).teams,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tokens.fgBright,
            ),
          ),
        ),
        const Divider(height: 1),

        // Teams list — switch only
        teamsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context).failedToLoadTeams,
                style: TextStyle(color: tokens.fgDim, fontSize: 13)),
          ),
          data: (teams) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final team in teams)
                _TeamRow(
                  team: team,
                  isActive: team.id == activeId,
                  onTap: () {
                    ref.read(activeTeamIdProvider.notifier).set(team.id);
                    onSwitch?.call(team.id);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Team Settings — navigates to settings/team
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            context.push(Routes.settingsTeam);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.fgDim.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.settings_outlined,
                      size: 14, color: tokens.fgMuted),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).teamSettings,
                  style: TextStyle(fontSize: 13, color: tokens.fgMuted),
                ),
              ],
            ),
          ),
        ),

        // Create New Team
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            showCreateTeamSheet(context, ref);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 14, color: tokens.accent),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).createNewTeam,
                  style: TextStyle(fontSize: 13, color: tokens.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Team Row ────────────────────────────────────────────────────────────────

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.isActive,
    required this.onTap,
  });

  final Team team;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            buildTeamAvatar(team, size: 32, tokens: tokens),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? tokens.fgBright : tokens.fgMuted,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (team.memberCount != null || team.role != null)
                    Text(
                      [
                        if (team.memberCount != null)
                          '${team.memberCount} member${team.memberCount == 1 ? '' : 's'}',
                        if (team.role != null) team.role,
                      ].join(' \u00B7 '),
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.fgDim,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_rounded, size: 16, color: tokens.accent),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Create Team — bottom sheet with name field
// ══════════════════════════════════════════════════════════════════════════════

/// Shows a bottom sheet to create a new team with a name.
void showCreateTeamSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CreateTeamSheet(ref: ref),
  );
}

class _CreateTeamSheet extends StatefulWidget {
  const _CreateTeamSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _creating = true);
    try {
      await widget.ref.read(apiClientProvider).createTeam(name);
      widget.ref.invalidate(teamsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).teamCreatedMessage(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToCreateTeam}: $e')),
        );
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            AppLocalizations.of(context).createNewTeam,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tokens.fgBright,
            ),
          ),
          const SizedBox(height: 16),

          // Team name
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: tokens.fgBright, fontSize: 15),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).teamNameHint,
              hintStyle: TextStyle(color: tokens.fgDim),
              prefixIcon: Icon(Icons.group_outlined,
                  size: 20, color: tokens.fgDim),
              filled: true,
              fillColor: tokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 16),

          // Create button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context).createTeam,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
