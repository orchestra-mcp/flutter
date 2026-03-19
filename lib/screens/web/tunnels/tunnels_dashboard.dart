import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/web/tunnels/tunnel_detail_sheet.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Tunnel model ────────────────────────────────────────────────────────────

enum TunnelOS { macos, windows, linux }

enum TunnelStatus { connected, degraded, disconnected }

class TunnelInfo {
  const TunnelInfo({
    required this.id,
    required this.machineName,
    required this.os,
    required this.status,
    required this.latencyMs,
    required this.lastActive,
    required this.connectedUser,
    required this.ipAddress,
    required this.toolsAvailable,
    required this.recentActions,
  });

  final String id;
  final String machineName;
  final TunnelOS os;
  final TunnelStatus status;
  final int latencyMs;
  final DateTime lastActive;
  final String connectedUser;
  final String ipAddress;
  final int toolsAvailable;
  final List<String> recentActions;

  IconData get osIcon {
    switch (os) {
      case TunnelOS.macos:
        return Icons.laptop_mac_rounded;
      case TunnelOS.windows:
        return Icons.desktop_windows_rounded;
      case TunnelOS.linux:
        return Icons.computer_rounded;
    }
  }

  String get osLabel {
    switch (os) {
      case TunnelOS.macos:
        return 'macOS';
      case TunnelOS.windows:
        return 'Windows';
      case TunnelOS.linux:
        return 'Linux';
    }
  }

  Color get statusColor {
    switch (status) {
      case TunnelStatus.connected:
        return const Color(0xFF4CAF50);
      case TunnelStatus.degraded:
        return const Color(0xFFFF9800);
      case TunnelStatus.disconnected:
        return const Color(0xFFF44336);
    }
  }

  String get statusLabel {
    switch (status) {
      case TunnelStatus.connected:
        return 'Connected';
      case TunnelStatus.degraded:
        return 'Degraded';
      case TunnelStatus.disconnected:
        return 'Disconnected';
    }
  }

  String get lastActiveRelative {
    final diff = DateTime.now().difference(lastActive);
    if (diff.inSeconds < 60) return 'Active now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Mock data ───────────────────────────────────────────────────────────────

final _mockTunnels = [
  TunnelInfo(
    id: 'tun-001',
    machineName: 'Fady-MacBook-Pro',
    os: TunnelOS.macos,
    status: TunnelStatus.connected,
    latencyMs: 12,
    lastActive: DateTime.now().subtract(const Duration(seconds: 5)),
    connectedUser: 'Fady Mondy',
    ipAddress: '192.168.1.42',
    toolsAvailable: 290,
    recentActions: [
      'advance_feature FEAT-BWL',
      'search_features "delegation"',
      'git_quick_commit',
      'log_run "make test"',
    ],
  ),
  TunnelInfo(
    id: 'tun-002',
    machineName: 'Sarah-Studio',
    os: TunnelOS.macos,
    status: TunnelStatus.connected,
    latencyMs: 28,
    lastActive: DateTime.now().subtract(const Duration(minutes: 3)),
    connectedUser: 'Sarah Chen',
    ipAddress: '10.0.0.15',
    toolsAvailable: 145,
    recentActions: [
      'create_feature "AI Insight"',
      'set_current_feature FEAT-WVS',
      'ai_prompt "Review code"',
    ],
  ),
  TunnelInfo(
    id: 'tun-003',
    machineName: 'MARCUS-WIN11',
    os: TunnelOS.windows,
    status: TunnelStatus.degraded,
    latencyMs: 142,
    lastActive: DateTime.now().subtract(const Duration(minutes: 18)),
    connectedUser: 'Marcus Rivera',
    ipAddress: '172.16.0.8',
    toolsAvailable: 85,
    recentActions: ['db_query "SELECT count(*)"', 'list_features'],
  ),
  TunnelInfo(
    id: 'tun-004',
    machineName: 'aisha-dev-server',
    os: TunnelOS.linux,
    status: TunnelStatus.connected,
    latencyMs: 8,
    lastActive: DateTime.now().subtract(const Duration(minutes: 1)),
    connectedUser: 'Aisha Patel',
    ipAddress: '10.0.1.200',
    toolsAvailable: 290,
    recentActions: [
      'run_tests "libs/sdk-go"',
      'git_push',
      'log_run "make build"',
      'search_features "tunnel"',
      'advance_feature FEAT-IGV',
    ],
  ),
  TunnelInfo(
    id: 'tun-005',
    machineName: 'james-laptop',
    os: TunnelOS.linux,
    status: TunnelStatus.disconnected,
    latencyMs: 0,
    lastActive: DateTime.now().subtract(const Duration(hours: 6)),
    connectedUser: 'James Wilson',
    ipAddress: '192.168.1.55',
    toolsAvailable: 0,
    recentActions: ['submit_review FEAT-UJV approved'],
  ),
];

// ── Provider (StreamProvider to simulate auto-refresh) ──────────────────────

final _tunnelsStreamProvider = StreamProvider<List<TunnelInfo>>((ref) {
  return Stream.periodic(
    const Duration(seconds: 10),
    (_) => _mockTunnels,
  ).asBroadcastStream()..first; // Emit immediately on listen.
});

// ── Screen ──────────────────────────────────────────────────────────────────

/// Dashboard showing connected desktop tunnel clients with live status.
class TunnelsDashboard extends ConsumerWidget {
  const TunnelsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final tunnelsAsync = ref.watch(_tunnelsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).connectedTunnels,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ConnectButton(tokens: tokens),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).desktopClientsConnected,
            style: TextStyle(color: tokens.fgMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Summary row ───────────────────────────────────────────
          tunnelsAsync.when(
            data: (tunnels) => _buildContent(context, tokens, tunnels),
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: CircularProgressIndicator(color: tokens.accent),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                AppLocalizations.of(context).failedToLoadTunnels,
                style: TextStyle(color: tokens.fgMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrchestraColorTokens tokens,
    List<TunnelInfo> tunnels,
  ) {
    final connected = tunnels
        .where((t) => t.status == TunnelStatus.connected)
        .length;
    final degraded = tunnels
        .where((t) => t.status == TunnelStatus.degraded)
        .length;
    final disconnected = tunnels
        .where((t) => t.status == TunnelStatus.disconnected)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status summary ────────────────────────────────────────
        Row(
          children: [
            _StatusBadge(
              label: '$connected Connected',
              color: const Color(0xFF4CAF50),
              tokens: tokens,
            ),
            const SizedBox(width: 12),
            _StatusBadge(
              label: '$degraded Degraded',
              color: const Color(0xFFFF9800),
              tokens: tokens,
            ),
            const SizedBox(width: 12),
            _StatusBadge(
              label: '$disconnected Offline',
              color: const Color(0xFFF44336),
              tokens: tokens,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Tunnel grid ───────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.55,
              ),
              itemCount: tunnels.length,
              itemBuilder: (ctx, i) =>
                  _TunnelCard(tunnel: tunnels[i], tokens: tokens),
            );
          },
        ),
      ],
    );
  }
}

