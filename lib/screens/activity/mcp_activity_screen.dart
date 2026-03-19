import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/mcp/mcp_action_logger.dart';
import 'package:orchestra/core/router/app_router.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Displays a timeline of all MCP tool calls with human-readable labels.
class McpActivityScreen extends ConsumerStatefulWidget {
  const McpActivityScreen({super.key});

  @override
  ConsumerState<McpActivityScreen> createState() => _McpActivityScreenState();
}

class _McpActivityScreenState extends ConsumerState<McpActivityScreen> {
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final logger = ref.watch(mcpActionLoggerProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: tokens.fgBright,
                      size: 20,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go(Routes.summary);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.activityTitle,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.activityActionsCount(logger.length),
                    style: TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Category filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: l10n.activityFilterAll,
                    isSelected: _categoryFilter == null,
                    onTap: () => setState(() => _categoryFilter = null),
                    tokens: tokens,
                  ),
                  for (final cat in _categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: cat[0].toUpperCase() + cat.substring(1),
                        isSelected: _categoryFilter == cat,
                        onTap: () => setState(() => _categoryFilter = cat),
                        tokens: tokens,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action list
            Expanded(
              child: ListenableBuilder(
                listenable: logger,
                builder: (context, _) {
                  final entries = _categoryFilter != null
                      ? logger.byCategory(_categoryFilter!)
                      : logger.entries;

                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: tokens.fgDim,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.activityNoActivityYet,
                            style: TextStyle(
                              color: tokens.fgBright,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.activityMcpToolCalls,
                            style: TextStyle(
                              color: tokens.fgMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _ActionTile(entry: entry, tokens: tokens);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _categories = [
  'features',
  'notes',
  'projects',
  'plans',
  'library',
  'ai',
  'sync',
];

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.tokens,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accent.withValues(alpha: 0.15)
              : tokens.bgAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? tokens.accent
                : tokens.fgDim.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? tokens.accent : tokens.fgMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.entry, required this.tokens});

  final McpActionEntry entry;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(entry.timestamp, AppLocalizations.of(context));
    final durationStr = '${entry.durationMs}ms';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  (entry.success
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              entry.success ? Icons.check_rounded : Icons.error_outline_rounded,
              size: 16,
              color: entry.success
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.humanLabel,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.toolName,
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          // Duration and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: TextStyle(color: tokens.fgDim, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                durationStr,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return l10n.activityJustNow;
    if (diff.inMinutes < 60) return l10n.activityMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.activityHoursAgo(diff.inHours);
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
