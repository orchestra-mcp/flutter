import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/realtime/realtime_models.dart';
import 'package:orchestra/core/realtime/realtime_service.dart';

// ─── Singleton service ──────────────────────────────────────────────────────

/// Provides a single [RealtimeService] instance for the app lifetime.
///
/// The service is disposed automatically when the provider is torn down.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

// ─── Connection state ───────────────────────────────────────────────────────

/// Stream of [RealtimeConnectionState] changes from the realtime service.
final realtimeConnectionProvider = StreamProvider<RealtimeConnectionState>((
  ref,
) {
  final service = ref.watch(realtimeServiceProvider);
  return service.stateStream;
});

// ─── Channel-specific providers ─────────────────────────────────────────────

/// Stream of [FileChangeEvent]s from the `file_changes` channel.
///
/// Automatically subscribes on first listen and maps raw events
/// into typed [FileChangeEvent] models.
final fileChangesProvider = StreamProvider<FileChangeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  ref.onDispose(() => service.unsubscribe(RealtimeChannels.fileChanges));

  return service
      .subscribe(RealtimeChannels.fileChanges)
      .map(FileChangeEvent.fromRealtimeEvent);
});

/// Stream of [FeatureUpdateEvent]s from the `feature_updates` channel.
///
/// Automatically subscribes on first listen and maps raw events
/// into typed [FeatureUpdateEvent] models.
final featureUpdatesProvider = StreamProvider<FeatureUpdateEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  ref.onDispose(() => service.unsubscribe(RealtimeChannels.featureUpdates));

  return service
      .subscribe(RealtimeChannels.featureUpdates)
      .map(FeatureUpdateEvent.fromRealtimeEvent);
});

/// Stream of [TunnelStatusEvent]s from the `tunnel_status` channel.
///
/// Reports when desktop tunnel clients connect, disconnect, or reconnect.
final realtimeTunnelStatusProvider = StreamProvider<TunnelStatusEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  ref.onDispose(() => service.unsubscribe(RealtimeChannels.tunnelStatus));

  return service
      .subscribe(RealtimeChannels.tunnelStatus)
      .map(TunnelStatusEvent.fromRealtimeEvent);
});

/// Stream of [TeamActivityEvent]s from the `team_activity` channel.
///
/// Shows real-time team activity such as feature starts, PR merges,
/// and deployments.
final teamActivityProvider = StreamProvider<TeamActivityEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  ref.onDispose(() => service.unsubscribe(RealtimeChannels.teamActivity));

  return service
      .subscribe(RealtimeChannels.teamActivity)
      .map(TeamActivityEvent.fromRealtimeEvent);
});
