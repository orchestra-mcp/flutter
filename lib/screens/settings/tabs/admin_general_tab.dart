import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin general settings tab — site name, description, site URL, support email, timezone, language.
class AdminGeneralTab extends ConsumerStatefulWidget {
  const AdminGeneralTab({super.key});

  @override
  ConsumerState<AdminGeneralTab> createState() => _AdminGeneralTabState();
}

class _AdminGeneralTabState extends ConsumerState<AdminGeneralTab> {
  final _siteNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _siteUrlCtrl = TextEditingController();
  final _supportEmailCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _languageCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _siteNameCtrl.text = data['site_name'] as String? ?? '';
    _descriptionCtrl.text = data['site_description'] as String? ?? '';
    _siteUrlCtrl.text = data['site_url'] as String? ?? '';
    _supportEmailCtrl.text = data['support_email'] as String? ?? '';
    _timezoneCtrl.text = data['timezone'] as String? ?? '';
    _languageCtrl.text = data['language'] as String? ?? '';
  }

  @override
  void dispose() {
    _siteNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _siteUrlCtrl.dispose();
    _supportEmailCtrl.dispose();
    _timezoneCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('general', {
        'site_name': _siteNameCtrl.text,
        'site_description': _descriptionCtrl.text,
        'site_url': _siteUrlCtrl.text,
        'support_email': _supportEmailCtrl.text,
        'timezone': _timezoneCtrl.text,
        'language': _languageCtrl.text,
      });
      ref.invalidate(adminSettingProvider('general'));
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
    final settingAsync = ref.watch(adminSettingProvider('general'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminGeneral),
            const SizedBox(height: 12),

            // Site Name
            _fieldLabel(tokens, l10n.adminSiteName),
            const SizedBox(height: 6),
            _field(tokens, _siteNameCtrl, hint: l10n.adminSiteNameHint),
            const SizedBox(height: 16),

            // Description
            _fieldLabel(tokens, l10n.adminDescription),
            const SizedBox(height: 6),
            _field(tokens, _descriptionCtrl,
                hint: l10n.adminDescriptionHint, maxLines: 3),
            const SizedBox(height: 16),

            // Site URL
            _fieldLabel(tokens, l10n.adminSiteUrl),
            const SizedBox(height: 6),
            _field(tokens, _siteUrlCtrl, hint: l10n.adminSiteUrlHint),
            const SizedBox(height: 16),

            // Support Email
            _fieldLabel(tokens, l10n.adminSupportEmail),
            const SizedBox(height: 6),
            _field(tokens, _supportEmailCtrl, hint: l10n.adminSupportEmailHint),
            const SizedBox(height: 16),

            // Timezone
            _fieldLabel(tokens, l10n.adminTimezone),
            const SizedBox(height: 6),
            _field(tokens, _timezoneCtrl, hint: 'UTC'),
            const SizedBox(height: 16),

            // Language
            _fieldLabel(tokens, l10n.adminLanguage),
            const SizedBox(height: 6),
            _field(tokens, _languageCtrl, hint: 'en'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Logo Upload
            _sectionHeader(tokens, l10n.adminBranding),
            const SizedBox(height: 12),
            _fieldLabel(tokens, l10n.adminLogo),
            const SizedBox(height: 6),
            _uploadArea(
                tokens, icon: Icons.image_rounded, label: l10n.adminUploadLogo),
            const SizedBox(height: 16),

            // Favicon Upload
            _fieldLabel(tokens, l10n.adminFavicon),
            const SizedBox(height: 6),
            _uploadArea(
                tokens, icon: Icons.tab_rounded, label: l10n.adminUploadFavicon),

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

  Widget _uploadArea(
    OrchestraColorTokens tokens, {
    required IconData icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: tokens.fgDim),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: tokens.fgDim),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).adminUploadHint,
              style: TextStyle(fontSize: 11, color: tokens.fgDim),
            ),
          ],
        ),
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
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
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
