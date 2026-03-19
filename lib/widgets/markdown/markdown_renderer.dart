import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/markdown/code_block_widget.dart';
import 'package:orchestra/widgets/markdown/export_image_helper.dart';
import 'package:orchestra/widgets/markdown/inline_formatter.dart';
import 'package:orchestra/widgets/markdown/markdown_data_table.dart';
import 'package:orchestra/widgets/markdown/markdown_export.dart';
import 'package:orchestra/widgets/markdown/markdown_parser.dart';
import 'package:share_plus/share_plus.dart';

/// A GitHub-flavored markdown renderer widget.
/// Parses raw markdown and renders blocks using [CodeBlockWidget],
/// [MarkdownDataTable], and inline formatting.
/// Context menu (right-click / long-press) provides export as
/// docs, PDF, HTML, image, markdown, and plain text.
class MarkdownRendererWidget extends StatefulWidget {
  const MarkdownRendererWidget({
    super.key,
    required this.content,
    this.onLinkClick,
    this.onConvertToMermaid,
    this.padding = const EdgeInsets.all(16),
  });

  /// Raw markdown text to render.
  final String content;

  /// Called when a markdown link is tapped.
  final void Function(String href)? onLinkClick;

  /// Called when user taps "Convert to Mermaid" on a code block.
  final void Function(String code)? onConvertToMermaid;

  /// Padding around the rendered content.
  final EdgeInsets padding;

  @override
  State<MarkdownRendererWidget> createState() => _MarkdownRendererWidgetState();
}

