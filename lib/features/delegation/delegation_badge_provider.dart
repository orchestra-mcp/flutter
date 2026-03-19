import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Badge state ─────────────────────────────────────────────────────────────

class DelegationBadgeState {
  const DelegationBadgeState({this.unreadCount = 0});

  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  /// Display string — "9+" for counts above 9.
  String get displayText => unreadCount > 9 ? '9+' : unreadCount.toString();

  DelegationBadgeState copyWith({int? unreadCount}) =>
      DelegationBadgeState(unreadCount: unreadCount ?? this.unreadCount);
}

// ── Notifier ────────────────────────────────────────────────────────────────

class DelegationBadgeNotifier extends Notifier<DelegationBadgeState> {
  @override
  DelegationBadgeState build() => const DelegationBadgeState();

  /// Increment the unread count by one (called when a new delegation arrives).
  void increment() {
    state = state.copyWith(unreadCount: state.unreadCount + 1);
  }

  /// Set the count to a specific value (e.g. after fetching from the API).
  void setCount(int count) {
    state = state.copyWith(unreadCount: count);
  }

  /// Mark all delegations as read — resets the badge.
  void markAllRead() {
    state = state.copyWith(unreadCount: 0);
  }

  /// Decrement by one (e.g. when a single delegation is read).
  void decrementOne() {
    final next = (state.unreadCount - 1).clamp(0, 999);
    state = state.copyWith(unreadCount: next);
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final delegationBadgeProvider =
    NotifierProvider<DelegationBadgeNotifier, DelegationBadgeState>(
      DelegationBadgeNotifier.new,
    );

/// Convenience — whether the badge should show.
final hasDelegationBadgeProvider = Provider<bool>((ref) {
  return ref.watch(delegationBadgeProvider).hasUnread;
});

/// Convenience — the formatted badge text.
final delegationBadgeTextProvider = Provider<String>((ref) {
  return ref.watch(delegationBadgeProvider).displayText;
});
