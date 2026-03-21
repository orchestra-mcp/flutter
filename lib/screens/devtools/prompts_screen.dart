import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/devtools/providers/prompts_provider.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Trigger metadata ────────────────────────────────────────────────────────

const _triggers = ['startup', 'manual', 'scheduled'];

Color _triggerColor(String trigger) {
  return switch (trigger) {
    'startup' => const Color(0xFF22C55E),
    'manual' => const Color(0xFF3B82F6),
    'scheduled' => const Color(0xFFF97316),
    _ => const Color(0xFF6B7280),
  };
}

String _triggerLabel(String trigger) {
  return switch (trigger) {
    'startup' => 'Startup',
    'manual' => 'Manual',
    'scheduled' => 'Scheduled',
    _ => trigger,
  };
}

// ── Main screen ─────────────────────────────────────────────────────────────

/// Prompts Manager screen with CRUD operations, search, trigger filtering,
/// enable/disable toggles, and priority display.
class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({super.key});

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _triggerFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Filtered prompts ──────────────────────────────────────────────────────

  List<Prompt> _filterPrompts(List<Prompt> prompts) {
    var filtered = prompts;

    if (_triggerFilter != null) {
      filtered = filtered.where((p) => p.trigger == _triggerFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lower = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(lower) ||
            p.prompt.toLowerCase().contains(lower) ||
            p.tags.any((t) => t.toLowerCase().contains(lower));
      }).toList();
    }

    return filtered;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _togglePrompt(Prompt prompt) async {
    try {
      await ref
          .read(promptsProvider.notifier)
          .togglePrompt(prompt.id, enabled: !prompt.enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle prompt: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deletePrompt(Prompt prompt) async {
    final tokens = ThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('Delete Prompt', style: TextStyle(color: tokens.fgBright)),
        content: Text(
          'Permanently delete "${prompt.title}"? This cannot be undone.',
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(promptsProvider.notifier).deletePrompt(prompt.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${prompt.title}" deleted'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ── Create / Edit dialog ──────────────────────────────────────────────────

  void _showPromptDialog({Prompt? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.prompt ?? '');
    final priorityCtrl = TextEditingController(
      text: (existing?.priority ?? 0).toString(),
    );
    final tagsCtrl = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    var selectedTrigger = existing?.trigger ?? 'manual';
    var isEnabled = existing?.enabled ?? true;
    final tokens = ThemeTokens.of(context);
    final isEditing = existing != null;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              title: Text(
                isEditing ? 'Edit Prompt' : 'New Prompt',
                style: TextStyle(color: tokens.fgBright),
              ),
              content: SizedBox(
                width: isDesktop ? 520 : double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      _DialogTextField(
                        controller: titleCtrl,
                        label: 'Title',
                        hint: 'My Prompt',
                        tokens: tokens,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),

                      // Prompt content (multiline, monospace)
                      TextField(
                        controller: contentCtrl,
                        maxLines: 8,
                        minLines: 8,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 13,
                          fontFamily: 'JetBrains Mono',
                          fontFamilyFallback: const ['monospace'],
                        ),
                        decoration: InputDecoration(
                          labelText: 'Prompt Content',
                          labelStyle: TextStyle(color: tokens.fgDim),
                          hintText:
                              'Enter the prompt content here...\nSupports multiple lines.',
                          hintStyle: TextStyle(
                            color: tokens.fgDim.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: tokens.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: tokens.borderFaint),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: tokens.borderFaint),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: tokens.accent),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Trigger dropdown + Priority row
                      Row(
                        children: [
                          // Trigger
                          Expanded(
                            flex: 3,
                            child: _buildTriggerDropdown(
                              tokens,
                              selectedTrigger,
                              (value) {
                                setDialogState(() => selectedTrigger = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Priority
                          Expanded(
                            flex: 2,
                            child: _DialogTextField(
                              controller: priorityCtrl,
                              label: 'Priority',
                              hint: '0',
                              tokens: tokens,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tags
                      _DialogTextField(
                        controller: tagsCtrl,
                        label: 'Tags (comma-separated)',
                        hint: 'db, setup, deploy',
                        tokens: tokens,
                      ),
                      const SizedBox(height: 12),

                      // Enabled switch
                      Row(
                        children: [
                          Text(
                            'Enabled',
                            style: TextStyle(
                              color: tokens.fgMuted,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isEnabled,
                            onChanged: (value) {
                              setDialogState(() => isEnabled = value);
                            },
                            activeThumbColor: tokens.accent,
                            inactiveTrackColor: tokens.border.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    if (title.isEmpty || content.isEmpty) return;

                    final priority =
                        int.tryParse(priorityCtrl.text.trim()) ?? 0;
                    final tags = tagsCtrl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    Navigator.pop(ctx);

                    try {
                      final notifier = ref.read(promptsProvider.notifier);
                      if (isEditing) {
                        await notifier.updatePrompt(
                          existing.id,
                          title: title,
                          prompt: content,
                          trigger: selectedTrigger,
                          priority: priority,
                          enabled: isEnabled,
                          tags: tags,
                        );
                      } else {
                        await notifier.createPrompt(
                          title: title,
                          prompt: content,
                          trigger: selectedTrigger,
                          priority: priority,
                          enabled: isEnabled,
                          tags: tags,
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing ? 'Prompt updated' : 'Prompt created',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to ${isEditing ? 'update' : 'create'}: $e',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    isEditing ? 'Save' : 'Create',
                    style: TextStyle(color: tokens.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      titleCtrl.dispose();
      contentCtrl.dispose();
      priorityCtrl.dispose();
      tagsCtrl.dispose();
    });
  }

  // ── Trigger dropdown builder ──────────────────────────────────────────────

  Widget _buildTriggerDropdown(
    OrchestraColorTokens tokens,
    String current,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      dropdownColor: tokens.bgAlt,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Trigger',
        labelStyle: TextStyle(color: tokens.fgDim),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
      items: _triggers.map((t) {
        final color = _triggerColor(t);
        return DropdownMenuItem(
          value: t,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(_triggerLabel(t)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final asyncPrompts = ref.watch(promptsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          // ── AppBar area ─────────────────────────────────────────────────
          _buildAppBar(tokens),

          // ── Prompt list ─────────────────────────────────────────────────
          Expanded(
            child: asyncPrompts.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: tokens.accent),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: tokens.fgDim,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load prompts',
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$e',
                        style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(promptsProvider),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: tokens.accent,
                        ),
                        label: Text(
                          'Retry',
                          style: TextStyle(color: tokens.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (prompts) {
                final filtered = _filterPrompts(prompts);
                if (prompts.isEmpty) {
                  return _buildEmptyState(tokens);
                }
                if (filtered.isEmpty) {
                  return _buildNoResultsState(tokens);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildPromptCard(tokens, filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showPromptDialog(),
              backgroundColor: tokens.accent,
              child: Icon(
                Icons.add_rounded,
                color: tokens.isLight ? Colors.white : tokens.bg,
              ),
            )
          : null,
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(OrchestraColorTokens tokens) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        isDesktop ? 16 : MediaQuery.paddingOf(context).top + 12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(
          bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: tokens.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prompts',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showPromptDialog(),
                  icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
                  label: Text(
                    'New Prompt',
                    style: TextStyle(color: tokens.accent, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: tokens.accent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Search + trigger filter row
          Row(
            children: [
              // Search field
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search prompts...',
                      hintStyle: TextStyle(
                        color: tokens.fgDim.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: tokens.fgDim,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: tokens.fgDim,
                              ),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.borderFaint),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: tokens.accent),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Trigger filter
              SizedBox(
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.borderFaint),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _triggerFilter,
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Trigger',
                          style: TextStyle(color: tokens.fgDim, fontSize: 13),
                        ),
                      ),
                      dropdownColor: tokens.bgAlt,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      icon: Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: _triggerFilter != null
                            ? tokens.accent
                            : tokens.fgDim,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      borderRadius: BorderRadius.circular(8),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Triggers',
                            style: TextStyle(color: tokens.fgBright),
                          ),
                        ),
                        ..._triggers.map((t) {
                          final color = _triggerColor(t);
                          return DropdownMenuItem<String?>(
                            value: t,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(_triggerLabel(t)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _triggerFilter = value);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Prompt card ───────────────────────────────────────────────────────────

  Widget _buildPromptCard(OrchestraColorTokens tokens, Prompt prompt) {
    final trigColor = _triggerColor(prompt.trigger);
    final firstLine = prompt.prompt.split('\n').first;
    final displayLine = firstLine.length > 120
        ? '${firstLine.substring(0, 120)}...'
        : firstLine;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: enabled dot + title + badges + actions ──────────
          Row(
            children: [
              // Enabled indicator dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: prompt.enabled
                      ? const Color(0xFF22C55E)
                      : tokens.fgDim.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),

              // Title
              Expanded(
                child: Text(
                  prompt.title,
                  style: TextStyle(
                    color: prompt.enabled ? tokens.fgBright : tokens.fgMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Trigger badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: trigColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _triggerLabel(prompt.trigger),
                  style: TextStyle(
                    color: trigColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.border.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'P:${prompt.priority}',
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                    fontFamilyFallback: const ['monospace'],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Toggle switch
              SizedBox(
                height: 24,
                width: 40,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: prompt.enabled,
                    onChanged: (_) => _togglePrompt(prompt),
                    activeThumbColor: tokens.accent,
                    inactiveTrackColor: tokens.border.withValues(alpha: 0.3),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Edit button
              _SmallIconButton(
                icon: Icons.edit_rounded,
                color: tokens.fgMuted,
                tooltip: 'Edit',
                onTap: () => _showPromptDialog(existing: prompt),
              ),

              // Delete button
              _SmallIconButton(
                icon: Icons.delete_outline_rounded,
                color: tokens.fgMuted,
                tooltip: 'Delete',
                onTap: () => _deletePrompt(prompt),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Prompt content preview ──────────────────────────────────────
          Text(
            displayLine,
            style: TextStyle(
              color: tokens.fgDim,
              fontSize: 13,
              fontFamily: 'JetBrains Mono',
              fontFamilyFallback: const ['monospace'],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Tags row ───────────────────────────────────────────────────
          if (prompt.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.label_outline_rounded,
                  size: 13,
                  color: tokens.fgDim,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    prompt.tags.join(', '),
                    style: TextStyle(color: tokens.fgDim, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Empty / no-results states ─────────────────────────────────────────────

  Widget _buildEmptyState(OrchestraColorTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: tokens.fgDim.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No prompts yet',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a prompt to automate your workflows.',
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showPromptDialog(),
            icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
            label: Text('New Prompt', style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(OrchestraColorTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: tokens.fgDim.withValues(alpha: 0.5),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching prompts',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter.',
            style: TextStyle(color: tokens.fgDim, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _triggerFilter = null;
              });
            },
            child: Text(
              'Clear filters',
              style: TextStyle(color: tokens.accent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable helper widgets ─────────────────────────────────────────────────

/// Compact icon button used in card action rows.
class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Styled text field used inside create/edit dialogs.
class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.tokens,
    this.autofocus = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool autofocus;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim),
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
