import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Universal Action Types
// ---------------------------------------------------------------------------

/// All entity types that can be created from the universal create dialog.
enum UniversalActionType {
  note,
  agent,
  skill,
  workflow,
  doc,
  feature,
  plan,
  request,
  person,
  healthBrief,
}

/// Backward-compatible alias so existing callers that import [SmartActionType]
/// keep compiling. The old enum had only 4 values; the new one has 10.
@Deprecated('Use UniversalActionType instead')
enum SmartActionType { note, agent, skill, workflow }

// ---------------------------------------------------------------------------
// Type metadata
// ---------------------------------------------------------------------------

class _ActionTypeMeta {
  const _ActionTypeMeta({
    required this.label,
    required this.icon,
    required this.color,
    this.aiHint,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? aiHint;

  static _ActionTypeMeta of(UniversalActionType type) => switch (type) {
    UniversalActionType.note => const _ActionTypeMeta(
      label: 'Note',
      icon: Icons.sticky_note_2_rounded,
      color: Color(0xFFFBBF24),
      aiHint: 'e.g. Write meeting notes about...',
    ),
    UniversalActionType.agent => const _ActionTypeMeta(
      label: 'Agent',
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFA78BFA),
      aiHint: 'e.g. Create an agent for code reviews...',
    ),
    UniversalActionType.skill => const _ActionTypeMeta(
      label: 'Skill',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF97316),
      aiHint: 'e.g. Create a skill that generates docs...',
    ),
    UniversalActionType.workflow => const _ActionTypeMeta(
      label: 'Workflow',
      icon: Icons.account_tree_rounded,
      color: Color(0xFFEC4899),
      aiHint: 'e.g. Create a scrum workflow...',
    ),
    UniversalActionType.doc => const _ActionTypeMeta(
      label: 'Doc',
      icon: Icons.description_rounded,
      color: Color(0xFF60A5FA),
      aiHint: 'e.g. Write a getting started guide...',
    ),
    UniversalActionType.feature => const _ActionTypeMeta(
      label: 'Feature',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00E5FF),
      aiHint: 'e.g. Add dark mode support...',
    ),
    UniversalActionType.plan => const _ActionTypeMeta(
      label: 'Plan',
      icon: Icons.map_rounded,
      color: Color(0xFF4ADE80),
      aiHint: 'e.g. Plan the API migration in 3 phases...',
    ),
    UniversalActionType.request => const _ActionTypeMeta(
      label: 'Request',
      icon: Icons.inbox_rounded,
      color: Color(0xFFFBBF24),
      aiHint: 'e.g. Request a bulk export feature...',
    ),
    UniversalActionType.person => const _ActionTypeMeta(
      label: 'Person',
      icon: Icons.person_rounded,
      color: Color(0xFF818CF8),
      aiHint: 'e.g. Add team member Sarah, senior engineer...',
    ),
    UniversalActionType.healthBrief => const _ActionTypeMeta(
      label: 'Health Brief',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF4444),
      aiHint: "Generate a health brief from today's data",
    ),
  };
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Opens the universal create dialog.
///
/// When [preselectedType] is provided the dialog skips the type-picker grid
/// and jumps directly to the AI/Manual form for that type.
void showUniversalCreateMenu(
  BuildContext context,
  WidgetRef ref, {
  UniversalActionType? preselectedType,
  String? projectId,
  required void Function(UniversalActionType type, String title, String content)
  onCreate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _UniversalCreateDialog(
      preselectedType: preselectedType,
      projectId: projectId,
      ref: ref,
      onCreate: onCreate,
    ),
  );
}

/// Legacy entry-point kept for backward compatibility.
@Deprecated('Use showUniversalCreateMenu instead')
void showCreateMenu(
  BuildContext context,
  WidgetRef ref, {
  required SmartActionType type,
  required void Function(String title, String content) onManualCreate,
  required void Function(String title, String content) onSmartCreate,
}) {
  final universalType = switch (type) {
    SmartActionType.note => UniversalActionType.note,
    SmartActionType.agent => UniversalActionType.agent,
    SmartActionType.skill => UniversalActionType.skill,
    SmartActionType.workflow => UniversalActionType.workflow,
  };
  showUniversalCreateMenu(
    context,
    ref,
    preselectedType: universalType,
    onCreate: (_, title, content) => onSmartCreate(title, content),
  );
}

// ---------------------------------------------------------------------------
// _UniversalCreateDialog
// ---------------------------------------------------------------------------

class _UniversalCreateDialog extends StatefulWidget {
  const _UniversalCreateDialog({
    required this.ref,
    required this.onCreate,
    this.preselectedType,
    this.projectId,
  });

  final WidgetRef ref;
  final UniversalActionType? preselectedType;
  final String? projectId;
  final void Function(UniversalActionType type, String title, String content)
  onCreate;

  @override
  State<_UniversalCreateDialog> createState() => _UniversalCreateDialogState();
}

