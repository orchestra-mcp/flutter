import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/devtools/providers/prompts_provider.dart';

void main() {
  // ── Prompt model ───────────────────────────────────────────────────────────

  group('Prompt model parsing', () {
    test('parses full prompt with all fields', () {
      final prompt = Prompt.fromJson({
        'id': 'pmt-1',
        'title': 'Database Setup',
        'prompt': 'Initialize the database connection and run migrations',
        'trigger': 'startup',
        'priority': 2,
        'enabled': true,
        'tags': ['db', 'setup'],
        'created_at': '2026-03-20T10:00:00Z',
        'updated_at': '2026-03-20T12:00:00Z',
      });
      expect(prompt.id, 'pmt-1');
      expect(prompt.title, 'Database Setup');
      expect(
        prompt.prompt,
        'Initialize the database connection and run migrations',
      );
      expect(prompt.trigger, 'startup');
      expect(prompt.priority, 2);
      expect(prompt.enabled, true);
      expect(prompt.tags, ['db', 'setup']);
      expect(prompt.createdAt, '2026-03-20T10:00:00Z');
      expect(prompt.updatedAt, '2026-03-20T12:00:00Z');
    });

    test('parses prompt with content field fallback', () {
      final prompt = Prompt.fromJson({
        'id': 'pmt-2',
        'title': 'Alt Content',
        'content': 'This uses content instead of prompt',
      });
      expect(prompt.prompt, 'This uses content instead of prompt');
    });

    test('uses defaults for missing fields', () {
      final prompt = Prompt.fromJson({});
      expect(prompt.id, '');
      expect(prompt.title, '');
      expect(prompt.prompt, '');
      expect(prompt.trigger, 'startup');
      expect(prompt.priority, 0);
      expect(prompt.enabled, true);
      expect(prompt.tags, isEmpty);
      expect(prompt.createdAt, isNull);
      expect(prompt.updatedAt, isNull);
    });

    test('handles null tags', () {
      final prompt = Prompt.fromJson({'id': 'pmt-3', 'tags': null});
      expect(prompt.tags, isEmpty);
    });

    test('parses all trigger types', () {
      for (final trigger in ['startup', 'manual', 'scheduled']) {
        final prompt = Prompt.fromJson({'trigger': trigger});
        expect(prompt.trigger, trigger);
      }
    });

    test('parses disabled prompt', () {
      final prompt = Prompt.fromJson({
        'id': 'pmt-4',
        'title': 'Disabled One',
        'enabled': false,
      });
      expect(prompt.enabled, false);
    });
  });

  // ── Filtering logic ────────────────────────────────────────────────────────

  group('Prompt list filtering', () {
    final prompts = [
      Prompt.fromJson({
        'id': 'p1',
        'title': 'Database Setup',
        'prompt': 'Connect to postgres',
        'trigger': 'startup',
        'tags': ['db', 'infra'],
      }),
      Prompt.fromJson({
        'id': 'p2',
        'title': 'Quick Deploy',
        'prompt': 'Deploy to staging',
        'trigger': 'manual',
        'tags': ['deploy', 'ci'],
      }),
      Prompt.fromJson({
        'id': 'p3',
        'title': 'Health Check',
        'prompt': 'Run health endpoints',
        'trigger': 'scheduled',
        'tags': ['health', 'monitoring'],
      }),
      Prompt.fromJson({
        'id': 'p4',
        'title': 'Code Review Prompt',
        'prompt': 'Review PR for best practices',
        'trigger': 'manual',
        'tags': ['review'],
      }),
    ];

    test('filter by title substring', () {
      final filtered = prompts
          .where((p) => p.title.toLowerCase().contains('deploy'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Quick Deploy');
    });

    test('filter by trigger type', () {
      final filtered = prompts.where((p) => p.trigger == 'manual').toList();
      expect(filtered.length, 2);
      expect(filtered.map((p) => p.title).toList(), [
        'Quick Deploy',
        'Code Review Prompt',
      ]);
    });

    test('filter by tag', () {
      final filtered = prompts.where((p) => p.tags.contains('infra')).toList();
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Database Setup');
    });

    test('combined trigger + search filter', () {
      final trigger = 'manual';
      final query = 'review';
      final filtered = prompts
          .where((p) => p.trigger == trigger)
          .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Code Review Prompt');
    });

    test('empty search returns all', () {
      const query = '';
      final filtered = prompts
          .where((p) => p.title.toLowerCase().contains(query))
          .toList();
      expect(filtered.length, prompts.length);
    });

    test('search matches prompt content', () {
      final filtered = prompts
          .where((p) => p.prompt.toLowerCase().contains('postgres'))
          .toList();
      expect(filtered.length, 1);
      expect(filtered[0].title, 'Database Setup');
    });
  });

  // ── Priority sorting ──────────────────────────────────────────────────────

  group('Prompt priority sorting', () {
    test('sorts by priority descending', () {
      final prompts = [
        Prompt.fromJson({'id': 'a', 'title': 'Low', 'priority': 0}),
        Prompt.fromJson({'id': 'b', 'title': 'High', 'priority': 5}),
        Prompt.fromJson({'id': 'c', 'title': 'Mid', 'priority': 2}),
      ];
      prompts.sort((a, b) => b.priority.compareTo(a.priority));
      expect(prompts.map((p) => p.title).toList(), ['High', 'Mid', 'Low']);
    });

    test('same priority preserves order', () {
      final prompts = [
        Prompt.fromJson({'id': 'a', 'title': 'First', 'priority': 1}),
        Prompt.fromJson({'id': 'b', 'title': 'Second', 'priority': 1}),
      ];
      prompts.sort((a, b) => b.priority.compareTo(a.priority));
      expect(prompts.map((p) => p.title).toList(), ['First', 'Second']);
    });
  });
}
