import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/sync_conflict_models.dart';
import 'package:orchestra/core/sync/sync_conflict_resolver.dart';

void main() {
  // ── ConflictResolution enum ─────────────────────────────────────────────

  group('ConflictResolution', () {
    test('fromString parses all values', () {
      expect(
        ConflictResolution.fromString('keep_local'),
        ConflictResolution.keepLocal,
      );
      expect(
        ConflictResolution.fromString('keep_remote'),
        ConflictResolution.keepRemote,
      );
      expect(ConflictResolution.fromString('merge'), ConflictResolution.merge);
    });

    test('toJson round-trips', () {
      for (final v in ConflictResolution.values) {
        expect(ConflictResolution.fromString(v.toJson()), v);
      }
    });

    test('fromString throws on unknown', () {
      expect(
        () => ConflictResolution.fromString('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // ── FieldDiff ───────────────────────────────────────────────────────────

  group('FieldDiff', () {
    test('hasConflict when values differ', () {
      const diff = FieldDiff(
        field: 'title',
        localValue: 'Local Title',
        remoteValue: 'Remote Title',
      );
      expect(diff.hasConflict, true);
    });

    test('no conflict when values match', () {
      const diff = FieldDiff(
        field: 'title',
        localValue: 'Same',
        remoteValue: 'Same',
      );
      expect(diff.hasConflict, false);
    });

    test('null vs value is a conflict', () {
      const diff = FieldDiff(
        field: 'description',
        localValue: null,
        remoteValue: 'Added remotely',
      );
      expect(diff.hasConflict, true);
    });

    test('isTextContent flag', () {
      const textDiff = FieldDiff(
        field: 'content',
        localValue: 'a',
        remoteValue: 'b',
        isTextContent: true,
      );
      expect(textDiff.isTextContent, true);

      const nonTextDiff = FieldDiff(
        field: 'mode',
        localValue: 'active',
        remoteValue: 'archived',
      );
      expect(nonTextDiff.isTextContent, false);
    });

    test('fromJson round-trip', () {
      const original = FieldDiff(
        field: 'content',
        localValue: 'local text',
        remoteValue: 'remote text',
        isTextContent: true,
      );
      final json = original.toJson();
      final restored = FieldDiff.fromJson(json);
      expect(restored.field, 'content');
      expect(restored.localValue, 'local text');
      expect(restored.remoteValue, 'remote text');
      expect(restored.isTextContent, true);
    });
  });

  // ── SyncConflict ────────────────────────────────────────────────────────

  group('SyncConflict', () {
    final conflict = SyncConflict(
      entityType: 'note',
      entityId: 'n1',
      entityTitle: 'Meeting Notes',
      localVersion: 2,
      remoteVersion: 4,
      localData: {'title': 'Local Title', 'content': 'Local body'},
      remoteData: {'title': 'Remote Title', 'content': 'Remote body'},
      diffs: const [
        FieldDiff(
          field: 'title',
          localValue: 'Local Title',
          remoteValue: 'Remote Title',
        ),
        FieldDiff(
          field: 'content',
          localValue: 'Local body',
          remoteValue: 'Remote body',
          isTextContent: true,
        ),
      ],
      detectedAt: DateTime.utc(2026, 3, 17, 12),
    );

    test('isOpen when unresolved', () {
      expect(conflict.isOpen, true);
    });

    test('conflictingFieldCount', () {
      expect(conflict.conflictingFieldCount, 2);
    });

    test('hasTextConflicts', () {
      expect(conflict.hasTextConflicts, true);
    });

    test('no text conflicts when only non-text fields differ', () {
      final nonTextConflict = SyncConflict(
        entityType: 'project',
        entityId: 'p1',
        entityTitle: 'Orchestra',
        localVersion: 1,
        remoteVersion: 2,
        localData: {'mode': 'active'},
        remoteData: {'mode': 'archived'},
        diffs: const [
          FieldDiff(
            field: 'mode',
            localValue: 'active',
            remoteValue: 'archived',
          ),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      expect(nonTextConflict.hasTextConflicts, false);
    });

    test('copyWith resolution', () {
      final resolved = conflict.copyWith(
        resolution: ConflictResolution.keepLocal,
        resolvedAt: DateTime.utc(2026, 3, 17, 13),
        resolvedData: {'title': 'Local Title', 'content': 'Local body'},
      );
      expect(resolved.isOpen, false);
      expect(resolved.resolution, ConflictResolution.keepLocal);
      expect(resolved.resolvedData!['title'], 'Local Title');
    });

    test('fromJson round-trip', () {
      final json = conflict.toJson();
      final restored = SyncConflict.fromJson(json);
      expect(restored.entityType, 'note');
      expect(restored.entityId, 'n1');
      expect(restored.localVersion, 2);
      expect(restored.remoteVersion, 4);
      expect(restored.diffs, hasLength(2));
      expect(restored.isOpen, true);
    });

    test('fromJson with resolution', () {
      final resolved = conflict.copyWith(
        resolution: ConflictResolution.merge,
        resolvedAt: DateTime.utc(2026, 3, 17, 14),
        resolvedData: {'title': 'Merged', 'content': 'Merged body'},
      );
      final json = resolved.toJson();
      final restored = SyncConflict.fromJson(json);
      expect(restored.isOpen, false);
      expect(restored.resolution, ConflictResolution.merge);
      expect(restored.resolvedData!['title'], 'Merged');
    });
  });

  // ── computeFieldDiffs ───────────────────────────────────────────────────

  group('computeFieldDiffs', () {
    test('detects differing fields', () {
      final diffs = computeFieldDiffs(
        {'title': 'A', 'mode': 'active'},
        {'title': 'B', 'mode': 'active'},
      );
      expect(diffs, hasLength(1));
      expect(diffs.first.field, 'title');
    });

    test('detects fields only in local', () {
      final diffs = computeFieldDiffs(
        {'title': 'A', 'extra': 'local only'},
        {'title': 'A'},
      );
      expect(diffs, hasLength(1));
      expect(diffs.first.field, 'extra');
      expect(diffs.first.remoteValue, isNull);
    });

    test('detects fields only in remote', () {
      final diffs = computeFieldDiffs(
        {'title': 'A'},
        {'title': 'A', 'new_field': 'remote only'},
      );
      expect(diffs, hasLength(1));
      expect(diffs.first.field, 'new_field');
      expect(diffs.first.localValue, isNull);
    });

    test('marks text fields as isTextContent', () {
      final diffs = computeFieldDiffs(
        {'content': 'Local', 'description': 'Local desc'},
        {'content': 'Remote', 'description': 'Remote desc'},
      );
      expect(diffs, hasLength(2));
      expect(diffs.every((d) => d.isTextContent), true);
    });

    test('empty maps produce no diffs', () {
      final diffs = computeFieldDiffs({}, {});
      expect(diffs, isEmpty);
    });

    test('identical maps produce no diffs', () {
      final diffs = computeFieldDiffs(
        {'title': 'Same', 'mode': 'active'},
        {'title': 'Same', 'mode': 'active'},
      );
      expect(diffs, isEmpty);
    });
  });

  // ── detectConflict ──────────────────────────────────────────────────────

  group('detectConflict', () {
    test('returns null when remote version <= local', () {
      final result = detectConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Test',
        localVersion: 3,
        remoteVersion: 3,
        localData: {'title': 'A'},
        remoteData: {'title': 'B'},
      );
      expect(result, isNull);
    });

    test('returns null when hashes match', () {
      final result = detectConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Test',
        localVersion: 2,
        remoteVersion: 3,
        localData: {'title': 'Same'},
        remoteData: {'title': 'Same'},
        localHash: 'abc123',
        remoteHash: 'abc123',
      );
      expect(result, isNull);
    });

    test('returns null when data is identical', () {
      final result = detectConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Test',
        localVersion: 2,
        remoteVersion: 3,
        localData: {'title': 'Same'},
        remoteData: {'title': 'Same'},
      );
      expect(result, isNull);
    });

    test('returns conflict when versions diverge and data differs', () {
      final result = detectConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Meeting Notes',
        localVersion: 2,
        remoteVersion: 4,
        localData: {'title': 'Local', 'content': 'Local body'},
        remoteData: {'title': 'Remote', 'content': 'Remote body'},
      );
      expect(result, isNotNull);
      expect(result!.entityType, 'note');
      expect(result.localVersion, 2);
      expect(result.remoteVersion, 4);
      expect(result.diffs, hasLength(2));
      expect(result.isOpen, true);
    });
  });

  // ── Resolution strategies ───────────────────────────────────────────────

  group('Resolution strategies', () {
    final conflict = SyncConflict(
      entityType: 'note',
      entityId: 'n1',
      entityTitle: 'Test',
      localVersion: 2,
      remoteVersion: 4,
      localData: {'title': 'Local', 'content': 'Local body'},
      remoteData: {'title': 'Remote', 'content': 'Remote body'},
      diffs: const [
        FieldDiff(field: 'title', localValue: 'Local', remoteValue: 'Remote'),
        FieldDiff(
          field: 'content',
          localValue: 'Local body',
          remoteValue: 'Remote body',
          isTextContent: true,
        ),
      ],
      detectedAt: DateTime.utc(2026, 3, 17),
    );

    test('resolveKeepLocal keeps local data', () {
      final resolved = resolveKeepLocal(conflict);
      expect(resolved.isOpen, false);
      expect(resolved.resolution, ConflictResolution.keepLocal);
      expect(resolved.resolvedData!['title'], 'Local');
      expect(resolved.resolvedData!['content'], 'Local body');
    });

    test('resolveKeepRemote keeps remote data', () {
      final resolved = resolveKeepRemote(conflict);
      expect(resolved.isOpen, false);
      expect(resolved.resolution, ConflictResolution.keepRemote);
      expect(resolved.resolvedData!['title'], 'Remote');
      expect(resolved.resolvedData!['content'], 'Remote body');
    });

    test('resolveMerge applies field choices', () {
      final resolved = resolveMerge(conflict, {
        'title': true, // keep local title
        'content': false, // keep remote content
      });
      expect(resolved.isOpen, false);
      expect(resolved.resolution, ConflictResolution.merge);
      expect(resolved.resolvedData!['title'], 'Local');
      expect(resolved.resolvedData!['content'], 'Remote body');
    });

    test('resolveMerge defaults to remote for unspecified fields', () {
      final resolved = resolveMerge(conflict, {});
      expect(resolved.resolvedData!['title'], 'Remote');
      expect(resolved.resolvedData!['content'], 'Remote body');
    });
  });

  // ── autoResolve ─────────────────────────────────────────────────────────

  group('autoResolve', () {
    test('returns null when text fields have conflicts', () {
      final conflict = SyncConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Test',
        localVersion: 1,
        remoteVersion: 2,
        localData: {'content': 'local'},
        remoteData: {'content': 'remote'},
        diffs: const [
          FieldDiff(
            field: 'content',
            localValue: 'local',
            remoteValue: 'remote',
            isTextContent: true,
          ),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      expect(autoResolve(conflict), isNull);
    });

    test('auto-resolves non-text conflicts with keep-remote', () {
      final conflict = SyncConflict(
        entityType: 'project',
        entityId: 'p1',
        entityTitle: 'Test',
        localVersion: 1,
        remoteVersion: 2,
        localData: {'mode': 'active'},
        remoteData: {'mode': 'archived'},
        diffs: const [
          FieldDiff(
            field: 'mode',
            localValue: 'active',
            remoteValue: 'archived',
          ),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      final resolved = autoResolve(conflict);
      expect(resolved, isNotNull);
      expect(resolved!.resolution, ConflictResolution.keepRemote);
      expect(resolved.resolvedData!['mode'], 'archived');
    });
  });

  // ── SyncConflictNotifier ────────────────────────────────────────────────

  group('SyncConflictNotifier', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(syncConflictsProvider), isEmpty);
    });

    test('addConflict stores conflict', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final conflict = SyncConflict(
        entityType: 'note',
        entityId: 'n1',
        entityTitle: 'Test',
        localVersion: 1,
        remoteVersion: 2,
        localData: {'title': 'A'},
        remoteData: {'title': 'B'},
        diffs: const [
          FieldDiff(field: 'title', localValue: 'A', remoteValue: 'B'),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      container.read(syncConflictsProvider.notifier).addConflict(conflict);
      final state = container.read(syncConflictsProvider);
      expect(state, hasLength(1));
      expect(state['note:n1'], isNotNull);
    });

    test('resolveConflict removes from map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final conflict = SyncConflict(
        entityType: 'skill',
        entityId: 's1',
        entityTitle: 'Deploy',
        localVersion: 1,
        remoteVersion: 3,
        localData: {'name': 'old'},
        remoteData: {'name': 'new'},
        diffs: const [
          FieldDiff(field: 'name', localValue: 'old', remoteValue: 'new'),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      container.read(syncConflictsProvider.notifier).addConflict(conflict);
      expect(container.read(syncConflictsProvider), hasLength(1));

      final resolved = resolveKeepRemote(conflict);
      container
          .read(syncConflictsProvider.notifier)
          .resolveConflict('skill', 's1', resolved);
      expect(container.read(syncConflictsProvider), isEmpty);
    });

    test('getConflict returns correct conflict', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final conflict = SyncConflict(
        entityType: 'doc',
        entityId: 'd1',
        entityTitle: 'API',
        localVersion: 5,
        remoteVersion: 7,
        localData: {'path': 'old.md'},
        remoteData: {'path': 'new.md'},
        diffs: const [
          FieldDiff(field: 'path', localValue: 'old.md', remoteValue: 'new.md'),
        ],
        detectedAt: DateTime.utc(2026, 3, 17),
      );
      container.read(syncConflictsProvider.notifier).addConflict(conflict);
      final found = container
          .read(syncConflictsProvider.notifier)
          .getConflict('doc', 'd1');
      expect(found, isNotNull);
      expect(found!.entityTitle, 'API');
    });

    test('getConflict returns null for unknown entity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final found = container
          .read(syncConflictsProvider.notifier)
          .getConflict('note', 'unknown');
      expect(found, isNull);
    });

    test('clear removes all conflicts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(syncConflictsProvider.notifier);
      for (var i = 0; i < 3; i++) {
        notifier.addConflict(
          SyncConflict(
            entityType: 'note',
            entityId: 'n$i',
            entityTitle: 'Note $i',
            localVersion: 1,
            remoteVersion: 2,
            localData: {'title': 'Local $i'},
            remoteData: {'title': 'Remote $i'},
            diffs: [
              FieldDiff(
                field: 'title',
                localValue: 'Local $i',
                remoteValue: 'Remote $i',
              ),
            ],
            detectedAt: DateTime.utc(2026, 3, 17),
          ),
        );
      }
      expect(container.read(syncConflictsProvider), hasLength(3));
      notifier.clear();
      expect(container.read(syncConflictsProvider), isEmpty);
    });
  });
}
