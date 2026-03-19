import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Dismissed state ──────────────────────────────────────────────────────────

/// Tracks whether the user has dismissed the update banner in this session.
class BannerDismissedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
  void reset() => state = false;
}

final bannerDismissedProvider = NotifierProvider<BannerDismissedNotifier, bool>(
  BannerDismissedNotifier.new,
);

// ── Pull in progress state ──────────────────────────────────────────────────

class PullInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final pullInProgressProvider = NotifierProvider<PullInProgressNotifier, bool>(
  PullInProgressNotifier.new,
);

// ── Auto-refresh timer ───────────────────────────────────────────────────────

/// Periodically invalidates [teamUpdatesProvider] to check for new updates.
/// Default interval: 5 minutes.
final updateCheckTimerProvider = Provider<void>((ref) {
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    ref.invalidate(teamUpdatesProvider);
  });
  ref.onDispose(timer.cancel);
});

// ── Entity type helpers ──────────────────────────────────────────────────────

IconData _iconForEntityType(String type) {
  return switch (type) {
    'project' => Icons.folder_rounded,
    'note' => Icons.sticky_note_2_rounded,
    'skill' => Icons.bolt_rounded,
    'workflow' => Icons.account_tree_rounded,
    'doc' => Icons.description_rounded,
    'agent' => Icons.smart_toy_rounded,
    _ => Icons.sync_rounded,
  };
}

Color _colorForEntityType(String type) {
  return switch (type) {
    'project' => const Color(0xFF38BDF8),
    'note' => const Color(0xFFFBBF24),
    'skill' => const Color(0xFFF97316),
    'workflow' => const Color(0xFFEC4899),
    'doc' => const Color(0xFF60A5FA),
    'agent' => const Color(0xFF4ADE80),
    _ => const Color(0xFFA78BFA),
  };
}

// ── Banner widget ────────────────────────────────────────────────────────────

/// A banner shown at the top of the summary screen when team updates are
/// available. Provides "Pull Updates" and "Dismiss" actions.
class TeamUpdatesBanner extends ConsumerWidget {
  const TeamUpdatesBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final dismissed = ref.watch(bannerDismissedProvider);
    final pulling = ref.watch(pullInProgressProvider);
    final asyncStatus = ref.watch(teamUpdatesProvider);

    // Start the auto-refresh timer.
    ref.watch(updateCheckTimerProvider);

    // Don't show if dismissed or no data yet.
    if (dismissed) return const SizedBox.shrink();

    return asyncStatus.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        if (status.availableUpdates == 0) return const SizedBox.shrink();

        // Group updates by entity type for the breakdown.
        final typeCounts = <String, int>{};
        for (final entry in status.updates) {
          typeCounts[entry.entityType] =
              (typeCounts[entry.entityType] ?? 0) + 1;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tokens.accent.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Row(
                  children: [
                    Icon(
                      Icons.cloud_download_rounded,
                      size: 18,
                      color: tokens.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your team has ${status.availableUpdates} update${status.availableUpdates == 1 ? '' : 's'} available',
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Dismiss button
                    GestureDetector(
                      onTap: () =>
                          ref.read(bannerDismissedProvider.notifier).dismiss(),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: tokens.fgDim,
                      ),
                    ),
                  ],
                ),

                // Entity type breakdown chips
                if (typeCounts.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: typeCounts.entries.map((entry) {
                      final color = _colorForEntityType(entry.key);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconForEntityType(entry.key),
                              size: 12,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.value} ${entry.key}${entry.value == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: tokens.fgBright,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    // Pull Updates button
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: pulling
                            ? null
                            : () => _pullUpdates(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: tokens.accent,
                          foregroundColor: tokens.isLight
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: pulling
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.isLight
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(
                          pulling
                              ? AppLocalizations.of(context).pulling
                              : AppLocalizations.of(context).pullUpdates,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss text button
                    TextButton(
                      onPressed: () =>
                          ref.read(bannerDismissedProvider.notifier).dismiss(),
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.fgMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).later,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pullUpdates(BuildContext context, WidgetRef ref) async {
    ref.read(pullInProgressProvider.notifier).set(true);

    try {
      final service = ref.read(teamSyncServiceProvider);
      final count = await service.pullUpdates(
        deviceId: service.changeTracker.nodeId,
      );

      if (!context.mounted) return;

      final tokens = ThemeTokens.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? AppLocalizations.of(context).pulledUpdatesCount(count)
                : AppLocalizations.of(context).alreadyUpToDate,
          ),
          backgroundColor: count > 0 ? tokens.accent : null,
          duration: const Duration(seconds: 3),
        ),
      );

      // Dismiss banner and refresh status.
      ref.read(bannerDismissedProvider.notifier).dismiss();
      ref.invalidate(teamUpdatesProvider);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).pullFailed}: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      ref.read(pullInProgressProvider.notifier).set(false);
    }
  }
}
