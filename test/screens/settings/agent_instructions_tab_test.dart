import 'package:flutter_test/flutter_test.dart';

// Tests for the pure logic in AgentInstructionsTab:
// _parseSections and _reconstructMarkdown are private, so we replicate
// the same logic here and test it in isolation.

// ── Replicated pure helpers (mirrors agent_instructions_tab.dart) ──────────

class Section {
  Section({required this.header, required this.body});
  String header;
  String body;
}

List<Section> parseSections(String content) {
  final sections = <Section>[];
  final lines = content.split('\n');
  String currentHeader = '';
  final bodyLines = <String>[];

  for (final line in lines) {
    if (line.startsWith('## ')) {
      if (currentHeader.isNotEmpty || bodyLines.isNotEmpty) {
        sections.add(
          Section(
            header: currentHeader.isEmpty ? 'Introduction' : currentHeader,
            body: bodyLines.join('\n').trim(),
          ),
        );
      }
      currentHeader = line.substring(3).trim();
      bodyLines.clear();
    } else {
      bodyLines.add(line);
    }
  }

  if (currentHeader.isNotEmpty || bodyLines.isNotEmpty) {
    sections.add(
      Section(
        header: currentHeader.isEmpty ? 'Introduction' : currentHeader,
        body: bodyLines.join('\n').trim(),
      ),
    );
  }

  return sections;
}

String reconstructMarkdown(List<Section> sections) {
  final buffer = StringBuffer();
  for (int i = 0; i < sections.length; i++) {
    final s = sections[i];
    if (i == 0 && s.header == 'Introduction') {
      buffer.writeln(s.body);
    } else {
      buffer.writeln('## ${s.header}');
      buffer.writeln();
      buffer.writeln(s.body);
    }
    buffer.writeln();
  }
  return buffer.toString().trimRight();
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('parseSections', () {
    test('empty input produces one Introduction section with empty body', () {
      final sections = parseSections('');
      expect(sections.length, 1);
      expect(sections[0].header, 'Introduction');
      expect(sections[0].body, '');
    });

    test('whitespace-only input produces one Introduction section', () {
      final sections = parseSections('   \n  ');
      expect(sections.length, 1);
      expect(sections[0].header, 'Introduction');
    });

    test('parses a single section with header', () {
      const md = '## Overview\nSome content here.';
      final sections = parseSections(md);
      expect(sections.length, 1);
      expect(sections[0].header, 'Overview');
      expect(sections[0].body, 'Some content here.');
    });

    test('parses multiple sections', () {
      const md = '''
## First
Content A.

## Second
Content B.
''';
      final sections = parseSections(md);
      expect(sections.length, 2);
      expect(sections[0].header, 'First');
      expect(sections[0].body, 'Content A.');
      expect(sections[1].header, 'Second');
      expect(sections[1].body, 'Content B.');
    });

    test('intro text before first ## becomes Introduction section', () {
      const md = 'Preamble text.\n\n## Rules\nDo stuff.';
      final sections = parseSections(md);
      expect(sections.length, 2);
      expect(sections[0].header, 'Introduction');
      expect(sections[0].body, 'Preamble text.');
      expect(sections[1].header, 'Rules');
    });

    test('preserves multiline body content', () {
      const md = '## Section\nLine 1\nLine 2\nLine 3';
      final sections = parseSections(md);
      expect(sections[0].body, 'Line 1\nLine 2\nLine 3');
    });

    test('handles content with only a header and no body', () {
      const md = '## Empty Section';
      final sections = parseSections(md);
      expect(sections.length, 1);
      expect(sections[0].header, 'Empty Section');
      expect(sections[0].body, '');
    });
  });

  group('reconstructMarkdown', () {
    test('returns empty string for empty list', () {
      expect(reconstructMarkdown([]), isEmpty);
    });

    test('reconstructs single section', () {
      final sections = [Section(header: 'Rules', body: 'Do stuff.')];
      final result = reconstructMarkdown(sections);
      expect(result, contains('## Rules'));
      expect(result, contains('Do stuff.'));
    });

    test('Introduction section omits ## prefix', () {
      final sections = [
        Section(header: 'Introduction', body: 'Preamble.'),
        Section(header: 'Rules', body: 'Do stuff.'),
      ];
      final result = reconstructMarkdown(sections);
      expect(result.startsWith('Preamble.'), isTrue);
      expect(result, isNot(contains('## Introduction')));
      expect(result, contains('## Rules'));
    });

    test('round-trips parse → reconstruct', () {
      const original = '## Overview\n\nSome overview text.\n\n## Details\n\nDetail content.';
      final sections = parseSections(original);
      final reconstructed = reconstructMarkdown(sections);
      // Re-parse the reconstructed text.
      final reParsed = parseSections(reconstructed);
      expect(reParsed.length, 2);
      expect(reParsed[0].header, 'Overview');
      expect(reParsed[1].header, 'Details');
    });

    test('non-Introduction first section gets ## prefix', () {
      final sections = [Section(header: 'Config', body: 'cfg content')];
      final result = reconstructMarkdown(sections);
      expect(result, contains('## Config'));
    });
  });
}
