import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Shows a glass-styled modal bottom sheet.
///
/// The sheet renders a drag-handle pill at the top followed by a [GlassCard]
/// wrapping [child]. Pass `fullHeight: true` to expand the sheet to
/// `MediaQuery.sizeOf(context).height - 48`.
///
/// ```dart
/// showGlassSheet(
///   context: context,
///   child: MySheetContent(),
/// );
/// ```
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required Widget child,
  bool fullHeight = false,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) => _GlassSheetContent(fullHeight: fullHeight, child: child),
  );
}

class _GlassSheetContent extends StatelessWidget {
  const _GlassSheetContent({required this.child, required this.fullHeight});

  final Widget child;
  final bool fullHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final sheetHeight = fullHeight ? screenHeight - 48.0 : null;

    return Padding(
      // Keep the sheet above the keyboard when it appears.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: fullHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Sheet body ────────────────────────────────────────────────
          if (fullHeight)
            Expanded(
              child: GlassCard(
                borderRadius: 20,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + bottomPadding,
                ),
                child: child,
              ),
            )
          else
            SizedBox(
              height: sheetHeight,
              child: GlassCard(
                borderRadius: 20,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + bottomPadding,
                ),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}
