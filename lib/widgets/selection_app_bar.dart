import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// A reusable selection-mode header that replaces the screen's normal app bar.
///
/// Shows the count of selected items and actions: clear, delete, select all.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    this.onSelectAll,
    this.onDelete,
    this.onPin,
    this.onExport,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onExport;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return AppBar(
      backgroundColor: tokens.accent.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.close, color: tokens.fgBright),
        onPressed: onClear,
      ),
      title: Text(
        l10n.selectedCount(selectedCount),
        style: TextStyle(
          color: tokens.fgBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (onSelectAll != null)
          IconButton(
            icon: Icon(Icons.select_all_rounded, color: tokens.fgMuted),
            tooltip: l10n.actionSelect,
            onPressed: onSelectAll,
          ),
        if (onPin != null)
          IconButton(
            icon: Icon(Icons.push_pin_outlined, color: tokens.fgMuted),
            tooltip: l10n.pin,
            onPressed: onPin,
          ),
        if (onExport != null)
          IconButton(
            icon: Icon(Icons.share_outlined, color: tokens.fgMuted),
            tooltip: l10n.export,
            onPressed: onExport,
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFDC2626)),
            tooltip: l10n.delete,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
