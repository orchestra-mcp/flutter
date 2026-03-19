import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Font size ────────────────────────────────────────────────────────────────

const _kFontSizeKey = 'terminal_font_size';
const kTerminalFontSizeDefault = 14.0;
const kTerminalFontSizeMin = 10.0;
const kTerminalFontSizeMax = 24.0;
const kTerminalFontSizeStep = 1.0;

/// Persisted terminal font size preference.
final terminalFontSizeProvider =
    NotifierProvider<TerminalFontSizeNotifier, double>(
      TerminalFontSizeNotifier.new,
    );

class TerminalFontSizeNotifier extends Notifier<double> {
  @override
  double build() {
    _load();
    return kTerminalFontSizeDefault;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_kFontSizeKey);
    if (saved != null)
      state = saved.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFontSizeKey, state);
  }

  void increase() {
    if (state < kTerminalFontSizeMax) {
      state = (state + kTerminalFontSizeStep).clamp(
        kTerminalFontSizeMin,
        kTerminalFontSizeMax,
      );
      _persist();
    }
  }

  void decrease() {
    if (state > kTerminalFontSizeMin) {
      state = (state - kTerminalFontSizeStep).clamp(
        kTerminalFontSizeMin,
        kTerminalFontSizeMax,
      );
      _persist();
    }
  }

  void reset() {
    state = kTerminalFontSizeDefault;
    _persist();
  }

  void set(double value) {
    state = value.clamp(kTerminalFontSizeMin, kTerminalFontSizeMax);
    _persist();
  }
}

// ── Search visibility ────────────────────────────────────────────────────────

/// Whether the terminal search bar is visible.
final terminalSearchVisibleProvider =
    NotifierProvider<_SearchVisibleNotifier, bool>(_SearchVisibleNotifier.new);

class _SearchVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}
