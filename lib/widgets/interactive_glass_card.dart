import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';

/// Interactive wrapper around [GlassCard] for grid screens (Agents, Projects).
///
/// Adds: right-click context menu, long-press selection (desktop) or
/// context sheet (mobile), selection highlight, and pin badge.
class InteractiveGlassCard extends StatelessWidget {
  const InteractiveGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.onSelect,
    this.contextMenuActions = const [],
    this.isSelected = false,
    this.isPinned = false,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final List<GlassListTileAction> contextMenuActions;
  final bool isSelected;
  final bool isPinned;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  void _handleLongPress(BuildContext context) {
    if (isMobile) {
      if (contextMenuActions.isNotEmpty) {
        _showMobileContextSheet(context);
      }
    } else {
      onSelect?.call();
    }
  }

  void _showContextMenuAt(BuildContext context, Offset position) {
    if (contextMenuActions.isEmpty) return;
    final tokens = ThemeTokens.of(context);
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
    final tokens = ThemeTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        GlassCard(
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          onTap: onTap,
          child: child,
        ),
        // Selection highlight overlay
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  color: tokens.accent.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        // Selection check badge
        if (isSelected)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: tokens.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ),
        // Pin badge
        if (isPinned && !isSelected)
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(
              Icons.push_pin_rounded,
              size: 14,
              color: Color(0xFFFBBF24),
            ),
          ),
      ],
    );

    // Wrap with gesture detectors
    content = GestureDetector(
      onLongPress: () => _handleLongPress(context),
      onSecondaryTapUp: (details) {
        _showContextMenuAt(context, details.globalPosition);
      },
      child: content,
    );

    return content;
  }
}
