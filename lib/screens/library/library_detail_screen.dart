import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/widgets/markdown/markdown_renderer.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';

// -- Item type enum -----------------------------------------------------------

enum LibraryItemType { agent, skill, workflow, doc }

// -- Type metadata ------------------------------------------------------------

/// Visual metadata for each [LibraryItemType]: display label, icon, and color.
class _TypeMeta {
  const _TypeMeta({
    required this.label,
    required this.icon,
    required this.color,
    required this.listRoute,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String listRoute;

  static _TypeMeta of(LibraryItemType type, AppLocalizations l10n) =>
      switch (type) {
        LibraryItemType.agent => _TypeMeta(
            label: l10n.agents,
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFFA78BFA),
            listRoute: Routes.agents,
          ),
        LibraryItemType.skill => _TypeMeta(
            label: l10n.skills,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF97316),
            listRoute: Routes.skills,
          ),
        LibraryItemType.workflow => _TypeMeta(
            label: l10n.workflows,
            icon: Icons.account_tree_rounded,
            color: const Color(0xFFEC4899),
            listRoute: Routes.workflows,
          ),
        LibraryItemType.doc => _TypeMeta(
            label: l10n.docs,
            icon: Icons.description_rounded,
            color: const Color(0xFF60A5FA),
            listRoute: Routes.docs,
          ),
      };
}

// -- Provider to find a single item from the list provider --------------------

/// Family provider that looks up a single library item by [itemType] and
/// [itemId]. First tries the cached list, then fetches the full item from
/// the API to ensure all fields (content, description, etc.) are present.
final _libraryItemProvider = FutureProvider.family<Map<String, dynamic>?,
    ({LibraryItemType type, String id})>((ref, params) async {
  final api = ref.watch(apiClientProvider);

  // Try fetching the full item directly from the API first.
  try {
    final item = await switch (params.type) {
      LibraryItemType.agent => api.getAgent(params.id),
      LibraryItemType.skill => api.getSkill(params.id),
      LibraryItemType.workflow => api.getWorkflow(params.id),
      LibraryItemType.doc => api.getDoc(params.id),
    };
    return item;
  } catch (_) {
    // API fetch failed — fall back to list provider lookup.
  }

  final listProvider = switch (params.type) {
    LibraryItemType.agent => agentsProvider,
    LibraryItemType.skill => skillsProvider,
    LibraryItemType.workflow => workflowsProvider,
    LibraryItemType.doc => docsProvider,
  };
  final items = await ref.watch(listProvider.future);
  if (items == null) return null;
  try {
    return items.firstWhere((item) => item['id'] == params.id);
  } catch (_) {
    try {
      return items.firstWhere((item) => item['name'] == params.id);
    } catch (_) {
      try {
        return items.firstWhere((item) => item['title'] == params.id);
      } catch (_) {
        return null;
      }
    }
  }
});

// -- Screen -------------------------------------------------------------------

/// Generic detail screen for library items (agents, skills, workflows, docs).
///
/// Accepts [itemId] and [itemType] as params, loads the item from the
/// appropriate list provider, and displays type-specific metadata and content.
class LibraryDetailScreen extends ConsumerStatefulWidget {
  const LibraryDetailScreen({
    super.key,
    required this.itemId,
    required this.itemType,
  });

  final String itemId;
  final LibraryItemType itemType;

  @override
  ConsumerState<LibraryDetailScreen> createState() =>
      _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends ConsumerState<LibraryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final meta = _TypeMeta.of(widget.itemType, l10n);
    final asyncItem = ref.watch(
      _libraryItemProvider((type: widget.itemType, id: widget.itemId)),
    );

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: asyncItem.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.accent),
          ),
          error: (e, _) => _ErrorState(tokens: tokens, meta: meta),
          data: (item) {
            if (item == null) {
              return _EmptyState(tokens: tokens, meta: meta);
            }
            return _DetailContent(
              item: item,
              itemType: widget.itemType,
              tokens: tokens,
              meta: meta,
            );
          },
        ),
      ),
    );
  }
}

