import 'package:flutter/material.dart';
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

/// Local overrides for verification tier changes (userId -> tier).
class _TierOverridesNotifier extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => {};

  void setTier(int userId, String tier) {
    state = {...state, userId: tier};
  }
}

final _tierOverridesProvider =
    NotifierProvider<_TierOverridesNotifier, Map<int, String>>(
      _TierOverridesNotifier.new,
    );

/// Merges API users with local tier overrides.
final _usersProvider =
    Provider.autoDispose<AsyncValue<List<Map<String, dynamic>>>>((ref) {
      final rawAsync = ref.watch(_usersRawProvider);
      final overrides = ref.watch(_tierOverridesProvider);
      return rawAsync.whenData((users) {
        if (overrides.isEmpty) return users;
        return users.map((u) {
          final id = (u['id'] as num?)?.toInt();
          if (id != null && overrides.containsKey(id)) {
            return {...u, 'verification_tier': overrides[id]};
          }
          return u;
        }).toList();
      });
    });

// ── Search state ────────────────────────────────────────────────────────────

class _VerificationSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider = NotifierProvider<_VerificationSearchNotifier, String>(
  _VerificationSearchNotifier.new,
);

// ── Tier helpers ────────────────────────────────────────────────────────────

const _tiers = ['unverified', 'verified', 'premium', 'enterprise'];

Color _tierColor(String tier) {
  return switch (tier) {
    'verified' => const Color(0xFF22C55E),
    'premium' => const Color(0xFFA855F7),
    'enterprise' => const Color(0xFF3B82F6),
    _ => const Color(0xFF6B7280),
  };
}

IconData _tierIcon(String tier) {
  return switch (tier) {
    'verified' => Icons.verified,
    'premium' => Icons.diamond_outlined,
    'enterprise' => Icons.business,
    _ => Icons.person_outline,
  };
}

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

void _showChangeTierDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> user,
) {
  final tokens = ThemeTokens.of(context);
  final name = user['name'] as String? ?? user['email'] as String? ?? 'User';
  String tier = user['verification_tier'] as String? ?? 'unverified';

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        titleTextStyle: TextStyle(
          color: tokens.fgBright,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        title: Text(AppLocalizations.of(context).adminVerificationFor(name)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).adminVerificationSelectTier,
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: tier,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(tokens, AppLocalizations.of(context).adminVerificationTier),
                items: _tiers
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(_tierIcon(t), size: 16, color: _tierColor(t)),
                            const SizedBox(width: 8),
                            Text(t[0].toUpperCase() + t.substring(1)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => tier = v);
                },
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
            onPressed: () async {
              final l10n = AppLocalizations.of(context);
              final api = ref.read(apiClientProvider);
              final userId = (user['id'] as num).toInt();
              if (tier == 'none') {
                await api.updateAdminUser(userId, {'is_verified': false});
              } else {
                await api.updateAdminUser(userId, {
                  'is_verified': true,
                  'verification_tier': tier,
                });
              }
              ref.read(_tierOverridesProvider.notifier).setTier(userId, tier);
              ref.invalidate(_usersRawProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.adminVerificationUpdated(tier))),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
            ),
            child: Text(AppLocalizations.of(context).update),
          ),
        ],
      ),
    ),
  );
}

// ── Verifications admin page ────────────────────────────────────────────────

/// Admin page for managing user verification status.
///
/// Lists users with their current verification tier (unverified, verified,
/// premium, enterprise). Supports search and tier changes via dialog.
class VerificationsAdminPage extends ConsumerWidget {
  const VerificationsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final usersAsync = ref.watch(_usersProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();

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
                  AppLocalizations.of(context).adminFailedToLoadVerifications,
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
                    final tier = (u['verification_tier'] as String? ?? '')
                        .toLowerCase();
                    return name.contains(searchQuery) ||
                        email.contains(searchQuery) ||
                        handle.contains(searchQuery) ||
                        tier.contains(searchQuery);
                  }).toList();

            // Count tiers
            int countTier(String t) => users
                .where((u) => (u['verification_tier'] ?? 'unverified') == t)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Text(
                  AppLocalizations.of(context).adminVerificationsTitle,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Tier summary chips ──────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tiers.map((t) {
                    final count = countTier(t);
                    final color = _tierColor(t);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tierIcon(t), size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '${t[0].toUpperCase()}${t.substring(1)}: $count',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // ── Search bar ──────────────────────────────────────────
                TextField(
                  onChanged: (v) =>
                      ref.read(_searchProvider.notifier).update(v),
                  style: TextStyle(color: tokens.fgBright, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).adminSearchVerifications,
                    hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
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

                // ── User list ───────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? AppLocalizations.of(context).adminNoVerificationUsersFound
                                : AppLocalizations.of(context).adminNoVerificationUsersMatching(searchQuery),
                            style: TextStyle(color: tokens.fgDim, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _UserVerificationTile(
                              tokens: tokens,
                              user: filtered[index],
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

// ── User verification tile ──────────────────────────────────────────────────

class _UserVerificationTile extends ConsumerWidget {
  const _UserVerificationTile({required this.tokens, required this.user});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user['name'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final handle = user['handle'] as String? ?? '';
    final tier = user['verification_tier'] as String? ?? 'unverified';
    final color = _tierColor(tier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
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
                Row(
                  children: [
                    Text(
                      name.isNotEmpty ? name : handle,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (tier != 'unverified') ...[
                      const SizedBox(width: 6),
                      Icon(_tierIcon(tier), size: 14, color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : handle,
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ],
            ),
          ),
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tier.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: () => _showChangeTierDialog(context, ref, user),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent.withValues(alpha: 0.1),
              foregroundColor: tokens.accent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text(AppLocalizations.of(context).adminChangeTier),
          ),
        ],
      ),
    );
  }
}
