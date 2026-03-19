import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// API tokens settings tab — generate and manage API keys.
class ApiTokensSettingsTab extends ConsumerStatefulWidget {
  const ApiTokensSettingsTab({super.key});

  @override
  ConsumerState<ApiTokensSettingsTab> createState() =>
      _ApiTokensSettingsTabState();
}

class _ApiTokensSettingsTabState extends ConsumerState<ApiTokensSettingsTab> {
  final _nameCtrl = TextEditingController();
  bool _generating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final result = await ref.read(apiClientProvider).createApiKey({
        'name': _nameCtrl.text.trim(),
      });
      ref.invalidate(apiKeysProvider);
      if (mounted) {
        _nameCtrl.clear();
        // Show the token once — it won't be retrievable again.
        final token = result['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          _showNewTokenDialog(token);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).apiKeyCreated)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToCreateApiKey}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showNewTokenDialog(String token) {
    final tokens = ThemeTokens.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'API Key Created',
          style: TextStyle(color: tokens.fgBright, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy this key now. You will not be able to see it again.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      token,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: tokens.fgBright,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded,
                        size: 16, color: tokens.accent),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppLocalizations.of(context).copiedToClipboard)),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).done, style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeKey(String id) async {
    try {
      await ref.read(apiClientProvider).revokeApiKey(id);
      ref.invalidate(apiKeysProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).apiKeyRevoked)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToRevokeApiKey}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final keysAsync = ref.watch(apiKeysProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // -- Generate API Key ------------------------------------------------
        _sectionHeader(tokens, 'Generate API Key'),
        const SizedBox(height: 12),
        _field(tokens, _nameCtrl, hint: 'Token name (e.g. CI/CD)'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generating ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(AppLocalizations.of(context).generate),
          ),
        ),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // -- Your API Keys ---------------------------------------------------
        _sectionHeader(tokens, 'Your API Keys'),
        const SizedBox(height: 4),
        Text(
          'Keys are shown as prefixes only. The full key is displayed once at creation.',
          style: TextStyle(fontSize: 11, color: tokens.fgDim),
        ),
        const SizedBox(height: 16),

        keysAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load API keys',
                    style:
                        TextStyle(color: tokens.fgBright, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$error',
                    style: TextStyle(color: tokens.fgDim, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(apiKeysProvider),
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                ],
              ),
            ),
          ),
          data: (keys) {
            if (keys.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No API keys yet.',
                    style:
                        TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                ),
              );
            }
            return DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < keys.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        color: tokens.border.withValues(alpha: 0.4),
                      ),
                    _buildKeyRow(tokens, keys[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyRow(
      OrchestraColorTokens tokens, Map<String, dynamic> key) {
    final name = (key['name'] ?? 'Unnamed').toString();
    final prefix = (key['prefix'] ?? key['key_prefix'] ?? '').toString();
    final createdAt = (key['created_at'] ?? '').toString();
    final lastUsed = (key['last_used'] ?? key['last_used_at'] ?? 'Never').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Key icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.vpn_key_rounded, size: 16, color: tokens.accent),
          ),
          const SizedBox(width: 12),

          // Key info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                if (prefix.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    prefix,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: tokens.fgMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Created $createdAt  ·  Last used $lastUsed',
                  style: TextStyle(fontSize: 10, color: tokens.fgDim),
                ),
              ],
            ),
          ),

          // Revoke button
          OutlinedButton(
            onPressed: () => _revokeKey(key['id'].toString()),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Revoke',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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

  Widget _field(
    OrchestraColorTokens tokens,
    TextEditingController ctrl, {
    required String hint,
  }) {
    return TextField(
      controller: ctrl,
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
