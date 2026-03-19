import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers ──────────────────────────────────────────────────────────

final _issuesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminIssues();
  final raw = result['issues'] as List<dynamic>? ?? <dynamic>[];
  return raw.cast<Map<String, dynamic>>();
});

// ── Search state ────────────────────────────────────────────────────────────

class _IssueSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider =
    NotifierProvider<_IssueSearchNotifier, String>(_IssueSearchNotifier.new);

// ── Issues page ─────────────────────────────────────────────────────────────

/// Admin issue tracker page.
///
/// Loads issues from the admin API and displays them with title, status
/// (open/in-review/closed), priority (low/medium/high), user ID, and dates.
/// Includes client-side search filtering and a "New Issue" button.
class IssuesPage extends ConsumerWidget {
  const IssuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final issuesAsync = ref.watch(_issuesProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).failedToLoadIssues,
                style: TextStyle(color: tokens.fgBright, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(color: tokens.fgDim, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(_issuesProvider),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
        data: (issues) {
          final filtered = searchQuery.isEmpty
              ? issues
              : issues.where((i) {
                  final title =
                      (i['title'] as String? ?? '').toLowerCase();
                  final status =
                      (i['status'] as String? ?? '').toLowerCase();
                  final priority =
                      (i['priority'] as String? ?? '').toLowerCase();
                  return title.contains(searchQuery) ||
                      status.contains(searchQuery) ||
                      priority.contains(searchQuery);
                }).toList();

          final openCount =
              issues.where((i) => i['status'] != 'closed').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).issues,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context).nOpen(openCount),
                      style: TextStyle(
                        color: tokens.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppLocalizations.of(context).newIssue),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: tokens.bg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).nIssuesTotal(issues.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // ── Search bar ──────────────────────────────────────────
              TextField(
                onChanged: (v) =>
                    ref.read(_searchProvider.notifier).update(v),
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchIssues,
                  hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, size: 18, color: tokens.fgDim),
                  filled: true,
                  fillColor: tokens.bgAlt,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
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
                ),
              ),
              const SizedBox(height: 16),

              // ── Issue list ──────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? AppLocalizations.of(context).noIssuesFound
                              : AppLocalizations.of(context).noIssuesMatch(searchQuery),
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final issue = filtered[index];
                          return _IssueTile(
                            tokens: tokens,
                            issue: issue,
                            onEdit: () =>
                                _showEditIssueDialog(context, ref, issue),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────────

void _showEditIssueDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> issue,
) {
  final tokens = ThemeTokens.of(context);
  final currentStatus = issue['status'] as String? ?? 'open';
  final currentPriority = issue['priority'] as String? ?? 'low';
  String selectedStatus = currentStatus;
  String selectedPriority = currentPriority;

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: tokens.bgAlt,
            titleTextStyle: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            title: Text(AppLocalizations.of(ctx).updateIssue),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(ctx).status,
                    style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  dropdownColor: tokens.bgAlt,
                  style: TextStyle(color: tokens.fgBright, fontSize: 14),
                  underline: Container(height: 1, color: tokens.border),
                  items: [
                    DropdownMenuItem(value: 'open', child: Text(AppLocalizations.of(ctx).open)),
                    DropdownMenuItem(
                        value: 'in-review', child: Text(AppLocalizations.of(ctx).inReview)),
                    DropdownMenuItem(value: 'closed', child: Text(AppLocalizations.of(ctx).closed)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedStatus = v);
                  },
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(ctx).priority,
                    style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  value: selectedPriority,
                  isExpanded: true,
                  dropdownColor: tokens.bgAlt,
                  style: TextStyle(color: tokens.fgBright, fontSize: 14),
                  underline: Container(height: 1, color: tokens.border),
                  items: [
                    DropdownMenuItem(value: 'low', child: Text(AppLocalizations.of(ctx).low)),
                    DropdownMenuItem(value: 'medium', child: Text(AppLocalizations.of(ctx).medium)),
                    DropdownMenuItem(value: 'high', child: Text(AppLocalizations.of(ctx).high)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedPriority = v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child:
                    Text(AppLocalizations.of(ctx).cancel, style: TextStyle(color: tokens.fgDim)),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final api = ref.read(apiClientProvider);
                  await api.updateAdminIssueStatus(
                    (issue['id'] as num).toInt(),
                    {
                      'status': selectedStatus,
                      'priority': selectedPriority,
                    },
                  );
                  ref.invalidate(_issuesProvider);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.bg,
                ),
                child: Text(AppLocalizations.of(ctx).save),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Issue tile ──────────────────────────────────────────────────────────────

class _IssueTile extends StatelessWidget {
  const _IssueTile({
    required this.tokens,
    required this.issue,
    required this.onEdit,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> issue;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = issue['status'] as String? ?? 'open';
    final priority = issue['priority'] as String? ?? 'low';
    final title = issue['title'] as String? ?? '';
    final userId = issue['user_id'];
    final createdAt = issue['created_at'] as String? ?? '';

    final statusColor = switch (status) {
      'open' => const Color(0xFF38BDF8),
      'in-review' => const Color(0xFFFBBF24),
      'closed' => const Color(0xFF4ADE80),
      _ => tokens.fgDim,
    };

    final priorityLabel = priority.toUpperCase();
    final priorityColor = switch (priority) {
      'high' => const Color(0xFFF87171),
      'medium' => const Color(0xFFFBBF24),
      'low' => const Color(0xFF38BDF8),
      _ => tokens.fgDim,
    };

    // Format the date for display
    final displayDate = createdAt.length >= 10
        ? createdAt.substring(0, 10)
        : createdAt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          // Priority badge
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priorityLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: priorityColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (userId != null)
                      Text(
                        AppLocalizations.of(context).userN(userId.toString()),
                        style:
                            TextStyle(color: tokens.fgMuted, fontSize: 12),
                      ),
                    if (userId != null) const SizedBox(width: 12),
                    Text(
                      displayDate,
                      style: TextStyle(color: tokens.fgDim, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).editStatusPriority,
          ),
        ],
      ),
    );
  }
}
