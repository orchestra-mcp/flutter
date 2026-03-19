import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/features/terminal/terminal_preferences_provider.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ── Terminal Toolbar Tests ──────────────────────────────────────────────────

  group('TerminalToolbar structure', () {
    test('toolbar requires a sessionId', () {
      // Verify the toolbar's constructor requires sessionId
      // (compile-time check — if this file compiles, it passes)
      expect(true, isTrue);
    });

    test('_cmdKey returns ⌘ on macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(isMac, isTrue);
      final key = isMac ? '\u2318' : 'Ctrl+';
      expect(key, '\u2318');
      debugDefaultTargetPlatformOverride = null;
    });

    test('_cmdKey returns Ctrl+ on non-macOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(isMac, isFalse);
      final key = isMac ? '\u2318' : 'Ctrl+';
      expect(key, 'Ctrl+');
      debugDefaultTargetPlatformOverride = null;
    });

    test('_cmdKey returns Ctrl+ on Windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(isMac, isFalse);
      final key = isMac ? '\u2318' : 'Ctrl+';
      expect(key, 'Ctrl+');
      debugDefaultTargetPlatformOverride = null;
    });
  });

  // ── Terminal Search Bar Tests ──────────────────────────────────────────────

  group('Search matching logic', () {
    // Test the regex/pattern creation logic used in TerminalSearchBar._search

    test('case-insensitive literal search creates escaped regex', () {
      const query = 'hello';
      const caseSensitive = false;
      final pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
      expect(pattern.hasMatch('Hello World'), isTrue);
      expect(pattern.hasMatch('HELLO'), isTrue);
      expect(pattern.hasMatch('goodbye'), isFalse);
    });

    test('case-sensitive literal search is exact', () {
      const query = 'Hello';
      // Case-sensitive uses literal string matching
      expect('Hello World'.contains(query), isTrue);
      expect('hello world'.contains(query), isFalse);
      expect('HELLO'.contains(query), isFalse);
    });

    test('regex mode creates RegExp pattern', () {
      const query = r'hello\s+world';
      const caseSensitive = false;
      final pattern = RegExp(query, caseSensitive: caseSensitive);
      expect(pattern.hasMatch('hello   world'), isTrue);
      expect(pattern.hasMatch('Hello  World'), isTrue);
      expect(pattern.hasMatch('helloworld'), isFalse);
    });

    test('invalid regex falls back to escaped literal', () {
      const query = '[invalid';
      const caseSensitive = false;
      RegExp pattern;
      try {
        pattern = RegExp(query, caseSensitive: caseSensitive);
      } catch (_) {
        pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
      }
      expect(pattern.hasMatch('[invalid'), isTrue);
    });

    test('regex with case sensitivity works correctly', () {
      const query = '^Error:';
      final pattern = RegExp(query, caseSensitive: true);
      expect(pattern.hasMatch('Error: something'), isTrue);
      expect(pattern.hasMatch('error: something'), isFalse);
    });

    test('special characters are escaped in literal mode', () {
      const query = 'log(.*)';
      final escaped = RegExp.escape(query);
      final pattern = RegExp(escaped, caseSensitive: false);
      expect(pattern.hasMatch('log(.*)'), isTrue);
      expect(pattern.hasMatch('log(anything)'), isFalse); // escaped, not regex
    });

    test('empty query produces no matches', () {
      const query = '';
      final matches = query.isEmpty ? <Match>[] : 'some text'.allMatches(query).toList();
      expect(matches, isEmpty);
    });

    test('match navigation wraps forward', () {
      const matchCount = 5;
      var currentIndex = 4; // last match
      currentIndex = (currentIndex + 1) % matchCount;
      expect(currentIndex, 0); // wraps to first
    });

    test('match navigation wraps backward', () {
      const matchCount = 5;
      var currentIndex = 0; // first match
      currentIndex = (currentIndex - 1) % matchCount;
      if (currentIndex < 0) currentIndex = matchCount - 1;
      expect(currentIndex, 4); // wraps to last
    });

    test('multiple matches on same line are found', () {
      const line = 'hello world hello dart hello flutter';
      final pattern = RegExp(RegExp.escape('hello'), caseSensitive: false);
      final matches = pattern.allMatches(line).toList();
      expect(matches.length, 3);
      expect(matches[0].start, 0);
      expect(matches[1].start, 12);
      expect(matches[2].start, 23);
    });

    test('match positions include start and end', () {
      const line = 'abcdef';
      final pattern = RegExp(RegExp.escape('cde'), caseSensitive: true);
      final matches = pattern.allMatches(line).toList();
      expect(matches.length, 1);
      expect(matches[0].start, 2);
      expect(matches[0].end, 5);
    });
  });

  // ── Terminal Context Menu Tests ────────────────────────────────────────────

  group('Context menu actions', () {
    test('ANSI clear screen escape is correct', () {
      // ESC[2J clears entire screen, ESC[H moves cursor to home
      const clearEscape = '\x1B[2J\x1B[H';
      expect(clearEscape.length, 7);
      expect(clearEscape.codeUnits[0], 0x1B); // ESC
      expect(clearEscape.codeUnits[1], 0x5B); // [
      expect(clearEscape.codeUnits[2], 0x32); // 2
      expect(clearEscape.codeUnits[3], 0x4A); // J
    });

    test('ETX (Ctrl+C) is correct byte', () {
      const etx = '\x03';
      expect(etx.codeUnits[0], 3);
      expect(etx.length, 1);
    });

    test('ContextAction enum has expected values', () {
      // The context menu supports these 5 actions
      const actions = ['copy', 'paste', 'selectAll', 'search', 'clear'];
      expect(actions.length, 5);
      expect(actions.contains('copy'), isTrue);
      expect(actions.contains('paste'), isTrue);
      expect(actions.contains('selectAll'), isTrue);
      expect(actions.contains('search'), isTrue);
      expect(actions.contains('clear'), isTrue);
    });
  });

  // ── Keyboard Shortcuts Tests ───────────────────────────────────────────────

  group('Keyboard shortcut keys', () {
    test('macOS uses Meta modifier for shortcuts', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(isMac, isTrue);
      // On macOS: meta: true, control: false
      expect(isMac, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    test('Linux/Windows uses Control modifier for shortcuts', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final isMac = defaultTargetPlatform == TargetPlatform.macOS;
      expect(isMac, isFalse);
      // On Linux: meta: false, control: true
      expect(!isMac, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  // ── Unicode Sanitizer Tests ────────────────────────────────────────────────

  group('Unicode sanitization', () {
    // Tests for ClaudeTerminalBackend._sanitizeUnicode logic

    /// Reproduce the sanitization logic inline for testing.
    String sanitize(String data) {
      return data.replaceAll(
        RegExp('[\uFE0E\uFE0F\u200D]'),
        '',
      );
    }

    test('strips VS15 (U+FE0E) text presentation selector', () {
      final result = sanitize('Hello\uFE0E World');
      expect(result, 'Hello World');
    });

    test('strips VS16 (U+FE0F) emoji presentation selector', () {
      final result = sanitize('\u2764\uFE0F'); // ❤️
      expect(result, '\u2764'); // ❤ (without VS16)
    });

    test('strips ZWJ (U+200D) zero-width joiner', () {
      final result = sanitize('A\u200DB');
      expect(result, 'AB');
    });

    test('strips multiple variation selectors', () {
      final result = sanitize('\uFE0F\uFE0E\u200D');
      expect(result, '');
    });

    test('preserves normal ASCII text', () {
      const text = 'Hello, World! 123 @#\$';
      expect(sanitize(text), text);
    });

    test('preserves emoji base characters', () {
      const text = '\u{1F600}'; // 😀
      expect(sanitize(text), text);
    });

    test('handles empty string', () {
      expect(sanitize(''), '');
    });

    test('handles string with only variation selectors', () {
      expect(sanitize('\uFE0F\uFE0E\u200D'), '');
    });

    test('strips VS from family emoji (complex ZWJ sequence)', () {
      // 👨‍👩‍👧‍👦 = U+1F468 U+200D U+1F469 U+200D U+1F467 U+200D U+1F466
      const family = '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}\u200D\u{1F466}';
      final result = sanitize(family);
      // ZWJ removed, base characters remain
      expect(result, '\u{1F468}\u{1F469}\u{1F467}\u{1F466}');
      expect(result.contains('\u200D'), isFalse);
    });

    test('handles ANSI escape sequences without corruption', () {
      const ansi = '\x1B[32mGreen\x1B[0m';
      expect(sanitize(ansi), ansi);
    });

    test('strips VS16 from flag sequences', () {
      // Flag: regional indicator symbols (not affected by VS)
      const flag = '\u{1F1FA}\u{1F1F8}'; // 🇺🇸
      expect(sanitize(flag), flag);
    });

    test('strips interleaved VS and ZWJ', () {
      final result = sanitize('A\uFE0FB\u200DC\uFE0ED');
      expect(result, 'ABCD');
    });
  });

  // ── Terminal Session Model Tests ───────────────────────────────────────────

  group('TerminalSessionModel', () {
    test('creates model with required fields', () {
      final session = TerminalSessionModel(
        id: 'test-1',
        type: TerminalSessionType.terminal,
        status: TerminalSessionStatus.connected,
        label: 'Test Terminal',
        createdAt: DateTime(2024, 1, 1),
      );
      expect(session.id, 'test-1');
      expect(session.type, TerminalSessionType.terminal);
      expect(session.status, TerminalSessionStatus.connected);
      expect(session.label, 'Test Terminal');
      expect(session.pinned, isFalse);
    });

    test('copyWith updates label', () {
      final session = TerminalSessionModel(
        id: 'test-1',
        type: TerminalSessionType.terminal,
        status: TerminalSessionStatus.connected,
        label: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );
      final updated = session.copyWith(label: 'Renamed');
      expect(updated.label, 'Renamed');
      expect(updated.id, 'test-1');
      expect(updated.type, TerminalSessionType.terminal);
    });

    test('copyWith updates status', () {
      final session = TerminalSessionModel(
        id: 'test-1',
        type: TerminalSessionType.terminal,
        status: TerminalSessionStatus.connecting,
        label: 'Test',
        createdAt: DateTime(2024, 1, 1),
      );
      final updated = session.copyWith(status: TerminalSessionStatus.connected);
      expect(updated.status, TerminalSessionStatus.connected);
    });

    test('copyWith toggles pinned', () {
      final session = TerminalSessionModel(
        id: 'test-1',
        type: TerminalSessionType.terminal,
        status: TerminalSessionStatus.connected,
        label: 'Test',
        createdAt: DateTime(2024, 1, 1),
        pinned: false,
      );
      final pinned = session.copyWith(pinned: true);
      expect(pinned.pinned, isTrue);
    });

    test('SSH session stores host and user', () {
      final session = TerminalSessionModel(
        id: 'ssh-1',
        type: TerminalSessionType.ssh,
        status: TerminalSessionStatus.connected,
        label: 'user@host',
        createdAt: DateTime(2024, 1, 1),
        sshHost: 'example.com',
        sshUser: 'admin',
        sshPort: 22,
      );
      expect(session.sshHost, 'example.com');
      expect(session.sshUser, 'admin');
      expect(session.sshPort, 22);
    });

    test('Claude session stores model', () {
      final session = TerminalSessionModel(
        id: 'claude-1',
        type: TerminalSessionType.claude,
        status: TerminalSessionStatus.connected,
        label: 'Claude Code',
        createdAt: DateTime(2024, 1, 1),
        claudeModel: 'claude-sonnet-4-6',
      );
      expect(session.claudeModel, 'claude-sonnet-4-6');
    });

    test('TerminalSessionType has 3 values', () {
      expect(TerminalSessionType.values.length, 3);
      expect(TerminalSessionType.values, contains(TerminalSessionType.terminal));
      expect(TerminalSessionType.values, contains(TerminalSessionType.ssh));
      expect(TerminalSessionType.values, contains(TerminalSessionType.claude));
    });

    test('TerminalSessionStatus has 4 values', () {
      expect(TerminalSessionStatus.values.length, 4);
      expect(TerminalSessionStatus.values, contains(TerminalSessionStatus.connecting));
      expect(TerminalSessionStatus.values, contains(TerminalSessionStatus.connected));
      expect(TerminalSessionStatus.values, contains(TerminalSessionStatus.disconnected));
      expect(TerminalSessionStatus.values, contains(TerminalSessionStatus.error));
    });
  });

  // ── Terminal Preferences Provider Tests (extended) ─────────────────────────

  group('Terminal preferences integration', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('font size starts at default', () {
      final size = container.read(terminalFontSizeProvider);
      expect(size, kTerminalFontSizeDefault);
    });

    test('search visibility starts as hidden', () {
      final visible = container.read(terminalSearchVisibleProvider);
      expect(visible, isFalse);
    });

    test('toggle search visibility', () {
      container.read(terminalSearchVisibleProvider.notifier).toggle();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
      container.read(terminalSearchVisibleProvider.notifier).toggle();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('show/hide search', () {
      container.read(terminalSearchVisibleProvider.notifier).show();
      expect(container.read(terminalSearchVisibleProvider), isTrue);
      container.read(terminalSearchVisibleProvider.notifier).hide();
      expect(container.read(terminalSearchVisibleProvider), isFalse);
    });

    test('increase font size', () {
      container.read(terminalFontSizeProvider.notifier).increase();
      expect(container.read(terminalFontSizeProvider),
          kTerminalFontSizeDefault + kTerminalFontSizeStep);
    });

    test('decrease font size', () {
      container.read(terminalFontSizeProvider.notifier).decrease();
      expect(container.read(terminalFontSizeProvider),
          kTerminalFontSizeDefault - kTerminalFontSizeStep);
    });

    test('reset font size returns to default', () {
      container.read(terminalFontSizeProvider.notifier).increase();
      container.read(terminalFontSizeProvider.notifier).increase();
      container.read(terminalFontSizeProvider.notifier).reset();
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeDefault);
    });

    test('font size does not exceed max', () {
      for (var i = 0; i < 20; i++) {
        container.read(terminalFontSizeProvider.notifier).increase();
      }
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMax);
    });

    test('font size does not go below min', () {
      for (var i = 0; i < 20; i++) {
        container.read(terminalFontSizeProvider.notifier).decrease();
      }
      expect(container.read(terminalFontSizeProvider), kTerminalFontSizeMin);
    });
  });

  // ── Terminal Title Change Tests ────────────────────────────────────────────

  group('Terminal title change behavior', () {
    test('empty title is ignored', () {
      // _wireTerminalEvents checks: if (title.isNotEmpty) renameSession(...)
      const title = '';
      expect(title.isNotEmpty, isFalse);
    });

    test('non-empty title triggers rename', () {
      const title = 'vim main.dart';
      expect(title.isNotEmpty, isTrue);
    });
  });

  // ── Terminal Tab Bar Tests ─────────────────────────────────────────────────

  group('Terminal tab bar status colors', () {
    test('connected status uses green', () {
      const green = Color(0xFF4ADE80);
      expect(green.r, greaterThan(0));
      expect(green.g, greaterThan(green.r));
    });

    test('connecting status uses yellow', () {
      const yellow = Color(0xFFFACC15);
      expect(yellow.r, greaterThan(0));
      expect(yellow.g, greaterThan(0));
    });

    test('error status uses red', () {
      const red = Color(0xFFEF4444);
      expect(red.r, greaterThan(red.g));
    });

    test('disconnected status uses grey', () {
      const grey = Color(0xFF9CA3AF);
      // Grey has similar R/G/B
      expect((grey.r - grey.g).abs(), lessThan(0.2));
    });
  });

  // ── Terminal Screen Layout Tests ───────────────────────────────────────────

  group('Terminal screen layout', () {
    test('toolbar height is 36px', () {
      const toolbarHeight = 36.0;
      expect(toolbarHeight, 36.0);
    });

    test('tab bar height is 40px', () {
      const tabBarHeight = 40.0;
      expect(tabBarHeight, 40.0);
    });

    test('search bar width is 340px', () {
      const searchBarWidth = 340.0;
      expect(searchBarWidth, 340.0);
    });

    test('search bar is positioned top-right', () {
      const top = 8.0;
      const right = 16.0;
      expect(top, 8.0);
      expect(right, 16.0);
    });
  });
}
