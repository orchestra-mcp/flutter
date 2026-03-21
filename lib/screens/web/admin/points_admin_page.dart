import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers ──────────────────────────────────────────────────────────

final _usersRawProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      try {
        final api = ref.watch(apiClientProvider);
        final result = await api.listAdminUsers();
        final raw = result['users'] as List<dynamic>? ?? <dynamic>[];
        return raw.cast<Map<String, dynamic>>();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    });

/// Merges API users with local point overrides.
final _usersProvider =
    Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
      final rawAsync = ref.watch(_usersRawProvider);
      final overrides = ref.watch(_pointOverridesProvider);
      return rawAsync.whenData((users) {
        if (overrides.isEmpty) return users;
        return users.map((u) {
          final id = (u['id'] as num?)?.toInt();
          if (id != null && overrides.containsKey(id)) {
            final basePoints = (u['points'] as num?)?.toInt() ?? 0;
            return {...u, 'points': basePoints + overrides[id]!};
          }
          return u;
        }).toList();
      });
    });

// ── Selected user for transaction history ───────────────────────────────────

class _SelectedUserNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? userId) => state = userId;
}

final _selectedUserProvider = NotifierProvider<_SelectedUserNotifier, int?>(
  _SelectedUserNotifier.new,
);

/// Local point adjustments: userId -> total delta.
class _PointOverridesNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  void adjust(int userId, int delta) {
    final current = state[userId] ?? 0;
    state = {...state, userId: current + delta};
  }
}

final _pointOverridesProvider =
    NotifierProvider<_PointOverridesNotifier, Map<int, int>>(
      _PointOverridesNotifier.new,
    );

/// Local transaction log: userId -> list of transactions.
class _TransactionsNotifier
    extends Notifier<Map<int, List<Map<String, dynamic>>>> {
  @override
  Map<int, List<Map<String, dynamic>>> build() => {};

  void add(int userId, Map<String, dynamic> tx) {
    final list = [...(state[userId] ?? []), tx];
    state = {...state, userId: list};
  }
}

final _transactionsNotifier =
    NotifierProvider<
      _TransactionsNotifier,
      Map<int, List<Map<String, dynamic>>>
    >(_TransactionsNotifier.new);

final _transactionsProvider = Provider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, userId) {
      final all = ref.watch(_transactionsNotifier);
      return all[userId] ?? [];
    });

// ── Search state ────────────────────────────────────────────────────────────

class _PointsSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider = NotifierProvider<_PointsSearchNotifier, String>(
  _PointsSearchNotifier.new,
);

// ── Shared input decoration ─────────────────────────────────────────────────

InputDecoration _inputDecoration(OrchestraColorTokens tokens, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
    filled: true,
    fillColor: tokens.bg,
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

// ── Dialogs ─────────────────────────────────────────────────────────────────

void _showAwardDeductDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> user, {
  required bool isAward,
}) {
  final amountCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  final tokens = ThemeTokens.of(context);
  final name = user['name'] as String? ?? user['email'] as String? ?? 'User';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(isAward ? AppLocalizations.of(context).adminAwardPoints : AppLocalizations.of(context).adminDeductPoints),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAward
                  ? AppLocalizations.of(context).adminAwardPointsTo(name)
                  : AppLocalizations.of(context).adminDeductPointsFrom(name),
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(context).adminPointsAmount),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: _inputDecoration(tokens, AppLocalizations.of(context).adminPointsReason),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context).cancel, style: TextStyle(color: tokens.fgDim)),
        ),
        FilledButton(
          onPressed: () {
            final l10n = AppLocalizations.of(context);
            final amount = int.tryParse(amountCtrl.text) ?? 0;
            if (amount <= 0) return;
            final userId = (user['id'] as num).toInt();
            final delta = isAward ? amount : -amount;
            ref.read(_pointOverridesProvider.notifier).adjust(userId, delta);
            ref.read(_transactionsNotifier.notifier).add(userId, {
              'amount': delta,
              'reason': reasonCtrl.text,
              'type': isAward ? 'award' : 'deduction',
              'created_at': DateTime.now().toIso8601String(),
            });
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.adminPointsSavedPending)),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: isAward
                ? const Color(0xFF22C55E)
                : const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(isAward ? AppLocalizations.of(context).adminAward : AppLocalizations.of(context).adminDeduct),
        ),
      ],
    ),
  );
}

