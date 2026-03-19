import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// 12-colour palette drawn from the Orchestra design system.
const List<Color> _kPaletteColors = [
  Color(0xFF8B5CF6), // Orchestra violet
  Color(0xFF6366F1), // Indigo
  Color(0xFF38BDF8), // Sky blue
  Color(0xFF4ADE80), // Green
  Color(0xFFFABD2F), // Yellow
  Color(0xFFF97316), // Orange
  Color(0xFFDC2626), // Red
  Color(0xFFEC4899), // Pink
  Color(0xFF14B8A6), // Teal
  Color(0xFFA78BFA), // Lavender
  Color(0xFF818CF8), // Periwinkle
  Color(0xFF94A3B8), // Slate
];

/// A grid of colour swatches.
///
/// Calls [onColorSelected] when the user taps a swatch. The currently
/// [selectedColor] is highlighted with an accent border + check mark.
class IconColorPicker extends StatefulWidget {
  const IconColorPicker({
    super.key,
    this.selectedColor,
    required this.onColorSelected,
  });

  /// The currently active colour, if any.
  final Color? selectedColor;

  /// Invoked with the new [Color] when the user taps a swatch.
  final ValueChanged<Color> onColorSelected;

  @override
  State<IconColorPicker> createState() => _IconColorPickerState();
}

class _IconColorPickerState extends State<IconColorPicker> {
  late Color? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedColor;
  }

  void _pick(Color color) {
    setState(() => _selected = color);
    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Semantics(
      label: AppLocalizations.of(context).colorPickerSemantics,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: _kPaletteColors.length,
        itemBuilder: (context, index) {
          final color = _kPaletteColors[index];
          final isActive = _selected == color;
          return Semantics(
            label: AppLocalizations.of(context).colorPickerSwatchSemantics,
            selected: isActive,
            button: true,
            child: GestureDetector(
              onTap: () => _pick(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: tokens.fgBright, width: 2.5)
                      : Border.all(color: Colors.transparent, width: 2.5),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.50),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isActive
                    ? Icon(
                        Icons.check_rounded,
                        color: tokens.fgBright,
                        size: 16,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shows [IconColorPicker] as a glass-styled bottom sheet.
///
/// Returns the selected [Color], or `null` if the sheet is dismissed without
/// a selection.
Future<Color?> showIconColorPicker({
  required BuildContext context,
  Color? initialColor,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final tokens = ThemeTokens.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tokens.bgAlt.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderFaint, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: tokens.fgDim.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).chooseColour,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              IconColorPicker(
                selectedColor: initialColor,
                onColorSelected: (color) => Navigator.of(ctx).pop(color),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
