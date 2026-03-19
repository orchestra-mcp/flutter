import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// Frosted-glass top header bar.
///
/// Uses a [BackdropFilter] blur to create the frosted glass look.
/// Colours are sourced exclusively from [ThemeTokens] — no hardcoded hex values.
class GlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlassHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.height = 60.0,
  });

  /// Primary title text displayed in the centre of the header.
  final String title;

  /// Optional widget anchored to the left side of the header.
  final Widget? leading;

  /// Optional widget(s) anchored to the right side of the header.
  final Widget? trailing;

  /// Total height of the bar (not including the top safe-area inset).
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tokens.bg.withValues(alpha: 0.72),
                tokens.bg.withValues(alpha: 0.56),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Leading slot
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ] else
                  const SizedBox(width: 4),

                // Title (expands to fill remaining space)
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Trailing slot
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
