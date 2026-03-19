import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

/// Full-page note editor with title, markdown body, and tag chips.
///
/// Pass [noteId] = null for "create new", or a real ID to edit an existing note.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  bool get isNew => noteId == null;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  List<String> _tags = [];
  bool _loading = true;
  bool _saving = false;
  bool _preview = false;

  // ── Smart action state ──────────────────────────────────────────────────
  bool _smartMode = false;
  bool _generating = false;
  String _selectedModel = 'sonnet';
  final _promptController = TextEditingController();
  final List<_SmartEvent> _smartEvents = [];

  @override
  void initState() {
    super.initState();
    if (widget.isNew) {
      _loading = false;
      _smartMode = isDesktop;
      if (!_smartMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _titleFocus.requestFocus();
        });
      }
    } else {
      _loadNote();
    }
  }

  Future<void> _loadNote() async {
    try {
      final note = await ref
          .read(noteRepositoryProvider)
          .getById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _tags = _parseTags(note.tags);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _parseTags(String tagsJson) {
    if (tagsJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(tagsJson);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _promptController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).titleRequired)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      final content = _contentController.text;

      if (widget.isNew) {
        final id = const Uuid().v4();
        await repo.create(id: id, title: title, content: content, tags: _tags);
        if (mounted) context.go('/library/notes/$id');
      } else {
        await repo.update(
          widget.noteId!,
          title: title,
          content: content,
          tags: _tags,
        );
        if (mounted) context.go('/library/notes/${widget.noteId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToSave}: $e'),
          ),
        );
        setState(() => _saving = false);
      }
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;
    setState(() {
      _tags.add(trimmed);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: tokens.bg,
        body: Center(child: CircularProgressIndicator(color: tokens.accent)),
      );
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildToolbar(tokens),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode toggle (new notes on desktop only)
                    if (widget.isNew && isDesktop) ...[
                      _buildModeToggle(tokens),
                      const SizedBox(height: 16),
                    ],

                    // Smart Action panel OR manual form
                    if (_smartMode && widget.isNew)
                      _buildSmartActionPanel(tokens)
                    else ...[
                      // Title field
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.noteHintTitle,
                          hintStyle: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                      ),

                      const SizedBox(height: 12),

                      // Tags
                      _buildTagSection(tokens),

                      const SizedBox(height: 16),

                      // Divider
                      Divider(color: tokens.border, height: 1),

                      const SizedBox(height: 16),

                      // Content — editor or preview
                      if (_preview)
                        _buildPreview(tokens)
                      else
                        _buildEditor(tokens),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Back / Cancel
          TextButton.icon(
            onPressed: () {
              if (widget.isNew) {
                context.go('/library/notes');
              } else {
                context.go('/library/notes/${widget.noteId}');
              }
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: tokens.fgMuted,
            ),
            label: Text(
              l10n.cancel,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ),

          const Spacer(),

          // Preview toggle
          IconButton(
            onPressed: () => setState(() => _preview = !_preview),
            icon: Icon(
              _preview ? Icons.edit_rounded : Icons.visibility_rounded,
              size: 18,
              color: tokens.fgMuted,
            ),
            tooltip: _preview ? l10n.edit : l10n.preview,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 8),

          // Save button
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.isLight ? Colors.white : Colors.black,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 16),
            label: Text(widget.isNew ? l10n.create : l10n.save),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.isLight ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              minimumSize: const Size(0, 34),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              final color = _tagColor(tag);
              return Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: Icon(Icons.close_rounded, size: 14, color: color),
                onDeleted: () => _removeTag(tag),
                backgroundColor: color.withValues(alpha: 0.1),
                side: BorderSide(
                  color: color.withValues(alpha: 0.25),
                  width: 0.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.only(left: 4),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // Tag input
        SizedBox(
          height: 32,
          child: TextField(
            controller: _tagController,
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.addTagHint,
              hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
              prefixIcon: Icon(
                Icons.label_outline_rounded,
                size: 16,
                color: tokens.fgDim,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 0,
              ),
              isDense: true,
            ),
            onSubmitted: _addTag,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[,\n]')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _contentController,
      focusNode: _contentFocus,
      style: TextStyle(
        color: tokens.fgBright,
        fontSize: 14,
        height: 1.7,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: l10n.writeMarkdownHint,
        hintStyle: TextStyle(
          color: tokens.fgDim,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 20,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildPreview(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    final text = _contentController.text;
    if (text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            l10n.nothingToPreview,
            style: TextStyle(color: tokens.fgDim, fontSize: 14),
          ),
        ),
      );
    }

    return MarkdownRendererWidget(content: text);
  }

  Color _tagColor(String tag) {
    const palette = [
      Color(0xFF38BDF8),
      Color(0xFF4ADE80),
      Color(0xFFFBBF24),
      Color(0xFFF472B6),
      Color(0xFF818CF8),
      Color(0xFF2DD4BF),
      Color(0xFFFB923C),
      Color(0xFFA78BFA),
    ];
    final index =
        tag.codeUnits.fold<int>(0, (sum, c) => sum + c) % palette.length;
    return palette[index];
  }

  // ── Smart Action ────────────────────────────────────────────────────────

  static const _noteColor = Color(0xFFFBBF24);

  Widget _buildModeToggle(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _SmartModeChip(
          label: l10n.smartAction,
          icon: Icons.auto_awesome_rounded,
          isActive: _smartMode,
          activeColor: _noteColor,
          tokens: tokens,
          onTap: () => setState(() => _smartMode = true),
        ),
        const SizedBox(width: 8),
        _SmartModeChip(
          label: l10n.manual,
          icon: Icons.edit_rounded,
          isActive: !_smartMode,
          activeColor: tokens.fgMuted,
          tokens: tokens,
          onTap: () => setState(() => _smartMode = false),
        ),
      ],
    );
  }

  Widget _buildSmartActionPanel(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt input card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _noteColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _noteColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: _noteColor),
                  const SizedBox(width: 8),
                  Text(
                    l10n.describeYourNote,
                    style: TextStyle(
                      color: _noteColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _promptController,
                maxLines: 3,
                autofocus: true,
                enabled: !_generating,
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.notePromptHint,
                  hintStyle: TextStyle(
                    color: tokens.fgDim.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: tokens.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _noteColor),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: tokens.borderFaint),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: _generating ? null : (_) => _generate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Model selector
                  for (final m in const ['haiku', 'sonnet', 'opus'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _ModelChip(
                        label: m[0].toUpperCase() + m.substring(1),
                        isActive: _selectedModel == m,
                        activeColor: _noteColor,
                        tokens: tokens,
                        onTap: _generating
                            ? null
                            : () => setState(() => _selectedModel = m),
                      ),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _generating ? null : _generate,
                    icon: _generating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.isLight
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(_generating ? l10n.generating : l10n.generate),
                    style: FilledButton.styleFrom(
                      backgroundColor: _noteColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Event log
        if (_smartEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in _smartEvents)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          event.isError
                              ? Icons.error_outline_rounded
                              : event.isDone
                              ? Icons.check_circle_outline_rounded
                              : Icons.circle_outlined,
                          size: 14,
                          color: event.isError
                              ? const Color(0xFFEF4444)
                              : event.isDone
                              ? const Color(0xFF22C55E)
                              : tokens.fgDim,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.message,
                            style: TextStyle(
                              color: event.isError
                                  ? const Color(0xFFEF4444)
                                  : tokens.fgMuted,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_generating)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Shimmer.fromColors(
                      baseColor: tokens.bgAlt,
                      highlightColor: tokens.border,
                      child: Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: tokens.bgAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _addEvent(String message, {bool isError = false, bool isDone = false}) {
    setState(() {
      _smartEvents.add(_SmartEvent(message, isError: isError, isDone: isDone));
    });
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final mcp = ref.read(mcpClientProvider);
    if (mcp == null) {
      _addEvent(l10n.mcpNotAvailable, isError: true);
      return;
    }

    setState(() {
      _generating = true;
      _smartEvents.clear();
    });

    _addEvent(l10n.sendingPrompt);

    try {
      const systemPrompt =
          'You are creating a note. '
          'Output ONLY a valid JSON object with these fields:\n'
          '{"title": string (required), "content": string (detailed markdown content), '
          '"tags": [array of short tag strings]}\n\n'
          'Rules:\n'
          '- Output ONLY the raw JSON object. No markdown code fences. No explanation.\n'
          '- All values must be strings except tags which is an array of strings.\n'
          '- For the content field, use proper markdown formatting.\n'
          '- Tags should be short, lowercase, relevant keywords.';

      _addEvent(l10n.aiGenerating);

      final result = await mcp.callTool('ai_prompt', {
        'prompt': prompt,
        'system_prompt': systemPrompt,
        'wait': true,
        'model': _selectedModel,
        'permission_mode': 'bypassPermissions',
        'max_budget': 0.05,
      }, timeout: const Duration(seconds: 300));

      _addEvent(l10n.responseReceived);

      // Check for tool-level error
      if (result['isError'] == true) {
        final c = result['content'];
        final errText = (c is List && c.isNotEmpty && c[0] is Map)
            ? c[0]['text']?.toString() ?? 'Unknown error'
            : 'Unknown error';
        _addEvent('AI error: $errText', isError: true);
        setState(() => _generating = false);
        return;
      }

      final parsed = _unwrapAndParse(result);
      if (parsed == null) {
        _addEvent(l10n.failedToParse, isError: true);
        setState(() => _generating = false);
        return;
      }

      // Populate title
      final title = parsed['title']?.toString();
      if (title != null && title.isNotEmpty) {
        _titleController.text = title;
      }

      // Populate content
      final content = parsed['content']?.toString();
      if (content != null && content.isNotEmpty) {
        _contentController.text = content;
      }

      // Populate tags
      final rawTags = parsed['tags'];
      if (rawTags is List) {
        _tags = rawTags.map((t) => t.toString()).toList();
      } else if (rawTags is String && rawTags.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawTags);
          if (decoded is List) {
            _tags = decoded.map((t) => t.toString()).toList();
          }
        } catch (_) {
          _tags = rawTags.split(',').map((t) => t.trim()).toList();
        }
      }

      _addEvent(l10n.noteGenerated, isDone: true);

      // Switch to manual mode for review
      setState(() {
        _generating = false;
        _smartMode = false;
      });
    } catch (e) {
      _addEvent(
        'Error: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
      setState(() => _generating = false);
    }
  }

  Map<String, dynamic>? _unwrapAndParse(Map<String, dynamic> result) {
    String? text;
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        text = first['text'] as String?;
      }
    }
    text ??= result['response'] as String? ?? result['text'] as String?;
    if (text == null || text.isEmpty) return null;

    text = text.trim();

    // The bridge returns a JSON envelope: {"response":"...", "session_id":"...", ...}
    // The actual AI output is in the "response" field.
    try {
      final envelope = jsonDecode(text);
      if (envelope is Map<String, dynamic> &&
          envelope.containsKey('response')) {
        text = envelope['response']?.toString() ?? text;
      }
    } catch (_) {
      // Not a bridge envelope — use text as-is
    }

    text = text!.trim();

    // Strip markdown code fences
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length >= 3) {
        lines.removeAt(0);
        if (lines.last.trim() == '```') lines.removeLast();
        text = lines.join('\n').trim();
      }
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Try extracting JSON object from surrounding text
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          final sub = text.substring(start, end + 1);
          final decoded = jsonDecode(sub);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {}
      }
    }
    return null;
  }
}

// ── Smart Action helpers ──────────────────────────────────────────────────────

class _SmartEvent {
  const _SmartEvent(this.message, {this.isError = false, this.isDone = false});
  final String message;
  final bool isError;
  final bool isDone;
}

class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final OrchestraColorTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.4)
                : tokens.borderFaint,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : tokens.fgDim,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SmartModeChip extends StatelessWidget {
  const _SmartModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.4)
                : tokens.borderFaint,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? activeColor : tokens.fgDim),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : tokens.fgDim,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
