import 'package:flutter/material.dart';

/// Lightweight regex-based syntax highlighter.
/// Ported from apps/components/editor/src/CodeBlock/highlighter.ts

// ── Token types ─────────────────────────────────────────────────────────────

enum SyntaxTokenType {
  plain,
  keyword,
  string,
  comment,
  number,
  variable,
  type,
  punctuation,
}

class SyntaxToken {
  const SyntaxToken({required this.text, this.type = SyntaxTokenType.plain});
  final String text;
  final SyntaxTokenType type;
}

// ── Colors ──────────────────────────────────────────────────────────────────

/// Get the color for a syntax token type.
Color syntaxColor(SyntaxTokenType type, {bool isDark = true}) {
  return switch (type) {
    SyntaxTokenType.keyword => isDark ? const Color(0xFFC792EA) : const Color(0xFF7C3AED),
    SyntaxTokenType.string => isDark ? const Color(0xFFA5D6A7) : const Color(0xFF16A34A),
    SyntaxTokenType.comment => isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
    SyntaxTokenType.number => isDark ? const Color(0xFFF78C6C) : const Color(0xFFEA580C),
    SyntaxTokenType.variable => isDark ? const Color(0xFF82AAFF) : const Color(0xFF2563EB),
    SyntaxTokenType.type => isDark ? const Color(0xFFFFCB6B) : const Color(0xFFCA8A04),
    SyntaxTokenType.punctuation => isDark ? const Color(0xFF89DDFF) : const Color(0xFF6B7280),
    SyntaxTokenType.plain => isDark ? const Color(0xFFD4D4D4) : const Color(0xFF1F2937),
  };
}

// ── Keyword tables ──────────────────────────────────────────────────────────

const _commonKeywords = [
  'if', 'else', 'for', 'while', 'return', 'function', 'class', 'const',
  'let', 'var', 'import', 'export', 'from', 'default', 'new', 'this',
  'throw', 'try', 'catch', 'finally', 'switch', 'case', 'break',
  'continue', 'do', 'in', 'of', 'typeof', 'instanceof', 'void',
  'delete', 'async', 'await', 'yield', 'static', 'extends', 'super',
  'implements', 'interface', 'type', 'enum', 'abstract', 'readonly',
];

const _phpKeywords = [
  'namespace', 'use', 'class', 'function', 'public', 'private', 'protected',
  'static', 'return', 'if', 'else', 'foreach', 'as', 'new', 'extends',
  'implements', 'interface', 'abstract', 'final', 'const', 'echo', 'throw',
  'try', 'catch', 'finally', 'match', 'fn', 'yield', 'readonly',
];

const _goKeywords = [
  'func', 'package', 'import', 'type', 'struct', 'interface', 'map',
  'chan', 'go', 'defer', 'return', 'if', 'else', 'for', 'range',
  'switch', 'case', 'default', 'break', 'continue', 'select', 'var',
  'const', 'fallthrough', 'goto',
];

const _rustKeywords = [
  'fn', 'let', 'mut', 'pub', 'struct', 'enum', 'impl', 'trait', 'use',
  'mod', 'crate', 'self', 'super', 'match', 'if', 'else', 'for', 'while',
  'loop', 'return', 'where', 'async', 'await', 'move', 'ref', 'type',
  'const', 'static', 'unsafe', 'extern', 'dyn', 'as', 'in',
];

const _pythonKeywords = [
  'def', 'class', 'import', 'from', 'return', 'if', 'elif', 'else',
  'for', 'while', 'in', 'not', 'and', 'or', 'is', 'with', 'as',
  'try', 'except', 'finally', 'raise', 'pass', 'break', 'continue',
  'lambda', 'yield', 'global', 'nonlocal', 'assert', 'del', 'async', 'await',
];

const _javaKeywords = [
  'class', 'interface', 'extends', 'implements', 'public', 'private', 'protected',
  'static', 'final', 'abstract', 'void', 'return', 'if', 'else', 'for', 'while',
  'do', 'switch', 'case', 'break', 'continue', 'new', 'throw', 'try', 'catch',
  'finally', 'import', 'package', 'this', 'super', 'synchronized', 'volatile',
];

