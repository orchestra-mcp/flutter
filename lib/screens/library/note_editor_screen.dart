import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/notifications/notification_store.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/widgets/markdown_editor.dart';
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

  // ── Smart action state ──────────────────────────────────────────────────
  bool _smartMode = false;
  bool _generating = false;
  String _selectedModel = 'sonnet';
  final _promptController = TextEditingController();

  // CLI-style spinner state
  static const _spinnerChars = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏',
  ];
  int _spinnerIndex = 0;
  Timer? _spinnerTimer;
  String _currentStatus = '';
  final _stopwatch = Stopwatch();
  bool _spinnerComplete = false;
  bool _spinnerError = false;
  String _errorMessage = '';

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

  void _startSpinner() {
    _spinnerIndex = 0;
    _spinnerComplete = false;
    _spinnerError = false;
    _errorMessage = '';
    _currentStatus = '';
    _stopwatch.reset();
    _stopwatch.start();
    _spinnerTimer?.cancel();
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(
        () => _spinnerIndex = (_spinnerIndex + 1) % _spinnerChars.length,
      );
    });
  }

  void _stopSpinner({bool error = false, String? errorMsg}) {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
    _stopwatch.stop();
    if (error) {
      _spinnerError = true;
      _errorMessage = errorMsg ?? 'Error';
    } else {
      _spinnerComplete = true;
    }
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
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
            // Smart mode: scrollable panel
            if (_smartMode && widget.isNew)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isNew && isDesktop) ...[
                        _buildModeToggle(tokens),
                        const SizedBox(height: 16),
                      ],
                      _buildSmartActionPanel(tokens),
                    ],
                  ),
                ),
              )
            // Manual mode: title + tags scroll, editor fills remaining space
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isNew && isDesktop) ...[
                        _buildModeToggle(tokens),
                        const SizedBox(height: 16),
                      ],
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

                      const SizedBox(height: 8),

                      // Rich Markdown editor with toolbar + preview
                      Expanded(
                        child: MarkdownEditor(
                          controller: _contentController,
                          hintText: l10n.writeMarkdownHint,
                        ),
                      ),
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

        // CLI-style spinner status
        if (_generating || _spinnerComplete || _spinnerError) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(
                      _spinnerError
                          ? 'err'
                          : _spinnerComplete
                          ? 'done'
                          : _currentStatus,
                    ),
                    children: [
                      if (_spinnerError)
                        Text(
                          '✗ ',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        )
                      else if (_spinnerComplete)
                        Text(
                          '✓ ',
                          style: TextStyle(
                            color: const Color(0xFF22C55E),
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        )
                      else
                        Text(
                          '${_spinnerChars[_spinnerIndex]} ',
                          style: TextStyle(
                            color: _noteColor,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _spinnerError
                              ? _errorMessage
                              : _spinnerComplete
                              ? 'Done (${_stopwatch.elapsed.inSeconds}s)'
                              : _currentStatus.isEmpty
                              ? 'Starting...'
                              : _currentStatus,
                          style: TextStyle(
                            color: _spinnerError
                                ? const Color(0xFFEF4444)
                                : _spinnerComplete
                                ? const Color(0xFF22C55E)
                                : tokens.fgMuted,
                            fontSize: 13,
                            fontFamily: 'monospace',
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      if (!_spinnerComplete && !_spinnerError)
                        Text(
                          '${_stopwatch.elapsed.inSeconds}s',
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
                if (_generating)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Shimmer.fromColors(
                      baseColor: tokens.bgAlt,
                      highlightColor: tokens.border,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: tokens.bgAlt,
                          borderRadius: BorderRadius.circular(2),
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

  void _setStatus(String status) {
    if (!mounted) return;
    setState(() => _currentStatus = status);
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final mcp = ref.read(mcpClientProvider);
    if (mcp == null) {
      setState(() {
        _spinnerError = true;
        _errorMessage = l10n.mcpNotAvailable;
      });
      return;
    }

    setState(() => _generating = true);
    _startSpinner();
    _setStatus(l10n.sendingPrompt);

    try {
      final fullPrompt =
          '$prompt\n\n'
          'Use the available tools to scan the project, read relevant files, '
          'and write a comprehensive markdown note based on what you find. '
          'Your final response should be the complete note content in markdown format.';

      _setStatus('Launching $_selectedModel...');

      // Listen for real-time events from the bridge.
      StreamSubscription<Map<String, dynamic>>? eventSub;
      eventSub = mcp.notifications.listen((json) {
        final result = json['result'] as Map<String, dynamic>?;
        if (result != null && result['method'] == 'notifications/events') {
          final params = result['params'];
          if (params is List) {
            for (final event in params) {
              if (event is! Map<String, dynamic>) continue;
              final type = event['type']?.toString() ?? '';
              final text = event['text']?.toString() ?? '';

              if (!mounted) continue;
              switch (type) {
                case 'text_chunk':
                  if (text.trim().isNotEmpty) {
                    final preview = text.trim();
                    _setStatus(
                      preview.length > 80
                          ? '${preview.substring(0, 77)}...'
                          : preview,
                    );
                  }
                case 'tool_start':
                  final toolName = event['tool_name']?.toString() ?? text;
                  if (toolName.isNotEmpty) _setStatus('⚡ $toolName');
                case 'tool_end':
                  final toolName = event['tool_name']?.toString() ?? '';
                  if (toolName.isNotEmpty) _setStatus('✓ $toolName');
                case 'thinking':
                  if (text.isNotEmpty) {
                    _setStatus(
                      text.length > 60 ? '${text.substring(0, 57)}...' : text,
                    );
                  }
              }
            }
          }
        }
      });

      final sw = Stopwatch()..start();
      debugPrint(
        '[SmartAction] Calling ai_prompt wait=true, model=$_selectedModel',
      );
      final result = await mcp.callTool('ai_prompt', {
        'prompt': fullPrompt,
        'model': _selectedModel,
        'permission_mode': 'bypassPermissions',
        'max_budget': 1.00,
        'wait': true,
      }, timeout: const Duration(minutes: 10));

      await eventSub.cancel();
      sw.stop();

      var responseText = _extractAiResponse(result);
      debugPrint(
        '[SmartAction] Done in ${sw.elapsedMilliseconds}ms, response: ${responseText.length} chars',
      );
      debugPrint(
        '[SmartAction] Response preview: ${responseText.substring(0, responseText.length.clamp(0, 200))}',
      );
      _setStatus('Processing response...');

      // If the AI used create_note tool, redirect to the created note.
      final noteIdMatch = RegExp(r'note-([a-f0-9]+)').firstMatch(responseText);
      if (noteIdMatch != null) {
        final noteId = 'note-${noteIdMatch.group(1)}';
        debugPrint('[SmartAction] AI created note $noteId — redirecting');
        _setStatus('Note created — opening...');

        // Extract title for the notification.
        String noteTitle = prompt.length > 40
            ? '${prompt.substring(0, 37)}...'
            : prompt;
        try {
          final noteResult = await mcp.callTool('get_note', {
            'id': noteId,
          }, timeout: const Duration(seconds: 10));
          final noteText = _extractText(noteResult);
          final titleMatch = RegExp(r'title:\s*(.+)').firstMatch(noteText);
          if (titleMatch != null) {
            noteTitle = titleMatch.group(1)!.trim().replaceAll('"', '');
          }
        } catch (_) {}

        _stopSpinner();
        ref
            .read(notificationStoreProvider.notifier)
            .addSmartActionComplete(noteTitle, noteId: noteId);
        ref.read(notesRefreshProvider.notifier).refresh();
        setState(() => _generating = false);

        if (mounted) {
          context.go('/library/notes/$noteId');
        }
        return;
      }

      // No note ID found — AI returned content directly. Save it ourselves.
      if (responseText.isEmpty || responseText.length < 20) {
        _stopSpinner(error: true, errorMsg: 'No content generated');
        setState(() => _generating = false);
        return;
      }

      // Parse title from content.
      String title = prompt.length > 60
          ? '${prompt.substring(0, 57)}...'
          : prompt;
      for (final line in responseText.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#')) {
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          break;
        }
      }

      // Save via MCP and redirect to the new note.
      String? savedNoteId;
      try {
        final saveResult = await mcp.callTool('create_note', {
          'title': title,
          'body': responseText,
          'project_id': '.global',
        }, timeout: const Duration(seconds: 10));
        final saveText = _extractText(saveResult);
        final idMatch = RegExp(r'note-([a-f0-9]+)').firstMatch(saveText);
        if (idMatch != null) savedNoteId = 'note-${idMatch.group(1)}';
      } catch (e) {
        debugPrint('[SmartAction] MCP save failed: $e');
      }

      _stopSpinner();
      ref
          .read(notificationStoreProvider.notifier)
          .addSmartActionComplete(title, noteId: savedNoteId);
      ref.read(notesRefreshProvider.notifier).refresh();
      setState(() => _generating = false);

      if (mounted && savedNoteId != null) {
        context.go('/library/notes/$savedNoteId');
      } else if (mounted) {
        // Fallback: populate editor with content if we can't redirect.
        _titleController.text = title;
        _contentController.text = responseText;
        _tags = ['ai-generated'];
        setState(() => _smartMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note "$title" generated!'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('[SmartAction] AI generation failed: $e');
      _stopSpinner(
        error: true,
        errorMsg: e.toString().replaceAll('Exception: ', ''),
      );
      setState(() => _generating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generation failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Extract the AI-generated content from the bridge response.
  /// The bridge wraps the response in a JSON envelope:
  /// {"response": "actual content", "cost_usd": 0.1, "model": "..."}
  String _extractAiResponse(Map<String, dynamic> result) {
    final raw = _extractText(result);

    // Try to parse as bridge envelope JSON.
    try {
      final envelope = jsonDecode(raw);
      if (envelope is Map<String, dynamic>) {
        final response = envelope['response']?.toString() ?? '';
        if (response.isNotEmpty) return response;
      }
    } catch (_) {}

    // Not an envelope — use raw text.
    // Strip markdown code fences if present.
    var text = raw.trim();
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length >= 3) {
        lines.removeAt(0);
        if (lines.last.trim() == '```') lines.removeLast();
        text = lines.join('\n').trim();
      }
    }

    return text;
  }

  /// Extract text from an MCP tool result (handles content array format).
  String _extractText(Map<String, dynamic> result) {
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['text'] != null) {
        return first['text'].toString();
      }
    }
    return result['response']?.toString() ??
        result['text']?.toString() ??
        result.toString();
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

      // Fallback: AI returned plain text — use it as content directly.
      if (text.length > 10) {
        final lines = text.split('\n');
        final title = lines.first.replaceAll(RegExp(r'^#+\s*'), '').trim();
        return {
          'title': title.isNotEmpty ? title : 'AI Generated Note',
          'content': text,
          'tags': <String>[],
        };
      }
    }
    return null;
  }
}

// ── Smart Action helpers ──────────────────────────────────────────────────────

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
