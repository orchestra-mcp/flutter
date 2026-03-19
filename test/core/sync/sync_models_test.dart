import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

void main() {
  // ── SyncDelta ─────────────────────────────────────────────────────────

  group('SyncDelta.fromJson', () {
    test('parses normally with all fields', () {
      final delta = SyncDelta.fromJson({
        'id': 'd1',
        'entity_type': 'feature',
        'entity_id': 'FEAT-001',
        'operation': 'create',
        'timestamp': '2026-03-17T12:00:00Z',
        'version': 1,
      });
      expect(delta.id, 'd1');
      expect(delta.entityType, 'feature');
      expect(delta.version, 1);
    });

    test('handles null String fields with defaults', () {
      final delta = SyncDelta.fromJson({
        'id': null,
        'entity_type': null,
        'entity_id': null,
        'operation': null,
        'timestamp': null,
        'version': null,
      });
      expect(delta.id, '');
      expect(delta.entityType, '');
      expect(delta.entityId, '');
      expect(delta.version, 0);
      expect(delta.timestamp, isA<DateTime>());
    });

    test('handles missing fields with defaults', () {
      final delta = SyncDelta.fromJson(<String, dynamic>{});
      expect(delta.id, '');
      expect(delta.entityType, '');
    });
  });

  // ── SyncPullResponse ──────────────────────────────────────────────────

  group('SyncPullResponse.fromJson', () {
    test('parses normally when all fields present', () {
      final response = SyncPullResponse.fromJson({
        'deltas': [
          {
            'id': 'd1',
            'entity_type': 'feature',
            'entity_id': 'FEAT-001',
            'operation': 'create',
            'timestamp': '2026-03-17T12:00:00Z',
            'version': 1,
          },
        ],
        'has_more': false,
        'server_timestamp': '2026-03-17T12:00:01Z',
      });
      expect(response.deltas, hasLength(1));
      expect(response.deltas.first.entityId, 'FEAT-001');
      expect(response.hasMore, isFalse);
    });

    test('handles null deltas without crashing', () {
      final response = SyncPullResponse.fromJson({
        'deltas': null,
        'server_timestamp': '2026-03-17T12:00:00Z',
      });
      expect(response.deltas, isEmpty);
    });

    test('handles null server_timestamp without crashing', () {
      final response = SyncPullResponse.fromJson({
        'deltas': <dynamic>[],
        'server_timestamp': null,
      });
      expect(response.serverTimestamp, isA<DateTime>());
    });

    test('handles completely empty JSON', () {
      final response =
          SyncPullResponse.fromJson(<String, dynamic>{});
      expect(response.deltas, isEmpty);
      expect(response.hasMore, isFalse);
    });
  });

  // ── SyncPushResponse ──────────────────────────────────────────────────

  group('SyncPushResponse.fromJson', () {
    test('parses normally when accepted is present', () {
      final response = SyncPushResponse.fromJson({
        'accepted': ['id1', 'id2'],
        'conflicts': <dynamic>[],
        'server_timestamp': '2026-03-17T12:00:00Z',
      });
      expect(response.accepted, ['id1', 'id2']);
    });

    test('handles null accepted without crashing', () {
      final response = SyncPushResponse.fromJson({
        'accepted': null,
        'conflicts': <dynamic>[],
        'server_timestamp': '2026-03-17T12:00:00Z',
      });
      expect(response.accepted, isEmpty);
    });

    test('handles null server_timestamp without crashing', () {
      final response = SyncPushResponse.fromJson({
        'accepted': <dynamic>[],
        'conflicts': <dynamic>[],
        'server_timestamp': null,
      });
      expect(response.serverTimestamp, isA<DateTime>());
    });
  });

  // ── SyncPushRequest ───────────────────────────────────────────────────

  group('SyncPushRequest.fromJson', () {
    test('handles null deltas without crashing', () {
      final request = SyncPushRequest.fromJson({
        'deltas': null,
        'client_id': 'client-1',
        'last_sync_timestamp': '2026-03-17T12:00:00Z',
      });
      expect(request.deltas, isEmpty);
    });

    test('handles null client_id and timestamp', () {
      final request = SyncPushRequest.fromJson({
        'deltas': <dynamic>[],
        'client_id': null,
        'last_sync_timestamp': null,
      });
      expect(request.clientId, '');
      expect(request.lastSyncTimestamp, isA<DateTime>());
    });
  });

  // ── TeamUpdateStatus ──────────────────────────────────────────────────

  group('TeamUpdateStatus.fromJson', () {
    test('handles null checked_at without crashing', () {
      final status = TeamUpdateStatus.fromJson({
        'available_updates': 5,
        'checked_at': null,
      });
      expect(status.availableUpdates, 5);
      expect(status.checkedAt, isA<DateTime>());
    });
  });

  // ── TeamUpdateEntry ───────────────────────────────────────────────────

  group('TeamUpdateEntry.fromJson', () {
    test('handles null fields with defaults', () {
      final entry = TeamUpdateEntry.fromJson({
        'entity_type': null,
        'entity_id': null,
        'entity_title': null,
        'team_id': null,
        'team_name': null,
        'author_name': null,
        'from_version': null,
        'to_version': null,
        'updated_at': null,
      });
      expect(entry.entityType, '');
      expect(entry.entityId, '');
      expect(entry.fromVersion, 0);
      expect(entry.updatedAt, isA<DateTime>());
    });
  });
}
