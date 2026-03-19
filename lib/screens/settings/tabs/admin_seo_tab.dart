import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin SEO tab — meta title, meta description, OG image, sitemap, robots.txt.
class AdminSeoTab extends ConsumerStatefulWidget {
  const AdminSeoTab({super.key});

  @override
  ConsumerState<AdminSeoTab> createState() => _AdminSeoTabState();
}

class _AdminSeoTabState extends ConsumerState<AdminSeoTab> {
  final _metaTitleCtrl = TextEditingController();
  final _metaDescriptionCtrl = TextEditingController();
  final _ogImageCtrl = TextEditingController();
  final _robotsTxtCtrl = TextEditingController();
  bool _sitemapEnabled = true;
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _metaTitleCtrl.text = data['meta_title'] as String? ?? '';
    _metaDescriptionCtrl.text = data['meta_description'] as String? ?? '';
    _ogImageCtrl.text = data['og_image'] as String? ?? '';
    _robotsTxtCtrl.text = data['robots_txt'] as String? ?? '';
    _sitemapEnabled = data['sitemap_enabled'] as bool? ?? true;
  }

  @override
  void dispose() {
    _metaTitleCtrl.dispose();
    _metaDescriptionCtrl.dispose();
    _ogImageCtrl.dispose();
    _robotsTxtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('seo', {
        'meta_title': _metaTitleCtrl.text,
        'meta_description': _metaDescriptionCtrl.text,
        'og_image': _ogImageCtrl.text,
        'robots_txt': _robotsTxtCtrl.text,
        'sitemap_enabled': _sitemapEnabled,
      });
      ref.invalidate(adminSettingProvider('seo'));
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
    final settingAsync = ref.watch(adminSettingProvider('seo'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminMetaTags),
            const SizedBox(height: 12),

            // Meta Title
            _fieldLabel(tokens, l10n.adminMetaTitle),
            const SizedBox(height: 6),
            _field(tokens, _metaTitleCtrl,
                hint: l10n.adminMetaTitleHint),
            const SizedBox(height: 16),

            // Meta Description
            _fieldLabel(tokens, l10n.adminMetaDescription),
            const SizedBox(height: 6),
            _field(tokens, _metaDescriptionCtrl,
                hint: l10n.adminMetaDescHint, maxLines: 3),
            const SizedBox(height: 16),

            // OG Image URL
            _fieldLabel(tokens, l10n.adminOgImageUrl),
            const SizedBox(height: 6),
            _field(tokens, _ogImageCtrl, hint: 'https://...'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            _sectionHeader(tokens, l10n.adminSitemap),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: tokens.fgMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.adminAutoGenerateSitemap,
                      style: TextStyle(fontSize: 14, color: tokens.fgBright),
                    ),
                  ),
                  Switch(
                    value: _sitemapEnabled,
                    activeThumbColor: tokens.accent,
                    onChanged: (v) => setState(() => _sitemapEnabled = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Robots.txt
            _sectionHeader(tokens, l10n.adminRobotsTxt),
            const SizedBox(height: 12),
            _field(tokens, _robotsTxtCtrl,
                hint: 'User-agent: *\nAllow: /', maxLines: 8),

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

  Widget _fieldLabel(OrchestraColorTokens tokens, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.fgDim,
          letterSpacing: 0.4,
        ),
      );

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bgAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
