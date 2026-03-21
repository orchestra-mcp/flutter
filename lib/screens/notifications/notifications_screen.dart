import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/notifications/notification_store.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/date_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

/// Notifications screen with swipe-to-dismiss and two sections (Updates /
/// Health Alerts). Placeholder data is used until the real
/// notifications_provider with Drift + WebSocket is wired.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _dismiss(String id) {
    ref.read(notificationStoreProvider.notifier).markRead(id);
  }

  void _markAllRead() {
    ref.read(notificationStoreProvider.notifier).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(notificationStoreProvider);
    final isEmpty = items.isEmpty;

    final updates = items.where((n) => n.type != 'health_alert').toList();
    final healthAlerts = items.where((n) => n.type == 'health_alert').toList();

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: tokens.fgBright,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    l10n.notifications,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (!isEmpty)
                    Semantics(
                      label: l10n.markAllNotificationsReadSemantics,
                      child: TextButton(
                        onPressed: _markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: tokens.accent,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        child: Text(
                          l10n.markAllReadAction,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isEmpty
                  ? _EmptyState(tokens: tokens)
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: tokens.accent,
                      backgroundColor: tokens.bgAlt,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (updates.isNotEmpty) ...[
                            _SectionHeader(label: l10n.updates, tokens: tokens),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _NotificationTile(
                                  item: updates[i],
                                  tokens: tokens,
                                  onDismissed: () => _dismiss(updates[i].id),
                                ),
                                childCount: updates.length,
                              ),
                            ),
                          ],
                          if (healthAlerts.isNotEmpty) ...[
                            _SectionHeader(
                              label: l10n.healthAlerts,
                              tokens: tokens,
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _NotificationTile(
                                  item: healthAlerts[i],
                                  tokens: tokens,
                                  onDismissed: () =>
                                      _dismiss(healthAlerts[i].id),
                                ),
                                childCount: healthAlerts.length,
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.tokens});
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: tokens.fgDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ── Notification tile ──────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.tokens,
    required this.onDismissed,
  });

  final AppNotification item;
  final OrchestraColorTokens tokens;
  final VoidCallback onDismissed;

  IconData get _icon => switch (item.type) {
    'feature_update' => Icons.auto_awesome_rounded,
    'health_alert' => Icons.favorite_rounded,
    'smart_action' => Icons.smart_toy_rounded,
    'sync' => Icons.sync_rounded,
    'agent_event' => Icons.security_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _iconColor(OrchestraColorTokens t) => switch (item.type) {
    'feature_update' => t.accent,
    'health_alert' => const Color(0xFF4ADE80),
    'smart_action' => const Color(0xFFA78BFA),
    'sync' => const Color(0xFF38BDF8),
    'agent_event' => const Color(0xFFFBBF24),
    _ => t.fgMuted,
  };

  /// Resolve a localized title from the stored `_titleKey` data field.
  String _localizedTitle(AppLocalizations l10n) {
    final key = item.data['_titleKey'] as String?;
    return switch (key) {
      'notifFeatureComplete' => l10n.notifFeatureComplete,
      'notifFeatureUpdated' => l10n.notifFeatureUpdated,
      'notifSmartActionComplete' => l10n.notifSmartActionComplete,
      'notifNoteGenerated' => l10n.notifNoteGenerated,
      'notifSyncComplete' => l10n.notifSyncComplete,
      'notifAgentFinished' => l10n.notifAgentFinished,
      'notifEntityDeleted' => l10n.notifEntityDeleted(
        item.data['entity_type']?.toString() ?? '',
      ),
      _ => item.title,
    };
  }

  /// Resolve a localized body from the stored structured data.
  String _localizedBody(AppLocalizations l10n) {
    final key = item.data['_titleKey'] as String?;
    return switch (key) {
      'notifNoteGenerated' => l10n.notifNoteReady(
        item.data['_bodyNoteTitle']?.toString() ?? item.body,
      ),
      'notifSyncComplete' => l10n.notifSyncItemsSynced(
        (item.data['_bodyCount'] as int?) ?? int.tryParse(item.body) ?? 0,
      ),
      'notifEntityDeleted' => l10n.notifEntityDeletedBody(
        item.data['entity_type']?.toString() ?? '',
        item.data['entity_id']?.toString() ?? '',
      ),
      'notifAgentFinished' =>
        item.body.isNotEmpty ? item.body : l10n.notifAgentSessionCompleted,
      _ => item.body,
    };
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor(tokens);
    final l10n = AppLocalizations.of(context);
    final displayTitle = _localizedTitle(l10n);
    final displayBody = _localizedBody(l10n);
    return Semantics(
      label:
          '$displayTitle, ${formatRelative(item.timestamp)}, '
          '${item.isRead ? l10n.notificationRead : l10n.notificationUnread}',
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: tokens.accent.withValues(alpha: 0.15),
          child: Icon(Icons.check_rounded, color: tokens.accent),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayBody,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRelative(item.timestamp),
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: tokens.fgDim,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).allCaughtUp,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).noNewNotifications,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
