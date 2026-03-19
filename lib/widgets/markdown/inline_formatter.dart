import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Inline markdown formatting — converts inline syntax to styled TextSpans.
/// Ported from apps/components/editor/src/MarkdownRenderer/inlineFormat.ts

/// Callback when a markdown link is tapped.
typedef LinkCallback = void Function(String href);

/// Parse inline markdown and return a list of [InlineSpan] segments.
List<InlineSpan> parseInline(String text) {
  final spans = <InlineSpan>[];
  final codeSlots = <String>[];

  // Step 1: Extract inline code to protect from other formatting
  final result = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) {
    final idx = codeSlots.length;
    codeSlots.add(m.group(1) ?? '');
    return '\x00CODE$idx\x00';
  });

  // Step 2: Parse into segments
  _parseSegments(result, codeSlots, spans, const InlineStyle());

  return spans;
}

/// Build a [TextSpan] tree from inline markdown text.
TextSpan buildInlineSpan(
  String text, {
  TextStyle? baseStyle,
  LinkCallback? onLinkClick,
}) {
  final segments = parseInline(text);
  return TextSpan(
    children: segments
        .map((s) => s.toTextSpan(baseStyle, onLinkClick))
        .toList(),
  );
}

/// Build a list of [InlineSpan] into a [Widget] with selectable text.
Widget buildInlineWidget(
  String text, {
  TextStyle? baseStyle,
  LinkCallback? onLinkClick,
}) {
  final span = buildInlineSpan(
    text,
    baseStyle: baseStyle,
    onLinkClick: onLinkClick,
  );
  return Text.rich(span);
}

// ── Types ───────────────────────────────────────────────────────────────────

/// Style flags for inline formatting.
class InlineStyle {
  const InlineStyle({
    this.bold = false,
    this.italic = false,
    this.strikethrough = false,
    this.isCode = false,
    this.isLink = false,
    this.linkHref,
    this.isImage = false,
    this.imageSrc,
    this.imageAlt,
  });

  final bool bold;
  final bool italic;
  final bool strikethrough;
  final bool isCode;
  final bool isLink;
  final String? linkHref;
  final bool isImage;
  final String? imageSrc;
  final String? imageAlt;

  InlineStyle copyWith({
    bool? bold,
    bool? italic,
    bool? strikethrough,
    bool? isCode,
    bool? isLink,
    String? linkHref,
    bool? isImage,
    String? imageSrc,
    String? imageAlt,
  }) {
    return InlineStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strikethrough: strikethrough ?? this.strikethrough,
      isCode: isCode ?? this.isCode,
      isLink: isLink ?? this.isLink,
      linkHref: linkHref ?? this.linkHref,
      isImage: isImage ?? this.isImage,
      imageSrc: imageSrc ?? this.imageSrc,
      imageAlt: imageAlt ?? this.imageAlt,
    );
  }
}

/// A segment of inline-formatted text.
class InlineSpan {
  const InlineSpan({required this.text, required this.style});
  final String text;
  final InlineStyle style;

  TextSpan toTextSpan(TextStyle? baseStyle, LinkCallback? onLinkClick) {
    var ts = baseStyle ?? const TextStyle();

    if (style.bold) ts = ts.copyWith(fontWeight: FontWeight.bold);
    if (style.italic) ts = ts.copyWith(fontStyle: FontStyle.italic);
    if (style.strikethrough) {
      ts = ts.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (style.isCode) {
      ts = ts.copyWith(
        fontFamily: 'monospace',
        backgroundColor: const Color(0x1A6366F1),
        fontSize: (ts.fontSize ?? 14) * 0.9,
      );
    }
    if (style.isLink) {
      ts = ts.copyWith(
        color: const Color(0xFF6366F1),
        decoration: TextDecoration.underline,
      );
      return TextSpan(
        text: text,
        style: ts,
        recognizer: onLinkClick != null && style.linkHref != null
            ? (TapGestureRecognizer()
                ..onTap = () => onLinkClick(style.linkHref!))
            : null,
      );
    }

    return TextSpan(text: text, style: ts);
  }
}

// ── Parser ──────────────────────────────────────────────────────────────────

/// Regex patterns for inline markdown.
final _boldItalicRe = RegExp(r'\*\*\*(.+?)\*\*\*');
final _boldRe = RegExp(r'\*\*(.+?)\*\*');
final _bold2Re = RegExp(r'__(.+?)__');
final _italicRe = RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');
final _italic2Re = RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)');
final _strikeRe = RegExp(r'~~(.+?)~~');
final _imageRe = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');
final _linkRe = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
final _codeSlotRe = RegExp(r'\x00CODE(\d+)\x00');

