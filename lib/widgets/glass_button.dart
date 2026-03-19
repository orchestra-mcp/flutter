import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// A full-width accent-gradient button with optional loading and disabled states.
///
/// Uses [ThemeTokens.accent] → [ThemeTokens.accentAlt] as the gradient stops.
/// No hardcoded colour values.
///
/// ```dart
/// GlassButton(
///   label: 'Continue',
///   onPressed: _submit,
/// )
/// ```
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Optional leading icon shown to the left of [label].
  final IconData? icon;

  /// When `true` a [CircularProgressIndicator] replaces the label content.
  final bool isLoading;

  /// When `true` the button is rendered at 50 % opacity and [onPressed] is ignored.
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final effectiveCallback = (isDisabled || isLoading) ? null : onPressed;

    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: label,
      enabled: !isDisabled && !isLoading,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: effectiveCallback,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [tokens.accent, tokens.accentAlt],
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
