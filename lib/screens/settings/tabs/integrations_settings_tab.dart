import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Integrations settings tab — connect/disconnect third-party providers.
class IntegrationsSettingsTab extends ConsumerStatefulWidget {
  const IntegrationsSettingsTab({super.key});

  @override
  ConsumerState<IntegrationsSettingsTab> createState() =>
      _IntegrationsSettingsTabState();
}

class _IntegrationsSettingsTabState
    extends ConsumerState<IntegrationsSettingsTab> {
  /// Known provider metadata for icons and descriptions.
  static const _providerMeta =
      <String, ({IconData icon, Color color, String description})>{
        'google': (
          icon: Icons.g_mobiledata_rounded,
          color: Color(0xFF4285F4),
          description: 'Sign in with Google and sync calendars.',
        ),
        'github': (
          icon: Icons.code_rounded,
          color: Color(0xFF6E5494),
          description: 'Link repositories and track commits.',
        ),
        'discord': (
          icon: Icons.headset_mic_rounded,
          color: Color(0xFF5865F2),
          description: 'Receive notifications in Discord channels.',
        ),
        'slack': (
          icon: Icons.tag_rounded,
          color: Color(0xFFE01E5A),
          description: 'Post updates and alerts to Slack.',
        ),
      };

  Future<void> _unlinkAccount(String provider) async {
    try {
      await ref.read(apiClientProvider).unlinkAccount(provider);
      ref.invalidate(connectedAccountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$provider ${AppLocalizations.of(context).disconnect}ed',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToDisconnect} $provider: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final accountsAsync = ref.watch(connectedAccountsProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: tokens.fgDim),
              const SizedBox(height: 12),
              Text(
                'Failed to load integrations',
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(color: tokens.fgDim, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(connectedAccountsProvider),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      ),
      data: (accounts) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // -- Connected Accounts -------------------------------------------
          _sectionHeader(tokens, 'Connected Accounts'),
          const SizedBox(height: 4),
          Text(
            'Manage your third-party integrations.',
            style: TextStyle(fontSize: 12, color: tokens.fgDim),
          ),
          const SizedBox(height: 16),

          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No connected accounts.',
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                ),
              ),
            )
          else
            for (int i = 0; i < accounts.length; i++) ...[
              _buildIntegrationCard(tokens, accounts[i]),
              if (i < accounts.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(
    OrchestraColorTokens tokens,
    Map<String, dynamic> account,
  ) {
    final provider = (account['provider'] ?? '').toString().toLowerCase();
    final name =
        (account['name'] ??
                account['provider_name'] ??
                provider[0].toUpperCase() + provider.substring(1))
            .toString();
    final connected =
        account['connected'] == true || account['status'] == 'connected';
    final meta = _providerMeta[provider];
    final iconData = meta?.icon ?? Icons.extension_rounded;
    final iconColor = meta?.color ?? tokens.accent;
    final description =
        (account['description'] ??
                meta?.description ??
                'Third-party integration.')
            .toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          // Provider icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),

          // Provider info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.fgBright,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (connected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF22C55E,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Connect / Disconnect button
          if (connected)
            OutlinedButton(
              onPressed: () => _unlinkAccount(provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).disconnect,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                // TODO(orchestra): Initiate OAuth flow for the provider.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).connect,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );
}
