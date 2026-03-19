import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ─── Feature row model ────────────────────────────────────────────────────────

class _FeatureRow {
  const _FeatureRow({
    required this.id,
    required this.title,
    required this.project,
    required this.status,
    required this.priority,
    required this.kind,
  });

  final String id;
  final String title;
  final String project;
  final String status;
  final String priority;
  final String kind;
}

const _placeholderRows = [
  _FeatureRow(
    id: 'FEAT-UJV',
    title: 'Web-specific architecture',
    project: 'orchestra-flutter',
    status: 'done',
    priority: 'P0',
    kind: 'feature',
  ),
  _FeatureRow(
    id: 'FEAT-FRU',
    title: 'Web app shell',
    project: 'orchestra-flutter',
    status: 'done',
    priority: 'P0',
    kind: 'feature',
  ),
  _FeatureRow(
    id: 'FEAT-HUF',
    title: 'Public marketing pages',
    project: 'orchestra-flutter',
    status: 'done',
    priority: 'P1',
    kind: 'feature',
  ),
  _FeatureRow(
    id: 'FEAT-YOZ',
    title: 'Authenticated web routes',
    project: 'orchestra-flutter',
    status: 'in-progress',
    priority: 'P1',
    kind: 'feature',
  ),
  _FeatureRow(
    id: 'FEAT-FNB',
    title: 'Admin panel',
    project: 'orchestra-flutter',
    status: 'todo',
    priority: 'P2',
    kind: 'feature',
  ),
];

// ─── Status badge ─────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'done':
      return const Color(0xFF4CAF50);
    case 'in-progress':
      return const Color(0xFF2196F3);
    case 'in-review':
      return const Color(0xFFFF9800);
    case 'in-testing':
      return const Color(0xFF9C27B0);
    case 'todo':
      return const Color(0xFF9E9E9E);
    default:
      return const Color(0xFF9E9E9E);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Global features list — all features across projects in a DataTable.
///
/// Columns: ID · Title · Project · Status · Priority · Kind
class FeaturesListScreen extends ConsumerWidget {
  const FeaturesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).features,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    tokens.bg.withValues(alpha: 0.5)),
                headingTextStyle: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                dataTextStyle:
                    TextStyle(color: tokens.fgBright, fontSize: 13),
                dividerThickness: 0.5,
                columns: [
                  DataColumn(label: Text(AppLocalizations.of(context).columnId)),
                  DataColumn(label: Text(AppLocalizations.of(context).columnTitle)),
                  DataColumn(label: Text(AppLocalizations.of(context).columnProject)),
                  DataColumn(label: Text(AppLocalizations.of(context).columnStatus)),
                  DataColumn(label: Text(AppLocalizations.of(context).columnPriority)),
                  DataColumn(label: Text(AppLocalizations.of(context).columnKind)),
                ],
                rows: _placeholderRows.map((row) {
                  final statusColor = _statusColor(row.status);
                  return DataRow(cells: [
                    DataCell(Text(row.id,
                        style: TextStyle(
                            color: tokens.accent,
                            fontFamily: 'monospace',
                            fontSize: 12))),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          row.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(row.project,
                        style: TextStyle(
                            color: tokens.fgMuted, fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          row.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(Text(row.priority)),
                    DataCell(Text(row.kind,
                        style: TextStyle(
                            color: tokens.fgMuted, fontSize: 12))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
