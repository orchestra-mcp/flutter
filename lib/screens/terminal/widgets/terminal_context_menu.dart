import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/clipboard_image_helper.dart';
import 'package:xterm/xterm.dart';

/// Shows a right-click context menu for the terminal.
Future<void> showTerminalContextMenu({
  required BuildContext context,
  required Offset position,
  required Terminal terminal,
  required TerminalController controller,
  required VoidCallback onSearch,
}) async {
  final tokens = ThemeTokens.of(context);
  final hasSelection = controller.selection != null;

  final result = await showMenu<_ContextAction>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Offset.zero &
          (Overlay.of(context).context.findRenderObject()! as RenderBox).size,
    ),
    color: tokens.bgAlt,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: tokens.border, width: 0.5),
    ),
    items: [
      _buildItem(
        _ContextAction.copy,
        Icons.copy_rounded,
        'Copy',
        tokens,
        enabled: hasSelection,
      ),
      _buildItem(_ContextAction.paste, Icons.paste_rounded, 'Paste', tokens),
      const PopupMenuDivider(height: 1),
      _buildItem(
        _ContextAction.selectAll,
        Icons.select_all_rounded,
        'Select All',
        tokens,
      ),
      const PopupMenuDivider(height: 1),
      _buildItem(_ContextAction.search, Icons.search_rounded, 'Search', tokens),
      _buildItem(
        _ContextAction.clear,
        Icons.clear_all_rounded,
        'Clear',
        tokens,
      ),
    ],
  );

  if (result == null) return;

  switch (result) {
    case _ContextAction.copy:
      if (hasSelection) {
        final text = terminal.buffer.getText(controller.selection!);
        if (text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: text));
        }
      }
    case _ContextAction.paste:
      final imagePath = await getClipboardImagePath();
      if (imagePath != null) {
        terminal.paste(imagePath);
      } else {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null && data!.text!.isNotEmpty) {
          terminal.paste(data.text!);
        }
      }
    case _ContextAction.selectAll:
      final buffer = terminal.buffer;
      if (buffer.height > 0) {
        controller.setSelection(
          buffer.createAnchor(0, 0),
          buffer.createAnchor(buffer.viewWidth - 1, buffer.height - 1),
        );
      }
    case _ContextAction.search:
      onSearch();
    case _ContextAction.clear:
      terminal.write('\x1B[2J\x1B[H');
  }
}

enum _ContextAction { copy, paste, selectAll, search, clear }

PopupMenuEntry<_ContextAction> _buildItem(
  _ContextAction value,
  IconData icon,
  String label,
  OrchestraColorTokens tokens, {
  bool enabled = true,
}) {
  return PopupMenuItem<_ContextAction>(
    value: value,
    enabled: enabled,
    height: 36,
    child: Row(
      children: [
        Icon(icon, size: 16, color: enabled ? tokens.fgMuted : tokens.fgDim),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: enabled ? tokens.fgBright : tokens.fgDim,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
