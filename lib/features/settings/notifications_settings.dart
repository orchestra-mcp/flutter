import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/providers/settings_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Notification settings screen for mobile — matches the desktop tab.
class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _saving = false;

  /// Calls notify_config set via MCP (desktop) or direct WebSocket (mobile).
  Future<void> _mcpSet(Map<String, dynamic> params) async {
    final mcp = ref.read(mcpClientProvider);
    if (mcp != null) {
      await mcp.callTool('notify_config', {'action': 'set', ...params});
      return;
    }
    // Mobile: connect directly to web-gate WebSocket.
    await _callViaWebGate('notify_config', {'action': 'set', ...params});
  }

  Future<void> _callViaWebGate(String tool, Map<String, dynamic> args) async {
    final host = Env.mcpHost;
    final uri = Uri.parse('ws://$host:9201/ws');
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;

    // Initialize.
    channel.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'mobile-settings', 'version': '1.0.0'},
        },
      }),
    );

    // Wait for init response.
    await channel.stream.first;

    // Call tool.
    channel.sink.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/call',
        'params': {'name': tool, 'arguments': args},
      }),
    );

    // Wait for response then close.
    await channel.stream.first;
    await channel.sink.close();
  }

  Future<void> _toggleAi(String key, bool value) async {
    setState(() => _saving = true);
    try {
      await _mcpSet({key: value});
      ref.invalidate(aiNotificationSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedToSaveError(e.toString()),
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
    final aiAsync = ref.watch(aiNotificationSettingsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI Agent Section ────────────────────────────────────
          _sectionHeader(l10n.aiAgentSection, tokens),
          const SizedBox(height: 8),
          aiAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => Text(
              l10n.couldNotLoadSettings,
              style: TextStyle(color: tokens.fgDim),
            ),
            data: (settings) => _buildAiSection(tokens, settings),
          ),
          const SizedBox(height: 24),

          // ── Voice & Schedule ────────────────────────────────────
          _sectionHeader(l10n.voiceAndSchedule, tokens),
          const SizedBox(height: 8),
          aiAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (settings) => _buildVoiceSection(tokens, settings),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, OrchestraColorTokens tokens) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tokens.fgBright,
      ),
    );
  }

  Widget _buildAiSection(
    OrchestraColorTokens tokens,
    Map<String, dynamic> settings,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          _toggleRow(
            tokens: tokens,
            icon: Icons.smart_toy_outlined,
            label: l10n.aiPushNotifications,
            subtitle: l10n.aiPushNotificationsSubtitle,
            value: settings['ai_push_enabled'] == true,
            onChanged: (v) => _toggleAi('ai_push_enabled', v),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: tokens.border.withValues(alpha: 0.4),
          ),
          _toggleRow(
            tokens: tokens,
            icon: Icons.record_voice_over_outlined,
            label: l10n.aiVoiceAlerts,
            subtitle: l10n.aiVoiceAlertsSubtitle,
            value: settings['ai_voice_enabled'] == true,
            onChanged: (v) => _toggleAi('ai_voice_enabled', v),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: tokens.border.withValues(alpha: 0.4),
          ),
          _toggleRow(
            tokens: tokens,
            icon: Icons.devices_rounded,
            label: l10n.pushToConnectedApps,
            subtitle: l10n.pushToConnectedAppsSubtitle,
            value: settings['socket_push_enabled'] == true,
            onChanged: (v) => _toggleAi('socket_push_enabled', v),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSection(
    OrchestraColorTokens tokens,
    Map<String, dynamic> settings,
  ) {
    final l10n = AppLocalizations.of(context);
    final voiceNameVal = (settings['voice_name'] as String?) ?? '';
    final voiceSpeed = (settings['voice_speed'] as String?) ?? '';
    final quietStart = (settings['quiet_hours_start'] as String?) ?? '';
    final quietEnd = (settings['quiet_hours_end'] as String?) ?? '';

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          _editableRow(
            tokens: tokens,
            icon: Icons.record_voice_over_rounded,
            label: l10n.voiceLabel,
            value: voiceNameVal.isEmpty ? l10n.systemDefault : voiceNameVal,
            onTap: () => _editField(
              'voice_name',
              l10n.voiceName,
              voiceNameVal,
              'e.g. Samantha',
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: tokens.border.withValues(alpha: 0.4),
          ),
          _editableRow(
            tokens: tokens,
            icon: Icons.speed_rounded,
            label: l10n.speedLabel,
            value: voiceSpeed.isEmpty
                ? l10n.defaultLabel
                : l10n.wpmSuffix(voiceSpeed),
            onTap: () => _editField(
              'voice_speed',
              l10n.speedWordsPerMin,
              voiceSpeed,
              'e.g. 180',
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: tokens.border.withValues(alpha: 0.4),
          ),
          _editableRow(
            tokens: tokens,
            icon: Icons.volume_up_rounded,
            label: l10n.volumeLabel,
            value: (settings['voice_volume'] as String? ?? '').isEmpty
                ? l10n.defaultLabel
                : '${settings['voice_volume']}',
            onTap: () => _editField(
              'voice_volume',
              l10n.volumeRange,
              (settings['voice_volume'] as String?) ?? '',
              'e.g. 0.8',
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: tokens.border.withValues(alpha: 0.4),
          ),
          _editableRow(
            tokens: tokens,
            icon: Icons.do_not_disturb_on_outlined,
            label: l10n.quietHours,
            value: quietStart.isEmpty
                ? l10n.quietHoursOff
                : '$quietStart – $quietEnd',
            onTap: () => _editQuietHours(quietStart, quietEnd),
          ),
        ],
      ),
    );
  }

  Future<void> _editField(
    String key,
    String label,
    String current,
    String hint,
  ) async {
    final ctrl = TextEditingController(text: current);
    final tokens = ThemeTokens.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(label, style: TextStyle(color: tokens.fgBright)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: tokens.fgBright),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: tokens.fgDim),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: tokens.fgMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(
              AppLocalizations.of(context).save,
              style: TextStyle(color: tokens.accent),
            ),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null) return;

    try {
      await _mcpSet({key: result});
      ref.invalidate(aiNotificationSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedToSaveError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editQuietHours(String start, String end) async {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final startCtrl = TextEditingController(text: start);
    final endCtrl = TextEditingController(text: end);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(
          l10n.quietHoursTitle,
          style: TextStyle(color: tokens.fgBright),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startCtrl,
              style: TextStyle(color: tokens.fgBright),
              decoration: InputDecoration(
                labelText: l10n.quietHoursStart,
                hintText: '22:00',
                labelStyle: TextStyle(color: tokens.fgDim),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endCtrl,
              style: TextStyle(color: tokens.fgBright),
              decoration: InputDecoration(
                labelText: l10n.quietHoursEnd,
                hintText: '08:00',
                labelStyle: TextStyle(color: tokens.fgDim),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              startCtrl.text = '';
              endCtrl.text = '';
              Navigator.pop(ctx, true);
            },
            child: Text(
              l10n.turnOff,
              style: TextStyle(color: Colors.red.shade300),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save, style: TextStyle(color: tokens.accent)),
          ),
        ],
      ),
    );
    if (result != true) {
      startCtrl.dispose();
      endCtrl.dispose();
      return;
    }

    try {
      await _mcpSet({
        'quiet_hours_start': startCtrl.text.trim(),
        'quiet_hours_end': endCtrl.text.trim(),
      });
      ref.invalidate(aiNotificationSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedToSaveError(e.toString()),
            ),
          ),
        );
      }
    }
    startCtrl.dispose();
    endCtrl.dispose();
  }

  Widget _toggleRow({
    required OrchestraColorTokens tokens,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
            onChanged: _saving ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _editableRow({
    required OrchestraColorTokens tokens,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
            Text(value, style: TextStyle(fontSize: 12, color: tokens.fgMuted)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: tokens.fgDim),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    OrchestraColorTokens tokens,
    IconData icon,
    String label,
    String value,
  ) {
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
          Text(value, style: TextStyle(fontSize: 12, color: tokens.fgMuted)),
        ],
      ),
    );
  }
}
