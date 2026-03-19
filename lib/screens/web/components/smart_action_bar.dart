import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/core/tunnel/tunnel_provider.dart';
import 'package:orchestra/screens/web/components/action_result_panel.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ─── Action definitions ─────────────────────────────────────────────────────

class _ActionDef {
  const _ActionDef({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
  });
  final TunnelActionType type;
  final String label;
  final IconData icon;
  final Color Function(OrchestraColorTokens tokens) color;
}

List<_ActionDef> _buildActions(AppLocalizations l10n) => [
  _ActionDef(
    type: TunnelActionType.summarize,
    label: l10n.smartActionSummarize,
    icon: Icons.summarize_rounded,
    color: (t) => t.accent,
  ),
  _ActionDef(
    type: TunnelActionType.explain,
    label: l10n.smartActionExplain,
    icon: Icons.lightbulb_rounded,
    color: (t) => t.accentAlt,
  ),
  _ActionDef(
    type: TunnelActionType.fix,
    label: l10n.smartActionFix,
    icon: Icons.build_rounded,
    color: (t) => t.accent,
  ),
  _ActionDef(
    type: TunnelActionType.translate,
    label: l10n.smartActionTranslate,
    icon: Icons.translate_rounded,
    color: (t) => t.accentAlt,
  ),
  _ActionDef(
    type: TunnelActionType.custom,
    label: l10n.smartActionCustom,
    icon: Icons.edit_note_rounded,
    color: (t) => t.accent,
  ),
];

// ─── Smart Action Bar ───────────────────────────────────────────────────────

/// A floating action bar for the web dashboard that provides quick access
/// to AI-powered smart actions (Summarize, Explain, Fix, Translate, Custom).
///
/// Clicking a button dispatches the action through the tunnel and shows
/// the streaming result in an expanding [ActionResultPanel] below.
///
/// ```dart
/// SmartActionBar(
///   contextText: selectedText,
/// )
/// ```
class SmartActionBar extends ConsumerStatefulWidget {
  const SmartActionBar({
    super.key,
    required this.contextText,
    this.onActionStarted,
    this.onActionCompleted,
  });

  /// The text context that actions will operate on (e.g. selected code,
  /// a document body, or a feature description).
  final String contextText;

  /// Optional callback invoked when an action dispatch begins.
  final ValueChanged<TunnelActionType>? onActionStarted;

  /// Optional callback invoked when an action completes or fails.
  final ValueChanged<TunnelResponse>? onActionCompleted;

  @override
  ConsumerState<SmartActionBar> createState() => _SmartActionBarState();
}

