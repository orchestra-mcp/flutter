import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/realtime/realtime_models.dart';
import 'package:orchestra/core/realtime/realtime_provider.dart';
import 'package:orchestra/core/realtime/realtime_service.dart';
import 'package:orchestra/screens/web/activity/activity_models.dart';

// ── Activity feed state ──────────────────────────────────────────────────────

class ActivityFeedState {
  const ActivityFeedState({
    required this.items,
    this.newCount = 0,
    this.isConnected = false,
  });

  final List<ActivityItem> items;
  final int newCount;
  final bool isConnected;

  ActivityFeedState copyWith({
    List<ActivityItem>? items,
    int? newCount,
    bool? isConnected,
  }) => ActivityFeedState(
    items: items ?? this.items,
    newCount: newCount ?? this.newCount,
    isConnected: isConnected ?? this.isConnected,
  );
}

// ── Provider notifier ────────────────────────────────────────────────────────

/// Maintains a live list of [ActivityItem]s fed by real-time [TeamActivityEvent]
/// and [FeatureUpdateEvent] streams from the WebSocket service.
///
/// New events are prepended so the feed shows newest-first. A [newCount]
/// counter tracks unseen items since the last [clearNewCount] call.
class ActivityFeedNotifier extends AsyncNotifier<ActivityFeedState> {
  StreamSubscription<TeamActivityEvent>? _teamSub;
  StreamSubscription<FeatureUpdateEvent>? _featureSub;
  StreamSubscription<RealtimeConnectionState>? _connSub;

