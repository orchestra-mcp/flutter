import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:orchestra/widgets/markdown/export_image_helper.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/markdown/inline_formatter.dart';
import 'package:orchestra/widgets/markdown/markdown_parser.dart';

/// A styled data table widget for markdown tables.
/// Always renders full width. Context menu on right-click (desktop) or
/// long-press (mobile) with export as CSV/Excel/Markdown/Text/Image and share.
class MarkdownDataTable extends StatefulWidget {
  const MarkdownDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.alignments = const [],
    this.onLinkClick,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final List<TableAlign> alignments;
  final void Function(String href)? onLinkClick;

  @override
  State<MarkdownDataTable> createState() => _MarkdownDataTableState();
}

class _MarkdownDataTableState extends State<MarkdownDataTable> {
  int? _sortColumn;
  bool _sortAscending = true;
  final _repaintKey = GlobalKey();

  List<List<String>> get _sortedRows {
    if (_sortColumn == null) return widget.rows;
    final sorted = List<List<String>>.from(widget.rows);
    sorted.sort((a, b) {
      final aVal = _sortColumn! < a.length ? a[_sortColumn!] : '';
      final bVal = _sortColumn! < b.length ? b[_sortColumn!] : '';
      return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return sorted;
  }

  // ── Export helpers ─────────────────────────────────────────────────────

  String _toCsv() {
    final buf = StringBuffer();
    buf.writeln(widget.headers.map(_escapeCsv).join(','));
    for (final row in widget.rows) {
      buf.writeln(row.map(_escapeCsv).join(','));
    }
    return buf.toString();
  }

  String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  String _toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('| ${widget.headers.join(' | ')} |');
    buf.writeln('| ${widget.headers.map((_) => '---').join(' | ')} |');
    for (final row in widget.rows) {
      buf.writeln('| ${row.join(' | ')} |');
    }
    return buf.toString();
  }

  String _toText() {
    final colWidths = <int>[];
    for (var c = 0; c < widget.headers.length; c++) {
      var max = widget.headers[c].length;
      for (final row in widget.rows) {
        if (c < row.length && row[c].length > max) max = row[c].length;
      }
      colWidths.add(max);
    }

    final buf = StringBuffer();
    buf.writeln(
      widget.headers
          .asMap()
          .entries
          .map((e) => e.value.padRight(colWidths[e.key]))
          .join('  '),
    );
    buf.writeln(colWidths.map((w) => '-' * w).join('  '));
    for (final row in widget.rows) {
      buf.writeln(
        row
            .asMap()
            .entries
            .map(
              (e) => (e.key < colWidths.length
                  ? e.value.padRight(colWidths[e.key])
                  : e.value),
            )
            .join('  '),
      );
    }
    return buf.toString();
  }

  String _toTsv() {
    final buf = StringBuffer();
    buf.writeln(widget.headers.join('\t'));
    for (final row in widget.rows) {
      buf.writeln(row.join('\t'));
    }
    return buf.toString();
  }

  /// Saves content via native share sheet (includes Save to Files on all platforms).
  Future<void> _saveFile(String content, String defaultName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${uniqueFileName(defaultName)}');
    await file.writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  Future<void> _exportImage() async {
    final tokens = ThemeTokens.of(context);
    await exportWidgetAsImage(
      repaintKey: _repaintKey,
      tokens: tokens,
      fileName: 'table_export.png',
    );
  }

  Future<void> _shareText() async {
    await SharePlus.instance.share(ShareParams(text: _toText()));
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final tokens = ThemeTokens.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: tokens.bgAlt,
      items: [
        PopupMenuItem(
          value: 'copy',
          child: _menuRow(
            Icons.copy_rounded,
            AppLocalizations.of(context).copyAsText,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: _menuRow(
            Icons.share_rounded,
            AppLocalizations.of(context).share,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'csv',
          child: _menuRow(
            Icons.table_chart_rounded,
            AppLocalizations.of(context).exportAsCsv,
          ),
        ),
        PopupMenuItem(
          value: 'excel',
          child: _menuRow(
            Icons.grid_on_rounded,
            AppLocalizations.of(context).exportAsExcelTsv,
          ),
        ),
        PopupMenuItem(
          value: 'markdown',
          child: _menuRow(
            Icons.code_rounded,
            AppLocalizations.of(context).exportAsMarkdown,
          ),
        ),
        PopupMenuItem(
          value: 'text',
          child: _menuRow(
            Icons.text_snippet_rounded,
            AppLocalizations.of(context).exportAsText,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'image',
          child: _menuRow(
            Icons.image_rounded,
            AppLocalizations.of(context).exportAsImage,
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'copy':
          Clipboard.setData(ClipboardData(text: _toText()));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).tableDataCopied),
              ),
            );
          }
        case 'share':
          _shareText();
        case 'csv':
          _saveFile(_toCsv(), 'table_export.csv');
        case 'excel':
          _saveFile(_toTsv(), 'table_export.tsv');
        case 'markdown':
          _saveFile(_toMarkdown(), 'table_export.md');
        case 'text':
          _saveFile(_toText(), 'table_export.txt');
        case 'image':
          _exportImage();
      }
    });
  }

