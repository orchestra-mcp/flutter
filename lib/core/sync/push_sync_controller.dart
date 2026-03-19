import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/sync/team_sync_service.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/team_selector_dialog.dart';

/// Result of a push sync operation.
class PushSyncResult {
  const PushSyncResult({
    required this.success,
    this.shareResponse,
    this.errorMessage,
  });

  final bool success;
  final ShareResponse? shareResponse;
  final String? errorMessage;
}

/// Orchestrates the end-to-end push sync flow:
/// 1. Opens team selector dialog
/// 2. Loads entity data
/// 3. Calls TeamSyncService.shareEntity
/// 4. Returns result for UI feedback
class PushSyncController {
  PushSyncController({required this.service});

  final TeamSyncService service;

  /// Executes a push sync for a single entity using the dialog selection.
  ///
  /// [entityData] is the serialized entity payload. If null, an empty map
  /// is used (the server will use any previously stored payload).
  Future<PushSyncResult> pushEntity({
    required TeamShareSelection selection,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> entityData,
  }) async {
    try {
      final response = await service.shareEntity(
        entityType: entityType,
        entityId: entityId,
        teamId: selection.teamId,
        shareWithAll: selection.shareWithAll,
        memberIds: selection.memberIds,
        permission: selection.permission,
        entityData: entityData,
      );

      return PushSyncResult(
        success: response.success,
        shareResponse: response,
        errorMessage: response.errorMessage,
      );
    } catch (e) {
      return PushSyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Batch push: shares multiple entities with the same team/settings.
  Future<List<PushSyncResult>> pushBatch({
    required TeamShareSelection selection,
    required List<({String entityType, String entityId, Map<String, dynamic> entityData})> entities,
  }) async {
    final results = <PushSyncResult>[];
    for (final entity in entities) {
      final result = await pushEntity(
        selection: selection,
        entityType: entity.entityType,
        entityId: entity.entityId,
        entityData: entity.entityData,
      );
      results.add(result);
    }
    return results;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provides the [PushSyncController] backed by the [TeamSyncService].
final pushSyncControllerProvider = Provider<PushSyncController>((ref) {
  return PushSyncController(
    service: ref.watch(teamSyncServiceProvider),
  );
});

// ── UI helper ─────────────────────────────────────────────────────────────────

/// Complete push sync flow: opens dialog → pushes → shows feedback.
///
/// Call this from any screen's onSync callback. Returns `true` if the sync
/// was successful, `false` if it failed, and `null` if the user dismissed
/// the dialog.
Future<bool?> performPushSync({
  required BuildContext context,
  required WidgetRef ref,
  required String entityType,
  required String entityId,
  required Map<String, dynamic> entityData,
}) async {
  // 1. Open team selector dialog.
  final selection = await showTeamSelectorDialog(
    context: context,
    entityType: entityType,
    entityId: entityId,
  );

  if (selection == null) return null; // User dismissed.

  if (!context.mounted) return null;

  // 2. Push to server.
  final controller = ref.read(pushSyncControllerProvider);
  final result = await controller.pushEntity(
    selection: selection,
    entityType: entityType,
    entityId: entityId,
    entityData: entityData,
  );

  if (!context.mounted) return result.success;

  // 3. Show feedback.
  if (result.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).sharedSuccessfully(entityType)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Revoke the share if user taps undo.
            if (result.shareResponse != null) {
              try {
                final mgmt = ref.read(teamSyncServiceProvider);
                await mgmt.repository.deleteShare(
                  result.shareResponse!.shareId,
                );
              } catch (_) {
                // Best effort — undo may fail.
              }
            }
          },
        ),
      ),
    );

    // Invalidate the sync status provider so the button updates.
    ref.invalidate(entitySyncStatusProvider((entityType, entityId)));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'Sync failed'),
        backgroundColor: const Color(0xFFEF4444),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  return result.success;
}
