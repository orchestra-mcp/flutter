import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/date_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

enum NotificationType { featureUpdate, healthAlert, mention }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    body: body,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );
}

// ── Placeholder data ───────────────────────────────────────────────────────────

final _placeholderItems = [
  NotificationItem(
    id: '1',
    type: NotificationType.featureUpdate,
    title: 'FEAT-APJ advanced to in-review',
    body: 'Summary screen is ready for your review.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  NotificationItem(
    id: '2',
    type: NotificationType.mention,
    title: 'You were mentioned in FEAT-UYK',
    body: 'Please review the notifications screen implementation.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: true,
  ),
  NotificationItem(
    id: '3',
    type: NotificationType.healthAlert,
    title: 'Hydration reminder',
    body: "You've only had 400 ml today. Goal: 2 000 ml.",
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  NotificationItem(
    id: '4',
    type: NotificationType.featureUpdate,
    title: 'FEAT-HAM marked done',
    body: 'Search screen feature completed successfully.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  NotificationItem(
    id: '5',
    type: NotificationType.healthAlert,
    title: 'Long sitting session detected',
    body: "You've been sitting for 90 minutes. Time to move!",
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    isRead: true,
  ),
];

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
  late List<NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(_placeholderItems);
  }

  Future<void> _onRefresh() async {
    // Placeholder: real implementation calls SyncEngine.sync().
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  void _dismiss(String id) {
    setState(() {
      final idx = _items.indexWhere((n) => n.id == id);
      if (idx != -1) _items[idx] = _items[idx].copyWith(isRead: true);
    });
  }

  void _markAllRead() {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  List<NotificationItem> get _updates => _items
      .where(
        (n) =>
            n.type == NotificationType.featureUpdate ||
            n.type == NotificationType.mention,
      )
      .toList();

  List<NotificationItem> get _healthAlerts =>
      _items.where((n) => n.type == NotificationType.healthAlert).toList();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final isEmpty = _items.isEmpty;

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
                          style: TextStyle(fontSize: 13),
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
                          if (_updates.isNotEmpty) ...[
                            _SectionHeader(label: l10n.updates, tokens: tokens),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _NotificationTile(
                                  item: _updates[i],
                                  tokens: tokens,
                                  onDismissed: () => _dismiss(_updates[i].id),
                                ),
                                childCount: _updates.length,
                              ),
                            ),
                          ],
                          if (_healthAlerts.isNotEmpty) ...[
                            _SectionHeader(
                              label: l10n.healthAlerts,
                              tokens: tokens,
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _NotificationTile(
                                  item: _healthAlerts[i],
                                  tokens: tokens,
                                  onDismissed: () =>
                                      _dismiss(_healthAlerts[i].id),
                                ),
                                childCount: _healthAlerts.length,
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

  final NotificationItem item;
  final OrchestraColorTokens tokens;
  final VoidCallback onDismissed;

  IconData get _icon {
    switch (item.type) {
      case NotificationType.featureUpdate:
        return Icons.auto_awesome_rounded;
      case NotificationType.healthAlert:
        return Icons.favorite_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
    }
  }

  Color _iconColor(OrchestraColorTokens t) {
    switch (item.type) {
      case NotificationType.featureUpdate:
        return t.accent;
      case NotificationType.healthAlert:
        return const Color(0xFF4ADE80);
      case NotificationType.mention:
        return const Color(0xFF38BDF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor(tokens);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label:
          '${item.title}, ${formatRelative(item.timestamp)}, '
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
                        item.title,
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
                        item.body,
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
