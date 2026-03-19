import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// A compact button that displays the sync status of an entity and triggers
/// the team sync flow when tapped.
///
/// Shows different icons and colours based on [EntitySyncStatus]:
/// - `neverSynced` → cloud-upload (dim)
/// - `synced`      → checkmark (green)
/// - `pending`     → clock (amber)
/// - `outdated`    → download (blue)
/// - `conflict`    → warning (red)
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.onSync,
  });

  /// The sync entity type string (e.g. 'project', 'note', 'skill', etc.)
  final String entityType;

  /// The unique identifier for this entity.
  final String entityId;

  /// Called when the user taps the button to initiate a sync/share action.
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final asyncMeta = ref.watch(
      entitySyncStatusProvider((entityType, entityId)),
    );

    return asyncMeta.when(
      loading: () => _buildIcon(
        tokens: tokens,
        icon: Icons.cloud_upload_outlined,
        color: tokens.fgDim,
      ),
      error: (_, _) => _buildIcon(
        tokens: tokens,
        icon: Icons.cloud_off_rounded,
        color: tokens.fgDim,
      ),
      data: (meta) {
        final status = meta?.status ?? EntitySyncStatus.neverSynced;
        final (IconData icon, Color color) = _iconForStatus(status, tokens);
        return _buildIcon(tokens: tokens, icon: icon, color: color);
      },
    );
  }

  Widget _buildIcon({
    required OrchestraColorTokens tokens,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onSync,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Sync with team',
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  static (IconData, Color) _iconForStatus(
    EntitySyncStatus status,
    OrchestraColorTokens tokens,
  ) {
    return switch (status) {
      EntitySyncStatus.neverSynced => (
        Icons.cloud_upload_outlined,
        tokens.fgDim,
      ),
      EntitySyncStatus.synced => (
        Icons.cloud_done_rounded,
        const Color(0xFF22C55E),
      ),
      EntitySyncStatus.pending => (
        Icons.schedule_rounded,
        const Color(0xFFF59E0B),
      ),
      EntitySyncStatus.outdated => (
        Icons.cloud_download_rounded,
        const Color(0xFF3B82F6),
      ),
      EntitySyncStatus.conflict => (
        Icons.warning_amber_rounded,
        const Color(0xFFEF4444),
      ),
    };
  }
}

/// A simpler inline dot indicator for sync status — used as a compact
/// alternative to [SyncStatusButton] when space is limited.
class SyncStatusDot extends ConsumerWidget {
  const SyncStatusDot({
    super.key,
    required this.entityType,
    required this.entityId,
  });

  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final asyncMeta = ref.watch(
      entitySyncStatusProvider((entityType, entityId)),
    );

    final status =
        asyncMeta.whenOrNull(data: (meta) => meta?.status) ??
        EntitySyncStatus.neverSynced;

    final color = switch (status) {
      EntitySyncStatus.neverSynced => tokens.fgDim,
      EntitySyncStatus.synced => const Color(0xFF22C55E),
      EntitySyncStatus.pending => const Color(0xFFF59E0B),
      EntitySyncStatus.outdated => const Color(0xFF3B82F6),
      EntitySyncStatus.conflict => const Color(0xFFEF4444),
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
