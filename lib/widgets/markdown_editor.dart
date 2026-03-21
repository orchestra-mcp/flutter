import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';

/// View mode for the markdown editor.
enum MarkdownEditorViewMode {
  /// Only the editor text field is visible.
  editOnly,

  /// Only the preview pane is visible.
  previewOnly,

  /// Editor and preview are shown side by side.
  sideBySide,
}

/// A glass-themed markdown editor with toolbar, split-view toggle,
/// and debounced auto-save.
///
/// ```dart
/// MarkdownEditor(
///   initialText: '# Hello\nWorld',
///   onChanged: (text) => print('Auto-saved: $text'),
/// )
/// ```
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    this.initialText = '',
    this.controller,
    this.onChanged,
    this.autoSaveDelay = const Duration(milliseconds: 500),
    this.hintText = 'Start writing markdown...',
  });

  /// Initial markdown text to populate the editor with.
  /// Ignored when [controller] is provided.
  final String initialText;

  /// Optional external controller. When provided, the editor uses this
  /// controller instead of creating its own. The caller is responsible
  /// for disposing it.
  final TextEditingController? controller;

  /// Called after the user stops typing for [autoSaveDelay].
  final ValueChanged<String>? onChanged;

  /// Debounce duration before [onChanged] fires. Defaults to 500ms.
  final Duration autoSaveDelay;

  /// Placeholder text shown when the editor is empty.
  final String hintText;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  late final FocusNode _focusNode;
  MarkdownEditorViewMode _viewMode = MarkdownEditorViewMode.editOnly;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(widget.autoSaveDelay, () {
      widget.onChanged?.call(_controller.text);
    });
    // Rebuild for live preview
    setState(() {});
  }

  // ── Toolbar insertions ────────────────────────────────────────────────

  void _insertAround(String prefix, String suffix) {
    final sel = _controller.selection;
    final text = _controller.text;

    if (sel.isCollapsed) {
      // No selection -- insert with placeholder
      final placeholder = '${prefix}text$suffix';
      _controller.text =
          text.substring(0, sel.baseOffset) +
          placeholder +
          text.substring(sel.baseOffset);
      _controller.selection = TextSelection(
        baseOffset: sel.baseOffset + prefix.length,
        extentOffset: sel.baseOffset + prefix.length + 4, // "text"
      );
    } else {
      // Wrap selection
      final selected = text.substring(sel.start, sel.end);
      final replacement = '$prefix$selected$suffix';
      _controller.text =
          text.substring(0, sel.start) + replacement + text.substring(sel.end);
      _controller.selection = TextSelection(
        baseOffset: sel.start + prefix.length,
        extentOffset: sel.start + prefix.length + selected.length,
      );
    }
    _focusNode.requestFocus();
  }

  void _insertAtLineStart(String prefix) {
    final sel = _controller.selection;
    final text = _controller.text;

    // Find start of the current line
    var lineStart = sel.baseOffset;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    _controller.text =
        text.substring(0, lineStart) + prefix + text.substring(lineStart);
    _controller.selection = TextSelection.collapsed(
      offset: sel.baseOffset + prefix.length,
    );
    _focusNode.requestFocus();
  }

  void _onBold() => _insertAround('**', '**');
  void _onItalic() => _insertAround('_', '_');
  void _onHeading() => _insertAtLineStart('## ');
  void _onBulletList() => _insertAtLineStart('- ');
  void _onCodeInline() => _insertAround('`', '`');

  void _onLink() {
    final sel = _controller.selection;
    final text = _controller.text;
    final label = sel.isCollapsed ? 'link' : text.substring(sel.start, sel.end);
    final replacement = '[$label](url)';

    final start = sel.isCollapsed ? sel.baseOffset : sel.start;
    final end = sel.isCollapsed ? sel.baseOffset : sel.end;

    _controller.text =
        text.substring(0, start) + replacement + text.substring(end);
    // Select "url" for quick replacement
    final urlStart = start + label.length + 3; // "[label]("
    _controller.selection = TextSelection(
      baseOffset: urlStart,
      extentOffset: urlStart + 3, // "url"
    );
    _focusNode.requestFocus();
  }

  void _onImage() {
    final sel = _controller.selection;
    final text = _controller.text;
    const replacement = '![alt](image_url)';
    final offset = sel.isCollapsed ? sel.baseOffset : sel.start;
    final end = sel.isCollapsed ? sel.baseOffset : sel.end;

    _controller.text =
        text.substring(0, offset) + replacement + text.substring(end);
    // Select "image_url"
    _controller.selection = TextSelection(
      baseOffset: offset + 7, // "![alt]("
      extentOffset: offset + 16, // "image_url"
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Column(
      children: [
        // ── Toolbar ────────────────────────────────────────────────────
        _buildToolbar(tokens),
        const SizedBox(height: 8),

        // ── Editor / Preview ───────────────────────────────────────────
        Expanded(
          child: switch (_viewMode) {
            MarkdownEditorViewMode.editOnly => _buildEditor(tokens),
            MarkdownEditorViewMode.previewOnly => _buildPreview(
              tokens,
              _controller.text,
            ),
            MarkdownEditorViewMode.sideBySide => Row(
              children: [
                Expanded(child: _buildEditor(tokens)),
                VerticalDivider(
                  width: 1,
                  color: tokens.border.withValues(alpha: 0.4),
                ),
                Expanded(child: _buildPreview(tokens, _controller.text)),
              ],
            ),
          },
        ),
      ],
    );
  }

  // ── Toolbar ─────────────────────────────────────────────────────────────

  Widget _buildToolbar(OrchestraColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          _toolbarButton(tokens, Icons.format_bold_rounded, 'Bold', _onBold),
          _toolbarButton(
            tokens,
            Icons.format_italic_rounded,
            'Italic',
            _onItalic,
          ),
          _toolbarDivider(tokens),
          _toolbarButton(tokens, Icons.title_rounded, 'Heading', _onHeading),
          _toolbarButton(
            tokens,
            Icons.format_list_bulleted_rounded,
            'List',
            _onBulletList,
          ),
          _toolbarButton(tokens, Icons.code_rounded, 'Code', _onCodeInline),
          _toolbarDivider(tokens),
          _toolbarButton(tokens, Icons.link_rounded, 'Link', _onLink),
          _toolbarButton(tokens, Icons.image_rounded, 'Image', _onImage),
          const Spacer(),
          // View mode toggle
          _viewModeButton(
            tokens,
            Icons.edit_rounded,
            'Edit only',
            MarkdownEditorViewMode.editOnly,
          ),
          _viewModeButton(
            tokens,
            Icons.vertical_split_rounded,
            'Side by side',
            MarkdownEditorViewMode.sideBySide,
          ),
          _viewModeButton(
            tokens,
            Icons.visibility_rounded,
            'Preview only',
            MarkdownEditorViewMode.previewOnly,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton(
    OrchestraColorTokens tokens,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: tokens.fgMuted),
          ),
        ),
      ),
    );
  }

  Widget _toolbarDivider(OrchestraColorTokens tokens) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: tokens.border.withValues(alpha: 0.4),
    );
  }

  Widget _viewModeButton(
    OrchestraColorTokens tokens,
    IconData icon,
    String tooltip,
    MarkdownEditorViewMode mode,
  ) {
    final isActive = _viewMode == mode;
    return Semantics(
      label: tooltip,
      button: true,
      selected: isActive,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => setState(() => _viewMode = mode),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? tokens.accent.withValues(alpha: 0.15) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? tokens.accent : tokens.fgDim,
            ),
          ),
        ),
      ),
    );
  }

  // ── Editor pane ─────────────────────────────────────────────────────────

  Widget _buildEditor(OrchestraColorTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          color: tokens.fgBright,
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: tokens.fgDim),
          contentPadding: const EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ── Preview pane ────────────────────────────────────────────────────────

  Widget _buildPreview(OrchestraColorTokens tokens, String markdown) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: markdown.isEmpty
            ? Center(
                child: Text(
                  'Nothing to preview',
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                ),
              )
            : SingleChildScrollView(
                child: MarkdownRendererWidget(
                  content: markdown,
                  padding: const EdgeInsets.all(14),
                ),
              ),
      ),
    );
  }
}