const _cKeywords = [
  'if', 'else', 'for', 'while', 'do', 'switch', 'case', 'break', 'continue',
  'return', 'struct', 'typedef', 'enum', 'union', 'void', 'int', 'char', 'float',
  'double', 'long', 'short', 'unsigned', 'signed', 'const', 'static', 'extern',
  'sizeof', 'include', 'define', 'ifdef', 'ifndef', 'endif', 'NULL',
];

const _rubyKeywords = [
  'def', 'class', 'module', 'end', 'if', 'elsif', 'else', 'unless', 'while',
  'until', 'for', 'do', 'begin', 'rescue', 'ensure', 'raise', 'return', 'yield',
  'block_given', 'require', 'include', 'extend', 'attr_accessor', 'attr_reader',
  'nil', 'true', 'false', 'self', 'super', 'puts', 'print',
];

const _bashKeywords = [
  'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'do', 'done', 'case',
  'esac', 'function', 'return', 'exit', 'echo', 'read', 'export', 'source',
  'local', 'readonly', 'shift', 'set', 'unset', 'trap', 'eval', 'exec',
  'cd', 'pwd', 'test', 'true', 'false',
];

const _sqlKeywords = [
  'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET',
  'DELETE', 'CREATE', 'TABLE', 'ALTER', 'DROP', 'INDEX', 'JOIN', 'LEFT',
  'RIGHT', 'INNER', 'OUTER', 'ON', 'AND', 'OR', 'NOT', 'NULL', 'AS',
  'ORDER', 'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET', 'DISTINCT', 'UNION',
  'EXISTS', 'IN', 'BETWEEN', 'LIKE', 'IS', 'PRIMARY', 'KEY', 'FOREIGN',
  'REFERENCES', 'CASCADE', 'DEFAULT', 'CONSTRAINT', 'BEGIN', 'COMMIT', 'ROLLBACK',
];

const _swiftKeywords = [
  'func', 'var', 'let', 'class', 'struct', 'enum', 'protocol', 'extension',
  'import', 'return', 'if', 'else', 'guard', 'switch', 'case', 'default',
  'for', 'while', 'repeat', 'break', 'continue', 'throw', 'try', 'catch',
  'self', 'super', 'init', 'deinit', 'nil', 'true', 'false', 'override',
  'private', 'public', 'internal', 'open', 'static', 'async', 'await',
];

const _kotlinKeywords = [
  'fun', 'val', 'var', 'class', 'object', 'interface', 'abstract', 'override',
  'open', 'data', 'sealed', 'import', 'package', 'return', 'if', 'else',
  'when', 'for', 'while', 'do', 'break', 'continue', 'throw', 'try', 'catch',
  'finally', 'this', 'super', 'null', 'true', 'false', 'is', 'as', 'in',
  'suspend', 'companion', 'init', 'private', 'public', 'internal', 'protected',
];

const _csharpKeywords = [
  'class', 'interface', 'struct', 'enum', 'namespace', 'using', 'public',
  'private', 'protected', 'internal', 'static', 'void', 'return', 'if', 'else',
  'for', 'foreach', 'while', 'do', 'switch', 'case', 'break', 'continue',
  'new', 'throw', 'try', 'catch', 'finally', 'async', 'await', 'var', 'const',
  'readonly', 'override', 'virtual', 'abstract', 'sealed', 'partial', 'this',
  'base', 'null', 'true', 'false', 'out', 'ref', 'in', 'yield',
];

const _dartKeywords = [
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
  'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
  'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
  'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
  'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
  'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when',
  'while', 'with', 'yield',
];

List<String> _getKeywords(String lang) {
  return switch (lang.toLowerCase()) {
    'php' => _phpKeywords,
    'go' || 'golang' => _goKeywords,
    'rust' || 'rs' => _rustKeywords,
    'python' || 'py' => _pythonKeywords,
    'java' => _javaKeywords,
    'c' || 'cpp' || 'c++' || 'h' => _cKeywords,
    'ruby' || 'rb' => _rubyKeywords,
    'bash' || 'sh' || 'shell' || 'zsh' => _bashKeywords,
    'sql' || 'mysql' || 'postgresql' || 'postgres' || 'sqlite' => _sqlKeywords,
    'swift' => _swiftKeywords,
    'kotlin' || 'kt' => _kotlinKeywords,
    'csharp' || 'cs' || 'c#' => _csharpKeywords,
    'dart' => _dartKeywords,
    _ => _commonKeywords,
  };
}

// ── Tokenizer ───────────────────────────────────────────────────────────────

