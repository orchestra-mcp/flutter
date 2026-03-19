import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';

/// Dialog shown when a deep link install request is received.
class DeepLinkInstallDialog extends StatelessWidget {
  const DeepLinkInstallDialog({
    super.key,
    required this.type,
    required this.slug,
    required this.onInstall,
    required this.onCancel,
  });

  final String type;
  final String slug;
  final VoidCallback onInstall;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return AlertDialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            type == 'pack'
                ? Icons.inventory_2_rounded
                : Icons.extension_rounded,
            color: tokens.accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Install ${type == 'pack' ? 'Pack' : 'Plugin'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tokens.fgBright,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Install "$slug" from the marketplace?',
            style: TextStyle(color: tokens.fgMuted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Text(
                  '\$ ',
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 13,
                    fontFamily: 'IBM Plex Mono',
                  ),
                ),
                Expanded(
                  child: Text(
                    'orchestra ${type == 'pack' ? 'pack' : 'plugin'} install $slug',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'IBM Plex Mono',
                      color: tokens.fgBright,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
        ),
        FilledButton(
          onPressed: onInstall,
          style: FilledButton.styleFrom(
            backgroundColor: tokens.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Install'),
        ),
      ],
    );
  }
}
