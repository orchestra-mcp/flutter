import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/update/update_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// A slim, dismissible banner shown when an app update is available.
///
/// Desktop: shows download progress and "Restart" prompt after download.
/// Mobile: shows "Update" button that opens the app store.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);

    // Only show when an update is available, downloading, or ready.
    if (state.status != UpdateStatus.available &&
        state.status != UpdateStatus.downloading &&
        state.status != UpdateStatus.readyToInstall) {
      return const SizedBox.shrink();
    }

    final tokens = ThemeTokens.of(context);
    final notifier = ref.read(updateProvider.notifier);
    final version = state.info?.latestVersion ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, size: 18, color: tokens.fgBright),
          const SizedBox(width: 10),

          // Status text
          Expanded(child: _buildStatusText(context, state, version, tokens)),

          // Download progress
          if (state.status == UpdateStatus.downloading) ...[
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.downloadProgress,
                  minHeight: 4,
                  backgroundColor: tokens.border,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(state.downloadProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                color: tokens.fgMuted,
                fontFamily: 'monospace',
              ),
            ),
          ],

          // Action button
          if (state.status == UpdateStatus.available) ...[
            _ActionButton(
              label: AppLocalizations.of(context).update,
              onPressed: () => notifier.install(),
              tokens: tokens,
            ),
            const SizedBox(width: 6),
            _DismissButton(onPressed: () => notifier.dismiss(), tokens: tokens),
          ],

          if (state.status == UpdateStatus.readyToInstall)
            _ActionButton(
              label: AppLocalizations.of(context).updateBannerRestart,
              onPressed: () => notifier.install(),
              tokens: tokens,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(
    BuildContext context,
    UpdateState state,
    String version,
    OrchestraColorTokens tokens,
  ) {
    final l10n = AppLocalizations.of(context);
    final String text;
    switch (state.status) {
      case UpdateStatus.available:
        text = l10n.updateBannerAvailable(version);
      case UpdateStatus.downloading:
        text = l10n.updateBannerDownloading(version);
      case UpdateStatus.readyToInstall:
        text = l10n.updateBannerReady(version);
      default:
        text = '';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.fgBright,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.tokens,
  });

  final String label;
  final VoidCallback onPressed;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onPressed, required this.tokens});

  final VoidCallback onPressed;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.close_rounded, size: 14, color: tokens.fgDim),
        padding: EdgeInsets.zero,
        tooltip: AppLocalizations.of(context).updateBannerDismiss,
      ),
    );
  }
}
