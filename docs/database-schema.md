# Database Schema (Drift)

12 SQLite tables via Drift ORM. Schema version 1. In-memory variant available via `AppDatabase.forTesting(NativeDatabase.memory())`.

## Tables

| Table | Primary Key | Notable Columns |
|-------|------------|-----------------|
| `users_table` | `id` (TEXT) | email, displayName, timezone (UTC default), role (member default) |
| `features_table` | `id` (TEXT) | title, status, labels (JSON), synced (bool) |
| `projects_table` | `id` (TEXT) | name, slug, stacks (JSON), synced (bool) |
| `notes_table` | `id` (TEXT) | title, content, tags (JSON), projectId (nullable FK) |
| `health_logs_table` | `id` (TEXT) | type, value (REAL), unit, metadata (JSON) |
| `notifications_table` | `id` (TEXT) | title, body, data (JSON), read (bool) |
| `sessions_table` | `id` (TEXT) | name, status, endedAt (nullable), metadata (JSON) |
| `sync_queue_table` | `id` (INTEGER autoincrement) | entityType, entityId, operation, payload (JSON), attempts, nextRetryAt |
| `agents_table` | `id` (TEXT) | name, provider, model, tools (JSON), systemPrompt (nullable) |
| `workflows_table` | `id` (TEXT) | name, steps (JSON), status (draft default) |
| `settings_table` | `key` (TEXT) | value, updatedAt |
| `delegations_table` | `id` (TEXT) | fromUserId, toUserId, featureId (nullable), status |

## Usage

```dart
// Riverpod provider
final db = ref.read(databaseProvider);

// Insert a setting
await db.into(db.settingsTable).insert(
  SettingsTableCompanion.insert(key: 'theme', value: 'dracula', updatedAt: DateTime.now()),
);

// Query
final row = await (db.select(db.settingsTable)
  ..where((t) => t.key.equals('theme'))).getSingle();
```

## Sync Queue

The `sync_queue_table` drives offline-first sync. Every local mutation enqueues a record with `operation` (create/update/delete) and `payload` (JSON). The sync engine processes the queue when connectivity is restored, retrying up to a configurable limit with exponential back-off via `nextRetryAt`.

## Codegen

Run after any table change:

```sh
dart run build_runner build --delete-conflicting-outputs
```
