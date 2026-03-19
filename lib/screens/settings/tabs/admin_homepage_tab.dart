import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin homepage tab — hero section, CTA button, hero image.
class AdminHomepageTab extends ConsumerStatefulWidget {
  const AdminHomepageTab({super.key});

  @override
  ConsumerState<AdminHomepageTab> createState() => _AdminHomepageTabState();
}

class _AdminHomepageTabState extends ConsumerState<AdminHomepageTab> {
  final _heroTitleCtrl = TextEditingController();
  final _heroSubtitleCtrl = TextEditingController();
  final _ctaTextCtrl = TextEditingController();
  final _ctaUrlCtrl = TextEditingController();
  bool _showFeatures = false;
  bool _showTestimonials = false;
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _heroTitleCtrl.text = data['hero_title'] as String? ?? '';
    _heroSubtitleCtrl.text = data['hero_subtitle'] as String? ?? '';
    _ctaTextCtrl.text = data['cta_text'] as String? ?? '';
    _ctaUrlCtrl.text = data['cta_url'] as String? ?? '';
    _showFeatures = data['show_features'] as bool? ?? false;
    _showTestimonials = data['show_testimonials'] as bool? ?? false;
  }

  @override
  void dispose() {
    _heroTitleCtrl.dispose();
    _heroSubtitleCtrl.dispose();
    _ctaTextCtrl.dispose();
    _ctaUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('homepage', {
        'hero_title': _heroTitleCtrl.text,
        'hero_subtitle': _heroSubtitleCtrl.text,
        'cta_text': _ctaTextCtrl.text,
        'cta_url': _ctaUrlCtrl.text,
        'show_features': _showFeatures,
        'show_testimonials': _showTestimonials,
      });
      ref.invalidate(adminSettingProvider('homepage'));
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
    final settingAsync = ref.watch(adminSettingProvider('homepage'));

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
            _sectionHeader(tokens, l10n.adminHeroSection),
            const SizedBox(height: 12),

            // Hero Title
            _fieldLabel(tokens, l10n.adminHeroTitle),
            const SizedBox(height: 6),
            _field(tokens, _heroTitleCtrl, hint: l10n.adminHeroTitleHint),
            const SizedBox(height: 16),

            // Hero Subtitle
            _fieldLabel(tokens, l10n.adminHeroSubtitle),
            const SizedBox(height: 6),
            _field(
              tokens,
              _heroSubtitleCtrl,
              hint: l10n.adminHeroSubtitleHint,
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // CTA Button
            _sectionHeader(tokens, l10n.adminCallToAction),
            const SizedBox(height: 12),
            _fieldLabel(tokens, l10n.adminButtonText),
            const SizedBox(height: 6),
            _field(tokens, _ctaTextCtrl, hint: l10n.adminButtonTextHint),
            const SizedBox(height: 16),
            _fieldLabel(tokens, l10n.adminButtonUrl),
            const SizedBox(height: 6),
            _field(tokens, _ctaUrlCtrl, hint: '/download'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Sections toggles
            _sectionHeader(tokens, l10n.adminSections),
            const SizedBox(height: 12),
            _toggleRow(
              tokens,
              label: l10n.adminShowFeaturesSection,
              value: _showFeatures,
              onChanged: (v) => setState(() => _showFeatures = v),
            ),
            const SizedBox(height: 8),
            _toggleRow(
              tokens,
              label: l10n.adminShowTestimonialsSection,
              value: _showTestimonials,
              onChanged: (v) => setState(() => _showTestimonials = v),
            ),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            // Hero Image Upload
            _sectionHeader(tokens, l10n.adminHeroImage),
            const SizedBox(height: 12),
            _uploadArea(
              tokens,
              icon: Icons.panorama_rounded,
              label: l10n.adminUploadHeroImage,
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

  Widget _toggleRow(
    OrchestraColorTokens tokens, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: tokens.fgBright),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: tokens.accent,
            onChanged: onChanged,
          ),
        ],
      ),
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
            Text(label, style: TextStyle(fontSize: 13, color: tokens.fgDim)),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).pngJpgLimit,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
