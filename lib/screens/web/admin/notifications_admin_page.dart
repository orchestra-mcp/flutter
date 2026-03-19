import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers ──────────────────────────────────────────────────────────

final _notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final result = await api.listAdminNotifications();
  final raw = result['notifications'] as List<dynamic>? ?? <dynamic>[];
  return raw.cast<Map<String, dynamic>>();
});

// ── Send form state ─────────────────────────────────────────────────────────

class _SendFormState {
  const _SendFormState({
    this.title = '',
    this.message = '',
    this.target = 'All Users',
  });
  final String title;
  final String message;
  final String target;

  _SendFormState copyWith({String? title, String? message, String? target}) =>
      _SendFormState(
        title: title ?? this.title,
        message: message ?? this.message,
        target: target ?? this.target,
      );
}

class _SendFormNotifier extends Notifier<_SendFormState> {
  @override
  _SendFormState build() => const _SendFormState();

  void setTitle(String title) => state = state.copyWith(title: title);
  void setMessage(String message) => state = state.copyWith(message: message);
  void setTarget(String target) => state = state.copyWith(target: target);
  void clear() => state = const _SendFormState();
}

final _sendFormProvider =
    NotifierProvider<_SendFormNotifier, _SendFormState>(_SendFormNotifier.new);

// ── Show form state ─────────────────────────────────────────────────────────

class _ShowFormNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final _showFormProvider =
    NotifierProvider<_ShowFormNotifier, bool>(_ShowFormNotifier.new);

// ── Search state ────────────────────────────────────────────────────────────

class _NotifSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider =
    NotifierProvider<_NotifSearchNotifier, String>(_NotifSearchNotifier.new);

// ── Notifications admin page ────────────────────────────────────────────────

/// Admin system notification management page.
///
/// Loads notifications from the admin API. Provides a "Send Notification"
/// button that reveals a form with title, message, and target. Lists
/// previously sent system notifications with metadata.
class NotificationsAdminPage extends ConsumerWidget {
  const NotificationsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final showForm = ref.watch(_showFormProvider);
    final formState = ref.watch(_sendFormProvider);
    final notificationsAsync = ref.watch(_notificationsProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                AppLocalizations.of(context).notifications,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(_showFormProvider.notifier).toggle(),
                icon: Icon(
                  showForm ? Icons.close : Icons.send_outlined,
                  size: 16,
                ),
                label: Text(showForm ? AppLocalizations.of(context).cancel : AppLocalizations.of(context).sendNotification),
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: tokens.bg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          notificationsAsync.when(
            loading: () => Text(
              AppLocalizations.of(context).loading,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            error: (_, _) => Text(
              AppLocalizations.of(context).failedToLoadCount,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
            data: (notifications) => Text(
              AppLocalizations.of(context).nNotificationsSent(notifications.length),
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          // ── Send form ─────────────────────────────────────────────────
          if (showForm) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: tokens.accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).newNotification,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title field
                  TextField(
                    onChanged: (v) =>
                        ref.read(_sendFormProvider.notifier).setTitle(v),
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration:
                        _inputDecoration(tokens, AppLocalizations.of(context).notificationTitlePlaceholder),
                  ),
                  const SizedBox(height: 12),
                  // Message field
                  TextField(
                    onChanged: (v) =>
                        ref.read(_sendFormProvider.notifier).setMessage(v),
                    maxLines: 3,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: _inputDecoration(tokens, AppLocalizations.of(context).messagePlaceholder),
                  ),
                  const SizedBox(height: 12),
                  // Target dropdown
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).targetLabel,
                        style: TextStyle(
                          color: tokens.fgMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: tokens.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.border),
                        ),
                        child: DropdownButton<String>(
                          value: formState.target,
                          dropdownColor: tokens.bgAlt,
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 13,
                          ),
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(
                              value: 'All Users',
                              child: Text(AppLocalizations.of(context).allUsersTarget),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text(AppLocalizations.of(context).adminTarget),
                            ),
                            DropdownMenuItem(
                              value: 'Team Owner',
                              child: Text(AppLocalizations.of(context).teamOwnerTarget),
                            ),
                            DropdownMenuItem(
                              value: 'Team Manager',
                              child: Text(AppLocalizations.of(context).teamManagerTarget),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(_sendFormProvider.notifier)
                                  .setTarget(v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final api = ref.read(apiClientProvider);
                      await api.createAdminNotification({
                        'title': formState.title,
                        'message': formState.message,
                        'target': formState.target,
                      });
                      ref.read(_sendFormProvider.notifier).clear();
                      ref.read(_showFormProvider.notifier).toggle();
                      ref.invalidate(_notificationsProvider);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: tokens.bg,
                    ),
                    child: Text(AppLocalizations.of(context).send),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Search bar ────────────────────────────────────────────────
          TextField(
            onChanged: (v) =>
                ref.read(_searchProvider.notifier).update(v),
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchNotifications,
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

          // ── Sent notifications list ───────────────────────────────────
          Text(
            AppLocalizations.of(context).sentNotifications,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notificationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: tokens.fgDim),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).failedToLoadNotifications,
                      style: TextStyle(
                          color: tokens.fgBright, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$error',
                      style: TextStyle(
                          color: tokens.fgDim, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(_notificationsProvider),
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  ],
                ),
              ),
              data: (notifications) {
                final filtered = searchQuery.isEmpty
                    ? notifications
                    : notifications.where((n) {
                        final title =
                            (n['title'] as String? ?? '').toLowerCase();
                        final message =
                            (n['message'] as String? ?? '').toLowerCase();
                        final target =
                            (n['target'] as String? ?? '').toLowerCase();
                        return title.contains(searchQuery) ||
                            message.contains(searchQuery) ||
                            target.contains(searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? AppLocalizations.of(context).noNotificationsSentYet
                          : AppLocalizations.of(context).noNotificationsMatch(searchQuery),
                      style: TextStyle(
                        color: tokens.fgDim,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _NotificationTile(
                      tokens: tokens,
                      notification: filtered[index],
                    );
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

  InputDecoration _inputDecoration(
    OrchestraColorTokens tokens,
    String hint,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
      filled: true,
      fillColor: tokens.bg,
      contentPadding: const EdgeInsets.all(12),
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
    );
  }
}

// ── Notification tile ───────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.tokens,
    required this.notification,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final target = notification['target'] as String? ?? '';
    final sentAt = notification['sent_at'] as String? ??
        notification['created_at'] as String? ??
        '';
    final readCount = notification['read_count'] as int? ?? 0;
    final totalCount = notification['total_count'] as int? ?? 0;

    final readPercent =
        totalCount > 0 ? ((readCount / totalCount) * 100).round() : 0;

    // Format date for display
    final displayDate =
        sentAt.length >= 16 ? sentAt.substring(0, 16) : sentAt;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_outlined, size: 20, color: tokens.accent),
          const SizedBox(width: 14),
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
                Text(
                  message,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (target.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.fgDim.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          target,
                          style: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (target.isNotEmpty) const SizedBox(width: 8),
                    if (displayDate.isNotEmpty)
                      Text(
                        displayDate,
                        style:
                            TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: tokens.fgDim,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$readCount/$totalCount ($readPercent%)',
                        style:
                            TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
