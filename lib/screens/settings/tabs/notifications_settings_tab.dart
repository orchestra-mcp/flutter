import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Notifications settings tab — toggle switches for each notification category.
class NotificationsSettingsTab extends ConsumerStatefulWidget {
  const NotificationsSettingsTab({super.key});

  @override
  ConsumerState<NotificationsSettingsTab> createState() =>
      _NotificationsSettingsTabState();
}

class _NotificationsSettingsTabState
    extends ConsumerState<NotificationsSettingsTab> {
  /// Local overrides while a save is in flight.
  Map<String, bool>? _pendingToggles;
  bool _saving = false;

  /// Local overrides for AI toggles while saving.
  Map<String, dynamic>? _pendingAiToggles;
  bool _savingAi = false;

  static List<({String key, IconData icon, String label, String sub})> _items(AppLocalizations l10n) => [
    (
      key: 'push',
      icon: Icons.notifications_rounded,
      label: l10n.notifSettingsPushNotifications,
      sub: l10n.notifSettingsPushNotificationsSub,
    ),
    (
      key: 'sync',
      icon: Icons.sync_rounded,
      label: l10n.notifSettingsSyncNotifications,
      sub: l10n.notifSettingsSyncNotificationsSub,
    ),
    (
      key: 'email',
      icon: Icons.email_outlined,
      label: l10n.notifSettingsEmailDigests,
      sub: l10n.notifSettingsEmailDigestsSub,
    ),
    (
      key: 'health',
      icon: Icons.favorite_border_rounded,
      label: l10n.notifSettingsHealthReminders,
      sub: l10n.notifSettingsHealthRemindersSub,
    ),
    (
      key: 'pomodoro',
      icon: Icons.timer_outlined,
      label: l10n.notifSettingsPomodoroAlerts,
      sub: l10n.notifSettingsPomodoroAlertsSub,
    ),
  ];

  Map<String, bool> _extractNotifications(Map<String, dynamic> prefs) {
    final raw = prefs['notifications'];
    const keys = ['push', 'sync', 'email', 'health', 'pomodoro'];
    if (raw is Map) {
      return {
        for (final key in keys) key: raw[key] != false,
      };
    }
    // Fallback: check top-level keys with notification_ prefix.
    return {
      for (final key in keys)
        key: prefs['notification_$key'] != false && prefs[key] != false,
    };
  }

  Future<void> _toggleAi(String key, bool value,
      Map<String, dynamic> current) async {
    final updated = {...current, key: value};
    setState(() {
      _pendingAiToggles = updated;
      _savingAi = true;
    });
    try {
      final mcp = ref.read(mcpClientProvider);
      if (mcp != null) {
        await mcp.callTool('notify_config', {
          'action': 'set',
          key: value,
        });
      }
      ref.invalidate(aiNotificationSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSaveAiSetting}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingAiToggles = null;
          _savingAi = false;
        });
      }
    }
  }

  Future<void> _toggle(String key, bool value,
      Map<String, bool> current) async {
    final updated = {...current, key: value};
    setState(() {
      _pendingToggles = updated;
      _saving = true;
    });
    try {
      await ref.read(apiClientProvider).updatePreferences({
        'notifications': updated,
      });
      ref.invalidate(preferencesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).failedToSavePreference}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingToggles = null;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(preferencesProvider);

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 40, color: tokens.fgDim),
              const SizedBox(height: 12),
              Text(
                l10n.notifSettingsFailedToLoadPreferences,
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
                onPressed: () => ref.invalidate(preferencesProvider),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      ),
      data: (prefs) {
        final notifications =
            _pendingToggles ?? _extractNotifications(prefs);
        final items = _items(l10n);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.notifSettingsNotifications,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.fgBright,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: tokens.border.withValues(alpha: 0.4),
                      ),
                    _NotifRow(
                      icon: items[i].icon,
                      label: items[i].label,
                      subtitle: items[i].sub,
                      value: notifications[items[i].key] ?? false,
                      tokens: tokens,
                      onChanged: _saving
                          ? null
                          : (v) => _toggle(
                              items[i].key, v, notifications),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.notifSettingsAiAgent,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.fgBright,
              ),
            ),
            const SizedBox(height: 12),
            _AiNotificationSection(
              pendingToggles: _pendingAiToggles,
              saving: _savingAi,
              onToggle: _toggleAi,
              tokens: tokens,
            ),
          ],
        );
      },
    );
  }
}

