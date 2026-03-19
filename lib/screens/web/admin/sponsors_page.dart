import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Data providers ──────────────────────────────────────────────────────────

final _sponsorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.watch(apiClientProvider);
      final result = await api.listAdminSponsors();
      final raw = result['sponsors'] as List<dynamic>? ?? <dynamic>[];
      return raw.cast<Map<String, dynamic>>();
    });

// ── Search state ────────────────────────────────────────────────────────────

class _SponsorSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final _searchProvider = NotifierProvider<_SponsorSearchNotifier, String>(
  _SponsorSearchNotifier.new,
);

// ── Shared input decoration ──────────────────────────────────────────────────

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

// ── Dialogs ──────────────────────────────────────────────────────────────────

void _showCreateSponsorDialog(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final logoCtrl = TextEditingController();
  final tokens = ThemeTokens.of(context);
  String tier = 'gold';

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
        title: Text(AppLocalizations.of(ctx).addSponsor),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).name,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tier,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).tierLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'gold',
                    child: Text(AppLocalizations.of(ctx).gold),
                  ),
                  DropdownMenuItem(
                    value: 'silver',
                    child: Text(AppLocalizations.of(ctx).silver),
                  ),
                  DropdownMenuItem(
                    value: 'bronze',
                    child: Text(AppLocalizations.of(ctx).bronze),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => tier = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).websiteUrl,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: logoCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).logoUrl,
                ),
              ),
            ],
          ),
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
              final api = ref.read(apiClientProvider);
              await api.createAdminSponsor({
                'name': nameCtrl.text,
                'tier': tier,
                'website_url': websiteCtrl.text,
                if (logoCtrl.text.isNotEmpty) 'logo_url': logoCtrl.text,
              });
              ref.invalidate(_sponsorsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
            ),
            child: Text(AppLocalizations.of(ctx).create),
          ),
        ],
      ),
    ),
  );
}

void _showEditSponsorDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> sponsor,
) {
  final nameCtrl = TextEditingController(
    text: sponsor['name'] as String? ?? '',
  );
  final websiteCtrl = TextEditingController(
    text: sponsor['website_url'] as String? ?? '',
  );
  final logoCtrl = TextEditingController(
    text: sponsor['logo_url'] as String? ?? '',
  );
  final tokens = ThemeTokens.of(context);
  String tier = sponsor['tier'] as String? ?? 'gold';

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
        title: Text(AppLocalizations.of(ctx).editSponsor),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).name,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tier,
                dropdownColor: tokens.bgAlt,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).tierLabel,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'gold',
                    child: Text(AppLocalizations.of(ctx).gold),
                  ),
                  DropdownMenuItem(
                    value: 'silver',
                    child: Text(AppLocalizations.of(ctx).silver),
                  ),
                  DropdownMenuItem(
                    value: 'bronze',
                    child: Text(AppLocalizations.of(ctx).bronze),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => tier = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).websiteUrl,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: logoCtrl,
                style: TextStyle(color: tokens.fgBright, fontSize: 13),
                decoration: _inputDecoration(
                  tokens,
                  AppLocalizations.of(ctx).logoUrl,
                ),
              ),
            ],
          ),
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
              final api = ref.read(apiClientProvider);
              await api.updateAdminSponsor((sponsor['id'] as num).toInt(), {
                'name': nameCtrl.text,
                'tier': tier,
                'website_url': websiteCtrl.text,
                'logo_url': logoCtrl.text,
              });
              ref.invalidate(_sponsorsProvider);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.bg,
            ),
            child: Text(AppLocalizations.of(ctx).save),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteSponsorDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> sponsor,
) {
  final tokens = ThemeTokens.of(context);
  final name = sponsor['name'] as String? ?? 'this sponsor';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: tokens.bgAlt,
      titleTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      title: Text(AppLocalizations.of(ctx).removeSponsor),
      content: Text(
        AppLocalizations.of(ctx).areYouSureRemove(name),
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
            final api = ref.read(apiClientProvider);
            await api.deleteAdminSponsor((sponsor['id'] as num).toInt());
            ref.invalidate(_sponsorsProvider);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(ctx).remove),
        ),
      ],
    ),
  );
}

// ── Sponsors page ───────────────────────────────────────────────────────────

/// Admin sponsors management page.
///
/// Loads sponsors from the admin API and displays them with name, logo
/// placeholder, tier (gold/silver/bronze), website URL, and status.
/// Includes client-side search filtering and an "Add Sponsor" button.
class SponsorsPage extends ConsumerWidget {
  const SponsorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final sponsorsAsync = ref.watch(_sponsorsProvider);
    final searchQuery = ref.watch(_searchProvider).toLowerCase();

    return ColoredBox(
      color: tokens.bg,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: sponsorsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).failedToLoadSponsors,
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
                  onPressed: () => ref.invalidate(_sponsorsProvider),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
          data: (sponsors) {
            final filtered = searchQuery.isEmpty
                ? sponsors
                : sponsors.where((s) {
                    final name = (s['name'] as String? ?? '').toLowerCase();
                    final tier = (s['tier'] as String? ?? '').toLowerCase();
                    final website = (s['website_url'] as String? ?? '')
                        .toLowerCase();
                    return name.contains(searchQuery) ||
                        tier.contains(searchQuery) ||
                        website.contains(searchQuery);
                  }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).sponsors,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _showCreateSponsorDialog(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppLocalizations.of(context).addSponsor),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: tokens.bg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).nSponsors(sponsors.length),
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                ),
                const SizedBox(height: 12),

                // ── Search bar ──────────────────────────────────────────
                TextField(
                  onChanged: (v) =>
                      ref.read(_searchProvider.notifier).update(v),
                  style: TextStyle(color: tokens.fgBright, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchSponsors,
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

                // ── Sponsor list ────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? AppLocalizations.of(context).noSponsorsFound
                                : AppLocalizations.of(
                                    context,
                                  ).noSponsorsMatch(searchQuery),
                            style: TextStyle(color: tokens.fgDim, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _SponsorTile(
                              tokens: tokens,
                              sponsor: filtered[index],
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

// ── Sponsor tile ────────────────────────────────────────────────────────────

class _SponsorTile extends ConsumerWidget {
  const _SponsorTile({required this.tokens, required this.sponsor});

  final OrchestraColorTokens tokens;
  final Map<String, dynamic> sponsor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = sponsor['name'] as String? ?? '';
    final tier = sponsor['tier'] as String? ?? '';
    final websiteUrl = sponsor['website_url'] as String? ?? '';
    final logoUrl = sponsor['logo_url'] as String? ?? '';
    final status = sponsor['status'] as String? ?? 'active';

    final tierColor = switch (tier) {
      'gold' => const Color(0xFFFBBF24),
      'silver' => const Color(0xFFA8A29E),
      'bronze' => const Color(0xFFCD7F32),
      _ => tokens.fgDim,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          // Name and website
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  websiteUrl,
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          if (status != 'active') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tier.toUpperCase(),
              style: TextStyle(
                color: tierColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: tokens.fgMuted),
            onPressed: () => _showEditSponsorDialog(context, ref, sponsor),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).edit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outlined, size: 16, color: tokens.fgDim),
            onPressed: () => _showDeleteSponsorDialog(context, ref, sponsor),
            visualDensity: VisualDensity.compact,
            tooltip: AppLocalizations.of(context).remove,
          ),
        ],
      ),
    );
  }
}
