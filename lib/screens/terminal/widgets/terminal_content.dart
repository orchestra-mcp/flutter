import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/clipboard_image_helper.dart';
import 'package:orchestra/features/terminal/terminal_preferences_provider.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/screens/terminal/widgets/terminal_context_menu.dart';
import 'package:orchestra/screens/terminal/widgets/terminal_search_bar.dart';
import 'package:xterm/xterm.dart';

/// Renders the terminal output for a single session using xterm TerminalView.
///
/// Includes search overlay, right-click context menu, and keyboard shortcuts.
class TerminalContent extends ConsumerWidget {
  const TerminalContent({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final notifier = ref.read(terminalSessionsProvider.notifier);
    final backend = notifier.backends[sessionId];
    final controller = notifier.controllers[sessionId];
    final scrollController = notifier.scrollControllers[sessionId];
    final fontSize = ref.watch(terminalFontSizeProvider);
    final searchVisible = ref.watch(terminalSearchVisibleProvider);

    if (backend == null) {
      return Center(
        child: Text(
          'Session not found',
          style: TextStyle(color: tokens.fgDim),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: _buildShortcuts(ref, backend.terminal, controller),
      child: Focus(
        autofocus: true,
        // Use LayoutBuilder to ensure xterm has valid constraints before rendering.
        // Fixes visual glitches (circles/overlays) on first load on mobile.
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
              return const SizedBox.shrink();
            }
            return Stack(
              children: [
                TerminalView(
                  backend.terminal,
                  controller: controller,
                  scrollController: scrollController,
                  theme: _buildTerminalTheme(tokens),
                  autofocus: !searchVisible,
                  alwaysShowCursor: true,
                  cursorType: TerminalCursorType.block,
                  padding: const EdgeInsets.all(4),
                  textStyle: TerminalStyle(
                    fontSize: fontSize,
                    fontFamily: 'MesloLGS NF',
                    fontFamilyFallback: const [
                      'JetBrains Mono',
                      'SF Mono',
                      'Menlo',
                      'Consolas',
                      'monospace',
                    ],
                  ),
                  onSecondaryTapDown: (details, _) {
                    if (controller == null) return;
                    showTerminalContextMenu(
                      context: context,
                      position: details.globalPosition,
                      terminal: backend.terminal,
                      controller: controller,
                      onSearch: () {
                        ref
                            .read(terminalSearchVisibleProvider.notifier)
                            .show();
                      },
                    );
                  },
                ),
                if (searchVisible) TerminalSearchBar(sessionId: sessionId),
              ],
            );
          },
        ),
      ),
    );
  }

  static Map<ShortcutActivator, VoidCallback> _buildShortcuts(
    WidgetRef ref,
    Terminal terminal,
    TerminalController? controller,
  ) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return {
      // Cmd/Ctrl + V → paste (check image clipboard first, then text)
      SingleActivator(LogicalKeyboardKey.keyV, meta: isMac, control: !isMac): () {
        _pasteWithImageSupport(terminal);
      },

      // Cmd/Ctrl + F → toggle search
      SingleActivator(LogicalKeyboardKey.keyF, meta: isMac, control: !isMac): () {
        ref.read(terminalSearchVisibleProvider.notifier).toggle();
      },

      // Cmd/Ctrl + K → clear terminal
      SingleActivator(LogicalKeyboardKey.keyK, meta: isMac, control: !isMac): () {
        terminal.write('\x1B[2J\x1B[H');
      },

      // Cmd/Ctrl + = → increase font size
      SingleActivator(LogicalKeyboardKey.equal, meta: isMac, control: !isMac): () {
        ref.read(terminalFontSizeProvider.notifier).increase();
      },

      // Cmd/Ctrl + - → decrease font size
      SingleActivator(LogicalKeyboardKey.minus, meta: isMac, control: !isMac): () {
        ref.read(terminalFontSizeProvider.notifier).decrease();
      },

      // Cmd/Ctrl + 0 → reset font size
      SingleActivator(LogicalKeyboardKey.digit0, meta: isMac, control: !isMac): () {
        ref.read(terminalFontSizeProvider.notifier).reset();
      },

      // Escape → close search
      const SingleActivator(LogicalKeyboardKey.escape): () {
        ref.read(terminalSearchVisibleProvider.notifier).hide();
      },
    };
  }

  static Future<void> _pasteWithImageSupport(Terminal terminal) async {
    final imagePath = await getClipboardImagePath();
    if (imagePath != null) {
      terminal.paste(imagePath);
      return;
    }
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      terminal.paste(data.text!);
    }
  }

  static TerminalTheme _buildTerminalTheme(OrchestraColorTokens tokens) {
    final bg = Color.lerp(tokens.bg, Colors.black, 0.35)!;
    return TerminalTheme(
      cursor: tokens.accent,
      selection: tokens.accent.withValues(alpha: 0.3),
      foreground: tokens.fgBright,
      background: bg,
      black: const Color(0xFF1D1F21),
      red: const Color(0xFFCC6666),
      green: const Color(0xFFB5BD68),
      yellow: const Color(0xFFF0C674),
      blue: const Color(0xFF81A2BE),
      magenta: const Color(0xFFB294BB),
      cyan: const Color(0xFF8ABEB7),
      white: const Color(0xFFC5C8C6),
      brightBlack: const Color(0xFF666666),
      brightRed: const Color(0xFFD54E53),
      brightGreen: const Color(0xFFB9CA4A),
      brightYellow: const Color(0xFFE7C547),
      brightBlue: const Color(0xFF7AA6DA),
      brightMagenta: const Color(0xFFC397D8),
      brightCyan: const Color(0xFF70C0B1),
      brightWhite: const Color(0xFFEAEAEA),
      searchHitBackground: tokens.accent.withValues(alpha: 0.2),
      searchHitBackgroundCurrent: tokens.accent.withValues(alpha: 0.4),
      searchHitForeground: tokens.fgBright,
    );
  }
}