class _TokenRule {
  _TokenRule(this.pattern, this.type);
  final RegExp pattern;
  final SyntaxTokenType type;
}

class _Marker {
  _Marker(this.start, this.end, this.type);
  final int start;
  final int end;
  final SyntaxTokenType type;
}

List<_TokenRule> _buildRules(String lang) {
  final keywords = _getKeywords(lang);
  final isSql = {'sql', 'mysql', 'postgresql', 'postgres', 'sqlite'}.contains(lang.toLowerCase());
  final hasDollarVars = {'php', 'bash', 'sh', 'shell', 'zsh'}.contains(lang.toLowerCase());
  final kwFlags = isSql ? 'i' : '';

  final kwPattern = RegExp('\\b(${keywords.join('|')})\\b', caseSensitive: kwFlags.isEmpty);

  return [
    // Comments
    _TokenRule(RegExp(r'//.*$'), SyntaxTokenType.comment),
    _TokenRule(RegExp(r'#.*$'), SyntaxTokenType.comment),
    _TokenRule(RegExp(r'/\*[\s\S]*?\*/'), SyntaxTokenType.comment),
    if (isSql) _TokenRule(RegExp(r'--.*$'), SyntaxTokenType.comment),
    // Strings
    _TokenRule(RegExp(r'"(?:[^"\\]|\\.)*"'), SyntaxTokenType.string),
    _TokenRule(RegExp(r"'(?:[^'\\]|\\.)*'"), SyntaxTokenType.string),
    _TokenRule(RegExp(r'`(?:[^`\\]|\\.)*`'), SyntaxTokenType.string),
    // Numbers
    _TokenRule(RegExp(r'\b\d+(?:\.\d+)?(?:e[+-]?\d+)?\b', caseSensitive: false), SyntaxTokenType.number),
    // Dollar variables
    if (hasDollarVars) _TokenRule(RegExp(r'\$[a-zA-Z_]\w*'), SyntaxTokenType.variable),
    // Type names (PascalCase)
    _TokenRule(RegExp(r'\b[A-Z][a-zA-Z0-9_]*\b'), SyntaxTokenType.type),
    // Keywords
    _TokenRule(kwPattern, SyntaxTokenType.keyword),
    // Punctuation
    _TokenRule(RegExp(r'=>|->|::|\.\.\.|\.\.|[{}()\[\];,.:?]'), SyntaxTokenType.punctuation),
  ];
}

/// Tokenize a single line of code into highlighted spans.
List<SyntaxToken> tokenizeLine(String line, String language) {
  if (line.isEmpty) return [const SyntaxToken(text: '\n')];
  if (language.isEmpty) return [SyntaxToken(text: line)];

  final rules = _buildRules(language);
  final markers = <_Marker>[];

  for (final rule in rules) {
    for (final match in rule.pattern.allMatches(line)) {
      markers.add(_Marker(match.start, match.end, rule.type));
    }
  }

  // Sort by start position, prefer longer matches
  markers.sort((a, b) {
    final cmp = a.start.compareTo(b.start);
    if (cmp != 0) return cmp;
    return (b.end - b.start).compareTo(a.end - a.start);
  });

  // Resolve overlaps: first match wins
  final resolved = <_Marker>[];
  var cursor = 0;
  for (final m in markers) {
    if (m.start >= cursor) {
      resolved.add(m);
      cursor = m.end;
    }
  }

  // Build token list
  final tokens = <SyntaxToken>[];
  var pos = 0;
  for (final m in resolved) {
    if (m.start > pos) {
      tokens.add(SyntaxToken(text: line.substring(pos, m.start)));
    }
    tokens.add(SyntaxToken(
      text: line.substring(m.start, m.end),
      type: m.type,
    ));
    pos = m.end;
  }
  if (pos < line.length) {
    tokens.add(SyntaxToken(text: line.substring(pos)));
  }

  return tokens.isNotEmpty ? tokens : [SyntaxToken(text: line)];
}

/// Build a list of [TextSpan] for a highlighted line of code.
List<TextSpan> highlightLine(String line, String language, {bool isDark = true, TextStyle? baseStyle}) {
  final tokens = tokenizeLine(line, language);
  return tokens.map((tok) {
    final color = syntaxColor(tok.type, isDark: isDark);
    return TextSpan(
      text: tok.text,
      style: (baseStyle ?? const TextStyle()).copyWith(color: color),
    );
  }).toList();
}
