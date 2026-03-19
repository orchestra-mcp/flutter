import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/sync/push_sync_controller.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';
import 'package:orchestra/widgets/icon_color_picker.dart';
import 'package:orchestra/widgets/icon_picker.dart';
import 'package:orchestra/widgets/markdown/markdown_export.dart';
import 'package:orchestra/widgets/team_selector_dialog.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

/// Factory that builds a standard set of [GlassListTileAction]s for any entity.
///
/// Pass `null` for any callback to omit that action from the menu.
/// When [markdownContent] is provided, a full set of export actions is included
/// (PDF, Document, HTML, Image, Markdown, Plain Text).
List<GlassListTileAction> buildEntityContextActions({
  required AppLocalizations l10n,
  VoidCallback? onRename,
  VoidCallback? onChangeIcon,
  VoidCallback? onChangeColor,
  VoidCallback? onSelect,
  VoidCallback? onEdit,
  VoidCallback? onPin,
  bool isPinned = false,
  VoidCallback? onSync,
  VoidCallback? onPublish,
  VoidCallback? onExportToWorkspace,
  VoidCallback? onExportMarkdown,
  VoidCallback? onDelete,
  String? markdownContent,
  String? markdownTitle,
  BuildContext? exportContext,
}) {
  return [
    if (onRename != null)
      GlassListTileAction(
        label: l10n.actionRename,
        icon: Icons.edit_outlined,
        onTap: onRename,
      ),
    if (onChangeIcon != null)
      GlassListTileAction(
        label: l10n.actionChangeIcon,
        icon: Icons.emoji_emotions_outlined,
        onTap: onChangeIcon,
      ),
    if (onChangeColor != null)
      GlassListTileAction(
        label: l10n.actionChangeColor,
        icon: Icons.palette_outlined,
        onTap: onChangeColor,
      ),
    if (onSelect != null)
      GlassListTileAction(
        label: l10n.actionSelect,
        icon: Icons.check_circle_outline,
        onTap: onSelect,
      ),
    if (onEdit != null)
      GlassListTileAction(
        label: l10n.actionEdit,
        icon: Icons.open_in_new_rounded,
        onTap: onEdit,
      ),
    if (onPin != null)
      GlassListTileAction(
        label: isPinned ? l10n.unpin : l10n.pin,
        icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        onTap: onPin,
      ),
    if (onSync != null)
      GlassListTileAction(
        label: l10n.actionSyncWithTeam,
        icon: Icons.sync_rounded,
        onTap: onSync,
      ),
    if (onPublish != null)
      GlassListTileAction(
        label: l10n.actionPublish,
        icon: Icons.cloud_upload_outlined,
        onTap: onPublish,
      ),
    if (onExportToWorkspace != null)
      GlassListTileAction(
        label: l10n.actionExportToWorkspace,
        icon: Icons.drive_file_move_outline,
        onTap: onExportToWorkspace,
      ),
    // Full export menu when markdown content is available
    if (markdownContent != null && markdownContent.isNotEmpty) ...[
      GlassListTileAction(
        label: l10n.actionExportPdf,
        icon: Icons.picture_as_pdf_rounded,
        onTap: () => exportMarkdownAsPdf(markdownContent, title: markdownTitle),
      ),
      GlassListTileAction(
        label: l10n.actionExportDocument,
        icon: Icons.description_rounded,
        onTap: () => exportContentAsFile(
          markdownToDocx(markdownContent),
          '${markdownTitle ?? 'document'}.doc',
        ),
      ),
      GlassListTileAction(
        label: l10n.actionExportHtml,
        icon: Icons.code_rounded,
        onTap: () => exportContentAsFile(
          markdownToHtml(markdownContent),
          '${markdownTitle ?? 'document'}.html',
        ),
      ),
      GlassListTileAction(
        label: l10n.actionExportMarkdown,
        icon: Icons.text_snippet_rounded,
        onTap: () => exportContentAsFile(
          markdownContent,
          '${markdownTitle ?? 'document'}.md',
        ),
      ),
      GlassListTileAction(
        label: l10n.actionExportPlainText,
        icon: Icons.notes_rounded,
        onTap: () => exportContentAsFile(
          markdownToPlainText(markdownContent),
          '${markdownTitle ?? 'document'}.txt',
        ),
      ),
    ] else if (onExportMarkdown != null)
      GlassListTileAction(
        label: l10n.actionExportMarkdown,
        icon: Icons.share_outlined,
        onTap: onExportMarkdown,
      ),
    if (onDelete != null)
      GlassListTileAction(
        label: l10n.delete,
        icon: Icons.delete_outline_rounded,
        onTap: onDelete,
        isDestructive: true,
      ),
  ];
}

/// Shows a rename dialog and returns the new name, or `null` if cancelled.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
  String title = 'Rename',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _RenameDialog(title: title, currentName: currentName),
  );
  return (result != null && result.isNotEmpty && result != currentName)
      ? result
      : null;
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.title, required this.currentName});

  final String title;
  final String currentName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.currentName.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return AlertDialog(
      backgroundColor: tokens.bgAlt,
      title: Text(widget.title, style: TextStyle(color: tokens.fgBright)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: tokens.fgBright),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).enterNewName,
          hintStyle: TextStyle(color: tokens.fgDim),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: tokens.borderFaint),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: tokens.accent),
          ),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).cancel,
            style: TextStyle(color: tokens.fgMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(
            AppLocalizations.of(context).rename,
            style: TextStyle(color: tokens.accent),
          ),
        ),
      ],
    );
  }
}

/// Exports content as markdown via the system share sheet.
Future<void> exportAsMarkdown({
  required String title,
  required String content,
}) async {
  final markdown = '# $title\n\n$content';
  await SharePlus.instance.share(ShareParams(text: markdown, subject: title));
}

/// Shows a "coming soon" snackbar for unimplemented actions.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature — ${AppLocalizations.of(context).comingSoon}'),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Opens the team selector dialog and optionally executes the full push sync.
///
/// When [ref] and [entityData] are provided, the full push flow is executed
/// (dialog → push → feedback snackbar). Otherwise just the dialog is shown
/// and the [TeamShareSelection] is returned for the caller to handle.
Future<TeamShareSelection?> openSyncDialog(
  BuildContext context, {
  required String entityType,
  required String entityId,
  WidgetRef? ref,
  Map<String, dynamic>? entityData,
}) {
  if (ref != null && entityData != null) {
    // Full push sync flow — returns null (result is communicated via snackbar).
    performPushSync(
      context: context,
      ref: ref,
      entityType: entityType,
      entityId: entityId,
      entityData: entityData,
    );
    return Future.value(null);
  }
  return showTeamSelectorDialog(
    context: context,
    entityType: entityType,
    entityId: entityId,
  );
}

/// Shows the color picker and persists the selection for [entityId].
Future<void> pickAndSaveColor(
  BuildContext context,
  WidgetRef ref,
  String entityId, {
  Color? currentColor,
}) async {
  final color = await showIconColorPicker(
    context: context,
    initialColor: currentColor,
  );
  if (color != null) {
    await ref
        .read(entityCustomizationProvider.notifier)
        .setColor(entityId, color);
  }
}

/// Shows the icon picker and persists the selection for [entityId].
Future<void> pickAndSaveIcon(
  BuildContext context,
  WidgetRef ref,
  String entityId, {
  int? currentCodePoint,
}) async {
  final codePoint = await showIconPicker(
    context: context,
    initialCodePoint: currentCodePoint,
  );
  if (codePoint != null) {
    await ref
        .read(entityCustomizationProvider.notifier)
        .setIcon(entityId, codePoint);
  }
}
