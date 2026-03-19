import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// Reusable search bar for entity list screens (mobile & desktop sidebar).
///
/// Glass-themed styling consistent with _NotesSidebar search. Use [compact]
/// for sidebar (32px) or default (36px) for mobile screens.
class EntitySearchBar extends StatelessWidget {
  const EntitySearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.tokens,
    this.compact = false,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final OrchestraColorTokens? tokens;

  /// If true, uses 32px height (sidebar). Otherwise 36px (mobile).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = tokens ?? ThemeTokens.of(context);
    final height = compact ? 32.0 : 36.0;
    final fontSize = compact ? 13.0 : 14.0;

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: t.fgBright, fontSize: fontSize),
        cursorColor: t.accent,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: t.fgDim, fontSize: fontSize),
          prefixIcon:
              Icon(Icons.search_rounded, size: 16, color: t.fgDim),
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
          suffixIcon: controller != null
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller!,
                  builder: (_, value, __) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 14, color: t.fgDim),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        controller!.clear();
                        onChanged('');
                      },
                    );
                  },
                )
              : null,
          filled: true,
          fillColor: t.bg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.borderFaint),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.borderFaint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: t.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}