  Widget _menuRow(IconData icon, String label) {
    final tokens = ThemeTokens.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: tokens.fgMuted),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: tokens.fgBright, fontSize: 13)),
      ],
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final sortedRows = _sortedRows;

    return GestureDetector(
      onSecondaryTapUp: (d) => _showContextMenu(context, d.globalPosition),
      onLongPressStart: (d) => _showContextMenu(context, d.globalPosition),
      child: RepaintBoundary(
        key: _repaintKey,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 64,
                ),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: tokens.border.withValues(alpha: 0.3),
                    ),
                  ),
                  children: [
                    // Header row
                    TableRow(
                      decoration: BoxDecoration(
                        color: tokens.isLight
                            ? const Color(0xFFF1F3F5)
                            : const Color(0xFF252536),
                      ),
                      children: widget.headers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final h = entry.value;
                        final align = i < widget.alignments.length
                            ? widget.alignments[i]
                            : TableAlign.left;
                        return _headerCell(tokens, h, i, align);
                      }).toList(),
                    ),
                    // Data rows
                    ...sortedRows.asMap().entries.map((entry) {
                      final rowIdx = entry.key;
                      final row = entry.value;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: rowIdx.isEven
                              ? (tokens.isLight
                                    ? Colors.white
                                    : const Color(0xFF1E1E2E))
                              : (tokens.isLight
                                    ? const Color(0xFFF8F9FA)
                                    : const Color(0xFF22223A)),
                        ),
                        children: widget.headers.asMap().entries.map((hEntry) {
                          final ci = hEntry.key;
                          final cellText = ci < row.length ? row[ci] : '';
                          final align = ci < widget.alignments.length
                              ? widget.alignments[ci]
                              : TableAlign.left;
                          return _dataCell(tokens, cellText, align);
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(
    OrchestraColorTokens tokens,
    String text,
    int colIndex,
    TableAlign align,
  ) {
    final isSorted = _sortColumn == colIndex;
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortColumn == colIndex) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumn = colIndex;
            _sortAscending = true;
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: _mainAxisAlign(align),
          children: [
            Text(
              text,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: tokens.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dataCell(OrchestraColorTokens tokens, String text, TableAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: _alignment(align),
        child: buildInlineWidget(
          text,
          baseStyle: TextStyle(color: tokens.fgMuted, fontSize: 13),
          onLinkClick: widget.onLinkClick,
        ),
      ),
    );
  }

  static MainAxisAlignment _mainAxisAlign(TableAlign align) {
    return switch (align) {
      TableAlign.center => MainAxisAlignment.center,
      TableAlign.right => MainAxisAlignment.end,
      TableAlign.left => MainAxisAlignment.start,
    };
  }

  static Alignment _alignment(TableAlign align) {
    return switch (align) {
      TableAlign.center => Alignment.center,
      TableAlign.right => Alignment.centerRight,
      TableAlign.left => Alignment.centerLeft,
    };
  }
}
