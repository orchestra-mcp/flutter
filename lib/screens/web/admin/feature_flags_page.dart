import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

/// Fetches feature-flag settings from the admin settings API
/// (category = "feature_flags").
final _featureFlagsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.listAdminSettings(category: 'feature_flags');
});

// ── Feature flags page ──────────────────────────────────────────────────────

/// Admin feature flags page.
///
/// Reads flags from [ApiClient.listAdminSettings] with `category: feature_flags`
/// and toggles them via [ApiClient.upsertAdminSetting].
class FeatureFlagsPage extends ConsumerWidget {
  const FeatureFlagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final flagsAsync = ref.watch(_featureFlagsProvider);

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
                  AppLocalizations.of(context).featureFlags,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showCreateDialog(context, ref, tokens),
                icon: Icon(Icons.add, size: 16, color: tokens.accent),
                label: Text(AppLocalizations.of(context).newFlag,
                    style: TextStyle(color: tokens.accent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: flagsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: tokens.accent),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: tokens.fgDim),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context).failedToLoadFeatureFlags,
                      style:
                          TextStyle(color: tokens.fgBright, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$e',
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (data) {
                final flags = _parseFlags(data);
                if (flags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 48, color: tokens.fgDim),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).noFeatureFlagsConfigured,
                          style: TextStyle(
                              color: tokens.fgDim, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).createFlagToGetStarted,
                          style: TextStyle(
                              color: tokens.fgDim, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final enabledCount =
                    flags.where((f) => f.enabled).length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).nOfNFlagsEnabled(enabledCount, flags.length),
                      style:
                          TextStyle(color: tokens.fgDim, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: flags.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final flag = flags[index];
                          return _FlagTile(
                            tokens: tokens,
                            flag: flag,
                            onToggle: () => _toggleFlag(ref, flag),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Parse the admin-settings response into a list of flags.
  List<_FlagEntry> _parseFlags(Map<String, dynamic> data) {
    final settings =
        (data['settings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return settings.map((s) {
      final key = s['key'] as String? ?? '';
      final value = s['value'];
      final description = s['description'] as String? ?? '';
      final enabled =
          value == true || value == 'true' || value == '1';
      return _FlagEntry(
        key: key,
        name: _humanize(key),
        description: description,
        enabled: enabled,
      );
    }).toList();
  }

  /// Toggle a flag by upserting its setting with the inverted value.
  Future<void> _toggleFlag(WidgetRef ref, _FlagEntry flag) async {
    try {
      await ref.read(apiClientProvider).upsertAdminSetting({
        'key': flag.key,
        'value': (!flag.enabled).toString(),
        'category': 'feature_flags',
        if (flag.description.isNotEmpty) 'description': flag.description,
      });
      ref.invalidate(_featureFlagsProvider);
    } catch (_) {}
  }

  /// Show a dialog to create a new feature flag.
  void _showCreateDialog(
      BuildContext context, WidgetRef ref, OrchestraColorTokens tokens) {
    final keyController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(AppLocalizations.of(ctx).newFeatureFlag,
            style: TextStyle(color: tokens.fgBright, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).keySnakeCase,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: tokens.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).descriptionLabel,
                labelStyle: TextStyle(color: tokens.fgDim, fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: tokens.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel,
                style: TextStyle(color: tokens.fgDim)),
          ),
          FilledButton(
            onPressed: () async {
              final key = keyController.text.trim();
              if (key.isEmpty) return;
              try {
                await ref.read(apiClientProvider).upsertAdminSetting({
                  'key': key,
                  'value': 'false',
                  'category': 'feature_flags',
                  'description': descController.text.trim(),
                });
                ref.invalidate(_featureFlagsProvider);
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
            ),
            child: Text(AppLocalizations.of(ctx).create),
          ),
        ],
      ),
    );
  }

  String _humanize(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ── Flag model ──────────────────────────────────────────────────────────────

class _FlagEntry {
  const _FlagEntry({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
  });
  final String key;
  final String name;
  final String description;
  final bool enabled;
}

// ── Flag tile ───────────────────────────────────────────────────────────────

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.tokens,
    required this.flag,
    required this.onToggle,
  });

  final OrchestraColorTokens tokens;
  final _FlagEntry flag;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: flag.enabled
              ? tokens.accent.withValues(alpha: 0.2)
              : tokens.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            flag.enabled ? Icons.flag : Icons.flag_outlined,
            size: 18,
            color: flag.enabled ? tokens.accent : tokens.fgDim,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        flag.name,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: tokens.fgDim.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        flag.key,
                        style: TextStyle(
                          color: tokens.fgDim,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                if (flag.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    flag.description,
                    style:
                        TextStyle(color: tokens.fgMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: flag.enabled,
            onChanged: (_) => onToggle(),
            activeTrackColor: tokens.accent,
          ),
        ],
      ),
    );
  }
}
