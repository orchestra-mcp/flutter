# WebSocket Manager

Real-time event stream with exponential backoff reconnect.

## Usage

```dart
// Riverpod
final ws = ref.read(wsManagerProvider);
await ws.connect();

// Listen to events
ws.eventStream.listen((event) {
  switch (event) {
    case FeatureUpdatedEvent(:final featureId): handleUpdate(featureId);
    case SyncAckEvent(:final queueId): markSynced(queueId);
    case PingEvent(): break; // handled internally
    default: break;
  }
});

// Listen to connection state
ws.stateStream.listen((state) => print(state));

// Send a message
ws.send({'type': 'subscribe', 'channel': 'project.abc'});
```

## Event Types

| Type | Class | Key fields |
|------|-------|------------|
| `feature.updated` | `FeatureUpdatedEvent` | `featureId`, `payload` |
| `note.created` | `NoteCreatedEvent` | `noteId`, `payload` |
| `sync.ack` | `SyncAckEvent` | `queueId` |
| `ping` | `PingEvent` | — |
| anything else | `UnknownWsEvent` | `type`, `data` |

## Reconnect

Exponential backoff: 1s, 2s, 4s, 8s … capped at 30s. Stops after 10 retries (`_maxRetries`). Reconnect resets on successful connect.

## States

`disconnected → connecting → connected → reconnecting → …`