// -- Detail content -----------------------------------------------------------

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.item,
    required this.itemType,
    required this.tokens,
    required this.meta,
  });

  final Map<String, dynamic> item;
  final LibraryItemType itemType;
  final OrchestraColorTokens tokens;
  final _TypeMeta meta;

  String _title(AppLocalizations l10n) {
    if (itemType == LibraryItemType.doc) {
      return (item['title'] as String?) ?? l10n.untitled;
    }
    final name = (item['name'] as String?) ?? l10n.unknown;
    if (itemType == LibraryItemType.workflow) {
      return name;
    }
    return name;
  }

  String _markdownContent(AppLocalizations l10n) {
    switch (itemType) {
      case LibraryItemType.agent:
        // Desktop MCP returns 'system_prompt', PowerSync has 'content'.
        final body = (item['system_prompt'] as String?) ??
            (item['systemPrompt'] as String?) ??
            (item['content'] as String?);
        if (body != null && body.isNotEmpty) {
          return body;
        }
        return (item['description'] as String?) ?? '_${l10n.noDescription}._';

      case LibraryItemType.skill:
        // Desktop MCP returns full body in 'description', PowerSync has it in 'content'.
        final content = (item['content'] as String?);
        if (content != null && content.isNotEmpty) return content;
        return (item['description'] as String?) ?? '_${l10n.noDescription}._';

      case LibraryItemType.workflow:
        final desc = (item['description'] as String?) ?? '';
        final parts = <String>[];
        if (desc.isNotEmpty) parts.add(desc);

        // Format states
        final states = item['states'];
        if (states is Map && states.isNotEmpty) {
          final sb = StringBuffer('## States\n\n');
          sb.writeln('| State | Label | Terminal | Active Work |');
          sb.writeln('|---|---|---|---|');
          for (final entry in states.entries) {
            final s = entry.value;
            final label = s is Map ? (s['label'] ?? entry.key) : entry.key;
            final terminal = s is Map ? (s['terminal'] == true ? 'yes' : 'no') : 'no';
            final activeWork = s is Map ? (s['active_work'] == true ? 'yes' : 'no') : 'no';
            sb.writeln('| ${entry.key} | $label | $terminal | $activeWork |');
          }
          parts.add(sb.toString());
        }

        // Format transitions
        final transitions = item['transitions'];
        if (transitions is List && transitions.isNotEmpty) {
          final sb = StringBuffer('## Transitions\n\n');
          sb.writeln('| From | To | Gate |');
          sb.writeln('|---|---|---|');
          for (final t in transitions) {
            if (t is Map) {
              final gate = (t['gate'] as String?)?.isNotEmpty == true ? t['gate'] : '(free)';
              sb.writeln('| ${t['from'] ?? ''} | ${t['to'] ?? ''} | $gate |');
            }
          }
          parts.add(sb.toString());
        }

        // Format gates
        final gates = item['gates'];
        if (gates is Map && gates.isNotEmpty) {
          final sb = StringBuffer('## Gates\n\n');
          sb.writeln('| Gate | Label | Required Section |');
          sb.writeln('|---|---|---|');
          for (final entry in gates.entries) {
            final g = entry.value;
            final label = g is Map ? (g['label'] ?? entry.key) : entry.key;
            final reqSection = g is Map ? (g['required_section'] ?? '--') : '--';
            sb.writeln('| ${entry.key} | $label | $reqSection |');
          }
          parts.add(sb.toString());
        }

        if (parts.isEmpty) return '_${l10n.noDescription}._';
        return parts.join('\n\n');

      case LibraryItemType.doc:
        // Desktop MCP returns 'content', PowerSync has 'body'.
        return (item['content'] as String?) ??
            (item['body'] as String?) ??
            '_${l10n.noContent}._';
    }
  }

  List<_MetadataEntry> _metadataEntries(AppLocalizations l10n) {
    switch (itemType) {
      case LibraryItemType.agent:
        return [
          _MetadataEntry(
            label: l10n.providerLabel,
            value: (item['provider'] as String?) ?? '--',
          ),
          _MetadataEntry(
            label: l10n.modelLabel,
            value: (item['model'] as String?) ?? '--',
          ),
        ];

      case LibraryItemType.skill:
        return [
          _MetadataEntry(
            label: l10n.commandLabel,
            value: (item['command'] as String?) ?? '--',
          ),
          _MetadataEntry(
            label: l10n.sourceLabel,
            value: (item['source'] as String?) ?? '--',
          ),
        ];

      case LibraryItemType.workflow:
        final states = item['states'];
        final stateCount = states is Map ? states.length : 0;
        final transitions = item['transitions'];
        final transitionCount = transitions is List ? transitions.length : 0;
        final gatesMap = item['gates'];
        final gateCount = gatesMap is Map ? gatesMap.length : 0;
        final projectId = (item['project_id'] as String?) ?? '--';
        final initialState = (item['initial_state'] as String?) ?? 'todo';
        return [
          _MetadataEntry(
            label: l10n.projectLabel,
            value: projectId,
          ),
          _MetadataEntry(
            label: l10n.initialStateLabel,
            value: initialState,
          ),
          _MetadataEntry(
            label: l10n.statesLabel,
            value: '$stateCount',
          ),
          _MetadataEntry(
            label: l10n.transitionsLabel,
            value: '$transitionCount',
          ),
          _MetadataEntry(
            label: l10n.gatesLabel,
            value: '$gateCount',
          ),
        ];

      case LibraryItemType.doc:
        return [
          _MetadataEntry(
            label: l10n.pathLabel,
            value: (item['path'] as String?) ?? '--',
          ),
          _MetadataEntry(
            label: l10n.projectLabel,
            value: (item['project_id'] as String?) ??
                (item['projectId'] as String?) ??
                '--',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = _metadataEntries(l10n);
    return Column(
      children: [
        // -- Header -----------------------------------------------------------
        _Header(
          title: _title(l10n),
          itemId: item['id']?.toString() ?? item['name']?.toString() ?? '',
          itemType: itemType,
          tokens: tokens,
          meta: meta,
        ),

        // -- Scrollable body --------------------------------------------------
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Type badge
              _TypeBadge(meta: meta, tokens: tokens),
              const SizedBox(height: 16),

              // Metadata card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.details,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _MetadataRow(
                        entry: entries[i],
                        tokens: tokens,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content card with markdown rendering
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemType == LibraryItemType.agent
                          ? l10n.systemPromptLabel
                          : itemType == LibraryItemType.doc
                              ? l10n.contentLabel
                              : l10n.descriptionLabel,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MarkdownRendererWidget(
                      content: _markdownContent(l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

// -- Header -------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({
    required this.title,
    required this.itemId,
    required this.itemType,
    required this.tokens,
    required this.meta,
  });

  final String title;
  final String itemId;
  final LibraryItemType itemType;
  final OrchestraColorTokens tokens;
  final _TypeMeta meta;

  String get _editRoute => switch (itemType) {
        LibraryItemType.agent => '/library/agents/$itemId/edit',
        LibraryItemType.skill => '/library/skills/$itemId/edit',
        LibraryItemType.workflow => '/library/workflows/$itemId/edit',
        LibraryItemType.doc => '/library/docs/$itemId/edit',
      };

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle(meta.label)),
        content: Text(l10n.deleteItemMessage(title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      await switch (itemType) {
        LibraryItemType.agent => client.deleteAgent(itemId),
        LibraryItemType.skill => client.deleteSkill(itemId),
        LibraryItemType.workflow => client.deleteWorkflow(itemId),
        LibraryItemType.doc => client.deleteDoc(itemId),
      };
      // Invalidate list provider
      switch (itemType) {
        case LibraryItemType.agent:
          ref.invalidate(agentsProvider);
        case LibraryItemType.skill:
          ref.invalidate(skillsProvider);
        case LibraryItemType.workflow:
          ref.invalidate(workflowsProvider);
        case LibraryItemType.doc:
          ref.invalidate(docsProvider);
      }
      if (context.mounted) context.go(meta.listRoute);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToDelete}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Semantics(
            label: AppLocalizations.of(context).goBack,
            button: true,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go(meta.listRoute);
                }
              },
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: tokens.fgBright,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => context.go(_editRoute),
            child: Icon(Icons.edit_rounded, color: tokens.fgMuted, size: 20),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _delete(context, ref),
            child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
          ),
        ],
      ),
    );
  }
}

