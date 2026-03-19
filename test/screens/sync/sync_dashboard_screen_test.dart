import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';

void main() {
  // ── Status helper functions ─────────────────────────────────────────────

  group('Status metadata helpers', () {
    test('EntitySyncStatus has all expected values', () {
      expect(EntitySyncStatus.values, hasLength(5));
      expect(EntitySyncStatus.values, contains(EntitySyncStatus.synced));
      expect(EntitySyncStatus.values, contains(EntitySyncStatus.pending));
      expect(EntitySyncStatus.values, contains(EntitySyncStatus.outdated));
      expect(EntitySyncStatus.values, contains(EntitySyncStatus.conflict));
      expect(EntitySyncStatus.values, contains(EntitySyncStatus.neverSynced));
    });

    test('EntitySyncStatus.fromString round-trips', () {
      for (final status in EntitySyncStatus.values) {
        expect(EntitySyncStatus.fromString(status.toJson()), status);
      }
    });

    test('fromString throws on unknown', () {
      expect(
        () => EntitySyncStatus.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── EntitySyncMetadata filtering ────────────────────────────────────────

  group('EntitySyncMetadata filtering', () {
    final entities = [
      const EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        status: EntitySyncStatus.synced,
        localVersion: 3,
      ),
      const EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n2',
        status: EntitySyncStatus.pending,
        localVersion: 2,
      ),
      const EntitySyncMetadata(
        entityType: 'project',
        entityId: 'p1',
        status: EntitySyncStatus.outdated,
        localVersion: 1,
        remoteVersion: 3,
      ),
      const EntitySyncMetadata(
        entityType: 'skill',
        entityId: 's1',
        status: EntitySyncStatus.conflict,
        localVersion: 2,
        remoteVersion: 4,
      ),
      const EntitySyncMetadata(
        entityType: 'doc',
        entityId: 'd1',
        status: EntitySyncStatus.neverSynced,
      ),
      const EntitySyncMetadata(
        entityType: 'agent',
        entityId: 'a1',
        status: EntitySyncStatus.synced,
        localVersion: 5,
      ),
    ];

    test('count synced entities', () {
      final synced = entities
          .where((e) => e.status == EntitySyncStatus.synced)
          .length;
      expect(synced, 2);
    });

    test('count pending entities', () {
      final pending = entities
          .where((e) => e.status == EntitySyncStatus.pending)
          .length;
      expect(pending, 1);
    });

    test('count outdated entities', () {
      final outdated = entities
          .where((e) => e.status == EntitySyncStatus.outdated)
          .length;
      expect(outdated, 1);
    });

    test('count conflict entities', () {
      final conflict = entities
          .where((e) => e.status == EntitySyncStatus.conflict)
          .length;
      expect(conflict, 1);
    });

    test('filter by specific status', () {
      const filter = EntitySyncStatus.synced;
      final filtered = entities.where((e) => e.status == filter).toList();
      expect(filtered, hasLength(2));
      expect(filtered.every((e) => e.status == EntitySyncStatus.synced), true);
    });

    test('null filter returns all', () {
      const EntitySyncStatus? filter = null;
      final filtered = filter == null
          ? entities
          : entities.where((e) => e.status == filter).toList();
      expect(filtered, hasLength(6));
    });

    test('filter with no matches returns empty', () {
      // All entities already have a status, but let's filter for one that
      // has few entries.
      final singleEntity = [
        const EntitySyncMetadata(
          entityType: 'workflow',
          entityId: 'w1',
          status: EntitySyncStatus.synced,
        ),
      ];
      final filtered = singleEntity
          .where((e) => e.status == EntitySyncStatus.conflict)
          .toList();
      expect(filtered, isEmpty);
    });
  });

  // ── Version display ─────────────────────────────────────────────────────

  group('Version display logic', () {
    test('local version only when remote is null', () {
      const meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        localVersion: 3,
      );
      expect(meta.localVersion, 3);
      expect(meta.remoteVersion, isNull);
    });

    test('both versions when remote is set', () {
      const meta = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        localVersion: 2,
        remoteVersion: 5,
      );
      expect(meta.localVersion, 2);
      expect(meta.remoteVersion, 5);
    });

    test('version display format', () {
      const meta = EntitySyncMetadata(
        entityType: 'skill',
        entityId: 's1',
        localVersion: 3,
        remoteVersion: 7,
      );
      final display = meta.remoteVersion != null
          ? 'v${meta.localVersion} → v${meta.remoteVersion}'
          : 'v${meta.localVersion}';
      expect(display, 'v3 → v7');
    });
  });

  // ── Time formatting ─────────────────────────────────────────────────────

  group('Time formatting logic', () {
    String formatTime(DateTime dt) {
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    test('just now for recent timestamps', () {
      expect(formatTime(DateTime.now()), 'just now');
    });

    test('minutes ago', () {
      final past = DateTime.now().subtract(const Duration(minutes: 15));
      expect(formatTime(past), '15m ago');
    });

    test('hours ago', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatTime(past), '3h ago');
    });

    test('days ago', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      expect(formatTime(past), '5d ago');
    });
  });

  // ── Stat card counts ──────────────────────────────────────────────────

  group('Stat card data', () {
    test('computes all counts from metadata list', () {
      final entities = [
        const EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n1',
          status: EntitySyncStatus.synced,
        ),
        const EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n2',
          status: EntitySyncStatus.synced,
        ),
        const EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n3',
          status: EntitySyncStatus.pending,
        ),
        const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p1',
          status: EntitySyncStatus.outdated,
        ),
        const EntitySyncMetadata(
          entityType: 'skill',
          entityId: 's1',
          status: EntitySyncStatus.conflict,
        ),
        const EntitySyncMetadata(
          entityType: 'doc',
          entityId: 'd1',
          status: EntitySyncStatus.neverSynced,
        ),
      ];

      final counts = <EntitySyncStatus, int>{};
      for (final e in entities) {
        counts[e.status] = (counts[e.status] ?? 0) + 1;
      }

      expect(counts[EntitySyncStatus.synced], 2);
      expect(counts[EntitySyncStatus.pending], 1);
      expect(counts[EntitySyncStatus.outdated], 1);
      expect(counts[EntitySyncStatus.conflict], 1);
      expect(counts[EntitySyncStatus.neverSynced], 1);
    });

    test('empty list produces zero counts', () {
      final entities = <EntitySyncMetadata>[];
      final synced = entities
          .where((e) => e.status == EntitySyncStatus.synced)
          .length;
      expect(synced, 0);
    });
  });

  // ── Entity type mapping ───────────────────────────────────────────────

  group('Entity type identification', () {
    test('all sync entity types are recognized', () {
      const types = ['project', 'note', 'skill', 'workflow', 'doc', 'agent'];
      for (final type in types) {
        expect(SyncEntityType.fromString(type), isNotNull);
      }
    });

    test('unknown type throws', () {
      expect(
        () => SyncEntityType.fromString('invalid_type'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── Metadata serialization ────────────────────────────────────────────

  group('EntitySyncMetadata serialization', () {
    test('fromJson round-trip preserves all fields', () {
      final metadata = EntitySyncMetadata(
        entityType: 'note',
        entityId: 'n1',
        status: EntitySyncStatus.pending,
        localVersion: 3,
        remoteVersion: 5,
        contentHash: 'abc123',
        lastSyncedBy: 'user-1',
        lastSyncedAt: DateTime.utc(2026, 3, 17, 12),
        sharedWithTeamIds: ['team-1', 'team-2'],
      );
      final json = metadata.toJson();
      final restored = EntitySyncMetadata.fromJson(json);
      expect(restored.entityType, 'note');
      expect(restored.entityId, 'n1');
      expect(restored.status, EntitySyncStatus.pending);
      expect(restored.localVersion, 3);
      expect(restored.remoteVersion, 5);
      expect(restored.contentHash, 'abc123');
      expect(restored.lastSyncedBy, 'user-1');
      expect(restored.sharedWithTeamIds, hasLength(2));
    });

    test('default values for missing fields', () {
      final json = <String, dynamic>{'entity_type': 'skill', 'entity_id': 's1'};
      final metadata = EntitySyncMetadata.fromJson(json);
      expect(metadata.status, EntitySyncStatus.neverSynced);
      expect(metadata.localVersion, 0);
      expect(metadata.remoteVersion, isNull);
      expect(metadata.lastSyncedAt, isNull);
      expect(metadata.sharedWithTeamIds, isEmpty);
    });
  });
}
