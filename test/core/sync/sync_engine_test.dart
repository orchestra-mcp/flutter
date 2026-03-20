import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/sync_engine.dart';

void main() {
  group('SyncPhase', () {
    test('has expected values', () {
      expect(SyncPhase.values, hasLength(3));
      expect(SyncPhase.idle.name, 'idle');
      expect(SyncPhase.syncing.name, 'syncing');
      expect(SyncPhase.error.name, 'error');
    });
  });

  group('SyncEngineState', () {
    test('defaults to idle with no error', () {
      const state = SyncEngineState();
      expect(state.phase, SyncPhase.idle);
      expect(state.lastSyncTimestamp, isNull);
      expect(state.errorMessage, isNull);
      expect(state.syncedDeltaCount, 0);
    });

    test('copyWith updates phase', () {
      const state = SyncEngineState();
      final updated = state.copyWith(phase: SyncPhase.syncing);
      expect(updated.phase, SyncPhase.syncing);
      expect(updated.lastSyncTimestamp, isNull);
    });

    test('copyWith updates lastSyncTimestamp', () {
      const state = SyncEngineState();
      final ts = DateTime.utc(2026, 3, 20);
      final updated = state.copyWith(lastSyncTimestamp: ts);
      expect(updated.lastSyncTimestamp, ts);
      expect(updated.phase, SyncPhase.idle);
    });

    test('copyWith updates errorMessage', () {
      const state = SyncEngineState();
      final updated = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: 'network failure',
      );
      expect(updated.phase, SyncPhase.error);
      expect(updated.errorMessage, 'network failure');
    });

    test('copyWith clears errorMessage when null passed', () {
      final state = const SyncEngineState().copyWith(errorMessage: 'old error');
      // copyWith with errorMessage: null clears the error
      final cleared = state.copyWith(phase: SyncPhase.idle);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith updates syncedDeltaCount', () {
      const state = SyncEngineState();
      final updated = state.copyWith(syncedDeltaCount: 42);
      expect(updated.syncedDeltaCount, 42);
    });

    test('copyWith preserves fields not overridden', () {
      final ts = DateTime.utc(2026, 3, 20);
      final state = SyncEngineState(
        phase: SyncPhase.syncing,
        lastSyncTimestamp: ts,
        syncedDeltaCount: 10,
      );
      final updated = state.copyWith(phase: SyncPhase.idle);
      expect(updated.phase, SyncPhase.idle);
      expect(updated.lastSyncTimestamp, ts);
      expect(updated.syncedDeltaCount, 10);
    });
  });
}
