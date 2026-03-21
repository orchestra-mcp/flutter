import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/web/activity/activity_feed_provider.dart';
import 'package:orchestra/screens/web/activity/activity_models.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Filter state ─────────────────────────────────────────────────────────────

class _ActivityFilterState {
  const _ActivityFilterState({
    this.selectedType,
    this.selectedUser,
  });

  final ActivityType? selectedType;
  final String? selectedUser;

  _ActivityFilterState copyWith({
    ActivityType? Function()? selectedType,
    String? Function()? selectedUser,
  }) {
    return _ActivityFilterState(
      selectedType: selectedType != null ? selectedType() : this.selectedType,
      selectedUser: selectedUser != null ? selectedUser() : this.selectedUser,
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
}

final _activityFilterProvider =
    NotifierProvider<_ActivityFilterNotifier, _ActivityFilterState>(
      _ActivityFilterNotifier.new,
    );

// ── Screen ───────────────────────────────────────────────────────────────────

/// Full-screen activity feed showing team-wide actions in real-time.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final filterState = ref.watch(_activityFilterProvider);
    final feedAsync = ref.watch(activityFeedProvider);

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (feed) {
        // Apply filters.
        var allItems = feed.items;
        if (filterState.selectedType != null) {
          allItems = allItems
              .where((a) => a.actionType == filterState.selectedType)
              .toList();
        }
        if (filterState.selectedUser != null) {
          allItems = allItems
              .where((a) => a.userName == filterState.selectedUser)
              .toList();
        }

        // Unique users from all unfiltered items for user-filter chips.
        final users = feed.items.map((a) => a.userName).toSet().toList()..sort();

        // Group by time.
        final groups = groupActivities(allItems);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
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
                  if (feed.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.activityLiveIndicator,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.rss_feed_rounded, color: tokens.accent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    l10n.activityCount(allItems.length),
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── "New activities" banner ────────────────────────────
              if (feed.newCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    onTap: () =>
                        ref.read(activityFeedProvider.notifier).clearNewCount(),
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
                          l10n.activityNewCount(feed.newCount),
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

              // ── Type filter chips ──────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: l10n.activityAllTypes,
                    isSelected: filterState.selectedType == null,
                    tokens: tokens,
                    onTap: () => ref
                        .read(_activityFilterProvider.notifier)
                        .setType(null),
                  ),
                  for (final type in ActivityType.values)
                    _FilterChip(
                      label: type.label,
                      isSelected: filterState.selectedType == type,
                      color: type.color,
                      tokens: tokens,
                      onTap: () => ref
                          .read(_activityFilterProvider.notifier)
                          .setType(type),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Member filter chips ────────────────────────────────
              if (users.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: l10n.activityAllMembers,
                      isSelected: filterState.selectedUser == null,
                      tokens: tokens,
                      onTap: () => ref
                          .read(_activityFilterProvider.notifier)
                          .setUser(null),
                    ),
                    for (final user in users)
                      _FilterChip(
                        label: user,
                        isSelected: filterState.selectedUser == user,
                        tokens: tokens,
                        onTap: () => ref
                            .read(_activityFilterProvider.notifier)
                            .setUser(user),
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // ── Timeline ───────────────────────────────────────────
              if (allItems.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: tokens.fgDim,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          feed.items.isEmpty
                              ? l10n.activityNoActivityYet
                              : l10n.activityNoMatchingFilters,
                          style:
                              TextStyle(color: tokens.fgMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final (group, groupItems) in groups) ...[
                  _TimeGroupHeader(
                    label: switch (group) {
                      ActivityTimeGroup.today => l10n.activityGroupToday,
                      ActivityTimeGroup.yesterday =>
                        l10n.activityGroupYesterday,
                      ActivityTimeGroup.earlier => l10n.activityGroupEarlier,
                    },
                    tokens: tokens,
                  ),
                  const SizedBox(height: 8),
                  for (final activity in groupItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityCard(
                        activity: activity,
                        tokens: tokens,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

// ── Time group header ────────────────────────────────────────────────────────

class _TimeGroupHeader extends StatelessWidget {
  const _TimeGroupHeader({required this.label, required this.tokens});

  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.fgDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(color: tokens.borderFaint, thickness: 1),
        ),
      ],
    );
  }
}

// ── Activity card ────────────────────────────────────────────────────────────

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
          // ── Avatar ────────────────────────────────────────────────
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

          // ── Content ───────────────────────────────────────────────
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
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      activity.relativeTime,
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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

// ── Filter chip ──────────────────────────────────────────────────────────────

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