class _MarkdownRendererWidgetState extends State<MarkdownRendererWidget> {
  final _repaintKey = GlobalKey();

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _exportImage() async {
    final tokens = ThemeTokens.of(context);
    await exportWidgetAsImage(
      repaintKey: _repaintKey,
      tokens: tokens,
      fileName: 'markdown_export.png',
    );
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).markdownCopied)),
      );
    }
  }

  Future<void> _handleShare() async {
    await SharePlus.instance.share(ShareParams(text: widget.content));
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
          child: _menuItem(Icons.copy_rounded, 'Copy markdown'),
        ),
        PopupMenuItem(
          value: 'share',
          child: _menuItem(Icons.share_rounded, 'Share'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'docs',
          child: _menuItem(Icons.description_rounded, 'Export as Document'),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: _menuItem(Icons.picture_as_pdf_rounded, 'Export as PDF'),
        ),
        PopupMenuItem(
          value: 'html',
          child: _menuItem(Icons.code_rounded, 'Export as HTML'),
        ),
        PopupMenuItem(
          value: 'image',
          child: _menuItem(Icons.image_rounded, 'Export as Image'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'markdown',
          child: _menuItem(Icons.text_snippet_rounded, 'Export as Markdown'),
        ),
        PopupMenuItem(
          value: 'plaintext',
          child: _menuItem(Icons.notes_rounded, 'Export as Plain Text'),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'copy':
          _handleCopy();
        case 'share':
          _handleShare();
        case 'docs':
          exportContentAsFile(markdownToDocx(widget.content), 'document.doc');
        case 'pdf':
          exportMarkdownAsPdf(widget.content);
        case 'html':
          exportContentAsFile(markdownToHtml(widget.content), 'document.html');
        case 'image':
          _exportImage();
        case 'markdown':
          exportContentAsFile(widget.content, 'document.md');
        case 'plaintext':
          exportContentAsFile(
            markdownToPlainText(widget.content),
            'document.txt',
          );
      }
    });
  }

  Widget _menuItem(IconData icon, String label) {
    final tokens = ThemeTokens.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: tokens.fgMuted),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: tokens.fgBright, fontSize: 13)),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) return const SizedBox.shrink();

    final blocks = parseMarkdown(widget.content);
    final tokens = ThemeTokens.of(context);

    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: RepaintBoundary(
        key: _repaintKey,
        child: SelectionArea(
          child: Padding(
            padding: widget.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  blocks
                      .map((b) => _buildBlock(b, tokens))
                      .expand((w) => [w, const SizedBox(height: 12)])
                      .toList()
                    ..removeLast(), // remove trailing spacer
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(MarkdownBlock block, OrchestraColorTokens tokens) {
    return switch (block) {
      HeadingBlock() => _heading(block, tokens),
      ParagraphBlock() => _paragraph(block, tokens),
      CodeBlock() => _codeBlock(block),
      TableBlock() => _table(block),
      BlockquoteBlock() => _blockquote(block, tokens),
      UnorderedListBlock() => _unorderedList(block, tokens),
      OrderedListBlock() => _orderedList(block, tokens),
      TaskListBlock() => _taskList(block, tokens),
      FrontmatterBlock() => _frontmatter(block, tokens),
      HorizontalRuleBlock() => _hr(tokens),
    };
  }

  // ── Heading ─────────────────────────────────────────────────────────────

  Widget _heading(HeadingBlock block, OrchestraColorTokens tokens) {
    final sizes = [28.0, 24.0, 20.0, 18.0, 16.0, 14.0];
    final size = block.level <= sizes.length ? sizes[block.level - 1] : 14.0;
    final showBorder = block.level <= 2;

    return Container(
      padding: showBorder ? const EdgeInsets.only(bottom: 8) : null,
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.border.withValues(alpha: 0.4)),
              ),
            )
          : null,
      child: buildInlineWidget(
        block.text,
        baseStyle: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: tokens.fgBright,
          height: 1.4,
        ),
        onLinkClick: widget.onLinkClick,
      ),
    );
  }

  // ── Paragraph ───────────────────────────────────────────────────────────

  Widget _paragraph(ParagraphBlock block, OrchestraColorTokens tokens) {
    return buildInlineWidget(
      block.text,
      baseStyle: TextStyle(fontSize: 14, color: tokens.fgMuted, height: 1.6),
      onLinkClick: widget.onLinkClick,
    );
  }

  // ── Code block ──────────────────────────────────────────────────────────

  Widget _codeBlock(CodeBlock block) {
    return CodeBlockWidget(
      code: block.code,
      language: block.language,
      onConvertToMermaid: widget.onConvertToMermaid,
      onLinkClick: widget.onLinkClick,
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────

  Widget _table(TableBlock block) {
    return MarkdownDataTable(
      headers: block.headers,
      rows: block.rows,
      alignments: block.alignments,
      onLinkClick: widget.onLinkClick,
    );
  }

  // ── Blockquote ──────────────────────────────────────────────────────────

  Widget _blockquote(BlockquoteBlock block, OrchestraColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: tokens.accent.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        color: tokens.accent.withValues(alpha: 0.05),
      ),
      child: buildInlineWidget(
        block.text,
        baseStyle: TextStyle(
          fontSize: 14,
          color: tokens.fgMuted,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
        onLinkClick: widget.onLinkClick,
      ),
    );
  }

  // ── Unordered list ──────────────────────────────────────────────────────

  Widget _unorderedList(UnorderedListBlock block, OrchestraColorTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.fgDim,
                    ),
                  ),
                ),
                Expanded(
                  child: buildInlineWidget(
                    item,
                    baseStyle: TextStyle(
                      fontSize: 14,
                      color: tokens.fgMuted,
                      height: 1.6,
                    ),
                    onLinkClick: widget.onLinkClick,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Ordered list ────────────────────────────────────────────────────────

  Widget _orderedList(OrderedListBlock block, OrchestraColorTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.key + 1}.',
                    style: TextStyle(
                      fontSize: 14,
                      color: tokens.fgDim,
                      height: 1.6,
                    ),
                  ),
                ),
                Expanded(
                  child: buildInlineWidget(
                    entry.value,
                    baseStyle: TextStyle(
                      fontSize: 14,
                      color: tokens.fgMuted,
                      height: 1.6,
                    ),
                    onLinkClick: widget.onLinkClick,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Task list ───────────────────────────────────────────────────────────

  Widget _taskList(TaskListBlock block, OrchestraColorTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Icon(
                    item.checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: item.checked
                        ? const Color(0xFF4ADE80)
                        : tokens.fgDim,
                  ),
                ),
                Expanded(
                  child: buildInlineWidget(
                    item.text,
                    baseStyle: TextStyle(
                      fontSize: 14,
                      color: tokens.fgMuted,
                      height: 1.6,
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: tokens.fgDim,
                    ),
                    onLinkClick: widget.onLinkClick,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Frontmatter ─────────────────────────────────────────────────────────

  Widget _frontmatter(FrontmatterBlock block, OrchestraColorTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Text(
              'Metadata',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens.accent,
              ),
            ),
          ),
          ...block.data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.fgDim,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 12, color: tokens.fgMuted),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Horizontal rule ─────────────────────────────────────────────────────

  Widget _hr(OrchestraColorTokens tokens) {
    return Divider(color: tokens.border.withValues(alpha: 0.5), height: 1);
  }
}
