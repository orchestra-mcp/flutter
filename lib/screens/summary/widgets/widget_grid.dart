import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Widget span (half = 1 column, full = 2 columns)
// ---------------------------------------------------------------------------

enum GridSpan { half, full }

// ---------------------------------------------------------------------------
// Widget config
// ---------------------------------------------------------------------------

class DashWidgetConfig {
  const DashWidgetConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.span,
    required this.builder,
    this.iconColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final GridSpan span;
  final Widget Function() builder;
  final Color? iconColor;
}

// ---------------------------------------------------------------------------
// Row grouping
// ---------------------------------------------------------------------------

class _GridRow {
  const _GridRow(this.cards);
  final List<DashWidgetConfig> cards;
}

List<_GridRow> _buildRows(List<DashWidgetConfig> cards) {
  final rows = <_GridRow>[];
  final pending = <DashWidgetConfig>[];

  for (final card in cards) {
    if (card.span == GridSpan.full) {
      if (pending.isNotEmpty) {
        rows.add(_GridRow(List.of(pending)));
        pending.clear();
      }
      rows.add(_GridRow([card]));
    } else {
      pending.add(card);
      if (pending.length == 2) {
        rows.add(_GridRow(List.of(pending)));
        pending.clear();
      }
    }
  }
  if (pending.isNotEmpty) {
    rows.add(_GridRow(List.of(pending)));
  }
  return rows;
}

// ---------------------------------------------------------------------------
// Widget grid (normal mode)
// ---------------------------------------------------------------------------

class WidgetGrid extends StatelessWidget {
  const WidgetGrid({
    super.key,
    required this.cards,
    required this.editMode,
    required this.onReorder,
    required this.onRemove,
    this.onLongPress,
  });

  final List<DashWidgetConfig> cards;
  final bool editMode;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String id) onRemove;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (editMode) {
      return _EditableWidgetGrid(
        cards: cards,
        onReorder: onReorder,
        onRemove: onRemove,
      );
    }

    final rows = _buildRows(cards);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row.cards.length == 1 && row.cards[0].span == GridSpan.full) {
            return GestureDetector(
              onLongPress: onLongPress,
              child: row.cards[0].builder(),
            );
          }
          if (row.cards.length == 1) {
            return GestureDetector(
              onLongPress: onLongPress,
              child: row.cards[0].builder(),
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: row.cards[0].builder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: row.cards[1].builder(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editable grid (reorderable flat list with drag handles + remove buttons)
// ---------------------------------------------------------------------------

/// Resolves a widget ID to its localized display label.
String _resolveEditLabel(AppLocalizations l10n, String id) => switch (id) {
  'health_score' => l10n.healthScore,
  'hydration' => l10n.hydration,
  'nutrition' => l10n.nutrition,
  'caffeine' => l10n.caffeine,
  'projects' => l10n.projects,
  'notes' => l10n.notes,
  'agents' => l10n.agents,
  'skills' => l10n.skills,
  'workflows' => l10n.workflows,
  'docs' => l10n.docs,
  'delegations' => l10n.delegations,
  'pomodoro' => l10n.pomodoro,
  _ => id,
};

class _EditableWidgetGrid extends StatelessWidget {
  const _EditableWidgetGrid({
    required this.cards,
    required this.onReorder,
    required this.onRemove,
  });

  final List<DashWidgetConfig> cards;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverReorderableList(
        itemBuilder: (context, index) {
          final card = cards[index];
          return ReorderableDragStartListener(
            key: ValueKey(card.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  card.builder(),
                  // Edit overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.bg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // Drag handle
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: tokens.bgAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: tokens.fgMuted,
                        size: 16,
                      ),
                    ),
                  ),
                  // Card label
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        _resolveEditLabel(l10n, card.id),
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Remove button
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => onRemove(card.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF44336,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFF44336),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        itemCount: cards.length,
        onReorderItem: (oldIndex, newIndex) => onReorder(oldIndex, newIndex),
      ),
    );
  }
}