class _UniversalCreateDialogState extends State<_UniversalCreateDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _promptController = TextEditingController();
  final _titleController = TextEditingController();
  bool _generating = false;

  // Streaming state
  String _streamedText = '';
  bool _streamComplete = false;
  StreamSubscription<Map<String, dynamic>>? _chunkSubscription;

  /// The selected type. `null` means the type-picker grid is shown.
  UniversalActionType? _selectedType;

  /// Whether the user arrived via [preselectedType] (hides back button).
  bool _lockedType = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType;
    _lockedType = widget.preselectedType != null;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _chunkSubscription?.cancel();
    _tabController.dispose();
    _promptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _selectType(UniversalActionType type) {
    setState(() {
      _selectedType = type;
      _promptController.clear();
      _titleController.clear();
      _generating = false;
      _streamedText = '';
      _streamComplete = false;
      // For healthBrief, auto-fill prompt and stay on AI tab.
      if (type == UniversalActionType.healthBrief) {
        _promptController.text = _ActionTypeMeta.of(type).aiHint ?? '';
        _tabController.index = 0;
      } else {
        _tabController.index = 0;
      }
    });
  }

  void _goBackToGrid() {
    _chunkSubscription?.cancel();
    setState(() {
      _selectedType = null;
      _promptController.clear();
      _titleController.clear();
      _generating = false;
      _streamedText = '';
      _streamComplete = false;
    });
  }

  // ---- Streaming AI generation ----

  Future<void> _generateWithAI(UniversalActionType type, String prompt) async {
    final mcp = widget.ref.read(mcpClientProvider);
    if (mcp == null) return;

    setState(() {
      _generating = true;
      _streamedText = '';
      _streamComplete = false;
    });

    try {
      final typeLabel = _ActionTypeMeta.of(type).label;

      // The webgate sends ALL chunks as notifications/stream_chunk messages
      // BEFORE sending the final JSON-RPC response. We must subscribe to
      // mcp.notifications BEFORE initiating the call so chunks are not missed
      // on the broadcast stream.
      //
      // Chunks arrive as: {method: 'notifications/stream_chunk', params: {stream_id, data}}
      // where `data` is the raw JSON string of a ChatEvent.
      // We buffer them until the final response resolves with the stream_id.
      String? resolvedStreamId;
      final bufferedChunks = <Map<String, dynamic>>[];

      unawaited(_chunkSubscription?.cancel());
      _chunkSubscription = mcp.notifications.listen((message) {
        if (!mounted) {
          _chunkSubscription?.cancel();
          return;
        }

        final method = message['method'] as String?;
        if (method != 'notifications/stream_chunk') return;

        final params = message['params'] as Map<String, dynamic>?;
        if (params == null) return;

        final chunkStreamId = params['stream_id'] as String?;
        final data = params['data'] as String?;
        if (chunkStreamId == null || data == null) return;

        if (resolvedStreamId != null) {
          // Stream id known — only process matching chunks.
          if (chunkStreamId != resolvedStreamId) return;
          _applyChunk(data);
        } else {
          // Stream id not yet known — buffer all chunks for processing later.
          bufferedChunks.add(params);
        }
      });

      // Initiate the streaming call. Chunks arrive on the notification stream
      // (already subscribed above) while this future resolves.
      final result = await mcp.callToolStreaming('ai_prompt_stream', {
        'prompt':
            'Generate a $typeLabel in markdown format based on this request: $prompt',
      });

      // The stream_id in the final response matches the gate-st-{id} prefix.
      final streamId =
          result['stream_id'] as String? ??
          (result['content'] is List ? null : result['stream_id'] as String?);

      if (streamId == null) {
        // No stream_id: streaming completed inline. The fallback text from
        // the final response contains the full result.
        unawaited(_chunkSubscription?.cancel());
        _chunkSubscription = null;
        final text = _extractText(result);
        if (mounted && text != null && !text.startsWith('[streamed ')) {
          setState(() {
            _streamedText = text;
            _streamComplete = true;
          });
        } else if (mounted && _streamedText.isNotEmpty) {
          // Chunks arrived and were applied; mark complete.
          setState(() => _streamComplete = true);
        }
        return;
      }

      // Apply any buffered chunks that arrived before we knew the stream_id.
      resolvedStreamId = streamId;
      for (final p in bufferedChunks) {
        if (p['stream_id'] == streamId) {
          _applyChunk(p['data'] as String);
        }
      }

      // Mark complete — all chunks have been sent before the final response.
      if (mounted) setState(() => _streamComplete = true);
      unawaited(_chunkSubscription?.cancel());
      _chunkSubscription = null;
    } catch (e) {
      debugPrint('[SmartAction] AI streaming failed: $e');
      if (mounted) {
        unawaited(_chunkSubscription?.cancel());
        _chunkSubscription = null;
        setState(() {
          _generating = false;
          _streamComplete = false;
        });
      }
    }
  }

  /// Apply a single chunk: parse the ChatEvent JSON and extract text.
  void _applyChunk(String data) {
    try {
      final event = jsonDecode(data) as Map<String, dynamic>?;
      if (event == null) return;
      final type = event['type'] as String?;
      final text = event['text'] as String?;
      if (type == 'text_chunk' && text != null && text.isNotEmpty && mounted) {
        setState(() => _streamedText += text);
      }
    } catch (_) {
      // Raw text chunk — append directly.
      if (data.isNotEmpty && mounted) {
        setState(() => _streamedText += data);
      }
    }
  }

  /// Extract text content from a non-streaming MCP tool result.
  String? _extractText(Map<String, dynamic> result) {
    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        return first['text'] as String?;
      }
    }
    return result['text'] as String?;
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Dialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _selectedType == null
              ? _buildTypeGrid(tokens)
              : _buildFormStep(tokens),
        ),
      ),
    );
  }

  // ---- Step 1: Type grid ----

  Widget _buildTypeGrid(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('type-grid'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.newEntityTitle('Item'),
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: tokens.fgDim, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.whatToCreate,
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),

        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: UniversalActionType.values
                  .map(
                    (t) => _TypeChip(
                      type: t,
                      tokens: tokens,
                      onTap: () => _selectType(t),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Step 2: AI / Manual form ----

  Widget _buildFormStep(OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);
    final type = _selectedType!;
    final meta = _ActionTypeMeta.of(type);
    final isHealthBrief = type == UniversalActionType.healthBrief;

    return Column(
      key: const ValueKey('form-step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 12, 0),
          child: Row(
            children: [
              if (!_lockedType)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: tokens.fgDim,
                    size: 20,
                  ),
                  onPressed: _goBackToGrid,
                ),
              if (_lockedType) const SizedBox(width: 12),
              Icon(meta.icon, color: meta.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.newEntityTitle(meta.label),
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: tokens.fgDim, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Tab bar (hide Manual tab for healthBrief)
        if (!isHealthBrief)
          TabBar(
            controller: _tabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgDim,
            indicatorColor: tokens.accent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                text: l10n.smartCreateAi,
              ),
              Tab(
                icon: const Icon(Icons.edit_rounded, size: 16),
                text: l10n.createManually,
              ),
            ],
          ),

        if (isHealthBrief) const SizedBox(height: 8),

        const SizedBox(height: 8),

        // Tab content
        Expanded(
          child: isHealthBrief
              ? _buildAiTab(tokens, l10n, type)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAiTab(tokens, l10n, type),
                    _buildManualTab(tokens, l10n, type),
                  ],
                ),
        ),
      ],
    );
  }

  // ---- AI tab ----

  Widget _buildAiTab(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    UniversalActionType type,
  ) {
    final meta = _ActionTypeMeta.of(type);

    // ---- Streaming / complete state ----
    if (_generating) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt preview (dimmed, non-editable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _promptController.text.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),

            // Streaming output area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bgAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    _streamedText.isEmpty ? ' ' : _streamedText,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontFamily: 'JetBrains Mono',
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom action row
            if (_streamComplete)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _chunkSubscription?.cancel();
                        setState(() {
                          _generating = false;
                          _streamedText = '';
                          _streamComplete = false;
                        });
                      },
                      child: Text(
                        l10n.discard,
                        style: TextStyle(color: tokens.fgDim),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final title = _promptController.text.trim();
                        final displayTitle = title.length > 40
                            ? '${title.substring(0, 40)}...'
                            : title;
                        Navigator.pop(context);
                        widget.onCreate(type, displayTitle, _streamedText);
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(l10n.useResult),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.generating,
                    style: TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // ---- Default state: prompt input + generate button ----
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              autofocus: true,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(color: tokens.fgBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: meta.aiHint ?? l10n.describeWhatToCreate,
                hintStyle: TextStyle(color: tokens.fgDim),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final prompt = _promptController.text.trim();
              if (prompt.isEmpty) return;
              _generateWithAI(type, prompt);
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(l10n.generate),
          ),
        ],
      ),
    );
  }

  // ---- Manual tab ----

  Widget _buildManualTab(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    UniversalActionType type,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            autofocus: false,
            style: TextStyle(color: tokens.fgBright, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.title,
              hintStyle: TextStyle(color: tokens.fgDim),
              filled: true,
              fillColor: tokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {
              final title = _titleController.text.trim();
              Navigator.pop(context);
              widget.onCreate(type, title, '');
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TypeChip — a single cell in the type-picker grid
// ---------------------------------------------------------------------------

class _TypeChip extends StatefulWidget {
  const _TypeChip({
    required this.type,
    required this.tokens,
    required this.onTap,
  });

  final UniversalActionType type;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  State<_TypeChip> createState() => _TypeChipState();
}

class _TypeChipState extends State<_TypeChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final meta = _ActionTypeMeta.of(widget.type);
    final bgAlpha = _hovering ? 0.2 : 0.1;
    const borderAlpha = 0.3;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: meta.color.withValues(alpha: borderAlpha),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(meta.icon, size: 20, color: meta.color),
              const SizedBox(height: 6),
              Text(
                meta.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.tokens.fgBright,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
