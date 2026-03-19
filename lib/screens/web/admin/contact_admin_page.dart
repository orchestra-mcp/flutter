import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data provider ────────────────────────────────────────────────────────────

final _contactProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final api = ref.watch(apiClientProvider);
    final result = await api.listAdminContact();
    final raw = result['messages'] as List<dynamic>? ?? <dynamic>[];
    return raw.cast<Map<String, dynamic>>();
  },
);

// ── Expanded state ───────────────────────────────────────────────────────────

class _ExpandedIndexNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void toggle(int index) {
    state = state == index ? null : index;
  }
}

final _expandedIndexProvider = NotifierProvider<_ExpandedIndexNotifier, int?>(
  _ExpandedIndexNotifier.new,
);

// ── Search state ─────────────────────────────────────────────────────────────

class _ContactSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _contactSearchProvider = NotifierProvider<_ContactSearchNotifier, String>(
  _ContactSearchNotifier.new,
);

// ── Contact admin page ───────────────────────────────────────────────────────

/// Admin contact form submissions page.
///
/// Fetches contact messages from [ApiClient.listAdminContact] and displays
/// them with name, email, subject, date, and status (new/read/replied).
/// Clicking a submission expands to show the full message. Includes
/// client-side search filtering.
class ContactAdminPage extends ConsumerWidget {
  const ContactAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final expandedIndex = ref.watch(_expandedIndexProvider);
    final query = ref.watch(_contactSearchProvider).toLowerCase();
    final contactAsync = ref.watch(_contactProvider);

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).contactSubmissions,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                contactAsync.when(
                  data: (messages) {
                    final newCount = messages
                        .where((m) => m['status'] == 'new')
                        .length;
                    if (newCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppLocalizations.of(context).nNew(newCount),
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            contactAsync.when(
              data: (messages) => Text(
                AppLocalizations.of(context).nSubmissionsTotal(messages.length),
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              loading: () => Text(
                AppLocalizations.of(context).loading,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
              error: (_, _) => Text(
                AppLocalizations.of(context).failedToLoadSubmissions,
                style: TextStyle(color: tokens.fgDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search ──────────────────────────────────────────────────────
            SizedBox(
              width: 320,
              child: TextField(
                onChanged: (v) =>
                    ref.read(_contactSearchProvider.notifier).update(v),
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchSubmissions,
                  hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 18, color: tokens.fgDim),
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
            ),
            const SizedBox(height: 20),

            // ── Submissions list ────────────────────────────────────────────
            Expanded(
              child: contactAsync.when(
                data: (messages) {
                  final filtered = messages.where((m) {
                    if (query.isEmpty) return true;
                    final name = (m['name'] as String? ?? '').toLowerCase();
                    final email = (m['email'] as String? ?? '').toLowerCase();
                    final subject = (m['subject'] as String? ?? '')
                        .toLowerCase();
                    return name.contains(query) ||
                        email.contains(query) ||
                        subject.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? AppLocalizations.of(context).noSubmissionsYet
                            : AppLocalizations.of(
                                context,
                              ).noSubmissionsMatch(query),
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final isExpanded = expandedIndex == index;
                      final msg = filtered[index];
                      return _SubmissionTile(
                        tokens: tokens,
                        submission: msg,
                        isExpanded: isExpanded,
                        onTap: () => ref
                            .read(_expandedIndexProvider.notifier)
                            .toggle(index),
                        onReply: () => _markAsReplied(context, ref, msg),
                        onClose: () => _markAsClosed(context, ref, msg),
                        onDelete: () => _showDeleteDialog(context, ref, msg),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 32, color: tokens.fgDim),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context).failedToLoadSubmissions,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(_contactProvider),
                        child: Text(AppLocalizations.of(context).retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Actions ─────────────────────────────────────────────────────────────────

Future<void> _markAsReplied(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> msg,
) async {
  final api = ref.read(apiClientProvider);
  await api.updateAdminContactStatus((msg['id'] as num).toInt(), {
    'status': 'replied',
  });
  ref.invalidate(_contactProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).markedAsReplied)),
    );
  }
}

Future<void> _markAsClosed(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> msg,
) async {
  final api = ref.read(apiClientProvider);
  await api.updateAdminContactStatus((msg['id'] as num).toInt(), {
    'status': 'closed',
  });
  ref.invalidate(_contactProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).submissionClosed)),
    );
  }
}

void _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> msg,
) {
  final tokens = ThemeTokens.of(context);
  final subject = msg['subject'] as String? ?? 'this submission';

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: tokens.bgAlt,
        titleTextStyle: TextStyle(
          color: tokens.fgBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        title: Text(AppLocalizations.of(ctx).deleteSubmission),
        content: Text(
          AppLocalizations.of(ctx).areYouSureDelete(subject),
          style: TextStyle(color: tokens.fgMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(ctx).cancel,
              style: TextStyle(color: tokens.fgDim),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final api = ref.read(apiClientProvider);
              await api.deleteAdminContactMessage((msg['id'] as num).toInt());
              ref.invalidate(_contactProvider);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(ctx).delete),
          ),
        ],
      );
    },
  );
}

// ── Submission tile ──────────────────────────────────────────────────────────

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({
    required this.tokens,
    required this.submission,
    required this.isExpanded,
    required this.onTap,
    required this.onReply,
    required this.onClose,
    required this.onDelete,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> submission;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subject =
        submission['subject'] as String? ??
        AppLocalizations.of(context).noSubject;
    final name =
        submission['name'] as String? ?? AppLocalizations.of(context).unknown;
    final email = submission['email'] as String? ?? '';
    final message = submission['message'] as String? ?? '';
    final status = submission['status'] as String? ?? 'new';
    final createdAt = submission['created_at'] as String? ?? '';

    final statusColor = switch (status) {
      'new' => const Color(0xFF38BDF8),
      'read' => const Color(0xFFFBBF24),
      'replied' => const Color(0xFF4ADE80),
      'closed' => tokens.fgDim,
      _ => tokens.fgDim,
    };

    return Material(
      color: tokens.bgAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: tokens.border.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExpanded
                  ? tokens.accent.withValues(alpha: 0.3)
                  : tokens.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: tokens.fgMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              email,
                              style: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 12,
                              ),
                            ),
                            if (createdAt.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Text(
                                createdAt.length >= 10
                                    ? createdAt.substring(0, 10)
                                    : createdAt,
                                style: TextStyle(
                                  color: tokens.fgDim,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outlined,
                      size: 16,
                      color: tokens.fgDim,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    tooltip: AppLocalizations.of(context).delete,
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: tokens.fgDim,
                  ),
                ],
              ),
              // Expanded message
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: tokens.border),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onReply,
                      icon: Icon(Icons.reply, size: 14, color: tokens.accent),
                      label: Text(
                        AppLocalizations.of(context).reply,
                        style: TextStyle(color: tokens.accent, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: tokens.accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onClose,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: tokens.border),
                        foregroundColor: tokens.fgDim,
                      ),
                      child: Text(
                        AppLocalizations.of(context).close,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
