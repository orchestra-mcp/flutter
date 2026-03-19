// ── Activity data models ────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// The type of activity that occurred in the team.
enum ActivityType {
  featureCreated,
  featureStatusChanged,
  noteCreated,
  noteEdited,
  delegationCreated,
  delegationCompleted,
  reviewSubmitted,
  commentAdded,
}

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.featureCreated:
        return 'Feature Created';
      case ActivityType.featureStatusChanged:
        return 'Status Changed';
      case ActivityType.noteCreated:
        return 'Note Created';
      case ActivityType.noteEdited:
        return 'Note Edited';
      case ActivityType.delegationCreated:
        return 'Delegation Created';
      case ActivityType.delegationCompleted:
        return 'Delegation Completed';
      case ActivityType.reviewSubmitted:
        return 'Review Submitted';
      case ActivityType.commentAdded:
        return 'Comment Added';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.featureCreated:
        return Icons.add_circle_outline_rounded;
      case ActivityType.featureStatusChanged:
        return Icons.swap_horiz_rounded;
      case ActivityType.noteCreated:
        return Icons.note_add_outlined;
      case ActivityType.noteEdited:
        return Icons.edit_note_rounded;
      case ActivityType.delegationCreated:
        return Icons.forward_to_inbox_rounded;
      case ActivityType.delegationCompleted:
        return Icons.task_alt_rounded;
      case ActivityType.reviewSubmitted:
        return Icons.rate_review_outlined;
      case ActivityType.commentAdded:
        return Icons.comment_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.featureCreated:
        return const Color(0xFF4CAF50);
      case ActivityType.featureStatusChanged:
        return const Color(0xFF2196F3);
      case ActivityType.noteCreated:
        return const Color(0xFF9C27B0);
      case ActivityType.noteEdited:
        return const Color(0xFF9C27B0);
      case ActivityType.delegationCreated:
        return const Color(0xFFFF9800);
      case ActivityType.delegationCompleted:
        return const Color(0xFF4CAF50);
      case ActivityType.reviewSubmitted:
        return const Color(0xFFE91E63);
      case ActivityType.commentAdded:
        return const Color(0xFF00BCD4);
    }
  }
}

/// A single activity in the team feed.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.entityTitle,
    required this.description,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final ActivityType actionType;

  /// The kind of entity referenced (e.g. "feature", "note", "delegation").
  final String entityType;
  final String entityId;
  final String entityTitle;
  final String description;
  final DateTime timestamp;

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      userAvatar: json['user_avatar'] as String? ?? '',
      actionType: ActivityType.values.firstWhere(
        (e) => e.name == (json['action_type'] as String? ?? ''),
        orElse: () => ActivityType.featureCreated,
      ),
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      entityTitle: json['entity_title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Human-readable relative timestamp.
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
