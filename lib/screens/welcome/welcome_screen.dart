import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/mcp/file_access_service.dart';
import 'package:orchestra/core/startup/startup_gate_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Shown on desktop when no workspace has been selected yet.
///
/// Offers two paths: open an existing folder or clone a GitHub repo.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _repoController = TextEditingController();
  bool _isCloning = false;
  String? _cloneError;

  /// Bring the app to foreground so macOS allows presenting dialogs
  /// from a tray-only (accessory) process.
  static const _appChannel = MethodChannel('com.orchestra.app/lifecycle');

  Future<void> _activateApp() async {
    if (!Platform.isMacOS) return;
    try {
      await _appChannel.invokeMethod('activateApp');
    } catch (_) {}
  }

  Future<void> _openExistingFolder() async {
    await _activateApp();
    final path = await FileAccessService.instance.pickDirectory(
      message: AppLocalizations.of(context).selectWorkspaceFolder,
    );
    if (path != null && mounted) {
      await switchWorkspace(ref, path);
      await ref.read(startupGateProvider.notifier).recheck();
    }
  }

  Future<void> _cloneFromGitHub() async {
    final repo = _repoController.text.trim();
    if (repo.isEmpty) {
      setState(
        () => _cloneError = AppLocalizations.of(context).pleaseEnterRepoUrl,
      );
      return;
    }

    await _activateApp();
    final parentDir = await FileAccessService.instance.pickDirectory(
      message: AppLocalizations.of(context).selectFolderToClone,
    );
    if (parentDir == null) return;

    setState(() {
      _isCloning = true;
      _cloneError = null;
    });

    try {
      final repoName = repo.split('/').last.replaceAll('.git', '');
      final targetPath = '$parentDir/$repoName';

      final result = await Process.run('git', ['clone', repo, targetPath]);
      if (!mounted) return;

      if (result.exitCode != 0) {
        setState(() {
          _isCloning = false;
          _cloneError = (result.stderr as String).trim();
        });
        return;
      }

      setState(() => _isCloning = false);
      await switchWorkspace(ref, targetPath);
      await ref.read(startupGateProvider.notifier).recheck();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCloning = false;
        _cloneError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final recentAsync = ref.watch(recentWorkspacesProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Icon(
                    Icons.folder_open_rounded,
                    size: 56,
                    color: tokens.accent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.chooseYourWorkspace,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: tokens.fgBright,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectProjectFolder,
                    style: TextStyle(fontSize: 14, color: tokens.fgMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Option 1: Open existing folder
                  GlassCard(
                    onTap: _openExistingFolder,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tokens.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            color: tokens.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.openExistingFolder,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: tokens.fgBright,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.chooseProjectFolder,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.fgDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: tokens.fgDim,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Clone from GitHub
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: tokens.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.cloud_download_rounded,
                                color: tokens.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.cloneFromGitHub,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: tokens.fgBright,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.cloneSetWorkspace,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tokens.fgDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _repoController,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.fgBright,
                          ),
                          decoration: InputDecoration(
                            hintText: 'https://github.com/user/repo.git',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: tokens.fgDim,
                            ),
                            filled: true,
                            fillColor: tokens.bg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: tokens.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: tokens.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: tokens.accent),
                            ),
                          ),
                        ),
                        if (_cloneError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _cloneError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isCloning ? null : _cloneFromGitHub,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isCloning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.cloneAndOpen),
                        ),
                      ],
                    ),
                  ),

                  // Recent workspaces
                  recentAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (workspaces) {
                      if (workspaces.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              l10n.recentWorkspaces,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tokens.fgDim,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          for (final ws in workspaces)
                            GlassCard(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              onTap: () async {
                                await switchWorkspace(ref, ws.path);
                                ref
                                    .read(startupGateProvider.notifier)
                                    .recheck();
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: tokens.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        ws.name.isEmpty
                                            ? '?'
                                            : ws.name
                                                  .substring(0, 1)
                                                  .toUpperCase(),
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
                                      ws.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tokens.fgMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: tokens.fgDim,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
