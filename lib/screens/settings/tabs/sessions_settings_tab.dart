import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Sessions settings tab — view and revoke active sessions.
class SessionsSettingsTab extends ConsumerStatefulWidget {
  const SessionsSettingsTab({super.key});

  @override
  ConsumerState<SessionsSettingsTab> createState() =>
      _SessionsSettingsTabState();
}

class _SessionsSettingsTabState extends ConsumerState<SessionsSettingsTab> {
  bool _revokingAll = false;

  IconData _deviceIcon(String? device) {
    final d = (device ?? '').toLowerCase();
    if (d.contains('iphone') || d.contains('android') || d.contains('phone')) {
      return Icons.phone_iphone_rounded;
    }
    if (d.contains('ipad') || d.contains('tablet')) {
      return Icons.tablet_mac_rounded;
    }
    if (d.contains('mac') || d.contains('laptop')) {
      return Icons.laptop_mac_rounded;
    }
    return Icons.desktop_windows_rounded;
  }

  /// Parse a raw user-agent string into a friendly "{Browser} on {OS}" label.
  String _parseUserAgent(String ua) {
    if (ua.isEmpty) return '';
    final lower = ua.toLowerCase();

    // Detect browser
    String browser = '';
    if (lower.contains('orchestra')) {
      browser = 'Orchestra App';
    } else if (lower.contains('edg/') || lower.contains('edga/')) {
      browser = 'Edge';
    } else if (lower.contains('chrome') && !lower.contains('chromium')) {
      browser = 'Chrome';
    } else if (lower.contains('firefox')) {
      browser = 'Firefox';
    } else if (lower.contains('safari') && !lower.contains('chrome')) {
      browser = 'Safari';
    } else if (lower.contains('opera') || lower.contains('opr/')) {
      browser = 'Opera';
    }

    // Detect OS
    String os = '';
    if (lower.contains('macintosh') || lower.contains('mac os')) {
      os = 'macOS';
    } else if (lower.contains('windows')) {
      os = 'Windows';
    } else if (lower.contains('linux')) {
      os = 'Linux';
    } else if (lower.contains('iphone')) {
      os = 'iPhone';
    } else if (lower.contains('ipad')) {
      os = 'iPad';
    } else if (lower.contains('android')) {
      os = 'Android';
    }

    if (browser.isNotEmpty && os.isNotEmpty) return '$browser on $os';
    if (browser.isNotEmpty) return browser;
    if (os.isNotEmpty) return os;
    // Truncate raw UA if nothing matched
    return ua.length > 40 ? '${ua.substring(0, 40)}…' : ua;
  }

  /// Convert a timestamp string to a relative time label like "2 hours ago".
  String _relativeTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return timestamp;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _revokeSession(String id) async {
    try {
      await ref.read(apiClientProvider).revokeSession(id);
      ref.invalidate(settingsSessionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).sessionRevoked)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToRevokeSession}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _revokeAllOthers(List<Map<String, dynamic>> sessions) async {
    setState(() => _revokingAll = true);
    try {
      for (final session in sessions) {
        if (session['is_current'] == true) continue;
        await ref
            .read(apiClientProvider)
            .revokeSession(session['id'].toString());
      }
      ref.invalidate(settingsSessionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).allSessionsRevoked),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToRevokeSessions}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _revokingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final sessionsAsync = ref.watch(settingsSessionsProvider);

    return sessionsAsync.when(
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
                'Failed to load sessions',
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
                onPressed: () => ref.invalidate(settingsSessionsProvider),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      ),
      data: (sessions) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // -- Active Sessions -----------------------------------------------
          _sectionHeader(tokens, 'Active Sessions'),
          const SizedBox(height: 4),
          Text(
            'These devices are currently signed into your account.',
            style: TextStyle(fontSize: 12, color: tokens.fgDim),
          ),
          const SizedBox(height: 16),

          // -- Session list --------------------------------------------------
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No active sessions found.',
                  style: TextStyle(color: tokens.fgDim, fontSize: 13),
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < sessions.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: tokens.border.withValues(alpha: 0.4),
                      ),
                    _buildSessionRow(tokens, sessions[i]),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 24),

          // -- Revoke all others ---------------------------------------------
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _revokingAll ? null : () => _revokeAllOthers(sessions),
              icon: _revokingAll
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.accent,
                      ),
                    )
                  : Icon(Icons.logout_rounded, size: 16, color: tokens.accent),
              label: Text(
                'Revoke All Other Sessions',
                style: TextStyle(color: tokens.accent),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.accent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(
    OrchestraColorTokens tokens,
    Map<String, dynamic> session,
  ) {
    final isCurrent = session['is_current'] == true;
    final deviceName =
        (session['device'] ?? session['device_name'] ?? 'Unknown device')
            .toString();
    final os = (session['os'] ?? '').toString();
    final browser = (session['browser'] ?? '').toString();
    final userAgent = (session['user_agent'] ?? '').toString();
    final ip = (session['ip'] ?? session['ip_address'] ?? '').toString();
    final lastActive =
        (session['last_active'] ??
                session['last_active_at'] ??
                session['last_seen'] ??
                '')
            .toString();
    final tunnelActive = session['tunnel_active'] == true;

    // Build a friendly description from parsed fields or user-agent
    final uaParsed = (os.isEmpty && browser.isEmpty && userAgent.isNotEmpty)
        ? _parseUserAgent(userAgent)
        : '';
    final relTime = _relativeTime(lastActive);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Device icon with status dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _deviceIcon(deviceName),
                  size: 18,
                  color: tokens.accent,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.bgAlt, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deviceName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.fgBright,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
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
                          'Current',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (os.isNotEmpty) os,
                    if (browser.isNotEmpty) browser,
                    if (uaParsed.isNotEmpty && os.isEmpty && browser.isEmpty)
                      uaParsed,
                    if (ip.isNotEmpty) ip else 'Unknown IP',
                    if (relTime.isNotEmpty)
                      relTime
                    else if (lastActive.isNotEmpty)
                      lastActive,
                  ].join(' · '),
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
                if (tunnelActive) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Tunnel connected',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Revoke button (not for current session)
          if (!isCurrent)
            TextButton(
              onPressed: () => _revokeSession(session['id'].toString()),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Revoke',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