// -- Type badge ---------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.meta, required this.tokens});

  final _TypeMeta meta;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: meta.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(meta.icon, color: meta.color, size: 16),
            const SizedBox(width: 6),
            Text(
              meta.label,
              style: TextStyle(
                color: meta.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Metadata row -------------------------------------------------------------

class _MetadataEntry {
  const _MetadataEntry({required this.label, required this.value});
  final String label;
  final String value;
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.entry, required this.tokens});

  final _MetadataEntry entry;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.label,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
        ),
        Flexible(
          child: Text(
            entry.value,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// -- Error state --------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.tokens, required this.meta});
  final OrchestraColorTokens tokens;
  final _TypeMeta meta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                l10n.failedToLoadItem(meta.label),
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.checkConnection,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go(meta.listRoute);
                  }
                },
                child: Text(
                  l10n.goBack,
                  style: TextStyle(
                    color: tokens.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Empty state (item not found) ---------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens, required this.meta});
  final OrchestraColorTokens tokens;
  final _TypeMeta meta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(meta.icon, size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                l10n.itemNotFound(meta.label),
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.itemMayHaveBeenRemoved,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go(meta.listRoute);
                  }
                },
                child: Text(
                  l10n.goBack,
                  style: TextStyle(
                    color: tokens.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