void _parseSegments(
  String text,
  List<String> codeSlots,
  List<InlineSpan> spans,
  InlineStyle currentStyle,
) {
  if (text.isEmpty) return;

  // Find the earliest match among all patterns
  _Match? earliest;

  void check(RegExp re, String type) {
    final m = re.firstMatch(text);
    if (m != null && (earliest == null || m.start < earliest!.start)) {
      earliest = _Match(match: m, type: type);
    }
  }

  check(_codeSlotRe, 'code');
  check(_imageRe, 'image');
  check(_linkRe, 'link');
  check(_boldItalicRe, 'bolditalic');
  check(_boldRe, 'bold');
  check(_bold2Re, 'bold2');
  check(_italicRe, 'italic');
  check(_italic2Re, 'italic2');
  check(_strikeRe, 'strike');

  if (earliest == null) {
    // No more patterns — emit plain text
    if (text.isNotEmpty) {
      spans.add(InlineSpan(text: text, style: currentStyle));
    }
    return;
  }

  final m = earliest!;

  // Text before the match
  if (m.start > 0) {
    spans.add(
      InlineSpan(text: text.substring(0, m.start), style: currentStyle),
    );
  }

  switch (m.type) {
    case 'code':
      final idxStr = m.match.group(1);
      if (idxStr == null) break;
      final idx = int.tryParse(idxStr) ?? 0;
      final codeText = idx < codeSlots.length ? codeSlots[idx] : '';
      spans.add(
        InlineSpan(text: codeText, style: currentStyle.copyWith(isCode: true)),
      );
    case 'image':
      final alt = m.match.group(1) ?? '';
      final src = m.match.group(2) ?? '';
      spans.add(
        InlineSpan(
          text: alt.isNotEmpty ? '[$alt]' : '[image]',
          style: currentStyle.copyWith(
            isImage: true,
            imageSrc: src,
            imageAlt: alt,
          ),
        ),
      );
    case 'link':
      final linkText = m.match.group(1) ?? '';
      final href = m.match.group(2) ?? '';
      if (linkText.isNotEmpty) {
        _parseSegments(
          linkText,
          codeSlots,
          spans,
          currentStyle.copyWith(isLink: true, linkHref: href),
        );
      }
    case 'bolditalic':
      final inner = m.match.group(1) ?? '';
      if (inner.isNotEmpty) {
        _parseSegments(
          inner,
          codeSlots,
          spans,
          currentStyle.copyWith(bold: true, italic: true),
        );
      }
    case 'bold' || 'bold2':
      final inner = m.match.group(1) ?? '';
      if (inner.isNotEmpty) {
        _parseSegments(
          inner,
          codeSlots,
          spans,
          currentStyle.copyWith(bold: true),
        );
      }
    case 'italic' || 'italic2':
      final inner = m.match.group(1) ?? '';
      if (inner.isNotEmpty) {
        _parseSegments(
          inner,
          codeSlots,
          spans,
          currentStyle.copyWith(italic: true),
        );
      }
    case 'strike':
      final inner = m.match.group(1) ?? '';
      if (inner.isNotEmpty) {
        _parseSegments(
          inner,
          codeSlots,
          spans,
          currentStyle.copyWith(strikethrough: true),
        );
      }
  }

  // Text after the match
  final after = text.substring(m.end);
  if (after.isNotEmpty) {
    _parseSegments(after, codeSlots, spans, currentStyle);
  }
}

class _Match {
  _Match({required this.match, required this.type});
  final RegExpMatch match;
  final String type;
  int get start => match.start;
  int get end => match.end;
}
