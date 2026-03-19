import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// The type of item being created via smart action.
enum SmartActionType { note, agent, skill, workflow }

/// Shows a dialog to create content via AI (smart action) or manually.
void showCreateMenu(
  BuildContext context,
  WidgetRef ref, {
  required SmartActionType type,
  required void Function(String title, String content) onManualCreate,
  required void Function(String title, String content) onSmartCreate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _CreateDialog(
      type: type,
      ref: ref,
      onManualCreate: onManualCreate,
      onSmartCreate: onSmartCreate,
    ),
  );
}

Future<String?> _generateWithAI(
  WidgetRef ref,
  SmartActionType type,
  String prompt,
) async {
  final mcp = ref.read(mcpClientProvider);
  if (mcp == null) return null;

  try {
    final typeLabel = type.name;
    final result = await mcp.callTool('ai_prompt', {
      'prompt':
          'Generate a $typeLabel in markdown format based on this request: $prompt',
      'wait': true,
    });

    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        return first['text'] as String?;
      }
    }
    return result['text'] as String?;
  } catch (e) {
    debugPrint('[SmartAction] AI generation failed: $e');
    return null;
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({
    required this.type,
    required this.ref,
    required this.onManualCreate,
    required this.onSmartCreate,
  });

  final SmartActionType type;
  final WidgetRef ref;
  final void Function(String title, String content) onManualCreate;
  final void Function(String title, String content) onSmartCreate;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _promptController = TextEditingController();
  final _titleController = TextEditingController();
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    // AI tab first (index 0), Manual tab second (index 1)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final typeLabel = widget.type.name;
    final typeName = '${typeLabel[0].toUpperCase()}${typeLabel.substring(1)}';

    return Dialog(
      backgroundColor: tokens.bgAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.newEntityTitle(typeName),
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: tokens.fgDim,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab bar
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

            const SizedBox(height: 8),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // AI tab
                  _buildAiTab(tokens, l10n, typeLabel),
                  // Manual tab
                  _buildManualTab(tokens, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTab(
    OrchestraColorTokens tokens,
    AppLocalizations l10n,
    String typeLabel,
  ) {
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
                hintText: l10n.describeWhatToCreate,
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
            onPressed: _generating
                ? null
                : () async {
                    final prompt = _promptController.text.trim();
                    if (prompt.isEmpty) return;
                    setState(() => _generating = true);
                    final title = prompt.length > 40
                        ? '${prompt.substring(0, 40)}...'
                        : prompt;
                    final content = await _generateWithAI(
                      widget.ref,
                      widget.type,
                      prompt,
                    );
                    if (mounted) Navigator.pop(context);
                    if (content != null) {
                      widget.onSmartCreate(title, content);
                    }
                  },
            icon: _generating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.fgBright,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(_generating ? l10n.generating : l10n.generate),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab(OrchestraColorTokens tokens, AppLocalizations l10n) {
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
              widget.onManualCreate(title, '');
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l10n.create),
          ),
        ],
      ),
    );
  }
}