class _SmartActionBarState extends ConsumerState<SmartActionBar>
    with SingleTickerProviderStateMixin {
  TunnelActionType? _activeAction;
  TunnelResponse? _latestResponse;
  String? _errorMessage;
  bool _showResult = false;
  bool _showCustomInput = false;
  StreamSubscription<TunnelResponse>? _responseSub;

  final _customPromptController = TextEditingController();

  late final AnimationController _barAnimController;
  late final Animation<double> _barScaleAnimation;

  @override
  void initState() {
    super.initState();
    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _barScaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _barAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _responseSub?.cancel();
    _customPromptController.dispose();
    _barAnimController.dispose();
    super.dispose();
  }

  // ── Dispatch ────────────────────────────────────────────────────────────

  void _dispatchAction(TunnelActionType type, {String? customPrompt}) {
    _responseSub?.cancel();

    setState(() {
      _activeAction = type;
      _latestResponse = null;
      _errorMessage = null;
      _showResult = true;
      _showCustomInput = false;
    });

    widget.onActionStarted?.call(type);

    final parameters = <String, dynamic>{};
    if (type == TunnelActionType.custom && customPrompt != null) {
      parameters['custom_prompt'] = customPrompt;
    }
    if (type == TunnelActionType.translate) {
      parameters['language'] = 'English'; // Default; UI could make this configurable.
    }

    final action = TunnelAction(
      actionType: type,
      context: widget.contextText,
      parameters: parameters,
    );

    final actionsNotifier = ref.read(tunnelActionsProvider.notifier);
    final stream = actionsNotifier.dispatch(action);

    _responseSub = stream.listen(
      (response) {
        if (!mounted) return;
        setState(() => _latestResponse = response);

        if (response.isTerminal) {
          widget.onActionCompleted?.call(response);
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.toString();
          _activeAction = null;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _activeAction = null);
      },
    );
  }

  void _handleCustomSubmit() {
    final prompt = _customPromptController.text.trim();
    if (prompt.isEmpty) return;
    _customPromptController.clear();
    _dispatchAction(TunnelActionType.custom, customPrompt: prompt);
  }

  void _dismissResult() {
    _responseSub?.cancel();
    setState(() {
      _showResult = false;
      _latestResponse = null;
      _errorMessage = null;
      _activeAction = null;
    });
    ref.read(tunnelActionsProvider.notifier).clearResponse();
  }

  void _retryLastAction() {
    if (_activeAction == null) return;
    _dispatchAction(_activeAction!);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = _buildActions(l10n);
    final isDispatching = _activeAction != null &&
        (_latestResponse == null || !_latestResponse!.isTerminal);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons row.
        ScaleTransition(
          scale: _barScaleAnimation,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sparkle indicator.
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tokens.accent, tokens.accentAlt],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Action buttons.
                    for (final action in actions) ...[
                      _SmartActionChip(
                        label: action.label,
                        icon: action.icon,
                        color: action.color(tokens),
                        tokens: tokens,
                        isActive: _activeAction == action.type && isDispatching,
                        onTap: isDispatching
                            ? null
                            : () {
                                if (action.type == TunnelActionType.custom) {
                                  setState(
                                      () => _showCustomInput = !_showCustomInput);
                                } else {
                                  _dispatchAction(action.type);
                                }
                              },
                      ),
                      if (action != actions.last) const SizedBox(width: 6),
                    ],
                  ],
                ),

                // Custom prompt input (inline).
                if (_showCustomInput) ...[
                  const SizedBox(height: 10),
                  _CustomPromptInput(
                    controller: _customPromptController,
                    tokens: tokens,
                    onSubmit: _handleCustomSubmit,
                    onCancel: () => setState(() => _showCustomInput = false),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Result panel.
        if (_showResult)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ActionResultPanel(
              response: _latestResponse,
              error: _errorMessage,
              isStreaming: isDispatching,
              onDismiss: _dismissResult,
              onRetry: _retryLastAction,
            ),
          ),
      ],
    );
  }
}

// ─── Action chip button ─────────────────────────────────────────────────────

class _SmartActionChip extends StatefulWidget {
  const _SmartActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.tokens,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_SmartActionChip> createState() => _SmartActionChipState();
}

class _SmartActionChipState extends State<_SmartActionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;

    return Semantics(
      label: widget.label,
      button: true,
      enabled: isEnabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.color.withValues(alpha: 0.20)
                  : _hovered
                      ? widget.tokens.accentSurface
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isActive
                    ? widget.color.withValues(alpha: 0.40)
                    : _hovered
                        ? widget.tokens.border
                        : Colors.transparent,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isActive)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(widget.icon, size: 14, color: widget.color),
                  ),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.isActive
                        ? widget.color
                        : widget.tokens.fgMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Custom prompt inline input ─────────────────────────────────────────────

class _CustomPromptInput extends StatelessWidget {
  const _CustomPromptInput({
    required this.controller,
    required this.tokens,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final OrchestraColorTokens tokens;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).enterCustomInstruction,
              hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
              filled: true,
              fillColor: tokens.bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
                borderSide: BorderSide(color: tokens.accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _MiniButton(
          icon: Icons.send_rounded,
          color: tokens.accent,
          onTap: onSubmit,
          tooltip: AppLocalizations.of(context).run,
        ),
        const SizedBox(width: 4),
        _MiniButton(
          icon: Icons.close_rounded,
          color: tokens.fgDim,
          onTap: onCancel,
          tooltip: AppLocalizations.of(context).cancel,
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
