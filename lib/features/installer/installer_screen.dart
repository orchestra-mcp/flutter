import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/installer/install_progress_model.dart';
import 'package:orchestra/features/installer/installer_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Full-screen installer UI with Welcome, Progress, Done and Error states.
class InstallerScreen extends ConsumerStatefulWidget {
  const InstallerScreen({super.key});

  @override
  ConsumerState<InstallerScreen> createState() => _InstallerScreenState();
}

class _InstallerScreenState extends ConsumerState<InstallerScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start install after a brief welcome pause.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) ref.read(installerProvider.notifier).startInstall();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final installAsync = ref.watch(installerProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: installAsync.when(
            loading: () => _WelcomeState(tokens: tokens),
            data: (progress) {
              if (progress.stage == InstallStage.done) {
                return _DoneState(tokens: tokens);
              }
              if (progress.stage == InstallStage.error) {
                return _ErrorState(
                  tokens: tokens,
                  message: progress.error ?? 'Unknown error',
                  onRetry: () =>
                      ref.read(installerProvider.notifier).startInstall(),
                );
              }
              return _ProgressState(tokens: tokens, progress: progress);
            },
            error: (err, _) => _ErrorState(
              tokens: tokens,
              message: err.toString(),
              onRetry: () =>
                  ref.read(installerProvider.notifier).startInstall(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Welcome state ─────────────────────────────────────────────────────────────

class _WelcomeState extends StatelessWidget {
  const _WelcomeState({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.music_note_rounded, size: 72, color: tokens.accent),
        const SizedBox(height: 24),
        Text(
          'Orchestra',
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).settingUpWorkspace,
          style: TextStyle(color: tokens.fgMuted, fontSize: 15),
        ),
      ],
    );
  }
}

// ── Progress state ────────────────────────────────────────────────────────────

class _ProgressState extends StatelessWidget {
  const _ProgressState({required this.tokens, required this.progress});
  final OrchestraColorTokens tokens;
  final InstallProgress progress;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.message,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.percent / 100,
                backgroundColor: tokens.border,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.percent}%',
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Done state ────────────────────────────────────────────────────────────────

class _DoneState extends StatelessWidget {
  const _DoneState({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF4ADE80), size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context).orchestraIsReady,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          height: 52,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context).getStarted,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.tokens,
    required this.message,
    required this.onRetry,
  });

  final OrchestraColorTokens tokens;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).installationFailed,
              style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.accent,
                    side: BorderSide(color: tokens.accent),
                  ),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
