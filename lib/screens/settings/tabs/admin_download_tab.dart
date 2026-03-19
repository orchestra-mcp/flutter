import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/admin_settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Admin download tab — download URLs for each platform, version, release notes.
class AdminDownloadTab extends ConsumerStatefulWidget {
  const AdminDownloadTab({super.key});

  @override
  ConsumerState<AdminDownloadTab> createState() => _AdminDownloadTabState();
}

class _AdminDownloadTabState extends ConsumerState<AdminDownloadTab> {
  final _macUrlCtrl = TextEditingController();
  final _windowsUrlCtrl = TextEditingController();
  final _linuxUrlCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _releaseNotesCtrl = TextEditingController();
  bool _saving = false;
  bool _initialized = false;

  void _populateFields(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    _macUrlCtrl.text = data['mac_url'] as String? ?? '';
    _windowsUrlCtrl.text = data['windows_url'] as String? ?? '';
    _linuxUrlCtrl.text = data['linux_url'] as String? ?? '';
    _versionCtrl.text = data['version'] as String? ?? '';
    _releaseNotesCtrl.text = data['release_notes'] as String? ?? '';
  }

  @override
  void dispose() {
    _macUrlCtrl.dispose();
    _windowsUrlCtrl.dispose();
    _linuxUrlCtrl.dispose();
    _versionCtrl.dispose();
    _releaseNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateAdminSetting('download', {
        'mac_url': _macUrlCtrl.text,
        'windows_url': _windowsUrlCtrl.text,
        'linux_url': _linuxUrlCtrl.text,
        'version': _versionCtrl.text,
        'release_notes': _releaseNotesCtrl.text,
      });
      ref.invalidate(adminSettingProvider('download'));
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
    final settingAsync = ref.watch(adminSettingProvider('download'));

    return settingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${AppLocalizations.of(context).failedToLoad}: $e')),
      data: (data) {
        final l10n = AppLocalizations.of(context);
        _populateFields(data);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader(tokens, l10n.adminDownloadUrls),
            const SizedBox(height: 12),

            // macOS
            _platformField(tokens,
                icon: Icons.laptop_mac_rounded,
                label: l10n.adminPlatformMacos,
                ctrl: _macUrlCtrl,
                hint: 'https://...'),
            const SizedBox(height: 12),

            // Windows
            _platformField(tokens,
                icon: Icons.desktop_windows_rounded,
                label: l10n.adminPlatformWindows,
                ctrl: _windowsUrlCtrl,
                hint: 'https://...'),
            const SizedBox(height: 12),

            // Linux
            _platformField(tokens,
                icon: Icons.computer_rounded,
                label: l10n.adminPlatformLinux,
                ctrl: _linuxUrlCtrl,
                hint: 'https://...'),

            const SizedBox(height: 24),
            Divider(color: tokens.border.withValues(alpha: 0.4)),
            const SizedBox(height: 20),

            _sectionHeader(tokens, l10n.adminReleaseInfo),
            const SizedBox(height: 12),

            // Version
            _fieldLabel(tokens, l10n.adminVersion),
            const SizedBox(height: 6),
            _field(tokens, _versionCtrl, hint: '1.0.0'),
            const SizedBox(height: 16),

            // Release Notes
            _fieldLabel(tokens, l10n.adminReleaseNotes),
            const SizedBox(height: 6),
            _field(tokens, _releaseNotesCtrl,
                hint: l10n.adminReleaseNotesHint, maxLines: 5),

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

  Widget _platformField(
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
              Icon(icon, size: 18, color: tokens.fgMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.fgBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: tokens.fgDim),
              filled: true,
              fillColor: tokens.bgAlt,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
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