// ── Tunnel card ─────────────────────────────────────────────────────────────

class _TunnelCard extends StatelessWidget {
  const _TunnelCard({required this.tunnel, required this.tokens});

  final TunnelInfo tunnel;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      onTap: () => showTunnelDetailSheet(context: context, tunnel: tunnel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: OS icon + status dot ─────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tunnel.osIcon, color: tokens.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tunnel.machineName,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tunnel.osLabel,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Status dot.
              _PulsingDot(color: tunnel.statusColor),
            ],
          ),
          const Spacer(),

          // ── User ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: tokens.fgMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                tunnel.connectedUser,
                style: TextStyle(color: tokens.fgBright, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Info row: latency + last active ─────────────────────
          Row(
            children: [
              if (tunnel.status != TunnelStatus.disconnected) ...[
                Icon(Icons.speed_rounded, color: tokens.fgDim, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${tunnel.latencyMs}ms',
                  style: TextStyle(
                    color: tunnel.latencyMs > 100
                        ? const Color(0xFFFF9800)
                        : tokens.fgMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(Icons.access_time_rounded, color: tokens.fgDim, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tunnel.lastActiveRelative,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Status label ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tunnel.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tunnel.statusLabel,
              style: TextStyle(
                color: tunnel.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulsing status dot ──────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.tokens,
  });

  final String label;
  final Color color;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connect button ──────────────────────────────────────────────────────────

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.tokens});
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showConnectDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [tokens.accent, tokens.accentAlt]),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).connectNew,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.border),
        ),
        title: Text(
          AppLocalizations.of(context).connectDesktopClient,
          style: TextStyle(color: tokens.fgBright, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).installOrchestraDesktop,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'curl -fsSL https://orchestra.dev/install | sh',
                style: TextStyle(
                  color: tokens.accent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).runTunnelCommand,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'orchestra tunnel connect --token <your-token>',
                style: TextStyle(
                  color: tokens.accent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).clientAppearsAutomatically,
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(context).close,
              style: TextStyle(color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }
}
