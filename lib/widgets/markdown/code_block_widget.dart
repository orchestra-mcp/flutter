import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:orchestra/widgets/markdown/export_image_helper.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/markdown/syntax_highlighter.dart';

/// A styled code block widget matching the React CodeBlock component.
/// Features: macOS window dots, language badge, line numbers, syntax
/// highlighting. All actions (copy, export, share, mermaid) are in the
/// context menu only — right-click on desktop, long-press on mobile.
class CodeBlockWidget extends StatefulWidget {
  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language = '',
    this.showLineNumbers = true,
    this.highlightLines = const [],
    this.copyable = true,
    this.exportable = true,
    this.exportImage = true,
    this.maxHeight,
    this.wrapLines = false,
    this.showWindowDots = true,
    this.onConvertToMermaid,
    this.onLinkClick,
  });

  final String code;
  final String language;
  final bool showLineNumbers;
  final List<int> highlightLines;
  final bool copyable;
  final bool exportable;
  final bool exportImage;
  final double? maxHeight;
  final bool wrapLines;
  final bool showWindowDots;
  final void Function(String code)? onConvertToMermaid;
  final void Function(String href)? onLinkClick;

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late bool _wrapped;
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _wrapped = widget.wrapLines;
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).codeCopied)),
      );
    }
  }

  Future<void> _handleExportFile() async {
    final ext = _languageExtension(widget.language);
    final defaultName = 'code_export.$ext';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${uniqueFileName(defaultName)}');
    await file.writeAsString(widget.code);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  Future<void> _handleExportImage() async {
    final tokens = ThemeTokens.of(context);
    final lang = widget.language.isNotEmpty ? widget.language : 'snippet';
    await exportWidgetAsImage(
      repaintKey: _repaintKey,
      tokens: tokens,
      fileName: 'code_$lang.png',
    );
  }

  Future<void> _handleShare() async {
    await SharePlus.instance.share(
      ShareParams(text: widget.code),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final tokens = ThemeTokens.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: tokens.bgAlt,
      items: [
        if (widget.copyable)
          PopupMenuItem(
            value: 'copy',
            child: _menuItem(Icons.copy_rounded, AppLocalizations.of(context).copyCode),
          ),
        PopupMenuItem(
          value: 'share',
          child: _menuItem(Icons.share_rounded, AppLocalizations.of(context).share),
        ),
        PopupMenuItem(
          value: 'wrap',
          child: _menuItem(
            _wrapped ? Icons.notes_rounded : Icons.wrap_text_rounded,
            _wrapped ? AppLocalizations.of(context).disableWordWrap : AppLocalizations.of(context).enableWordWrap,
          ),
        ),
        if (widget.exportable || widget.exportImage) const PopupMenuDivider(),
        if (widget.exportable)
          PopupMenuItem(
            value: 'export_file',
            child: _menuItem(Icons.save_rounded, AppLocalizations.of(context).saveAsFile),
          ),
        if (widget.exportImage)
          PopupMenuItem(
            value: 'export_image',
            child: _menuItem(Icons.image_rounded, AppLocalizations.of(context).saveAsImage),
          ),
        if (widget.onConvertToMermaid != null &&
            widget.language.toLowerCase() != 'mermaid') ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'mermaid',
            child:
                _menuItem(Icons.account_tree_rounded, AppLocalizations.of(context).convertToMermaid),
          ),
        ],
      ],
    ).then((value) {
      switch (value) {
        case 'copy':
          _handleCopy();
        case 'share':
          _handleShare();
        case 'wrap':
          setState(() => _wrapped = !_wrapped);
        case 'export_file':
          _handleExportFile();
        case 'export_image':
          _handleExportImage();
        case 'mermaid':
          widget.onConvertToMermaid?.call(widget.code);
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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final lines = widget.code.split('\n');
    final highlightSet = widget.highlightLines.toSet();
    final isDark = !tokens.isLight;

    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition),
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: RepaintBoundary(
        key: _repaintKey,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(tokens, isDark),
              _buildBody(tokens, lines, highlightSet, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(OrchestraColorTokens tokens, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252536) : const Color(0xFFEEF0F2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          // macOS dots
          if (widget.showWindowDots) ...[
            _dot(const Color(0xFFFF5F57)),
            const SizedBox(width: 6),
            _dot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 6),
            _dot(const Color(0xFF28C840)),
            const SizedBox(width: 12),
          ],
          // Language badge
          if (widget.language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.language,
                style: TextStyle(
                  color: tokens.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    OrchestraColorTokens tokens,
    List<String> lines,
    Set<int> highlightSet,
    bool isDark,
  ) {
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.6,
      color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1F2937),
    );

    Widget body = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          if (widget.showLineNumbers)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(lines.length, (i) {
                  return SizedBox(
                    height: codeStyle.fontSize! * codeStyle.height!,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: codeStyle.height,
                        color: tokens.fgDim.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // Code
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: lines.asMap().entries.map((entry) {
                  final i = entry.key;
                  final line = entry.value;
                  final isHighlighted = highlightSet.contains(i + 1);

                  final lineSpans = widget.language.isNotEmpty
                      ? highlightLine(line, widget.language,
                          isDark: isDark, baseStyle: codeStyle)
                      : [TextSpan(text: line, style: codeStyle)];

                  return TextSpan(
                    children: [
                      if (isHighlighted)
                        WidgetSpan(
                          child: Container(
                            color: tokens.accent.withValues(alpha: 0.1),
                            child: Text.rich(TextSpan(children: lineSpans)),
                          ),
                        )
                      else
                        ...lineSpans,
                      if (i < lines.length - 1) const TextSpan(text: '\n'),
                    ],
                  );
                }).toList(),
              ),
              style: codeStyle,
            ),
          ),
        ],
      ),
    );

    if (widget.maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: body),
      );
    }

    return body;
  }

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  static String _languageExtension(String lang) {
    const extensions = {
      'javascript': 'js', 'typescript': 'ts', 'python': 'py',
      'ruby': 'rb', 'rust': 'rs', 'go': 'go', 'java': 'java',
      'css': 'css', 'html': 'html', 'json': 'json', 'yaml': 'yml',
      'bash': 'sh', 'shell': 'sh', 'sql': 'sql', 'markdown': 'md',
      'php': 'php', 'csharp': 'cs', 'swift': 'swift', 'kotlin': 'kt',
      'dart': 'dart',
    };
    return extensions[lang.toLowerCase()] ?? lang.toLowerCase();
  }
}
