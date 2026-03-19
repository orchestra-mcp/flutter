import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/i18n/locale_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Profile settings — avatar, name, email, phone, gender, position, timezone, bio.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();

  String? _gender;
  String? _avatarUrl;
  String? _coverUrl;
  bool _publicProfileEnabled = true;
  bool _showComments = true;
  List<Map<String, String>> _socialLinks = [];
  bool _saving = false;
  bool _uploading = false;
  bool _loading = true;

  static const _genderOptions = ['male', 'female', 'other', 'prefer_not_to_say'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(apiClientProvider).getProfile();
      _nameCtrl.text = (profile['name'] as String?) ?? '';
      _emailCtrl.text = (profile['email'] as String?) ?? '';
      _avatarUrl = profile['avatar_url'] as String?;

      // Extended fields live in `settings` JSON.
      final settings = profile['settings'];
      final s = settings is Map<String, dynamic> ? settings : <String, dynamic>{};
      _phoneCtrl.text = (s['phone'] as String?) ?? (profile['phone'] as String?) ?? '';
      _positionCtrl.text = (s['position'] as String?) ?? (profile['position'] as String?) ?? '';
      _bioCtrl.text = (s['bio'] as String?) ?? (profile['bio'] as String?) ?? '';
      _timezoneCtrl.text = (s['timezone'] as String?) ?? (profile['timezone'] as String?) ?? '';
      _gender = (s['gender'] as String?) ?? (profile['gender'] as String?);
      _handleCtrl.text = (s['handle'] as String?) ?? '';
      _coverUrl = s['cover_url'] as String?;
      _publicProfileEnabled = s['public_profile_enabled'] != false;
      _showComments = s['show_comments_on_profile'] != false;
      final rawLinks = s['social_links'];
      if (rawLinks is List) {
        _socialLinks = rawLinks
            .whereType<Map<String, dynamic>>()
            .map((l) => {
                  'platform': (l['platform'] as String?) ?? 'website',
                  'url': (l['url'] as String?) ?? '',
                })
            .toList();
      }
    } catch (_) {
      // Fallback: pre-fill from cached auth state.
      final authState = ref.read(authProvider);
      final data = authState.value;
      if (data is AuthAuthenticated) {
        _nameCtrl.text = data.user.name;
        _emailCtrl.text = data.user.email;
        _avatarUrl = data.user.avatarUrl;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploading = true);
    try {
      final result =
          await ref.read(apiClientProvider).uploadAvatar(image.path);
      final newUrl = result['avatar_url'] as String?;
      if (newUrl != null && mounted) {
        setState(() => _avatarUrl = newUrl);
        // Refresh auth state to update cached user avatar everywhere.
        ref.invalidate(authProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).avatarUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToUploadAvatar}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).updateSettingsProfile({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender ?? '',
        'position': _positionCtrl.text.trim(),
        'timezone': _timezoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'handle': _handleCtrl.text.trim(),
        'public_profile_enabled': _publicProfileEnabled,
        'show_comments_on_profile': _showComments,
        'social_links': _socialLinks.where((l) => l['url']!.trim().isNotEmpty).toList(),
      });
      // Refresh auth state so the cached user name/email stays in sync.
      ref.invalidate(authProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
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
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _bioCtrl.dispose();
    _timezoneCtrl.dispose();
    _handleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.accent,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Avatar ──────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        _buildAvatar(tokens),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: tokens.accent,
                            child: _uploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Name ────────────────────────────────────────────
                _field(_nameCtrl, l10n.name, tokens),
                const SizedBox(height: 12),

                // ── Email ───────────────────────────────────────────
                _field(_emailCtrl, l10n.email, tokens,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),

                // ── Phone ───────────────────────────────────────────
                _field(_phoneCtrl, l10n.phone, tokens,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),

                // ── Gender ──────────────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: l10n.gender,
                    labelStyle: TextStyle(color: tokens.fgMuted),
                  ),
                  dropdownColor: tokens.bgAlt,
                  style: TextStyle(color: tokens.fgBright),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.select)),
                    for (final g in _genderOptions)
                      DropdownMenuItem(
                        value: g,
                        child: Text(_genderLabel(g, l10n)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const SizedBox(height: 12),

                // ── Position ────────────────────────────────────────
                _field(_positionCtrl, l10n.position, tokens),
                const SizedBox(height: 12),

                // ── Timezone ────────────────────────────────────────
                _field(_timezoneCtrl, l10n.timezone, tokens,
                    hint: 'e.g. Africa/Cairo'),
                const SizedBox(height: 12),

                // ── Language ──────────────────────────────────────────
                _buildLanguagePicker(tokens, l10n),
                const SizedBox(height: 12),

                // ── Bio ─────────────────────────────────────────────
                _field(_bioCtrl, l10n.bio, tokens, maxLines: 3),
                const SizedBox(height: 24),

                // ── Cover Image ─────────────────────────────────────
                _buildCoverImage(tokens),
                const SizedBox(height: 24),

                // ── Public Profile ──────────────────────────────────
                Text(
                  l10n.publicProfileSection,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: tokens.fgDim,
                  ),
                ),
                const SizedBox(height: 12),

                _field(_handleCtrl, l10n.handle, tokens,
                    hint: l10n.handleHint, icon: Icons.alternate_email),
                const SizedBox(height: 12),

                // Public profile toggle
                SwitchListTile(
                  value: _publicProfileEnabled,
                  onChanged: (v) => setState(() => _publicProfileEnabled = v),
                  title: Text(l10n.publicProfileToggle, style: TextStyle(color: tokens.fgBright, fontSize: 14)),
                  subtitle: Text(l10n.publicProfileSubtitle, style: TextStyle(color: tokens.fgDim, fontSize: 12)),
                  activeColor: tokens.accent,
                  contentPadding: EdgeInsets.zero,
                ),

                // Show comments toggle
                SwitchListTile(
                  value: _showComments,
                  onChanged: (v) => setState(() => _showComments = v),
                  title: Text(l10n.showComments, style: TextStyle(color: tokens.fgBright, fontSize: 14)),
                  subtitle: Text(l10n.showCommentsSubtitle, style: TextStyle(color: tokens.fgDim, fontSize: 12)),
                  activeColor: tokens.accent,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // ── Social Links (dynamic) ─────────────────────────
                _buildSocialLinks(tokens),
                const SizedBox(height: 24),

                // ── Save ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.save),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Cover image ──────────────────────────────────────────────────────────

  Widget _buildCoverImage(OrchestraColorTokens tokens) {
    return GestureDetector(
      onTap: _pickAndUploadCover,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: tokens.bgAlt,
          image: _coverUrl != null && _coverUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(resolveAvatarUrl(_coverUrl)!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverUrl == null || _coverUrl!.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: tokens.fgDim),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context).addCoverImage, style: TextStyle(color: tokens.fgDim, fontSize: 12)),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _uploading = true);
    try {
      // Use the REST API directly for cover upload.
      final api = ref.read(apiClientProvider);
      final result = await api.updateSettingsProfile({
        'cover_path': image.path,
      });
      final newUrl = result['cover_url'] as String? ?? result['settings']?['cover_url'] as String?;
      if (newUrl != null && mounted) {
        setState(() => _coverUrl = newUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).coverUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToUploadCover}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Dynamic social links ───────────────────────────────────────────────

  static const _platformOptions = [
    ('github', 'GitHub', Icons.code, 'https://github.com/...'),
    ('twitter', 'Twitter / X', Icons.alternate_email, 'https://twitter.com/...'),
    ('linkedin', 'LinkedIn', Icons.work_outline, 'https://linkedin.com/in/...'),
    ('youtube', 'YouTube', Icons.play_circle_outline, 'https://youtube.com/...'),
    ('discord', 'Discord', Icons.chat_bubble_outline, 'https://discord.gg/...'),
    ('website', 'Website', Icons.language, 'https://...'),
    ('instagram', 'Instagram', Icons.camera_alt_outlined, 'https://instagram.com/...'),
    ('bluesky', 'Bluesky', Icons.cloud_outlined, 'https://bsky.app/...'),
    ('other', 'Other', Icons.link, 'https://...'),
  ];

  Widget _buildSocialLinks(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).socialLinksSection,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: tokens.fgDim),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < _socialLinks.length; i++) ...[
          _socialLinkRow(tokens, i),
          const SizedBox(height: 8),
        ],
        if (_socialLinks.length < 10)
          TextButton.icon(
            onPressed: () => setState(() => _socialLinks.add({'platform': 'website', 'url': ''})),
            icon: Icon(Icons.add_rounded, size: 18, color: tokens.accent),
            label: Text(AppLocalizations.of(context).addLink, style: TextStyle(color: tokens.accent, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _socialLinkRow(OrchestraColorTokens tokens, int index) {
    final link = _socialLinks[index];
    final platform = link['platform'] ?? 'website';
    final option = _platformOptions.firstWhere((o) => o.$1 == platform, orElse: () => _platformOptions.last);

    return Row(
      children: [
        // Platform dropdown
        PopupMenuButton<String>(
          onSelected: (v) => setState(() => _socialLinks[index] = {...link, 'platform': v}),
          itemBuilder: (_) => _platformOptions.map((o) => PopupMenuItem(
                value: o.$1,
                child: Row(
                  children: [
                    Icon(o.$3, size: 18, color: tokens.fgMuted),
                    const SizedBox(width: 8),
                    Text(o.$2, style: TextStyle(color: tokens.fgBright, fontSize: 13)),
                  ],
                ),
              )).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(option.$3, size: 16, color: tokens.accent),
                const SizedBox(width: 6),
                Icon(Icons.arrow_drop_down, size: 16, color: tokens.fgDim),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // URL input
        Expanded(
          child: TextField(
            controller: TextEditingController(text: link['url']),
            onChanged: (v) => _socialLinks[index] = {...link, 'url': v},
            style: TextStyle(color: tokens.fgBright, fontSize: 13),
            decoration: InputDecoration(
              hintText: option.$4,
              hintStyle: TextStyle(color: tokens.fgDim.withValues(alpha: 0.5), fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tokens.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tokens.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: tokens.accent)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Delete
        IconButton(
          onPressed: () => setState(() => _socialLinks.removeAt(index)),
          icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade300),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildLanguagePicker(OrchestraColorTokens tokens, AppLocalizations l10n) {
    final currentLocale = ref.watch(localeProvider);
    final currentLabel = currentLocale.languageCode == 'ar' ? l10n.arabic : l10n.english;

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.selectLanguage, style: TextStyle(color: tokens.fgBright)),
            backgroundColor: tokens.bg,
            children: [
              _languageOption(ctx, tokens, l10n.english, 'en', currentLocale.languageCode == 'en'),
              _languageOption(ctx, tokens, l10n.arabic, 'ar', currentLocale.languageCode == 'ar'),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.language,
          labelStyle: TextStyle(color: tokens.fgMuted),
          suffixIcon: Icon(Icons.language, color: tokens.fgMuted),
        ),
        child: Text(currentLabel, style: TextStyle(color: tokens.fgBright)),
      ),
    );
  }

  Widget _languageOption(BuildContext ctx, OrchestraColorTokens tokens, String label, String code, bool isSelected) {
    return ListTile(
      leading: isSelected
          ? Icon(Icons.check_circle_rounded, color: tokens.accent)
          : Icon(Icons.radio_button_off_rounded, color: tokens.fgDim),
      title: Text(label, style: TextStyle(color: tokens.fgBright)),
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.of(ctx).pop();
      },
    );
  }

  Widget _buildAvatar(OrchestraColorTokens tokens) {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: tokens.accentSurface,
        backgroundImage: NetworkImage(resolveAvatarUrl(_avatarUrl)!),
        onBackgroundImageError: (_, __) {},
      );
    }
    final initial = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : '?';
    return CircleAvatar(
      radius: 40,
      backgroundColor: tokens.accentSurface,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: tokens.accent,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    OrchestraColorTokens tokens, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    IconData? icon,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: tokens.fgMuted),
        hintStyle: TextStyle(color: tokens.fgMuted.withValues(alpha: 0.5)),
        prefixIcon: icon != null ? Icon(icon, color: tokens.fgDim, size: 20) : null,
      ),
      style: TextStyle(color: tokens.fgBright),
    );
  }

  String _genderLabel(String value, AppLocalizations l10n) => switch (value) {
        'male' => l10n.male,
        'female' => l10n.female,
        'other' => l10n.genderOther,
        'prefer_not_to_say' => l10n.preferNotToSay,
        _ => value,
      };
}
