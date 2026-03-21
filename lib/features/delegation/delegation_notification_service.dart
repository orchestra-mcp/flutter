import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/ws/ws_manager.dart';
import 'package:orchestra/core/ws/ws_provider.dart';
import 'package:orchestra/features/delegation/delegation_badge_provider.dart';

// ── Delegation event model ──────────────────────────────────────────────────

enum DelegationEventType { created, accepted, rejected, completed, expired }

class DelegationEvent {
  const DelegationEvent({
    required this.id,
    required this.type,
    required this.featureId,
    required this.featureTitle,
    required this.fromUser,
    required this.toUser,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final DelegationEventType type;
  final String featureId;
  final String featureTitle;
  final String fromUser;
  final String toUser;
  final String message;
  final DateTime timestamp;

  factory DelegationEvent.fromJson(Map<String, dynamic> json) {
    return DelegationEvent(
      id: json['id'] as String? ?? '',
      type: DelegationEventType.values.firstWhere(
        (e) => e.name == (json['delegation_type'] as String? ?? 'created'),
        orElse: () => DelegationEventType.created,
      ),
      featureId: json['feature_id'] as String? ?? '',
      featureTitle: json['feature_title'] as String? ?? '',
      fromUser: json['from_user'] as String? ?? '',
      toUser: json['to_user'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get actionText {
    switch (type) {
      case DelegationEventType.created:
        return '$fromUser delegated "$featureTitle" to you';
      case DelegationEventType.accepted:
        return '$toUser accepted delegation for "$featureTitle"';
      case DelegationEventType.rejected:
        return '$toUser declined delegation for "$featureTitle"';
      case DelegationEventType.completed:
        return 'Delegation for "$featureTitle" completed';
      case DelegationEventType.expired:
        return 'Delegation for "$featureTitle" expired';
    }
  }

  IconData get icon {
    switch (type) {
      case DelegationEventType.created:
        return Icons.forward_to_inbox_rounded;
      case DelegationEventType.accepted:
        return Icons.check_circle_outline_rounded;
      case DelegationEventType.rejected:
        return Icons.cancel_outlined;
      case DelegationEventType.completed:
        return Icons.task_alt_rounded;
      case DelegationEventType.expired:
        return Icons.timer_off_outlined;
    }
  }

  Color get color {
    switch (type) {
      case DelegationEventType.created:
        return const Color(0xFF2196F3);
      case DelegationEventType.accepted:
        return const Color(0xFF4CAF50);
      case DelegationEventType.rejected:
        return const Color(0xFFF44336);
      case DelegationEventType.completed:
        return const Color(0xFF4CAF50);
      case DelegationEventType.expired:
        return const Color(0xFFFF9800);
    }
  }
}

// ── Service ─────────────────────────────────────────────────────────────────

class DelegationNotificationService {
  DelegationNotificationService({required this.ref});

  final Ref ref;
  StreamSubscription<dynamic>? _subscription;
  final _eventController = StreamController<DelegationEvent>.broadcast();

  Stream<DelegationEvent> get eventStream => _eventController.stream;

  /// Starts listening to delegation events from the WebSocket manager.
  void startListening() {
    final ws = ref.read(wsManagerProvider);
    _subscription = ws.eventStream.listen((event) {
      // Check if the WS event is a delegation event by examining its type
      // via the UnknownWsEvent fallback (delegation events come through as
      // unrecognised types for now).
      final json = _extractDelegationJson(event);
      if (json != null) {
        handleDelegationEvent(json);
      }
    });
  }

  Map<String, dynamic>? _extractDelegationJson(dynamic event) {
    // In the current WsEvent sealed class, delegation events arrive as
    // UnknownWsEvent with type starting with 'delegation.'.
    if (event is! Object) return null;
    try {
      final dynamic data = (event as dynamic).data;
      final dynamic type = (event as dynamic).type;
      if (type is String && type.startsWith('delegation.')) {
        return data as Map<String, dynamic>?;
      }
    } catch (_) {
      // Not a delegation event
    }
    return null;
  }

  /// Processes a raw delegation event payload.
  void handleDelegationEvent(Map<String, dynamic> json) {
    final event = DelegationEvent.fromJson(json);
    _eventController.add(event);

    // Increment unread count.
    ref.read(delegationBadgeProvider.notifier).increment();
  }

  /// Shows a snackbar notification for a delegation event.
  void showSnackbar(BuildContext context, DelegationEvent event) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E2E),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(event.icon, color: event.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.actionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event.message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: event.color,
          onPressed: () {
            context.go(Routes.delegation(event.id));
          },
        ),
      ),
    );
  }

  /// Stops listening and cleans up.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _eventController.close();
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final delegationNotificationServiceProvider =
    Provider<DelegationNotificationService>((ref) {
      final service = DelegationNotificationService(ref: ref);
      ref.onDispose(service.dispose);
      return service;
    });
