import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin social tab — social platform links.
class AdminSocialTab extends ConsumerStatefulWidget {
  const AdminSocialTab({super.key});

  @override
  ConsumerState<AdminSocialTab> createState() => _AdminSocialTabState();
}

class _AdminSocialTabState extends ConsumerState<AdminSocialTab> {
  final _twitterUrlCtrl = TextEditingController();
  final _githubUrlCtrl = TextEditingController();
  final _discordUrlCtrl = TextEditingController();
  final _linkedinUrlCtrl = TextEditingController();
  final _youtubeUrlCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _twitterUrlCtrl.text = data['twitter_url'] as String? ?? '';
    _githubUrlCtrl.text = data['github_url'] as String? ?? '';
    _discordUrlCtrl.text = data['discord_url'] as String? ?? '';
    _linkedinUrlCtrl.text = data['linkedin_url'] as String? ?? '';
    _youtubeUrlCtrl.text = data['youtube_url'] as String? ?? '';
  }

  @override
  void dispose() {
    _twitterUrlCtrl.dispose();
    _githubUrlCtrl.dispose();
    _discordUrlCtrl.dispose();
    _linkedinUrlCtrl.dispose();
    _youtubeUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('social_platforms', {
        'twitter_url': _twitterUrlCtrl.text,
        'github_url': _githubUrlCtrl.text,
        'discord_url': _discordUrlCtrl.text,
        'linkedin_url': _linkedinUrlCtrl.text,
        'youtube_url': _youtubeUrlCtrl.text,
      });
      ref.invalidate(adminSettingProvider('social_platforms'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToSave}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final settingAsync = ref.watch(adminSettingProvider('social_platforms'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('${AppLocalizations.of(context).failedToLoad}: $e'),
      ),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminSocialLinks),
            const SizedBox(height: 4),
            Text(
              l10n.adminSocialLinksDesc,
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
            const SizedBox(height: 16),

            // Twitter
            _socialField(
              tokens,
              icon: Icons.alternate_email_rounded,
              label: 'Twitter',
              ctrl: _twitterUrlCtrl,
              hint: 'https://twitter.com/orchestra',
            ),
            const SizedBox(height: 12),

            // GitHub
            _socialField(
              tokens,
              icon: Icons.code_rounded,
              label: 'GitHub',
              ctrl: _githubUrlCtrl,
              hint: 'https://github.com/orchestra-mcp',
            ),
            const SizedBox(height: 12),

            // Discord
            _socialField(
              tokens,
              icon: Icons.discord_rounded,
              label: 'Discord',
              ctrl: _discordUrlCtrl,
              hint: 'https://discord.gg/orchestra',
            ),
            const SizedBox(height: 12),

            // LinkedIn
            _socialField(
              tokens,
              icon: Icons.business_rounded,
              label: 'LinkedIn',
              ctrl: _linkedinUrlCtrl,
              hint: 'https://linkedin.com/company/orchestra',
            ),
            const SizedBox(height: 12),

            // YouTube
            _socialField(
              tokens,
              icon: Icons.play_circle_outline_rounded,
              label: 'YouTube',
              ctrl: _youtubeUrlCtrl,
              hint: 'https://youtube.com/@orchestra',
            ),

            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _socialField(
    OrchestraColorTokens tokens, {
    required IconData icon,
    required String label,
    required TextEditingController ctrl,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: tokens.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.fgBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: tokens.fgDim),
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
