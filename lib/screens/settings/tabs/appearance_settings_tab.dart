import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/theme/orchestra_theme.dart';
import 'package:orchestra/core/theme/theme_provider.dart';

/// Appearance settings tab — theme picker only. Language is in Profile settings.
class AppearanceSettingsTab extends ConsumerWidget {
  const AppearanceSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final currentThemeId = ref.watch(themeIdProvider);
    final grouped = ref.watch(groupedThemesProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader(tokens, 'Theme'),
        const SizedBox(height: 12),
        for (final entry in grouped.entries) ...[
          _groupLabel(tokens, entry.key.name),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
            children: entry.value.map((theme) {
              final isSelected = theme.id == currentThemeId;
              return _ThemeCard(
                theme: theme,
                isSelected: isSelected,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(theme.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );

  Widget _groupLabel(OrchestraColorTokens tokens, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: tokens.fgDim,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final OrchestraTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: theme.glassColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? tokens.accent : tokens.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colour swatch row
            Row(
              children: [
                _swatch(theme.accent),
                const SizedBox(width: 3),
                _swatch(theme.bg),
                const SizedBox(width: 3),
                _swatch(theme.fgBright),
              ],
            ),
            const Spacer(),
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? tokens.accent : tokens.fgMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
