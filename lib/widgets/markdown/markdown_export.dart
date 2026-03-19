import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:orchestra/widgets/markdown/export_image_helper.dart';
import 'package:orchestra/widgets/markdown/markdown_parser.dart';

// ── HTML helpers ─────────────────────────────────────────────────────────────

String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String inlineToHtml(String text) {
  var result = escapeHtml(text);
  result = result.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => '<strong>${m[1]}</strong>',
  );
  result = result.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (m) => '<em>${m[1]}</em>',
  );
  result = result.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => '<code>${m[1]}</code>',
  );
  result = result.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
    (m) => '<a href="${m[2]}">${m[1]}</a>',
  );
  return result;
}

String stripInlineMarkdown(String text) {
  var result = text;
  result = result.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
  result = result.replaceAllMapped(
    RegExp(r'\*{1,3}([^*]+)\*{1,3}'),
    (m) => m[1]!,
  );
  result = result.replaceAllMapped(
    RegExp(r'_{1,3}([^_]+)_{1,3}'),
    (m) => m[1]!,
  );
  result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
  result = result.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]+\)'),
    (m) => m[1]!,
  );
  result = result.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
    (m) => m[1]!,
  );
  return result;
}

// ── Block → HTML body ────────────────────────────────────────────────────────

void _writeBlocksHtml(StringBuffer buf, List<MarkdownBlock> blocks) {
  for (final block in blocks) {
    switch (block) {
      case HeadingBlock():
        buf.writeln(
          '<h${block.level}>${inlineToHtml(block.text)}</h${block.level}>',
        );
      case ParagraphBlock():
        buf.writeln('<p>${inlineToHtml(block.text)}</p>');
      case CodeBlock():
        final lang = block.language.isNotEmpty
            ? ' class="language-${block.language}"'
            : '';
        buf.writeln('<pre><code$lang>${escapeHtml(block.code)}</code></pre>');
      case TableBlock():
        buf.writeln('<table><thead><tr>');
        for (final h in block.headers) {
          buf.writeln('<th>${inlineToHtml(h)}</th>');
        }
        buf.writeln('</tr></thead><tbody>');
        for (final row in block.rows) {
          buf.writeln('<tr>');
          for (final cell in row) {
            buf.writeln('<td>${inlineToHtml(cell)}</td>');
          }
          buf.writeln('</tr>');
        }
        buf.writeln('</tbody></table>');
      case BlockquoteBlock():
        buf.writeln(
          '<blockquote><p>${inlineToHtml(block.text)}</p></blockquote>',
        );
      case UnorderedListBlock():
        buf.writeln('<ul>');
        for (final item in block.items) {
          buf.writeln('<li>${inlineToHtml(item)}</li>');
        }
        buf.writeln('</ul>');
      case OrderedListBlock():
        buf.writeln('<ol>');
        for (final item in block.items) {
          buf.writeln('<li>${inlineToHtml(item)}</li>');
        }
        buf.writeln('</ol>');
      case TaskListBlock():
        buf.writeln('<ul style="list-style:none;padding-left:0;">');
        for (final item in block.items) {
          final checked = item.checked ? 'checked disabled' : 'disabled';
          buf.writeln(
            '<li><input type="checkbox" $checked> ${inlineToHtml(item.text)}</li>',
          );
        }
        buf.writeln('</ul>');
      case FrontmatterBlock():
        buf.writeln('<table><tbody>');
        for (final entry in block.data.entries) {
          buf.writeln(
            '<tr><td><strong>${escapeHtml(entry.key)}</strong></td><td>${escapeHtml(entry.value)}</td></tr>',
          );
        }
        buf.writeln('</tbody></table>');
      case HorizontalRuleBlock():
        buf.writeln('<hr>');
    }
  }
}

// ── Public generators ────────────────────────────────────────────────────────

