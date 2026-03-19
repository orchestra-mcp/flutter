/// Flutter markdown rendering components.
///
/// Provides a GitHub-flavored markdown renderer with:
/// - Syntax-highlighted code blocks with export context menu
/// - Data tables with sortable columns and export context menu
/// - Inline formatting (bold, italic, strikethrough, code, links)
/// - Task lists, blockquotes, frontmatter, headings, lists
library;

export 'code_block_widget.dart';
export 'inline_formatter.dart' hide LinkCallback;
export 'markdown_data_table.dart';
export 'markdown_parser.dart';
export 'markdown_renderer.dart';
export 'syntax_highlighter.dart';
