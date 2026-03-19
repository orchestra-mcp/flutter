# Sync Engine

Drift-backed push/pull sync with exponential backoff and conflict resolution via upsert.

## Usage

```dart
// Inject via Riverpod
final engine = ref.read(syncEngineProvider);

// Enqueue a local mutation (called after any local DB write)
await engine.enqueue(
  entityType: 'feature',
  entityId: 'f-123',
  operation: 'update',
  payload: {'status': 'done'},
);

// Full sync (pull from server, then push local queue)
await engine.sync();

// Pull only (e.g. on app foreground)
await engine.pull(since: '2025-01-01T00:00:00Z');

// Push only (e.g. on connectivity restored)
await engine.push();

// Check status
print(engine.status); // SyncStatus.idle | syncing | error
```

## Architecture

```
SyncEngine
  ├── push()  → drains sync_queue → POST /api/sync/push → deletes on ack
  ├── pull()  → GET /api/sync/pull → upsertOnConflict features/projects/notes
  └── sync()  → pull() then push()
```

## Push Flow

1. Read all rows from `sync_queue` table
2. For each entry:
   - Skip if `nextRetryAt` is in the future (backoff window)
   - Call `ApiClient.pushSync()` with `{entity_type, entity_id, operation, payload}`
   - On success: delete the row from queue
   - On failure: increment `attempts`, set `nextRetryAt = now + 30s × attempts`

## Pull Flow

1. Call `ApiClient.pullSync(since: ...)` → returns `{features, projects, notes}`
2. For each entity list, call `insertOnConflictUpdate` (last-write-wins)
3. Marks all pulled rows with `synced = true`

## Exponential Backoff

| Attempts | Retry delay |
|----------|-------------|
| 1 | 30s |
| 2 | 60s |
| 3 | 90s |
| N | N × 30s |

## Providers

```dart
final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    db: ref.watch(databaseProvider),
    client: ref.watch(apiClientProvider),
  );
});
```

## Conflict Resolution

Uses last-write-wins via Drift's `insertOnConflictUpdate`. The server is the source of truth on pull; local mutations are queued and pushed after.
