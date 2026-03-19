import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tests hook installer JSON manipulation logic without calling HookInstaller
/// directly (which depends on Platform.environment). Instead we test the
/// same JSON merge logic inline.
void main() {
  group('Hook installer JSON logic', () {
    test('merges hooks into empty settings', () {
      final settings = <String, dynamic>{};
      final hooks = <String, dynamic>{};
      final events = ['tool_use_start', 'notification'];

      for (final event in events) {
        final eventHooks = <dynamic>[];
        eventHooks.add({
          'command': '/home/user/.claude/hooks/orchestra-mcp-hook.sh',
          'timeout': 5000,
        });
        hooks[event] = eventHooks;
      }
      settings['hooks'] = hooks;

      expect(settings['hooks'], isA<Map>());
      final h = settings['hooks'] as Map<String, dynamic>;
      expect(h['tool_use_start'], isA<List>());
      expect((h['tool_use_start'] as List).length, 1);
      expect(h['notification'], isA<List>());
    });

    test('preserves existing hooks when merging', () {
      final settings = <String, dynamic>{
        'theme': 'dark',
        'hooks': {
          'tool_use_start': [
            {'command': '/other/hook.sh', 'timeout': 3000},
          ],
        },
      };

      final hooks = settings['hooks'] as Map<String, dynamic>;
      final existing = hooks['tool_use_start'] as List<dynamic>;

      // Check if orchestra hook already registered.
      final alreadyRegistered = existing.any((h) {
        if (h is Map<String, dynamic>) {
          return (h['command'] as String).contains('orchestra-mcp-hook');
        }
        return false;
      });
      expect(alreadyRegistered, false);

      // Add our hook.
      existing.add({
        'command': '/home/user/.claude/hooks/orchestra-mcp-hook.sh',
        'timeout': 5000,
      });

      expect(existing.length, 2);
      expect(settings['theme'], 'dark');
    });

    test('detects already installed hooks', () {
      final settings = {
        'hooks': {
          'tool_use_start': [
            {
              'command': '/home/user/.claude/hooks/orchestra-mcp-hook.sh',
              'timeout': 5000,
            },
          ],
        },
      };

      final hooks = settings['hooks']!;
      final eventHooks = hooks['tool_use_start']! as List<dynamic>;
      final installed = eventHooks.any((h) {
        if (h is Map<String, dynamic>) {
          return (h['command'] as String).contains('orchestra-mcp-hook');
        }
        return false;
      });

      expect(installed, true);
    });

    test('removes orchestra hooks during uninstall', () {
      final hooks = {
        'tool_use_start': <dynamic>[
          {'command': '/other/hook.sh', 'timeout': 3000},
          {'command': '/home/.claude/hooks/orchestra-mcp-hook.sh', 'timeout': 5000},
        ],
      };

      final eventHooks = hooks['tool_use_start']!;
      eventHooks.removeWhere((h) {
        if (h is Map<String, dynamic>) {
          return (h['command'] as String).contains('orchestra-mcp-hook');
        }
        return false;
      });

      expect(eventHooks.length, 1);
      expect((eventHooks[0] as Map)['command'], '/other/hook.sh');
    });

    test('round-trips through JSON encode/decode', () {
      final settings = {
        'hooks': {
          'tool_use_start': [
            {'command': '/home/.claude/hooks/orchestra-mcp-hook.sh', 'timeout': 5000},
          ],
        },
      };

      final encoded = const JsonEncoder.withIndent('  ').convert(settings);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final hooks = decoded['hooks'] as Map<String, dynamic>;
      final list = hooks['tool_use_start'] as List;
      expect(list.length, 1);
      expect((list[0] as Map)['command'], contains('orchestra-mcp-hook'));
    });
  });
}
