import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/terminal_preferences_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:xterm/xterm.dart';

/// Floating search bar overlaid on the terminal (top-right, VS Code style).
///
/// Scans the terminal buffer for text matches and highlights them via
/// [TerminalController.highlight]. Supports case sensitivity and regex modes.
class TerminalSearchBar extends ConsumerStatefulWidget {
  const TerminalSearchBar({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<TerminalSearchBar> createState() => _TerminalSearchBarState();
}

class _TerminalSearchBarState extends ConsumerState<TerminalSearchBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  bool _caseSensitive = false;
  bool _useRegex = false;
  int _currentIndex = 0;
  List<_SearchMatch> _matches = [];
  List<TerminalHighlight> _highlights = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _clearHighlights();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearHighlights() {
    for (final h in _highlights) {
      h.dispose();
    }
    _highlights = [];
  }

  void _search(String query) {
    _clearHighlights();
    _matches = [];
    _currentIndex = 0;

    if (query.isEmpty) {
      setState(() {});
      return;
    }

    final notifier = ref.read(terminalSessionsProvider.notifier);
    final backend = notifier.backends[widget.sessionId];
    final controller = notifier.controllers[widget.sessionId];
    if (backend == null || controller == null) return;

    final buffer = backend.terminal.buffer;
    final totalLines = buffer.height;

    Pattern pattern;
    if (_useRegex) {
      try {
        pattern = RegExp(query, caseSensitive: _caseSensitive);
      } catch (_) {
        // Invalid regex — treat as literal
        pattern = _caseSensitive ? query : RegExp(RegExp.escape(query), caseSensitive: false);
      }
    } else {
      pattern = _caseSensitive ? query : RegExp(RegExp.escape(query), caseSensitive: false);
    }

    for (var y = 0; y < totalLines; y++) {
      final lineText = buffer.lines[y].toString();
      final lineMatches = pattern.allMatches(lineText);
      for (final m in lineMatches) {
        _matches.add(_SearchMatch(y: y, startX: m.start, endX: m.end));
      }
    }

    // Highlight all matches
    final tokens = ThemeTokens.of(context);
    for (var i = 0; i < _matches.length; i++) {
      final m = _matches[i];
      try {
        final highlight = controller.highlight(
          p1: buffer.createAnchor(m.startX, m.y),
          p2: buffer.createAnchor(m.endX, m.y),
          color: i == _currentIndex
              ? tokens.accent.withValues(alpha: 0.5)
              : tokens.accent.withValues(alpha: 0.2),
        );
        _highlights.add(highlight);
      } catch (_) {
        // Anchor creation may fail for lines no longer in buffer
      }
    }

    setState(() {});
  }

  void _navigateMatch(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + delta) % _matches.length;
      if (_currentIndex < 0) _currentIndex = _matches.length - 1;
    });
    // Re-highlight with updated current
    _search(_textController.text);

    // Scroll to current match
    final notifier = ref.read(terminalSessionsProvider.notifier);
    final scrollCtrl = notifier.scrollControllers[widget.sessionId];
    if (scrollCtrl != null && scrollCtrl.hasClients && _matches.isNotEmpty) {
      final match = _matches[_currentIndex];
      final backend = notifier.backends[widget.sessionId];
      if (backend != null) {
        final viewHeight = backend.terminal.viewHeight;
        final scrollBack = backend.terminal.buffer.height - viewHeight;
        if (scrollBack > 0) {
          final targetOffset = (match.y / scrollBack).clamp(0.0, 1.0) *
              scrollCtrl.position.maxScrollExtent;
          scrollCtrl.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  void _close() {
    _clearHighlights();
    ref.read(terminalSearchVisibleProvider.notifier).hide();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final matchText = _matches.isEmpty
        ? l10n.noResults
        : '${_currentIndex + 1} of ${_matches.length}';

    return Positioned(
      top: 8,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: tokens.bgAlt,
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.border, width: 0.5),
          ),
          child: Row(
            children: [
              // ── Search input ───────────────────────────────────────────
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchTerminalHint,
                      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: tokens.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _search,
                    onSubmitted: (_) => _navigateMatch(1),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // ── Match counter ──────────────────────────────────────────
              Text(
                matchText,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),

              // ── Navigate up ────────────────────────────────────────────
              _MiniButton(
                icon: Icons.keyboard_arrow_up_rounded,
                tokens: tokens,
                onPressed: () => _navigateMatch(-1),
              ),

              // ── Navigate down ──────────────────────────────────────────
              _MiniButton(
                icon: Icons.keyboard_arrow_down_rounded,
                tokens: tokens,
                onPressed: () => _navigateMatch(1),
              ),

              // ── Case sensitivity toggle ────────────────────────────────
              _MiniButton(
                icon: Icons.format_size_rounded,
                tokens: tokens,
                isActive: _caseSensitive,
                tooltip: l10n.caseSensitive,
                onPressed: () {
                  setState(() => _caseSensitive = !_caseSensitive);
                  _search(_textController.text);
                },
              ),

              // ── Regex toggle ───────────────────────────────────────────
              _MiniButton(
                icon: Icons.data_object_rounded,
                tokens: tokens,
                isActive: _useRegex,
                tooltip: l10n.regex,
                onPressed: () {
                  setState(() => _useRegex = !_useRegex);
                  _search(_textController.text);
                },
              ),

              // ── Close ──────────────────────────────────────────────────
              _MiniButton(
                icon: Icons.close_rounded,
                tokens: tokens,
                onPressed: _close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Search match data ───────────────────────────────────────────────────────

class _SearchMatch {
  const _SearchMatch({
    required this.y,
    required this.startX,
    required this.endX,
  });

  final int y;
  final int startX;
  final int endX;
}

// ── Mini icon button ────────────────────────────────────────────────────────

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.tokens,
    required this.onPressed,
    this.isActive = false,
    this.tooltip,
  });

  final IconData icon;
  final OrchestraColorTokens tokens;
  final VoidCallback onPressed;
  final bool isActive;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 14,
          color: isActive ? tokens.accent : tokens.fgMuted,
        ),
        padding: EdgeInsets.zero,
        splashRadius: 12,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor:
              isActive ? tokens.accent.withValues(alpha: 0.15) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
