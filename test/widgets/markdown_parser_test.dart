import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/widgets/markdown/markdown_parser.dart';

void main() {
  // ── Headings ───────────────────────────────────────────────────────────────

  group('HeadingBlock', () {
    test('parses h1', () {
      final blocks = parseMarkdown('# Hello World');
      expect(blocks, hasLength(1));
      final h = blocks[0] as HeadingBlock;
      expect(h.level, 1);
      expect(h.text, 'Hello World');
    });

    test('parses h2–h6', () {
      for (var level = 2; level <= 6; level++) {
        final blocks = parseMarkdown('${'#' * level} Title');
        final h = blocks[0] as HeadingBlock;
        expect(h.level, level);
      }
    });

    test('heading id is slugified', () {
      final blocks = parseMarkdown('# Hello World');
      final h = blocks[0] as HeadingBlock;
      expect(h.id, 'hello-world');
    });

    test('heading id strips special chars', () {
      final blocks = parseMarkdown('# Hello, World!');
      final h = blocks[0] as HeadingBlock;
      expect(h.id, 'hello-world');
    });
  });

  // ── Paragraph ─────────────────────────────────────────────────────────────

  group('ParagraphBlock', () {
    test('parses single-line paragraph', () {
      final blocks = parseMarkdown('Hello world');
      expect(blocks, hasLength(1));
      final p = blocks[0] as ParagraphBlock;
      expect(p.text, 'Hello world');
    });

    test('joins multi-line paragraph with space', () {
      final blocks = parseMarkdown('Line one\nLine two');
      final p = blocks[0] as ParagraphBlock;
      expect(p.text, 'Line one Line two');
    });

    test('blank line separates paragraphs', () {
      final blocks = parseMarkdown('Para one\n\nPara two');
      expect(blocks, hasLength(2));
      expect(blocks[0], isA<ParagraphBlock>());
      expect(blocks[1], isA<ParagraphBlock>());
    });
  });

  // ── Code block ────────────────────────────────────────────────────────────

  group('CodeBlock', () {
    test('parses fenced code block with language', () {
      final blocks = parseMarkdown('```dart\nfinal x = 1;\n```');
      expect(blocks, hasLength(1));
      final c = blocks[0] as CodeBlock;
      expect(c.language, 'dart');
      expect(c.code, 'final x = 1;');
    });

    test('parses fenced code block without language', () {
      final blocks = parseMarkdown('```\nsome code\n```');
      final c = blocks[0] as CodeBlock;
      expect(c.language, '');
      expect(c.code, 'some code');
    });

    test('preserves internal newlines in code', () {
      final blocks = parseMarkdown('```\nline1\nline2\n```');
      final c = blocks[0] as CodeBlock;
      expect(c.code, 'line1\nline2');
    });
  });

  // ── Blockquote ────────────────────────────────────────────────────────────

  group('BlockquoteBlock', () {
    test('parses single-line blockquote', () {
      final blocks = parseMarkdown('> Quote text');
      expect(blocks, hasLength(1));
      final b = blocks[0] as BlockquoteBlock;
      expect(b.text, 'Quote text');
    });

    test('parses multi-line blockquote', () {
      final blocks = parseMarkdown('> Line one\n> Line two');
      final b = blocks[0] as BlockquoteBlock;
      expect(b.text, contains('Line one'));
      expect(b.text, contains('Line two'));
    });
  });

  // ── Unordered list ────────────────────────────────────────────────────────

  group('UnorderedListBlock', () {
    test('parses dash items', () {
      final blocks = parseMarkdown('- Apple\n- Banana\n- Cherry');
      expect(blocks, hasLength(1));
      final list = blocks[0] as UnorderedListBlock;
      expect(list.items, ['Apple', 'Banana', 'Cherry']);
    });

    test('parses asterisk items', () {
      final blocks = parseMarkdown('* One\n* Two');
      final list = blocks[0] as UnorderedListBlock;
      expect(list.items, hasLength(2));
    });

    test('parses plus items', () {
      final blocks = parseMarkdown('+ Foo\n+ Bar');
      final list = blocks[0] as UnorderedListBlock;
      expect(list.items, ['Foo', 'Bar']);
    });
  });

  // ── Ordered list ──────────────────────────────────────────────────────────

  group('OrderedListBlock', () {
    test('parses numbered items', () {
      final blocks = parseMarkdown('1. First\n2. Second\n3. Third');
      expect(blocks, hasLength(1));
      final list = blocks[0] as OrderedListBlock;
      expect(list.items, ['First', 'Second', 'Third']);
    });
  });

  // ── Task list ─────────────────────────────────────────────────────────────

  group('TaskListBlock', () {
    test('parses checked and unchecked items', () {
      final blocks = parseMarkdown('- [x] Done\n- [ ] Todo');
      expect(blocks, hasLength(1));
      final tasks = blocks[0] as TaskListBlock;
      expect(tasks.items[0].checked, isTrue);
      expect(tasks.items[0].text, 'Done');
      expect(tasks.items[1].checked, isFalse);
      expect(tasks.items[1].text, 'Todo');
    });

    test('parses uppercase X as checked', () {
      final blocks = parseMarkdown('- [X] Done');
      final tasks = blocks[0] as TaskListBlock;
      expect(tasks.items[0].checked, isTrue);
    });
  });

  // ── Table ─────────────────────────────────────────────────────────────────

  group('TableBlock', () {
    test('parses simple table', () {
      const md = '| Name | Age |\n| --- | --- |\n| Alice | 30 |';
      final blocks = parseMarkdown(md);
      expect(blocks, hasLength(1));
      final table = blocks[0] as TableBlock;
      expect(table.headers, ['Name', 'Age']);
      expect(table.rows[0], ['Alice', '30']);
    });

    test('parses column alignments', () {
      const md = '| L | C | R |\n| :--- | :---: | ---: |\n| a | b | c |';
      final blocks = parseMarkdown(md);
      final table = blocks[0] as TableBlock;
      expect(table.alignments[0], TableAlign.left);
      expect(table.alignments[1], TableAlign.center);
      expect(table.alignments[2], TableAlign.right);
    });
  });

  // ── Frontmatter ───────────────────────────────────────────────────────────

  group('FrontmatterBlock', () {
    test('parses YAML frontmatter', () {
      const md = '---\ntitle: Hello\nauthor: Alice\n---\n\nBody text';
      final blocks = parseMarkdown(md);
      expect(blocks[0], isA<FrontmatterBlock>());
      final fm = blocks[0] as FrontmatterBlock;
      expect(fm.data['title'], 'Hello');
      expect(fm.data['author'], 'Alice');
    });

    test('strips quotes from frontmatter values', () {
      const md = '---\ntitle: "Quoted"\n---';
      final blocks = parseMarkdown(md);
      final fm = blocks[0] as FrontmatterBlock;
      expect(fm.data['title'], 'Quoted');
    });

    test('body after frontmatter is parsed normally', () {
      const md = '---\ntitle: T\n---\n\n# Heading';
      final blocks = parseMarkdown(md);
      expect(blocks.any((b) => b is HeadingBlock), isTrue);
    });
  });

  // ── Horizontal rule ───────────────────────────────────────────────────────

  group('HorizontalRuleBlock', () {
    test('parses ---', () {
      final blocks = parseMarkdown('---');
      expect(blocks[0], isA<HorizontalRuleBlock>());
    });

    test('parses ***', () {
      final blocks = parseMarkdown('***');
      expect(blocks[0], isA<HorizontalRuleBlock>());
    });

    test('parses ___', () {
      final blocks = parseMarkdown('___');
      expect(blocks[0], isA<HorizontalRuleBlock>());
    });
  });

  // ── Mixed content ─────────────────────────────────────────────────────────

  group('Mixed content', () {
    test('parses heading then paragraph', () {
      final blocks = parseMarkdown('# Title\n\nSome text');
      expect(blocks[0], isA<HeadingBlock>());
      expect(blocks[1], isA<ParagraphBlock>());
    });

    test('empty string returns no blocks', () {
      final blocks = parseMarkdown('');
      expect(blocks, isEmpty);
    });

    test('only whitespace returns no blocks', () {
      final blocks = parseMarkdown('   \n\n   ');
      expect(blocks, isEmpty);
    });

    test('complex document produces correct block count', () {
      const md = '''---
title: Test
---

# Heading

Paragraph text.

- Item 1
- Item 2

> Quote

```dart
code here
```

---
''';
      final blocks = parseMarkdown(md);
      expect(blocks.whereType<FrontmatterBlock>(), hasLength(1));
      expect(blocks.whereType<HeadingBlock>(), hasLength(1));
      expect(blocks.whereType<ParagraphBlock>(), hasLength(1));
      expect(blocks.whereType<UnorderedListBlock>(), hasLength(1));
      expect(blocks.whereType<BlockquoteBlock>(), hasLength(1));
      expect(blocks.whereType<CodeBlock>(), hasLength(1));
      expect(blocks.whereType<HorizontalRuleBlock>(), hasLength(1));
    });
  });
}
