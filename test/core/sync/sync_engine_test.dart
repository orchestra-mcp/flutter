import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/api/api_client.dart';
import 'package:orchestra/core/db/app_database.dart';
import 'package:orchestra/core/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient implements ApiClient {
  final List<Map<String, dynamic>> pushCalls = [];
  Map<String, dynamic> pullResult = {
    'features': <Map<String, dynamic>>[],
    'projects': <Map<String, dynamic>>[],
    'notes': <Map<String, dynamic>>[],
  };
  bool throwOnPush = false;

  @override
  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> payload) async {
    if (throwOnPush) throw Exception('network error');
    pushCalls.add(payload);
    return {};
  }

  @override
  Future<Map<String, dynamic>> pullSync({String? since}) async => pullResult;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _FakeApiClient fakeClient;
  late SyncEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeClient = _FakeApiClient();
    engine = SyncEngine(db: db, client: fakeClient);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine.enqueue', () {
    test('inserts a row into sync_queue', () async {
      await engine.enqueue(
        entityType: 'feature',
        entityId: 'f-1',
        operation: 'update',
        payload: {'status': 'done'},
      );
      final rows = await db.select(db.syncQueueTable).get();
      expect(rows.length, 1);
      expect(rows.first.entityType, 'feature');
      expect(rows.first.entityId, 'f-1');
      expect(rows.first.operation, 'update');
      expect(jsonDecode(rows.first.payload)['status'], 'done');
    });

    test('inserts multiple entries independently', () async {
      await engine.enqueue(
          entityType: 'note', entityId: 'n-1', operation: 'create', payload: {});
      await engine.enqueue(
          entityType: 'note', entityId: 'n-2', operation: 'create', payload: {});
      final rows = await db.select(db.syncQueueTable).get();
      expect(rows.length, 2);
    });
  });

  group('SyncEngine.push', () {
    test('pushes queued entries and removes them on success', () async {
      await engine.enqueue(
        entityType: 'feature',
        entityId: 'f-1',
        operation: 'update',
        payload: {'status': 'done'},
      );
      await engine.push();

      expect(fakeClient.pushCalls.length, 1);
      expect(fakeClient.pushCalls.first['entity_id'], 'f-1');
      final rows = await db.select(db.syncQueueTable).get();
      expect(rows, isEmpty);
    });

    test('does nothing when queue is empty', () async {
      await engine.push();
      expect(fakeClient.pushCalls, isEmpty);
    });

    test('increments attempts and schedules retry on failure', () async {
      fakeClient.throwOnPush = true;
      await engine.enqueue(
          entityType: 'feature',
          entityId: 'f-err',
          operation: 'delete',
          payload: {});
      await engine.push();

      final rows = await db.select(db.syncQueueTable).get();
      expect(rows.length, 1);
      expect(rows.first.attempts, 1);
      expect(rows.first.nextRetryAt, isNotNull);
    });

    test('skips entries whose nextRetryAt is in the future', () async {
      await engine.enqueue(
          entityType: 'feature',
          entityId: 'f-skip',
          operation: 'create',
          payload: {});
      await (db.update(db.syncQueueTable)).write(SyncQueueTableCompanion(
        nextRetryAt: Value(DateTime.now().add(const Duration(hours: 1))),
        attempts: const Value(1),
      ));
      await engine.push();
      expect(fakeClient.pushCalls, isEmpty);
    });

    test('status returns to idle after push', () async {
      await engine.push();
      expect(engine.status, SyncStatus.idle);
    });
  });

  group('SyncEngine.pull', () {
    test('upserts features from server response', () async {
      fakeClient.pullResult = {
        'features': <Map<String, dynamic>>[
          {
            'id': 'f-server-1',
            'project_id': 'p-1',
            'title': 'Server feature',
            'status': 'in-progress',
            'kind': 'feature',
            'priority': 'P1',
            'labels': '[]',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
          }
        ],
        'projects': <Map<String, dynamic>>[],
        'notes': <Map<String, dynamic>>[],
      };
      await engine.pull();
      final rows = await db.select(db.featuresTable).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'f-server-1');
      expect(rows.first.title, 'Server feature');
      expect(rows.first.synced, true);
    });

    test('upserts projects from server response', () async {
      fakeClient.pullResult = {
        'features': <Map<String, dynamic>>[],
        'projects': <Map<String, dynamic>>[
          {
            'id': 'p-1',
            'slug': 'my-project',
            'name': 'My Project',
            'stacks': '["go"]',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
          }
        ],
        'notes': <Map<String, dynamic>>[],
      };
      await engine.pull();
      final rows = await db.select(db.projectsTable).get();
      expect(rows.length, 1);
      expect(rows.first.slug, 'my-project');
      expect(rows.first.synced, true);
    });

    test('upserts notes from server response', () async {
      fakeClient.pullResult = {
        'features': <Map<String, dynamic>>[],
        'projects': <Map<String, dynamic>>[],
        'notes': <Map<String, dynamic>>[
          {
            'id': 'n-1',
            'title': 'My Note',
            'content': 'Hello world',
            'is_pinned': true,
            'tags': '[]',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
          }
        ],
      };
      await engine.pull();
      final rows = await db.select(db.notesTable).get();
      expect(rows.length, 1);
      expect(rows.first.title, 'My Note');
      expect(rows.first.pinned, true);
    });

    test('handles empty response gracefully', () async {
      await engine.pull();
      expect(engine.status, SyncStatus.idle);
    });
  });

  group('SyncEngine.sync', () {
    test('pulls then pushes', () async {
      await engine.enqueue(
          entityType: 'note',
          entityId: 'n-local',
          operation: 'create',
          payload: {'title': 'hi'});
      await engine.sync();
      expect(fakeClient.pushCalls.length, 1);
    });
  });
}