// ── Points admin page ───────────────────────────────────────────────────────

/// Admin page for managing user points.
///
/// Lists users with their current points balance. Supports manual
/// award/deduct via dialog. Shows transaction history for a selected user.
class PointsAdminPage extends ConsumerWidget {
  const PointsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final usersAsync = ref.watch(_usersProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();
    final selectedUserId = ref.watch(_selectedUserProvider);

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).adminFailedToLoadUsers,
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
                  onPressed: () => ref.invalidate(_usersRawProvider),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
          data: (users) {
            final filtered = searchQuery.isEmpty
                ? users
                : users.where((u) {
                    final name = (u['name'] as String? ?? '').toLowerCase();
                    final email = (u['email'] as String? ?? '').toLowerCase();
                    final handle = (u['handle'] as String? ?? '').toLowerCase();
                    return name.contains(searchQuery) ||
                        email.contains(searchQuery) ||
                        handle.contains(searchQuery);
                  }).toList();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: user list ─────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).adminPointsManagement,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${users.length} user${users.length == 1 ? '' : 's'}',
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // ── Search bar ────────────────────────────────────
                      TextField(
                        onChanged: (v) =>
                            ref.read(_searchProvider.notifier).update(v),
                        style: TextStyle(color: tokens.fgBright, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).adminSearchUsers,
                          hintStyle: TextStyle(
                            color: tokens.fgDim,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: tokens.fgDim,
                          ),
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

                      // ── User list ─────────────────────────────────────
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  searchQuery.isEmpty
                                      ? AppLocalizations.of(context).adminNoUsersFound
                                      : AppLocalizations.of(context).adminNoUsersMatching(searchQuery),
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
                                  final user = filtered[index];
                                  final userId = (user['id'] as num?)?.toInt();
                                  final isSelected = userId == selectedUserId;
                                  return _UserPointsTile(
                                    tokens: tokens,
                                    user: user,
                                    isSelected: isSelected,
                                    onTap: () => ref
                                        .read(_selectedUserProvider.notifier)
                                        .select(userId),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // ── Right: transaction history ──────────────────────────
                if (selectedUserId != null) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: _TransactionHistory(
                      tokens: tokens,
                      userId: selectedUserId,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── User points tile ────────────────────────────────────────────────────────

class _UserPointsTile extends ConsumerWidget {
  const _UserPointsTile({
    required this.tokens,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> user;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final handle = user['handle'] as String? ?? '';
    final points = (user['points'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accent.withValues(alpha: 0.06)
              : tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? tokens.accent : tokens.border),
        ),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : handle,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.isNotEmpty ? email : handle,
                    style: TextStyle(color: tokens.fgDim, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Award button
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Color(0xFF22C55E),
              ),
              onPressed: () =>
                  _showAwardDeductDialog(context, ref, user, isAward: true),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context).adminAwardPointsTooltip,
            ),
            // Deduct button
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              onPressed: () =>
                  _showAwardDeductDialog(context, ref, user, isAward: false),
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context).adminDeductPointsTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction history panel ───────────────────────────────────────────────

class _TransactionHistory extends ConsumerWidget {
  const _TransactionHistory({required this.tokens, required this.userId});

  final OrchestraColorTokens tokens;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(_transactionsProvider(userId));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: tokens.fgMuted),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).adminTransactionHistory,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).adminNoTransactions,
                      style: TextStyle(color: tokens.fgDim, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: tokens.border),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final amount = (tx['amount'] as num?)?.toInt() ?? 0;
                      final reason = tx['reason'] as String? ?? '';
                      final type = tx['type'] as String? ?? '';
                      final createdAt = tx['created_at'] as String? ?? '';
                      final isPositive = amount >= 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: isPositive
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason.isNotEmpty ? reason : type,
                                    style: TextStyle(
                                      color: tokens.fgBright,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (createdAt.isNotEmpty)
                                    Text(
                                      createdAt,
                                      style: TextStyle(
                                        color: tokens.fgDim,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : ''}$amount',
                              style: TextStyle(
                                color: isPositive
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