class _AiNotificationSection extends ConsumerWidget {
  const _AiNotificationSection({
    required this.pendingToggles,
    required this.saving,
    required this.onToggle,
    required this.tokens,
  });

  final Map<String, dynamic>? pendingToggles;
  final bool saving;
  final void Function(String key, bool value, Map<String, dynamic> current)
      onToggle;
  final OrchestraColorTokens tokens;

  static List<({String key, IconData icon, String label, String sub})> _aiItems(AppLocalizations l10n) => [
    (
      key: 'ai_push_enabled',
      icon: Icons.smart_toy_outlined,
      label: l10n.notifSettingsAiPushNotifications,
      sub: l10n.notifSettingsAiPushNotificationsSub,
    ),
    (
      key: 'ai_voice_enabled',
      icon: Icons.record_voice_over_outlined,
      label: l10n.notifSettingsAiVoiceAlerts,
      sub: l10n.notifSettingsAiVoiceAlertsSub,
    ),
    (
      key: 'socket_push_enabled',
      icon: Icons.devices_rounded,
      label: l10n.notifSettingsPushToConnectedApps,
      sub: l10n.notifSettingsPushToConnectedAppsSub,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final aiAsync = ref.watch(aiNotificationSettingsProvider);

    return aiAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          l10n.notifSettingsCouldNotLoadAiSettings,
          style: TextStyle(color: tokens.fgDim, fontSize: 12),
        ),
      ),
      data: (aiSettings) {
        final current = pendingToggles ?? aiSettings;
        final voiceName = aiSettings['voice_name'] as String? ?? '';
        final voiceSpeed = aiSettings['voice_speed'] as String? ?? '';
        final quietStart = aiSettings['quiet_hours_start'] as String? ?? '';
        final quietEnd = aiSettings['quiet_hours_end'] as String? ?? '';
        final aiItems = _aiItems(l10n);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < aiItems.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: tokens.border.withValues(alpha: 0.4),
                      ),
                    _NotifRow(
                      icon: aiItems[i].icon,
                      label: aiItems[i].label,
                      subtitle: aiItems[i].sub,
                      value: (current[aiItems[i].key] as bool?) ?? true,
                      tokens: tokens,
                      onChanged: saving
                          ? null
                          : (v) => onToggle(aiItems[i].key, v, current),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Voice & Quiet Hours
            Text(
              l10n.notifSettingsVoiceAndSchedule,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.fgMuted,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.record_voice_over_rounded,
                    label: l10n.notifSettingsVoice,
                    value: voiceName.isEmpty ? l10n.notifSettingsSystemDefault : voiceName,
                    tokens: tokens,
                  ),
                  Divider(height: 1, indent: 56, color: tokens.border.withValues(alpha: 0.4)),
                  _InfoRow(
                    icon: Icons.speed_rounded,
                    label: l10n.notifSettingsSpeed,
                    value: voiceSpeed.isEmpty ? l10n.notifSettingsSpeedDefault : l10n.notifSettingsSpeedWpm(voiceSpeed),
                    tokens: tokens,
                  ),
                  Divider(height: 1, indent: 56, color: tokens.border.withValues(alpha: 0.4)),
                  _InfoRow(
                    icon: Icons.do_not_disturb_on_outlined,
                    label: l10n.notifSettingsQuietHours,
                    value: quietStart.isEmpty
                        ? l10n.notifSettingsQuietHoursOff
                        : l10n.notifSettingsQuietHoursRange(quietStart, quietEnd),
                    tokens: tokens,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final String value;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: tokens.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: tokens.fgBright,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: tokens.fgMuted),
          ),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.tokens,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final OrchestraColorTokens tokens;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: tokens.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
              ],
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
}
