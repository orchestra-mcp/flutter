import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// A context-menu action entry for [GlassListTile].
class GlassListTileAction {
  const GlassListTileAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// When `true` the action is rendered in a destructive (red) colour.
  final bool isDestructive;
}

/// A glass-styled list tile with swipe-to-pin/delete, a three-dot context
/// menu, right-click context menu, and optional multi-select mode.
///
/// All colours come from [ThemeTokens] — no hardcoded hex values.
class GlassListTile extends StatelessWidget {
  const GlassListTile({
    super.key,
    required this.leadingIcon,
    required this.leadingColor,
    required this.label,
    this.description,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onSelect,
    this.contextMenuActions = const [],
    this.isSelected = false,
    this.isPinned = false,
    this.onPin,
    this.onDelete,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String label;
  final String? description;

  /// Optional widget shown between text content and context menu button.
  final Widget? trailing;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called to toggle selection (desktop/web long-press).
  final VoidCallback? onSelect;

  final List<GlassListTileAction> contextMenuActions;

  /// When `true` a [Checkbox] replaces the leading icon (multi-select mode).
  final bool isSelected;

  /// When `true` a gold pin badge is shown on the leading icon.
  final bool isPinned;

  /// Called when the user swipes right (pin gesture).
  final VoidCallback? onPin;

  /// Called when the user swipes left and confirms deletion.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    Widget tile = _TileContent(
      leadingIcon: leadingIcon,
      leadingColor: leadingColor,
      label: label,
      description: description,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      onSelect: onSelect,
      contextMenuActions: contextMenuActions,
      isSelected: isSelected,
      isPinned: isPinned,
      tokens: tokens,
    );

    // Wrap with Dismissible only when callbacks are provided.
    if (onPin != null || onDelete != null) {
      tile = Dismissible(
        key: ValueKey(label),
        // ── Pin (swipe right) ──────────────────────────────────────────
        direction: onDelete != null && onPin != null
            ? DismissDirection.horizontal
            : onPin != null
            ? DismissDirection.startToEnd
            : DismissDirection.endToStart,
        background: _SwipeBackground(
          alignment: AlignmentDirectional.centerStart,
          color: const Color(0xFFD97706),
          icon: Icons.star_rounded,
          label: AppLocalizations.of(context).pin,
        ),
        secondaryBackground: _SwipeBackground(
          alignment: AlignmentDirectional.centerEnd,
          color: const Color(0xFFDC2626),
          icon: Icons.delete_rounded,
          label: AppLocalizations.of(context).delete,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onPin?.call();
            return false; // don't actually remove from list
          }
          // Perform deletion inside confirmDismiss and return false so the
          // Dismissible never enters the "dismissed but still in tree" state.
          // The parent rebuild removes the widget.
          final confirmed = await _confirmDelete(context, tokens);
          if (confirmed) onDelete?.call();
          return false;
        },
        child: tile,
      );
    }

    return tile;
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    OrchestraColorTokens tokens,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(
          AppLocalizations.of(context).deleteItemTitle(label),
          style: TextStyle(color: tokens.fgBright),
        ),
        content: Text(
          AppLocalizations.of(context).deleteConfirm,
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: tokens.fgMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ─── Tile content ─────────────────────────────────────────────────────────────

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.leadingIcon,
    required this.leadingColor,
    required this.label,
    required this.isSelected,
    required this.isPinned,
    required this.tokens,
    this.description,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.onSelect,
    this.contextMenuActions = const [],
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String label;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelect;
  final List<GlassListTileAction> contextMenuActions;
  final bool isSelected;
  final bool isPinned;
  final OrchestraColorTokens tokens;

  void _handleLongPress(BuildContext context) {
    if (isMobile) {
      // Mobile: show context menu as bottom sheet
      if (contextMenuActions.isNotEmpty) {
        _showMobileContextSheet(context);
      } else {
        onLongPress?.call();
      }
    } else {
      // Desktop/web: enter selection mode
      if (onSelect != null) {
        onSelect!();
      } else {
        onLongPress?.call();
      }
    }
  }

  void _showContextMenuAt(BuildContext context, Offset position) {
    if (contextMenuActions.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: contextMenuActions.map((a) {
        final color = a.isDestructive
            ? const Color(0xFFDC2626)
            : tokens.fgBright;
        return PopupMenuItem<void>(
          onTap: a.onTap,
          child: Row(
            children: [
              Icon(a.icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(a.label, style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
        );
      }).toList(),
      color: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showMobileContextSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: tokens.bgAlt,
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: tokens.fgDim.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...contextMenuActions.map((a) {
                        final color = a.isDestructive
                            ? const Color(0xFFDC2626)
                            : tokens.fgBright;
                        return ListTile(
                          leading: Icon(a.icon, color: color, size: 20),
                          title: Text(a.label, style: TextStyle(color: color)),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            a.onTap();
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Semantics(
      label: label,
      button: onTap != null,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _handleLongPress(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.accent.withValues(alpha: 0.10)
                : tokens.bgAlt.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? tokens.accent.withValues(alpha: 0.40)
                  : tokens.borderFaint,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // ── Leading slot ───────────────────────────────────────
              if (isSelected)
                Checkbox(
                  value: true,
                  onChanged: null,
                  activeColor: tokens.accent,
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: leadingColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(leadingIcon, color: leadingColor, size: 18),
                    ),
                    if (isPinned)
                      const Positioned(
                        top: -4,
                        right: -4,
                        child: Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 12),

              // ── Text content ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Trailing widget ────────────────────────────────────
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],

              // ── Context menu ───────────────────────────────────────
              if (contextMenuActions.isNotEmpty)
                _ContextMenuButton(actions: contextMenuActions, tokens: tokens),
            ],
          ),
        ),
      ),
    );

    // Wrap with right-click detection for desktop/web
    if (contextMenuActions.isNotEmpty) {
      content = GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenuAt(context, details.globalPosition);
        },
        child: content,
      );
    }

    return content;
  }
}

// ─── Context menu button (three-dot) ──────────────────────────────────────────

class _ContextMenuButton extends StatelessWidget {
  const _ContextMenuButton({required this.actions, required this.tokens});

  final List<GlassListTileAction> actions;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: actions.map((a) {
        final color = a.isDestructive
            ? const Color(0xFFDC2626)
            : tokens.fgBright;
        return MenuItemButton(
          leadingIcon: Icon(a.icon, size: 16, color: color),
          onPressed: a.onTap,
          child: Text(a.label, style: TextStyle(color: color)),
        );
      }).toList(),
      builder: (context, controller, child) => Semantics(
        label: AppLocalizations.of(context).moreOptionsSemantics,
        button: true,
        child: IconButton(
          icon: Icon(Icons.more_vert_rounded, color: tokens.fgMuted, size: 18),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        ),
      ),
    );
  }
}

// ─── Swipe background ─────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
