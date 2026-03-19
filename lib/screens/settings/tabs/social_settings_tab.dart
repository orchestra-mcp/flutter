import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/auth/auth_provider.dart';
import 'package:orchestra/core/auth/user_model.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/url_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Social & public profile settings — cover image, social links, visibility toggles.
class SocialSettingsTab extends ConsumerStatefulWidget {
  const SocialSettingsTab({super.key});

  @override
  ConsumerState<SocialSettingsTab> createState() => _SocialSettingsTabState();
}

class _SocialSettingsTabState extends ConsumerState<SocialSettingsTab> {
  bool _publicProfile = false;
  bool _showComments = true;
  String? _coverUrl;

  final _links = <_SocialLink>[];
  bool _saving = false;

  static const _platforms = [
    'website',
    'github',
    'twitter',
    'linkedin',
    'youtube',
    'discord',
    'instagram',
    'facebook',
    'dribbble',
    'behance',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider.notifier).currentUser;
    if (user != null) {
      _publicProfile = user.publicProfileEnabled;
      _showComments = user.showCommentsOnProfile;
      _coverUrl = user.coverUrl;
      for (final link in user.socialLinks) {
        _links.add(
          _SocialLink(
            platform: link['platform'] ?? 'website',
            controller: TextEditingController(text: link['url'] ?? ''),
          ),
        );
      }
    }
    if (_links.isEmpty) {
      _links.add(
        _SocialLink(platform: 'website', controller: TextEditingController()),
      );
    }
  }

  @override
  void dispose() {
    for (final link in _links) {
      link.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final socialLinks = _links
          .where((l) => l.controller.text.trim().isNotEmpty)
          .map((l) => {'platform': l.platform, 'url': l.controller.text.trim()})
          .toList();

      await ref.read(apiClientProvider).updateSettingsProfile({
        'public_profile_enabled': _publicProfile,
        'show_comments_on_profile': _showComments,
        'cover_url': _coverUrl ?? '',
        'social_links': socialLinks,
      });
      ref.invalidate(authProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).socialLinksUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToSaveSocialLinks}: $e',
            ),
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
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Cover image ──────────────────────────────────────────────
        _sectionHeader(tokens, l10n.coverImage),
        const SizedBox(height: 4),
        Text(
          l10n.coverImageDesc,
          style: TextStyle(fontSize: 12, color: tokens.fgDim),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // TODO: image picker for cover upload
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
              image: _coverUrl != null && _coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(resolveMediaUrl(_coverUrl!)!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _coverUrl == null || _coverUrl!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 28,
                          color: tokens.fgDim,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.uploadCover,
                          style: TextStyle(color: tokens.fgDim, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        // ── Public profile toggle ────────────────────────────────────
        _sectionHeader(tokens, l10n.publicProfile),
        const SizedBox(height: 12),
        _toggle(
          tokens,
          l10n.enablePublicProfile,
          l10n.enablePublicProfileDesc,
          _publicProfile,
          (v) => setState(() => _publicProfile = v),
        ),
        const SizedBox(height: 12),
        _toggle(
          tokens,
          l10n.showCommentsOnProfile,
          l10n.showCommentsOnProfileDesc,
          _showComments,
          (v) => setState(() => _showComments = v),
        ),
        const SizedBox(height: 24),

        // ── Social links ─────────────────────────────────────────────
        _sectionHeader(tokens, l10n.socialLinks),
        const SizedBox(height: 4),
        Text(
          l10n.socialLinksDesc,
          style: TextStyle(fontSize: 12, color: tokens.fgDim),
        ),
        const SizedBox(height: 16),
        ..._links.asMap().entries.map((entry) {
          final idx = entry.key;
          final link = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Platform dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: link.platform,
                      dropdownColor: tokens.bgAlt,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      items: _platforms
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _iconForPlatform(p),
                                    size: 16,
                                    color: tokens.fgMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(_capitalize(p)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => link.platform = v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // URL field
                Expanded(
                  child: TextField(
                    controller: link.controller,
                    style: TextStyle(color: tokens.fgBright, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'https://',
                      hintStyle: TextStyle(color: tokens.fgDim),
                      filled: true,
                      fillColor: tokens.bgAlt,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
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
                  ),
                ),
                const SizedBox(width: 6),
                // Remove button
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _links[idx].controller.dispose();
                      _links.removeAt(idx);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        // Add link button
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _links.add(
                  _SocialLink(
                    platform: 'website',
                    controller: TextEditingController(),
                  ),
                );
              });
            },
            icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
            label: Text(
              l10n.addLink,
              style: TextStyle(color: tokens.accent, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Save ─────────────────────────────────────────────────────
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
                : Text(l10n.save),
          ),
        ),
        const SizedBox(height: 40),
      ],
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

  Widget _toggle(
    OrchestraColorTokens tokens,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.accent,
          ),
        ],
      ),
    );
  }

  static IconData _iconForPlatform(String p) => switch (p) {
    'github' => Icons.code_rounded,
    'twitter' => Icons.alternate_email_rounded,
    'linkedin' => Icons.work_outline_rounded,
    'youtube' => Icons.play_circle_outline_rounded,
    'discord' => Icons.chat_rounded,
    'instagram' => Icons.camera_alt_outlined,
    'facebook' => Icons.facebook_rounded,
    'dribbble' => Icons.sports_basketball_rounded,
    'behance' => Icons.brush_rounded,
    _ => Icons.language_rounded,
  };

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _SocialLink {
  _SocialLink({required this.platform, required this.controller});
  String platform;
  final TextEditingController controller;
}

/// Resolve a media URL (cover image, etc.) — prepend API base if relative.
String? resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return resolveAvatarUrl(url);
}
