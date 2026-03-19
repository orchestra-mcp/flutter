import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/web/activity/activity_models.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Mock data ───────────────────────────────────────────────────────────────

final _mockActivities = [
  ActivityItem(
    id: 'act-001',
    userId: 'u1',
    userName: 'Sarah Chen',
    userAvatar: 'SC',
    actionType: ActivityType.featureCreated,
    entityType: 'feature',
    entityId: 'FEAT-WVS',
    entityTitle: 'AI insight engine',
    description: 'Created new feature with priority P0',
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
  ),
  ActivityItem(
    id: 'act-002',
    userId: 'u2',
    userName: 'Marcus Rivera',
    userAvatar: 'MR',
    actionType: ActivityType.featureStatusChanged,
    entityType: 'feature',
    entityId: 'FEAT-BHF',
    entityTitle: 'Nutrition manager',
    description: 'Moved from in-testing to in-review',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  ActivityItem(
    id: 'act-003',
    userId: 'u3',
    userName: 'Aisha Patel',
    userAvatar: 'AP',
    actionType: ActivityType.delegationCreated,
    entityType: 'delegation',
    entityId: 'DEL-042',
    entityTitle: 'Web auth storage',
    description: 'Delegated to Marcus Rivera for code review',
    timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
  ),
  ActivityItem(
    id: 'act-004',
    userId: 'u4',
    userName: 'James Wilson',
    userAvatar: 'JW',
    actionType: ActivityType.reviewSubmitted,
    entityType: 'feature',
    entityId: 'FEAT-UJV',
    entityTitle: 'WebSocket transport layer',
    description: 'Approved with no changes requested',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  ActivityItem(
    id: 'act-005',
    userId: 'u1',
    userName: 'Sarah Chen',
    userAvatar: 'SC',
    actionType: ActivityType.noteCreated,
    entityType: 'note',
    entityId: 'NOTE-8F2',
    entityTitle: 'Architecture decision: QUIC vs gRPC',
    description: 'Added design note with benchmarks',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ActivityItem(
    id: 'act-006',
    userId: 'u2',
    userName: 'Marcus Rivera',
    userAvatar: 'MR',
    actionType: ActivityType.commentAdded,
    entityType: 'feature',
    entityId: 'FEAT-FRU',
    entityTitle: 'Web app shell',
    description: 'Commented on responsive layout approach',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  ActivityItem(
    id: 'act-007',
    userId: 'u3',
    userName: 'Aisha Patel',
    userAvatar: 'AP',
    actionType: ActivityType.delegationCompleted,
    entityType: 'delegation',
    entityId: 'DEL-039',
    entityTitle: 'Plugin host refactor',
    description: 'Delegation completed successfully',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  ActivityItem(
    id: 'act-008',
    userId: 'u4',
    userName: 'James Wilson',
    userAvatar: 'JW',
    actionType: ActivityType.noteEdited,
    entityType: 'note',
    entityId: 'NOTE-4A1',
    entityTitle: 'Sprint retrospective notes',
    description: 'Updated action items section',
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  ActivityItem(
    id: 'act-009',
    userId: 'u1',
    userName: 'Sarah Chen',
    userAvatar: 'SC',
    actionType: ActivityType.featureStatusChanged,
    entityType: 'feature',
    entityId: 'FEAT-HUF',
    entityTitle: 'Public marketing pages',
    description: 'Moved from in-progress to in-testing',
    timestamp: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  ActivityItem(
    id: 'act-010',
    userId: 'u2',
    userName: 'Marcus Rivera',
    userAvatar: 'MR',
    actionType: ActivityType.featureCreated,
    entityType: 'feature',
    entityId: 'FEAT-KTT',
    entityTitle: 'Workflow generator',
    description: 'Created chore for CLAUDE.md generation',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// ── Filter state ────────────────────────────────────────────────────────────

class _ActivityFilterState {
  const _ActivityFilterState({
    this.selectedType,
    this.selectedUser,
    this.newActivityCount = 0,
  });

  final ActivityType? selectedType;
  final String? selectedUser;
  final int newActivityCount;

  _ActivityFilterState copyWith({
    ActivityType? Function()? selectedType,
    String? Function()? selectedUser,
    int? newActivityCount,
  }) {
    return _ActivityFilterState(
      selectedType: selectedType != null ? selectedType() : this.selectedType,
      selectedUser: selectedUser != null ? selectedUser() : this.selectedUser,
      newActivityCount: newActivityCount ?? this.newActivityCount,
    );
  }
}

class _ActivityFilterNotifier extends Notifier<_ActivityFilterState> {
  @override
  _ActivityFilterState build() => const _ActivityFilterState();

  void setType(ActivityType? type) =>
      state = state.copyWith(selectedType: () => type);

  void setUser(String? user) =>
      state = state.copyWith(selectedUser: () => user);

  void addNewActivities(int count) =>
      state = state.copyWith(newActivityCount: state.newActivityCount + count);

  void clearNewActivities() => state = state.copyWith(newActivityCount: 0);
}

final _activityFilterProvider =
    NotifierProvider<_ActivityFilterNotifier, _ActivityFilterState>(
      _ActivityFilterNotifier.new,
    );

// ── Screen ──────────────────────────────────────────────────────────────────

/// Full-screen activity feed showing team-wide actions in real-time.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final filterState = ref.watch(_activityFilterProvider);

    // Apply filters to mock data.
    var filtered = _mockActivities.toList();
    if (filterState.selectedType != null) {
      filtered = filtered
          .where((a) => a.actionType == filterState.selectedType)
          .toList();
    }
    if (filterState.selectedUser != null) {
      filtered = filtered
          .where((a) => a.userName == filterState.selectedUser)
          .toList();
    }

    // Unique users for the user filter.
    final users = _mockActivities.map((a) => a.userName).toSet().toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.activityFeedTitle,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.rss_feed_rounded, color: tokens.accent, size: 20),
              const SizedBox(width: 6),
              Text(
                l10n.activityCount(filtered.length),
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── "New activities" banner ──────────────────────────────
          if (filterState.newActivityCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                onTap: () {
                  ref
                      .read(_activityFilterProvider.notifier)
                      .clearNewActivities();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: tokens.accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.activityNewCount(filterState.newActivityCount),
                      style: TextStyle(
                        color: tokens.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Filter chips ────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: l10n.activityAllTypes,
                isSelected: filterState.selectedType == null,
                tokens: tokens,
                onTap: () =>
                    ref.read(_activityFilterProvider.notifier).setType(null),
              ),
              for (final type in ActivityType.values)
                _FilterChip(
                  label: type.label,
                  isSelected: filterState.selectedType == type,
                  color: type.color,
                  tokens: tokens,
                  onTap: () =>
                      ref.read(_activityFilterProvider.notifier).setType(type),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── User filter ─────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: l10n.activityAllMembers,
                isSelected: filterState.selectedUser == null,
                tokens: tokens,
                onTap: () =>
                    ref.read(_activityFilterProvider.notifier).setUser(null),
              ),
              for (final user in users)
                _FilterChip(
                  label: user,
                  isSelected: filterState.selectedUser == user,
                  tokens: tokens,
                  onTap: () =>
                      ref.read(_activityFilterProvider.notifier).setUser(user),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Timeline ────────────────────────────────────────────
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, color: tokens.fgDim, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      l10n.activityNoMatchingFilters,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityCard(activity: activity, tokens: tokens),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Activity card ───────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.tokens});

  final ActivityItem activity;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.actionType.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                activity.userAvatar,
                style: TextStyle(
                  color: activity.actionType.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.userName,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      activity.actionType.icon,
                      color: activity.actionType.color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.actionType.label.toLowerCase(),
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      activity.relativeTime,
                      style: TextStyle(color: tokens.fgDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Entity link.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.entityId,
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity.entityTitle,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? tokens.accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.20)
              : tokens.bgAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor.withValues(alpha: 0.6)
                : tokens.borderFaint,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : tokens.fgMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