  @override
  Future<ActivityFeedState> build() async {
    ref.onDispose(_cancelSubscriptions);

    _listenTeamActivity();
    _listenFeatureUpdates();
    _listenConnectionState();

    return const ActivityFeedState(items: []);
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  void _listenTeamActivity() {
    final service = ref.read(realtimeServiceProvider);
    _teamSub?.cancel();
    _teamSub = service
        .subscribe(RealtimeChannels.teamActivity)
        .map(TeamActivityEvent.fromRealtimeEvent)
        .listen(_onTeamActivity);
  }

  void _listenFeatureUpdates() {
    final service = ref.read(realtimeServiceProvider);
    _featureSub?.cancel();
    _featureSub = service
        .subscribe(RealtimeChannels.featureUpdates)
        .map(FeatureUpdateEvent.fromRealtimeEvent)
        .listen(_onFeatureUpdate);
  }

  void _listenConnectionState() {
    final service = ref.read(realtimeServiceProvider);
    _connSub?.cancel();
    _connSub = service.stateStream.listen((s) {
      final connected = s == RealtimeConnectionState.connected;
      final current = state.value ?? const ActivityFeedState(items: []);
      state = AsyncValue.data(current.copyWith(isConnected: connected));
    });
  }

  void _onTeamActivity(TeamActivityEvent event) {
    final item = _teamEventToActivity(event);
    if (item == null) return;
    _prependItem(item);
  }

  void _onFeatureUpdate(FeatureUpdateEvent event) {
    _prependItem(_featureEventToActivity(event));
  }

  void _prependItem(ActivityItem item) {
    final current = state.value ?? const ActivityFeedState(items: []);
    // Deduplicate by id.
    if (current.items.any((ActivityItem e) => e.id == item.id)) return;
    state = AsyncValue.data(
      current.copyWith(
        items: [item, ...current.items],
        newCount: current.newCount + 1,
      ),
    );
  }

  void _cancelSubscriptions() {
    _teamSub?.cancel();
    _featureSub?.cancel();
    _connSub?.cancel();
  }

  // ── Event mappers ────────────────────────────────────────────────────────

  ActivityItem? _teamEventToActivity(TeamActivityEvent event) {
    if (event.userId.isEmpty) return null;

    final (actionType, entityType, description) = _mapTeamAction(
      action: event.action,
      target: event.target,
      details: event.details,
    );

    return ActivityItem(
      id: '${event.userId}-${event.action}-${event.timestamp.millisecondsSinceEpoch}',
      userId: event.userId,
      userName: event.userName ?? event.userId,
      userAvatar: _initials(event.userName ?? event.userId),
      actionType: actionType,
      entityType: entityType,
      entityId: event.target,
      entityTitle: event.details ?? event.target,
      description: description,
      timestamp: event.timestamp,
    );
  }

  ActivityItem _featureEventToActivity(FeatureUpdateEvent event) {
    final isCreated = event.previousStatus.isEmpty;
    final actionType =
        isCreated ? ActivityType.featureCreated : ActivityType.featureStatusChanged;
    final description = isCreated
        ? 'Created feature ${event.featureId}'
        : 'Moved from ${event.previousStatus} to ${event.status}';

    return ActivityItem(
      id: '${event.featureId}-${event.status}-${event.timestamp.millisecondsSinceEpoch}',
      userId: event.userId ?? '',
      userName: event.userId ?? 'System',
      userAvatar: _initials(event.userId ?? 'S'),
      actionType: actionType,
      entityType: 'feature',
      entityId: event.featureId,
      entityTitle: event.title ?? event.featureId,
      description: description,
      timestamp: event.timestamp,
    );
  }

  /// Maps a [TeamActivityEvent.action] string to display fields.
  (ActivityType, String, String) _mapTeamAction({
    required String action,
    required String target,
    String? details,
  }) {
    switch (action) {
      case 'created_feature':
        return (ActivityType.featureCreated, 'feature', details ?? 'New feature created');
      case 'status_changed':
        return (ActivityType.featureStatusChanged, 'feature', details ?? 'Status updated');
      case 'created_note':
        return (ActivityType.noteCreated, 'note', details ?? 'Note created');
      case 'edited_note':
        return (ActivityType.noteEdited, 'note', details ?? 'Note edited');
      case 'delegated':
        return (ActivityType.delegationCreated, 'delegation', details ?? 'Delegation created');
      case 'completed_delegation':
        return (ActivityType.delegationCompleted, 'delegation', details ?? 'Delegation completed');
      case 'submitted_review':
        return (ActivityType.reviewSubmitted, 'feature', details ?? 'Review submitted');
      case 'commented':
        return (ActivityType.commentAdded, 'feature', details ?? 'Comment added');
      default:
        return (ActivityType.featureStatusChanged, 'feature', details ?? action);
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Clears the unseen-activity counter (call when user scrolls to top / taps banner).
  void clearNewCount() {
    final current = state.value;
    if (current == null || current.newCount == 0) return;
    state = AsyncValue.data(current.copyWith(newCount: 0));
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provides the live [ActivityFeedState] for the activity feed screen.
final activityFeedProvider =
    AsyncNotifierProvider<ActivityFeedNotifier, ActivityFeedState>(
      ActivityFeedNotifier.new,
    );

// ── Time grouping ─────────────────────────────────────────────────────────────

enum ActivityTimeGroup { today, yesterday, earlier }

ActivityTimeGroup groupForItem(ActivityItem item) {
  final now = DateTime.now();
  final itemDate = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (itemDate == today) return ActivityTimeGroup.today;
  if (itemDate == yesterday) return ActivityTimeGroup.yesterday;
  return ActivityTimeGroup.earlier;
}

/// Splits [items] into an ordered list of `(group, items)` pairs, newest-first within each group.
List<(ActivityTimeGroup, List<ActivityItem>)> groupActivities(
  List<ActivityItem> items,
) {
  final Map<ActivityTimeGroup, List<ActivityItem>> grouped = {};
  for (final item in items) {
    final g = groupForItem(item);
    (grouped[g] ??= []).add(item);
  }
  return [
    for (final g in ActivityTimeGroup.values)
      if (grouped.containsKey(g)) (g, grouped[g]!),
  ];
}