/// Converts markdown content to a styled HTML document with full Unicode support.
String markdownToHtml(String content) {
  final blocks = parseMarkdown(content);
  final buf = StringBuffer();
  buf.writeln('<!DOCTYPE html>');
  buf.writeln('<html dir="auto"><head><meta charset="utf-8">');
  buf.writeln('<style>');
  buf.writeln(
    'body { font-family: "IBM Plex Sans", "IBM Plex Sans Arabic", -apple-system, BlinkMacSystemFont, "Segoe UI", "Geeza Pro", "Al Nile", Roboto, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #1f2937; }',
  );
  buf.writeln(
    'h1, h2 { border-bottom: 1px solid #e5e7eb; padding-bottom: 8px; }',
  );
  buf.writeln(
    'code { font-family: "IBM Plex Mono", Consolas, monospace; background: #f3f4f6; padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }',
  );
  buf.writeln(
    'pre { font-family: "IBM Plex Mono", Consolas, monospace; background: #1e1e2e; color: #d4d4d4; padding: 16px; border-radius: 8px; overflow-x: auto; }',
  );
  buf.writeln('pre code { background: none; padding: 0; color: inherit; }');
  buf.writeln(
    'blockquote { border-left: 3px solid #6366f1; margin: 0; padding: 8px 16px; background: rgba(99,102,241,0.05); }',
  );
  buf.writeln('table { border-collapse: collapse; width: 100%; }');
  buf.writeln(
    'th, td { border: 1px solid #e5e7eb; padding: 8px 12px; text-align: left; }',
  );
  buf.writeln('th { background: #f1f3f5; font-weight: 600; }');
  buf.writeln('tr:nth-child(even) { background: #f8f9fa; }');
  buf.writeln('hr { border: none; border-top: 1px solid #e5e7eb; }');
  buf.writeln('</style></head><body>');
  _writeBlocksHtml(buf, blocks);
  buf.writeln('</body></html>');
  return buf.toString();
}

/// Converts markdown content to a DOCX-compatible HTML file
/// (opens in Google Docs & Microsoft Word) with full Unicode support.
String markdownToDocx(String content) {
  final blocks = parseMarkdown(content);
  final buf = StringBuffer();
  buf.writeln('<!DOCTYPE html>');
  buf.writeln(
    '<html dir="auto" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">',
  );
  buf.writeln('<head><meta charset="utf-8">');
  buf.writeln(
    '<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View></w:WordDocument></xml><![endif]-->',
  );
  buf.writeln('<style>');
  buf.writeln(
    'body { font-family: "IBM Plex Sans", "IBM Plex Sans Arabic", Calibri, "Geeza Pro", Arial, sans-serif; font-size: 11pt; line-height: 1.5; }',
  );
  buf.writeln('h1 { font-size: 20pt; color: #1f2937; }');
  buf.writeln('h2 { font-size: 16pt; color: #1f2937; }');
  buf.writeln('h3 { font-size: 13pt; color: #1f2937; }');
  buf.writeln(
    'code { font-family: "IBM Plex Mono", Consolas, monospace; background: #f3f4f6; padding: 1px 4px; }',
  );
  buf.writeln(
    'pre { font-family: "IBM Plex Mono", Consolas, monospace; background: #f3f4f6; padding: 12px; border: 1px solid #e5e7eb; }',
  );
  buf.writeln('table { border-collapse: collapse; width: 100%; }');
  buf.writeln('th, td { border: 1px solid #d1d5db; padding: 6px 10px; }');
  buf.writeln('th { background: #f1f3f5; font-weight: bold; }');
  buf.writeln(
    'blockquote { border-left: 3px solid #6366f1; margin: 0; padding: 8px 16px; }',
  );
  buf.writeln('</style></head><body>');

  // DOCX uses simplified HTML (no checkbox inputs)
  for (final block in blocks) {
    switch (block) {
      case HeadingBlock():
        buf.writeln(
          '<h${block.level}>${inlineToHtml(block.text)}</h${block.level}>',
        );
      case ParagraphBlock():
        buf.writeln('<p>${inlineToHtml(block.text)}</p>');
      case CodeBlock():
        buf.writeln('<pre><code>${escapeHtml(block.code)}</code></pre>');
      case TableBlock():
        buf.writeln('<table><thead><tr>');
        for (final h in block.headers) {
          buf.writeln('<th>${inlineToHtml(h)}</th>');
        }
        buf.writeln('</tr></thead><tbody>');
        for (final row in block.rows) {
          buf.writeln('<tr>');
          for (final cell in row) {
            buf.writeln('<td>${inlineToHtml(cell)}</td>');
          }
          buf.writeln('</tr>');
        }
        buf.writeln('</tbody></table>');
      case BlockquoteBlock():
        buf.writeln(
          '<blockquote><p>${inlineToHtml(block.text)}</p></blockquote>',
        );
      case UnorderedListBlock():
        buf.writeln('<ul>');
        for (final item in block.items) {
          buf.writeln('<li>${inlineToHtml(item)}</li>');
        }
        buf.writeln('</ul>');
      case OrderedListBlock():
        buf.writeln('<ol>');
        for (final item in block.items) {
          buf.writeln('<li>${inlineToHtml(item)}</li>');
        }
        buf.writeln('</ol>');
      case TaskListBlock():
        buf.writeln('<ul>');
        for (final item in block.items) {
          final marker = item.checked ? '[x]' : '[ ]';
          buf.writeln('<li>$marker ${inlineToHtml(item.text)}</li>');
        }
        buf.writeln('</ul>');
      case FrontmatterBlock():
        buf.writeln('<table><tbody>');
        for (final entry in block.data.entries) {
          buf.writeln(
            '<tr><td><strong>${escapeHtml(entry.key)}</strong></td><td>${escapeHtml(entry.value)}</td></tr>',
          );
        }
        buf.writeln('</tbody></table>');
      case HorizontalRuleBlock():
        buf.writeln('<hr>');
    }
  }

  buf.writeln('</body></html>');
  return buf.toString();
}

