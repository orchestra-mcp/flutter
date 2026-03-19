import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_conflict_resolver.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Status colors ───────────────────────────────────────────────────────────

Color _statusColor(EntitySyncStatus status) => switch (status) {
      EntitySyncStatus.synced => const Color(0xFF4ADE80),
      EntitySyncStatus.pending => const Color(0xFFFBBF24),
      EntitySyncStatus.outdated => const Color(0xFF38BDF8),
      EntitySyncStatus.conflict => const Color(0xFFEF4444),
      EntitySyncStatus.neverSynced => const Color(0xFF6B7280),
    };

IconData _statusIcon(EntitySyncStatus status) => switch (status) {
      EntitySyncStatus.synced => Icons.check_circle_rounded,
      EntitySyncStatus.pending => Icons.upload_rounded,
      EntitySyncStatus.outdated => Icons.download_rounded,
      EntitySyncStatus.conflict => Icons.warning_rounded,
      EntitySyncStatus.neverSynced => Icons.circle_outlined,
    };

String _statusLabelFallback(EntitySyncStatus status) => switch (status) {
      EntitySyncStatus.synced => 'Synced',
      EntitySyncStatus.pending => 'Pending',
      EntitySyncStatus.outdated => 'Outdated',
      EntitySyncStatus.conflict => 'Conflict',
      EntitySyncStatus.neverSynced => 'Not synced',
    };

String _statusLabel(EntitySyncStatus status, [AppLocalizations? l10n]) {
  if (l10n == null) return _statusLabelFallback(status);
  return switch (status) {
    EntitySyncStatus.synced => l10n.synced,
    EntitySyncStatus.pending => l10n.pending,
    EntitySyncStatus.outdated => l10n.outdated,
    EntitySyncStatus.conflict => l10n.conflict,
    EntitySyncStatus.neverSynced => l10n.notSynced,
  };
}

IconData _entityIcon(String type) => switch (type) {
      'project' => Icons.folder_rounded,
      'note' => Icons.sticky_note_2_rounded,
      'skill' => Icons.bolt_rounded,
      'workflow' => Icons.account_tree_rounded,
      'doc' => Icons.description_rounded,
      'agent' => Icons.smart_toy_rounded,
      _ => Icons.data_object_rounded,
    };

// ── Filter state ────────────────────────────────────────────────────────────

class _FilterNotifier extends Notifier<EntitySyncStatus?> {
  @override
  EntitySyncStatus? build() => null;

  void set(EntitySyncStatus? value) => state = value;
}

final _filterProvider =
    NotifierProvider<_FilterNotifier, EntitySyncStatus?>(_FilterNotifier.new);

// ── Screen ──────────────────────────────────────────────────────────────────

class SyncDashboardScreen extends ConsumerWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final metadataAsync = ref.watch(allSyncMetadataProvider);
    final conflicts = ref.watch(syncConflictsProvider);
    final wsManager = ref.watch(wsManagerProvider);
    final filter = ref.watch(_filterProvider);

    return ColoredBox(
      color: tokens.bg,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Text(
                      l10n.syncStatus,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _ConnectionBadge(wsManager: wsManager, tokens: tokens),
                  ],
                ),
              ),
            ),

            // ── Overview cards ──────────────────────────────────
            SliverToBoxAdapter(
              child: metadataAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.errorWithDetails('$e'),
                      style: TextStyle(color: tokens.fgDim)),
                ),
                data: (entities) {
                  final synced = entities
                      .where((e) => e.status == EntitySyncStatus.synced)
                      .length;
                  final pending = entities
                      .where((e) => e.status == EntitySyncStatus.pending)
                      .length;
                  final outdated = entities
                      .where((e) => e.status == EntitySyncStatus.outdated)
                      .length;
                  final conflictCount = conflicts.length;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        _StatCard(
                          label: l10n.synced,
                          count: synced,
                          color: const Color(0xFF4ADE80),
                          icon: Icons.check_circle_rounded,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: l10n.pending,
                          count: pending,
                          color: const Color(0xFFFBBF24),
                          icon: Icons.upload_rounded,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: l10n.outdated,
                          count: outdated,
                          color: const Color(0xFF38BDF8),
                          icon: Icons.download_rounded,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          label: l10n.conflicts,
                          count: conflictCount,
                          color: const Color(0xFFEF4444),
                          icon: Icons.warning_rounded,
                          tokens: tokens,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Filter chips ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.all,
                      selected: filter == null,
                      tokens: tokens,
                      onTap: () =>
                          ref.read(_filterProvider.notifier).set(null),
                    ),
                    for (final status in EntitySyncStatus.values) ...[
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: _statusLabel(status, l10n),
                        selected: filter == status,
                        color: _statusColor(status),
                        tokens: tokens,
                        onTap: () =>
                            ref.read(_filterProvider.notifier).set(status),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Entity list ─────────────────────────────────────
            metadataAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
              data: (entities) {
                final filtered = filter == null
                    ? entities
                    : entities.where((e) => e.status == filter).toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          filter == null
                              ? l10n.noSyncedEntities
                              : l10n.noFilteredEntities(_statusLabel(filter, l10n).toLowerCase()),
                          style: TextStyle(color: tokens.fgDim, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _EntityRow(
                      metadata: filtered[i],
                      tokens: tokens,
                    ),
                    childCount: filtered.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.wsManager, required this.tokens});
  final WsManager wsManager;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = wsManager.state == WsState.connected;
    final color = connected ? const Color(0xFF4ADE80) : const Color(0xFFEF4444);
    final label = connected ? l10n.connected : l10n.disconnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.tokens,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.tokens,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color? color;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? tokens.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.5)
                : tokens.border.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? chipColor : tokens.fgMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _EntityRow extends StatelessWidget {
  const _EntityRow({required this.metadata, required this.tokens});
  final EntitySyncMetadata metadata;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(metadata.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Entity type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _entityIcon(metadata.entityType),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),

            // Entity info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${metadata.entityType}/${metadata.entityId}',
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'v${metadata.localVersion}',
                        style: TextStyle(
                          color: tokens.fgDim,
                          fontSize: 11,
                        ),
                      ),
                      if (metadata.remoteVersion != null) ...[
                        Text(
                          ' → v${metadata.remoteVersion}',
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (metadata.lastSyncedAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.schedule_rounded,
                            size: 10, color: tokens.fgDim),
                        const SizedBox(width: 2),
                        Text(
                          _formatTime(metadata.lastSyncedAt!),
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(metadata.status), size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _statusLabel(metadata.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now'; // Short time format
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
