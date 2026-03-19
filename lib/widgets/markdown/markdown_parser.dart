/// Lightweight markdown parser — no external dependencies.
/// Splits raw markdown into typed blocks for rendering.
/// Ported from apps/components/editor/src/MarkdownRenderer/parseMarkdown.ts

/// Table column alignment.
enum TableAlign { left, center, right }

/// Union type for parsed markdown blocks.
sealed class MarkdownBlock {
  const MarkdownBlock();
}

class HeadingBlock extends MarkdownBlock {
  const HeadingBlock({required this.level, required this.text, required this.id});
  final int level;
  final String text;
  final String id;
}

class ParagraphBlock extends MarkdownBlock {
  const ParagraphBlock({required this.text});
  final String text;
}

class CodeBlock extends MarkdownBlock {
  const CodeBlock({required this.language, required this.code});
  final String language;
  final String code;
}

class TableBlock extends MarkdownBlock {
  const TableBlock({
    required this.headers,
    required this.rows,
    required this.alignments,
  });
  final List<String> headers;
  final List<List<String>> rows;
  final List<TableAlign> alignments;
}

class BlockquoteBlock extends MarkdownBlock {
  const BlockquoteBlock({required this.text});
  final String text;
}

class UnorderedListBlock extends MarkdownBlock {
  const UnorderedListBlock({required this.items});
  final List<String> items;
}

class OrderedListBlock extends MarkdownBlock {
  const OrderedListBlock({required this.items});
  final List<String> items;
}

class TaskListItem {
  const TaskListItem({required this.checked, required this.text});
  final bool checked;
  final String text;
}

class TaskListBlock extends MarkdownBlock {
  const TaskListBlock({required this.items});
  final List<TaskListItem> items;
}

class FrontmatterBlock extends MarkdownBlock {
  const FrontmatterBlock({required this.data});
  final Map<String, String> data;
}

class HorizontalRuleBlock extends MarkdownBlock {
  const HorizontalRuleBlock();
}

// ── Regex patterns ──────────────────────────────────────────────────────────

final _ulRe = RegExp(r'^\s*[-*+]\s');
final _olRe = RegExp(r'^\s*\d+[.)]\s');
bool _isList(String line) => _ulRe.hasMatch(line) || _olRe.hasMatch(line);

final _headingRe = RegExp(r'^(#{1,6})\s+(.*)');
final _codeFenceRe = RegExp(r'^```(\w*)');
final _hrRe = RegExp(r'^[-*_]{3,}$');
final _separatorRe = RegExp(r'^\|?[\s\-:|]+\|?$');

// ── Helpers ─────────────────────────────────────────────────────────────────

String _slugify(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();
}

List<TableAlign> _parseAlignments(String separatorLine) {
  return separatorLine
      .split('|')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .map((cell) {
    final left = cell.startsWith(':');
    final right = cell.endsWith(':');
    if (left && right) return TableAlign.center;
    if (right) return TableAlign.right;
    return TableAlign.left;
  }).toList();
}

TableBlock? _parseTable(List<String> lines) {
  if (lines.length < 2) return null;
  List<String> parseLine(String line) =>
      line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  final headers = parseLine(lines[0]);
  if (!_separatorRe.hasMatch(lines[1])) return null;
  final alignments = _parseAlignments(lines[1]);
  final rows = lines.skip(2).map(parseLine).toList();
  return TableBlock(headers: headers, rows: rows, alignments: alignments);
}

MarkdownBlock _parseListBlock(List<String> lines) {
  final stripped = lines.map((l) => l.replaceFirst(RegExp(r'^\s+'), '')).toList();
  final taskMatch = RegExp(r'^[-*+]\s+\[([ xX])\]').firstMatch(stripped[0]);
  if (taskMatch != null) {
    final items = stripped.map((l) {
      final m = RegExp(r'^[-*+]\s+\[([ xX])\]\s*(.*)').firstMatch(l);
      return TaskListItem(
        checked: m != null ? m.group(1) != ' ' : false,
        text: m != null ? (m.group(2) ?? l) : l,
      );
    }).toList();
    return TaskListBlock(items: items);
  }
  if (_olRe.hasMatch(stripped[0])) {
    return OrderedListBlock(
      items: stripped.map((l) => l.replaceFirst(RegExp(r'^\d+[.)]\s*'), '')).toList(),
    );
  }
  return UnorderedListBlock(
    items: stripped.map((l) => l.replaceFirst(RegExp(r'^[-*+]\s*'), '')).toList(),
  );
}