/// Converts markdown content to a plain-text string (stripped of syntax).
String markdownToPlainText(String content) {
  return stripInlineMarkdown(content);
}

// ── PDF font loader ─────────────────────────────────────────────────────────

/// Cached PDF fonts loaded from app assets (IBM Plex family).
class _PdfFonts {
  _PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;
  static pw.Font? _arabicRegular;
  static pw.Font? _arabicBold;
  static pw.Font? _mono;

  static Future<void> _ensureLoaded() async {
    _regular ??= pw.Font.ttf(
      await _loadAsset('assets/fonts/IBMPlexSans-Regular.ttf'),
    );
    _bold ??= pw.Font.ttf(
      await _loadAsset('assets/fonts/IBMPlexSans-Bold.ttf'),
    );
    _arabicRegular ??= pw.Font.ttf(
      await _loadAsset('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    _arabicBold ??= pw.Font.ttf(
      await _loadAsset('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );
    _mono ??= pw.Font.ttf(
      await _loadAsset('assets/fonts/IBMPlexMono-Regular.ttf'),
    );
  }

  static Future<ByteData> _loadAsset(String path) => rootBundle.load(path);

  static pw.Font get regular => _regular!;
  static pw.Font get bold => _bold!;
  static pw.Font get mono => _mono!;

  /// Fallback list for Arabic and extended Unicode support.
  static List<pw.Font> get fallback => [_arabicRegular!, _arabicBold!];
}

// ── PDF text helper ─────────────────────────────────────────────────────────

String _pdfText(String markdown) => stripInlineMarkdown(markdown);

// ── PDF export ───────────────────────────────────────────────────────────────

/// Generates a real PDF from markdown content and shares it via native share sheet.
/// Supports full Unicode including Arabic, special characters, and arrows.
Future<void> exportMarkdownAsPdf(String content, {String? title}) async {
  await _PdfFonts._ensureLoaded();

  final blocks = parseMarkdown(content);
  final doc = pw.Document();

  final fallback = _PdfFonts.fallback;

  final baseStyle = pw.TextStyle(
    fontSize: 11,
    lineSpacing: 4,
    font: _PdfFonts.regular,
    fontFallback: fallback,
  );
  final codeStyle = pw.TextStyle(
    fontSize: 9,
    font: _PdfFonts.mono,
    lineSpacing: 3,
    fontFallback: fallback,
  );

  final widgets = <pw.Widget>[];

  for (final block in blocks) {
    switch (block) {
      case HeadingBlock():
        final sizes = [24.0, 20.0, 16.0, 14.0, 12.0, 11.0];
        final size = block.level <= sizes.length
            ? sizes[block.level - 1]
            : 11.0;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Text(
              _pdfText(block.text),
              style: pw.TextStyle(
                fontSize: size,
                fontWeight: pw.FontWeight.bold,
                font: _PdfFonts.bold,
                fontBold: _PdfFonts.bold,
                fontFallback: fallback,
              ),
            ),
          ),
        );
        if (block.level <= 2) {
          widgets.add(pw.Divider(thickness: 0.5));
        }
      case ParagraphBlock():
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(_pdfText(block.text), style: baseStyle),
          ),
        );
      case CodeBlock():
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F4F6'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              ),
              child: pw.Text(block.code, style: codeStyle),
            ),
          ),
        );
      case TableBlock():
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                font: _PdfFonts.bold,
                fontBold: _PdfFonts.bold,
                fontFallback: fallback,
              ),
              cellStyle: pw.TextStyle(
                fontSize: 10,
                font: _PdfFonts.regular,
                fontFallback: fallback,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F1F3F5'),
              ),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColor.fromHex('#D1D5DB')),
              headers: block.headers.map(stripInlineMarkdown).toList(),
              data: block.rows
                  .map((r) => r.map(stripInlineMarkdown).toList())
                  .toList(),
            ),
          ),
        );
      case BlockquoteBlock():
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Container(
              padding: const pw.EdgeInsets.only(left: 12, top: 6, bottom: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.indigo, width: 3),
                ),
              ),
              child: pw.Text(
                _pdfText(block.text),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  font: _PdfFonts.regular,
                  fontFallback: fallback,
                ),
              ),
            ),
          ),
        );
      case UnorderedListBlock():
        for (final item in block.items) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 5,
                    height: 5,
                    margin: const pw.EdgeInsets.only(top: 4, right: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey800,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(child: pw.Text(_pdfText(item), style: baseStyle)),
                ],
              ),
            ),
          );
        }
      case OrderedListBlock():
        for (var i = 0; i < block.items.length; i++) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text('${i + 1}.', style: baseStyle),
                  ),
                  pw.Expanded(
                    child: pw.Text(_pdfText(block.items[i]), style: baseStyle),
                  ),
                ],
              ),
            ),
          );
        }
      case TaskListBlock():
        for (final item in block.items) {
          final check = item.checked ? '[x]' : '[ ]';
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: pw.Text('$check ${_pdfText(item.text)}', style: baseStyle),
            ),
          );
        }
      case FrontmatterBlock():
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                font: _PdfFonts.bold,
                fontBold: _PdfFonts.bold,
                fontFallback: fallback,
              ),
              cellStyle: pw.TextStyle(
                fontSize: 10,
                font: _PdfFonts.regular,
                fontFallback: fallback,
              ),
              cellPadding: const pw.EdgeInsets.all(4),
              border: pw.TableBorder.all(color: PdfColor.fromHex('#D1D5DB')),
              headers: ['Key', 'Value'],
              data: block.data.entries.map((e) => [e.key, e.value]).toList(),
            ),
          ),
        );
      case HorizontalRuleBlock():
        widgets.add(pw.Divider());
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => widgets,
    ),
  );

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/${uniqueFileName('${title ?? 'document'}.pdf')}',
  );
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

// ── File export helper ───────────────────────────────────────────────────────

/// Writes content to a temp file and shares it via the native share sheet.
Future<void> exportContentAsFile(String content, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${uniqueFileName(fileName)}');
  await file.writeAsString(content);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}
