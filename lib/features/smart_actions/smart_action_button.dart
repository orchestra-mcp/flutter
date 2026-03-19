import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// A smart-action entry shown in the bottom sheet.
class SmartAction {
  const SmartAction({
    required this.label,
    required this.icon,
    this.description,
  });

  final String label;
  final IconData icon;
  final String? description;
}

/// Callback signature when a smart action is selected.
typedef SmartActionCallback =
    void Function(SmartAction action, String? customPrompt);

/// Builds localized default smart actions.
List<SmartAction> buildDefaultSmartActions(AppLocalizations l10n) => [
  SmartAction(
    label: l10n.smartActionSummarize,
    icon: Icons.summarize_rounded,
    description: l10n.smartActionSummarizeDesc,
  ),
  SmartAction(
    label: l10n.smartActionExplain,
    icon: Icons.lightbulb_rounded,
    description: l10n.smartActionExplainDesc,
  ),
  SmartAction(
    label: l10n.smartActionFix,
    icon: Icons.build_rounded,
    description: l10n.smartActionFixDesc,
  ),
  SmartAction(
    label: l10n.smartActionTranslate,
    icon: Icons.translate_rounded,
    description: l10n.smartActionTranslateDesc,
  ),
  SmartAction(
    label: l10n.smartActionCustomPrompt,
    icon: Icons.edit_note_rounded,
    description: l10n.smartActionCustomPromptDesc,
  ),
];

/// A reusable AI sparkle button that opens a bottom sheet with quick actions.
///
/// Place this button anywhere that supports AI-powered actions. On tap it
/// shows a bottom sheet with predefined quick-action options and a custom
/// prompt field.
///
/// ```dart
/// SmartActionButton(
///   onAction: (action, customPrompt) {
///     print('Selected: ${action.label}');
///   },
/// )
/// ```
class SmartActionButton extends StatelessWidget {
  const SmartActionButton({
    super.key,
    required this.onAction,
    this.actions,
    this.size = 40,
  });

  /// Called when the user selects an action from the sheet.
  final SmartActionCallback onAction;

  /// Actions to display. Defaults to [buildDefaultSmartActions] when null.
  final List<SmartAction>? actions;

  /// Icon button diameter. Defaults to 40.
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.aiSmartActions, // Semantics label - set dynamically in build
      button: true,
      child: GestureDetector(
        onTap: () => _showActionSheet(context),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tokens.accent, tokens.accentAlt],
            ),
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: tokens.accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (ctx) => _SmartActionSheet(
        tokens: tokens,
        actions:
            actions ?? buildDefaultSmartActions(AppLocalizations.of(context)),
        onAction: onAction,
      ),
    );
  }
}

// ── Bottom sheet content ────────────────────────────────────────────────────

class _SmartActionSheet extends StatefulWidget {
  const _SmartActionSheet({
    required this.tokens,
    required this.actions,
    required this.onAction,
  });

  final OrchestraColorTokens tokens;
  final List<SmartAction> actions;
  final SmartActionCallback onAction;

  @override
  State<_SmartActionSheet> createState() => _SmartActionSheetState();
}

class _SmartActionSheetState extends State<_SmartActionSheet> {
  final _customPromptCtrl = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customPromptCtrl.dispose();
    super.dispose();
  }

  void _selectAction(SmartAction action) {
    if (action.label == 'Custom prompt') {
      setState(() => _showCustomInput = true);
      return;
    }
    Navigator.of(context).pop();
    widget.onAction(action, null);
  }

  void _submitCustom() {
    final prompt = _customPromptCtrl.text.trim();
    if (prompt.isEmpty) return;
    Navigator.of(context).pop();
    widget.onAction(
      const SmartAction(label: 'Custom prompt', icon: Icons.edit_note_rounded),
      prompt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.fgDim.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).smartActions,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tokens.fgBright,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: tokens.border.withValues(alpha: 0.4)),

            // Actions list
            if (!_showCustomInput)
              ...widget.actions.map(
                (action) => _ActionTile(
                  action: action,
                  tokens: tokens,
                  onTap: () => _selectAction(action),
                ),
              ),

            // Custom prompt input
            if (_showCustomInput)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).customPromptTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.fgBright,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customPromptCtrl,
                      autofocus: true,
                      maxLines: 3,
                      style: TextStyle(color: tokens.fgBright, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        ).enterYourInstruction,
                        hintStyle: TextStyle(color: tokens.fgDim),
                        filled: true,
                        fillColor: tokens.bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: tokens.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: tokens.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _showCustomInput = false),
                          child: Text(
                            AppLocalizations.of(context).back,
                            style: TextStyle(color: tokens.fgMuted),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _submitCustom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context).run),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            SizedBox(height: bottomPadding + 8),
          ],
        ),
      ),
    );
  }
}

// ── Single action tile ──────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.tokens,
    required this.onTap,
  });

  final SmartAction action;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: action.label,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, size: 18, color: tokens.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.fgBright,
                      ),
                    ),
                    if (action.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.description!,
                        style: TextStyle(fontSize: 12, color: tokens.fgDim),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: tokens.fgDim),
            ],
          ),
        ),
      ),
    );
  }
}
