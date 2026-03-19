import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Feature flag model.
class _FeatureFlag {
  _FeatureFlag({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
  });

  final String key;
  final String name;
  final String description;
  bool enabled;
}

/// Admin features tab — toggle feature flags for the platform.
class AdminFeaturesTab extends ConsumerStatefulWidget {
  const AdminFeaturesTab({super.key});

  @override
  ConsumerState<AdminFeaturesTab> createState() => _AdminFeaturesTabState();
}

class _AdminFeaturesTabState extends ConsumerState<AdminFeaturesTab> {
  List<_FeatureFlag> _flags = [];
  bool _saving = false;
  bool _initialized = false;

  static List<Map<String, String>> _flagDefinitions(AppLocalizations l10n) => [
    {'key': 'registrations', 'name': l10n.adminFlagRegistrations, 'description': l10n.adminFlagRegistrationsDesc},
    {'key': 'api_access', 'name': l10n.adminFlagApiAccess, 'description': l10n.adminFlagApiAccessDesc},
    {'key': 'delegations', 'name': l10n.adminFlagDelegations, 'description': l10n.adminFlagDelegationsDesc},
    {'key': 'ai_sessions', 'name': l10n.adminFlagAiSessions, 'description': l10n.adminFlagAiSessionsDesc},
    {'key': 'health', 'name': l10n.adminFlagHealth, 'description': l10n.adminFlagHealthDesc},
    {'key': 'rag', 'name': l10n.adminFlagRag, 'description': l10n.adminFlagRagDesc},
    {'key': 'multi_agent', 'name': l10n.adminFlagMultiAgent, 'description': l10n.adminFlagMultiAgentDesc},
    {'key': 'marketplace', 'name': l10n.adminFlagMarketplace, 'description': l10n.adminFlagMarketplaceDesc},
    {'key': 'quic_bridge', 'name': l10n.adminFlagQuicBridge, 'description': l10n.adminFlagQuicBridgeDesc},
    {'key': 'web_gateway', 'name': l10n.adminFlagWebGateway, 'description': l10n.adminFlagWebGatewayDesc},
    {'key': 'packs', 'name': l10n.adminFlagPacks, 'description': l10n.adminFlagPacksDesc},
    {'key': 'projects', 'name': l10n.adminFlagProjects, 'description': l10n.adminFlagProjectsDesc},
    {'key': 'notes', 'name': l10n.adminFlagNotes, 'description': l10n.adminFlagNotesDesc},
    {'key': 'wiki', 'name': l10n.adminFlagWiki, 'description': l10n.adminFlagWikiDesc},
    {'key': 'devtools', 'name': l10n.adminFlagDevTools, 'description': l10n.adminFlagDevToolsDesc},
    {'key': 'sponsors', 'name': l10n.adminFlagSponsors, 'description': l10n.adminFlagSponsorsDesc},
    {'key': 'community', 'name': l10n.adminFlagCommunity, 'description': l10n.adminFlagCommunityDesc},
    {'key': 'issues', 'name': l10n.adminFlagIssues, 'description': l10n.adminFlagIssuesDesc},
  ];

  void _populateFlags(Map<String, dynamic> data, AppLocalizations l10n) {
    if (_initialized) return;
    _initialized = true;
    _flags = _flagDefinitions(l10n).map((def) {
      return _FeatureFlag(
        key: def['key']!,
        name: def['name']!,
        description: def['description']!,
        enabled: data[def['key']] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      for (final flag in _flags) {
        payload[flag.key] = flag.enabled;
      }
      await ref.read(apiClientProvider).updateAdminSetting('features', payload);
      ref.invalidate(adminSettingProvider('features'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSave}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('features'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFlags(data, l10n);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminFeatureFlags),
            const SizedBox(height: 4),
            Text(
              l10n.adminFeatureFlagsDesc,
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _flags.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        color: tokens.border.withValues(alpha: 0.4),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _flags[i].name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: tokens.fgBright,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _flags[i].description,
                                  style: TextStyle(
                                      fontSize: 11, color: tokens.fgDim),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _flags[i].enabled,
                            activeThumbColor: tokens.accent,
                            onChanged: (v) =>
                                setState(() => _flags[i].enabled = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        );
      },
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