Map<String, String> _parseYaml(List<String> lines) {
  final data = <String, String>{};
  for (final line in lines) {
    final match = RegExp(r'^(\w[\w\s-]*):\s*(.*)').firstMatch(line);
    if (match != null) {
      final key = (match.group(1) ?? '').trim();
      var value = (match.group(2) ?? '').trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      data[key] = value;
    }
  }
  return data;
}

// ── Main parser ─────────────────────────────────────────────────────────────

/// Parse raw markdown into a list of typed blocks.
List<MarkdownBlock> parseMarkdown(String content) {
  final blocks = <MarkdownBlock>[];
  final rawLines = content.split('\n');
  var i = 0;

  // YAML frontmatter — must be the very first line
  if (rawLines.isNotEmpty && rawLines[0].trim() == '---') {
    i = 1;
    final fmLines = <String>[];
    while (i < rawLines.length && rawLines[i].trim() != '---') {
      fmLines.add(rawLines[i]);
      i++;
    }
    if (i < rawLines.length) {
      i++; // skip closing ---
      final data = _parseYaml(fmLines);
      if (data.isNotEmpty) {
        blocks.add(FrontmatterBlock(data: data));
      }
    } else {
      i = 0; // No closing --- found
    }
  }

  while (i < rawLines.length) {
    final line = rawLines[i];

    // Blank line
    if (line.trim().isEmpty) {
      i++;
      continue;
    }

    // Horizontal rule
    if (_hrRe.hasMatch(line.trim())) {
      blocks.add(const HorizontalRuleBlock());
      i++;
      continue;
    }

    // Heading
    final headingMatch = _headingRe.firstMatch(line);
    if (headingMatch != null) {
      final hashes = headingMatch.group(1) ?? '#';
      final text = headingMatch.group(2) ?? '';
      blocks.add(HeadingBlock(
        level: hashes.length,
        text: text,
        id: _slugify(text),
      ));
      i++;
      continue;
    }

    // Fenced code block
    final codeMatch = _codeFenceRe.firstMatch(line);
    if (codeMatch != null) {
      final language = codeMatch.group(1) ?? '';
      final codeLines = <String>[];
      i++;
      while (i < rawLines.length && !rawLines[i].startsWith('```')) {
        codeLines.add(rawLines[i]);
        i++;
      }
      blocks.add(CodeBlock(language: language, code: codeLines.join('\n')));
      if (i < rawLines.length) i++; // skip closing ```
      continue;
    }

    // Table
    if (line.contains('|') &&
        i + 1 < rawLines.length &&
        _separatorRe.hasMatch(rawLines[i + 1])) {
      final tableLines = <String>[];
      while (i < rawLines.length && rawLines[i].contains('|')) {
        tableLines.add(rawLines[i]);
        i++;
      }
      final table = _parseTable(tableLines);
      if (table != null) {
        blocks.add(table);
        continue;
      }
    }

    // Blockquote
    if (line.startsWith('>')) {
      final quoteLines = <String>[];
      while (i < rawLines.length && rawLines[i].startsWith('>')) {
        quoteLines.add(rawLines[i].replaceFirst(RegExp(r'^>\s?'), ''));
        i++;
      }
      blocks.add(BlockquoteBlock(text: quoteLines.join('\n')));
      continue;
    }

    // List
    if (_isList(line)) {
      final listLines = <String>[];
      while (i < rawLines.length) {
        final cur = rawLines[i];
        if (cur.trim().isEmpty) break;
        if (_isList(cur)) {
          listLines.add(cur);
          i++;
        } else if (listLines.isNotEmpty &&
            (cur.startsWith('  ') || cur.startsWith('\t'))) {
          listLines[listLines.length - 1] += ' ${cur.trim()}';
          i++;
        } else {
          break;
        }
      }
      blocks.add(_parseListBlock(listLines));
      continue;
    }

    // Paragraph
    final paraLines = <String>[];
    while (i < rawLines.length &&
        rawLines[i].trim().isNotEmpty &&
        _headingRe.firstMatch(rawLines[i]) == null &&
        !rawLines[i].startsWith('```') &&
        !rawLines[i].startsWith('>') &&
        !_hrRe.hasMatch(rawLines[i].trim()) &&
        !_isList(rawLines[i]) &&
        !(rawLines[i].contains('|') &&
            i + 1 < rawLines.length &&
            _separatorRe.hasMatch(rawLines[i + 1]))) {
      paraLines.add(rawLines[i]);
      i++;
    }
    if (paraLines.isNotEmpty) {
      blocks.add(ParagraphBlock(text: paraLines.join(' ')));
    }
  }

  return blocks;
}
