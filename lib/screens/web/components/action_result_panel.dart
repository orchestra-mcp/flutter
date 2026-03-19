import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/tunnel/tunnel_protocol.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// An animated panel that displays the streaming result of a tunnel action.
///
/// Features:
/// - Animated expand/collapse via [AnimatedSize].
/// - Streaming text display with a blinking cursor indicator.
/// - Copy-to-clipboard and dismiss buttons.
/// - Error state with retry.
/// - Themed with [GlassCard] and [ThemeTokens].
///
/// ```dart
/// ActionResultPanel(
///   response: tunnelResponse,
///   isStreaming: true,
///   onDismiss: () {},
///   onRetry: () {},
/// )
/// ```
class ActionResultPanel extends StatefulWidget {
  const ActionResultPanel({
    super.key,
    this.response,
    this.error,
    required this.isStreaming,
    required this.onDismiss,
    required this.onRetry,
  });

  /// The latest [TunnelResponse] (may be partial during streaming).
  final TunnelResponse? response;

  /// An error message to display instead of the response.
  final String? error;

  /// Whether the action is still streaming results.
  final bool isStreaming;

  /// Called when the user dismisses the panel.
  final VoidCallback onDismiss;

  /// Called when the user taps retry after an error.
  final VoidCallback onRetry;

  @override
  State<ActionResultPanel> createState() => _ActionResultPanelState();
}

class _ActionResultPanelState extends State<ActionResultPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final hasError =
        widget.error != null ||
        widget.response?.status == TunnelResponseStatus.failed;
    final resultText = widget.response?.result ?? '';
    final errorText =
        widget.error ?? widget.response?.error ?? 'An unknown error occurred.';
    final progress = widget.response?.progress;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            _PanelHeader(
              tokens: tokens,
              isStreaming: widget.isStreaming,
              hasError: hasError,
              progress: progress,
              onDismiss: widget.onDismiss,
            ),

            Divider(height: 1, color: tokens.border.withValues(alpha: 0.3)),

            // ── Body ────────────────────────────────────────────────────
            if (hasError)
              _ErrorBody(
                tokens: tokens,
                errorText: errorText,
                onRetry: widget.onRetry,
              )
            else if (resultText.isEmpty && widget.isStreaming)
              _LoadingBody(tokens: tokens)
            else
              _ResultBody(
                tokens: tokens,
                text: resultText,
                isStreaming: widget.isStreaming,
                cursorController: _cursorController,
              ),

            // ── Footer (copy / actions) ─────────────────────────────────
            if (!hasError && resultText.isNotEmpty)
              _PanelFooter(
                tokens: tokens,
                copied: _copied,
                onCopy: () => _copyToClipboard(resultText),
                onDismiss: widget.onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.tokens,
    required this.isStreaming,
    required this.hasError,
    required this.progress,
    required this.onDismiss,
  });

  final OrchestraColorTokens tokens;
  final bool isStreaming;
  final bool hasError;
  final double? progress;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final statusColor = hasError
        ? const Color(0xFFEF4444)
        : isStreaming
        ? tokens.accent
        : const Color(0xFF22C55E);
    final statusLabel = hasError
        ? 'Error'
        : isStreaming
        ? 'Streaming...'
        : 'Complete';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Status indicator dot.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),

          // Progress bar (only during streaming).
          if (isStreaming && progress != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: tokens.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
                ),
              ),
            ),
          ] else
            const Spacer(),

          // Dismiss X button.
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: tokens.fgDim),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading body ───────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Processing...',
            style: TextStyle(fontSize: 13, color: tokens.fgMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Result body (streaming text) ───────────────────────────────────────────

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.tokens,
    required this.text,
    required this.isStreaming,
    required this.cursorController,
  });

  final OrchestraColorTokens tokens;
  final String text;
  final bool isStreaming;
  final AnimationController cursorController;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SelectableText(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: tokens.fgBright,
                ),
              ),
            ),
            // Blinking cursor while streaming.
            if (isStreaming)
              FadeTransition(
                opacity: cursorController,
                child: Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.only(left: 2, bottom: 2),
                  color: tokens.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Error body ─────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.tokens,
    required this.errorText,
    required this.onRetry,
  });

  final OrchestraColorTokens tokens;
  final String errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorText,
                  style: TextStyle(fontSize: 13, color: tokens.fgMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, size: 16, color: tokens.accent),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: 12, color: tokens.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Footer ─────────────────────────────────────────────────────────────────

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({
    required this.tokens,
    required this.copied,
    required this.onCopy,
    required this.onDismiss,
  });

  final OrchestraColorTokens tokens;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: tokens.border.withValues(alpha: 0.3)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Copy button.
              TextButton.icon(
                onPressed: onCopy,
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 14,
                  color: copied ? const Color(0xFF22C55E) : tokens.fgDim,
                ),
                label: Text(
                  copied ? 'Copied' : 'Copy',
                  style: TextStyle(
                    fontSize: 12,
                    color: copied ? const Color(0xFF22C55E) : tokens.fgDim,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Dismiss button.
              TextButton.icon(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, size: 14, color: tokens.fgDim),
                label: Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 12, color: tokens.fgDim),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
