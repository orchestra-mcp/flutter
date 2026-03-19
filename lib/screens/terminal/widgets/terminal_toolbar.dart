import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/terminal_preferences_provider.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Compact toolbar above the terminal content area.
///
/// Provides search toggle, font size controls, copy/paste, clear buffer,
/// and kill process actions.
class TerminalToolbar extends ConsumerWidget {
  const TerminalToolbar({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final fontSize = ref.watch(terminalFontSizeProvider);
    final searchVisible = ref.watch(terminalSearchVisibleProvider);
    final notifier = ref.read(terminalSessionsProvider.notifier);
    final controller = notifier.controllers[sessionId];
    final backend = notifier.backends[sessionId];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // ── Search toggle ──────────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.search_rounded,
            tooltip: l10n.terminalToolbarSearch(_cmdKey),
            isActive: searchVisible,
            tokens: tokens,
            onPressed: () {
              ref.read(terminalSearchVisibleProvider.notifier).toggle();
            },
          ),

          _divider(tokens),

          // ── Font size controls ─────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.remove_rounded,
            tooltip: l10n.terminalToolbarDecreaseFontSize,
            tokens: tokens,
            onPressed: () {
              ref.read(terminalFontSizeProvider.notifier).decrease();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () {
                ref.read(terminalFontSizeProvider.notifier).reset();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${fontSize.toInt()}',
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          _ToolbarButton(
            icon: Icons.add_rounded,
            tooltip: l10n.terminalToolbarIncreaseFontSize,
            tokens: tokens,
            onPressed: () {
              ref.read(terminalFontSizeProvider.notifier).increase();
            },
          ),

          _divider(tokens),

          // ── Copy ───────────────────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.copy_rounded,
            tooltip: l10n.terminalToolbarCopy(_cmdKey),
            tokens: tokens,
            onPressed: () {
              if (controller == null || backend == null) return;
              final selection = controller.selection;
              if (selection == null) return;
              final text = backend.terminal.buffer.getText(selection);
              if (text.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: text));
              }
            },
          ),

          // ── Paste ──────────────────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.paste_rounded,
            tooltip: l10n.terminalToolbarPaste(_cmdKey),
            tokens: tokens,
            onPressed: () async {
              if (backend == null) return;
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && data!.text!.isNotEmpty) {
                backend.terminal.paste(data.text!);
              }
            },
          ),

          _divider(tokens),

          // ── Clear buffer ───────────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.clear_all_rounded,
            tooltip: l10n.terminalToolbarClear,
            tokens: tokens,
            onPressed: () {
              if (backend == null) return;
              // Write clear-screen ANSI escape: ESC[2J + ESC[H
              backend.terminal.write('\x1B[2J\x1B[H');
            },
          ),

          // ── Kill / Send SIGINT ─────────────────────────────────────────
          _ToolbarButton(
            icon: Icons.stop_circle_outlined,
            tooltip: l10n.terminalToolbarSendInterrupt,
            tokens: tokens,
            onPressed: () {
              if (backend == null) return;
              // Send ETX (Ctrl+C) to the terminal process
              backend.terminal.textInput('\x03');
            },
          ),

          const Spacer(),
        ],
      ),
    );
  }

  static Widget _divider(OrchestraColorTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(width: 1, color: tokens.border),
    );
  }

  static String get _cmdKey {
    return defaultTargetPlatform == TargetPlatform.macOS ? '\u2318' : 'Ctrl+';
  }
}

// ── Toolbar button ──────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.tokens,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final OrchestraColorTokens tokens;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: isActive ? tokens.accent : tokens.fgMuted,
        ),
        padding: EdgeInsets.zero,
        splashRadius: 14,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isActive
              ? tokens.accent.withValues(alpha: 0.15)
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
