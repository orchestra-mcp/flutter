import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/ws/ws_event.dart';

/// Tests for MCP notification event parsing used by AgentNotificationService.
/// The service itself depends on flutter_local_notifications plugin internals
/// which require platform channel mocking, so we test the event parsing layer.
void main() {
  group('McpNotificationEvent parsing', () {
    test('parses delegation notification', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'delegation',
        'entity_id': 'del-123',
        'session_id': 'sess-abc',
        'timestamp': 1710000000,
      });
      expect(e, isA<McpNotificationEvent>());
      final n = e as McpNotificationEvent;
      expect(n.entityType, 'delegation');
      expect(n.entityId, 'del-123');
    });

    test('parses permission notification', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'permission',
        'entity_id': 'perm-456',
        'session_id': 'sess-def',
        'timestamp': 1710000001,
      });
      expect(e, isA<McpNotificationEvent>());
      final n = e as McpNotificationEvent;
      expect(n.entityType, 'permission');
    });

    test('parses review notification', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'review',
        'entity_id': 'rev-789',
        'session_id': 'sess-ghi',
        'timestamp': 1710000002,
      });
      expect(e, isA<McpNotificationEvent>());
      final n = e as McpNotificationEvent;
      expect(n.entityType, 'review');
    });

    test('agent_spawned event parsed for verbose notifications', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'agent_spawned',
        'agent_type': 'devops',
        'session_id': 'sess-jkl',
        'timestamp': 1710000003,
      });
      expect(e, isA<McpAgentSpawnedEvent>());
      final a = e as McpAgentSpawnedEvent;
      expect(a.agentType, 'devops');
    });

    test('tool_called events are NOT notifications', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'tool_called',
        'tool_name': 'Read',
        'session_id': 'sess-mno',
        'timestamp': 1710000004,
      });
      expect(e, isNot(isA<McpNotificationEvent>()));
      expect(e, isA<McpToolCalledEvent>());
    });
  });
}
