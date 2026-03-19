import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Result returned when the user creates a new Claude session.
@immutable
class ClaudeSessionResult {
  const ClaudeSessionResult({required this.model});

  final String model;
}

/// Available Claude model identifiers.
const _claudeModels = <String>[
  'claude-haiku-4-5',
  'claude-sonnet-4-6',
  'claude-opus-4-6',
];

/// Dialog that lets the user select a Claude model for a new session.
///
/// Returns a [ClaudeSessionResult] when submitted, or `null` if cancelled.
///
/// ```dart
/// final result = await showDialog<ClaudeSessionResult>(
///   context: context,
///   builder: (_) => const ClaudeSessionDialog(),
/// );
/// ```
class ClaudeSessionDialog extends StatefulWidget {
  const ClaudeSessionDialog({super.key});

  @override
  State<ClaudeSessionDialog> createState() => _ClaudeSessionDialogState();
}

class _ClaudeSessionDialogState extends State<ClaudeSessionDialog> {
  String _selectedModel = 'claude-sonnet-4-6';

  void _submit() {
    Navigator.of(context).pop(ClaudeSessionResult(model: _selectedModel));
  }

  void _cancel() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        l10n.newClaudeSession,
        style: TextStyle(
          color: tokens.fgBright,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.model,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              onChanged: (v) {
                if (v != null) setState(() => _selectedModel = v);
              },
              items: _claudeModels
                  .map(
                    (model) => DropdownMenuItem<String>(
                      value: model,
                      child: Text(
                        model,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              dropdownColor: tokens.bgAlt,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.accent, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              icon: Icon(
                Icons.expand_more_rounded,
                color: tokens.fgDim,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: Text(l10n.cancel, style: TextStyle(color: tokens.fgMuted)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: tokens.accent),
          child: Text(
            l10n.create,
            style: TextStyle(color: tokens.fgBright),
          ),
        ),
      ],
    );
  }
}
