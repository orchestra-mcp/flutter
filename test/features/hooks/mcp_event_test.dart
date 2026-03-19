import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/ws/ws_event.dart';

void main() {
  group('MCP WsEvent parsing', () {
    test('parses mcp tool_called event', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'tool_called',
        'tool_name': 'Read',
        'entity_type': 'tool',
        'session_id': 'sess-123',
        'timestamp': 1710000000,
      });
      expect(e, isA<McpToolCalledEvent>());
      final mcp = e as McpToolCalledEvent;
      expect(mcp.toolName, 'Read');
      expect(mcp.entityType, 'tool');
      expect(mcp.sessionId, 'sess-123');
      expect(mcp.timestamp, 1710000000);
    });

    test('parses mcp agent_spawned event', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'agent_spawned',
        'agent_type': 'general-purpose',
        'session_id': 'sess-456',
        'timestamp': 1710000001,
      });
      expect(e, isA<McpAgentSpawnedEvent>());
      final mcp = e as McpAgentSpawnedEvent;
      expect(mcp.agentType, 'general-purpose');
      expect(mcp.sessionId, 'sess-456');
    });

    test('parses mcp notification event', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'notification',
        'entity_type': 'notification',
        'entity_id': 'n-789',
        'session_id': 'sess-789',
        'timestamp': 1710000002,
      });
      expect(e, isA<McpNotificationEvent>());
      final mcp = e as McpNotificationEvent;
      expect(mcp.entityType, 'notification');
      expect(mcp.entityId, 'n-789');
    });

    test('parses unknown mcp action as McpGenericEvent', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'some_future_action',
        'session_id': 'sess-000',
        'timestamp': 1710000003,
      });
      expect(e, isA<McpGenericEvent>());
      final mcp = e as McpGenericEvent;
      expect(mcp.action, 'some_future_action');
    });

    test('McpEvent is a WsEvent', () {
      final e = WsEvent.fromJson({
        'type': 'mcp',
        'action': 'tool_called',
        'tool_name': 'Write',
        'session_id': '',
        'timestamp': 0,
      });
      expect(e, isA<WsEvent>());
      expect(e, isA<McpEvent>());
    });

    test('handles missing mcp fields gracefully', () {
      final e = WsEvent.fromJson({'type': 'mcp', 'action': 'tool_called'});
      expect(e, isA<McpToolCalledEvent>());
      final mcp = e as McpToolCalledEvent;
      expect(mcp.toolName, '');
      expect(mcp.sessionId, '');
      expect(mcp.timestamp, 0);
    });
  });
}
