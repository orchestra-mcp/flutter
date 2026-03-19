import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/web/tunnels/tunnels_dashboard.dart';
import 'package:orchestra/widgets/glass_card.dart';

/// Shows a bottom sheet with detailed tunnel info.
Future<void> showTunnelDetailSheet({
  required BuildContext context,
  required TunnelInfo tunnel,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) => _TunnelDetailContent(tunnel: tunnel),
  );
}

class _TunnelDetailContent extends StatelessWidget {
  const _TunnelDetailContent({required this.tunnel});

  final TunnelInfo tunnel;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.fgDim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 20 + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tunnel.osIcon,
                          color: tokens.accent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tunnel.machineName,
                              style: TextStyle(
                                color: tokens.fgBright,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: tunnel.statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tunnel.statusLabel,
                                  style: TextStyle(
                                    color: tunnel.statusColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Machine info ────────────────────────────────
                  Text(
                    AppLocalizations.of(context).machineInformation,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: AppLocalizations.of(context).operatingSystem,
                          value: tunnel.osLabel,
                          icon: tunnel.osIcon,
                          tokens: tokens,
                        ),
                        _divider(tokens),
                        _InfoRow(
                          label: AppLocalizations.of(context).ipAddress,
                          value: tunnel.ipAddress,
                          icon: Icons.language_rounded,
                          tokens: tokens,
                        ),
                        _divider(tokens),
                        _InfoRow(
                          label: AppLocalizations.of(
                            context,
                          ).connectedUserLabel,
                          value: tunnel.connectedUser,
                          icon: Icons.person_outline_rounded,
                          tokens: tokens,
                        ),
                        _divider(tokens),
                        _InfoRow(
                          label: AppLocalizations.of(context).latencyLabel,
                          value: tunnel.status == TunnelStatus.disconnected
                              ? '--'
                              : '${tunnel.latencyMs}ms',
                          icon: Icons.speed_rounded,
                          tokens: tokens,
                          valueColor: tunnel.latencyMs > 100
                              ? const Color(0xFFFF9800)
                              : null,
                        ),
                        _divider(tokens),
                        _InfoRow(
                          label: AppLocalizations.of(
                            context,
                          ).toolsAvailableLabel,
                          value: '${tunnel.toolsAvailable}',
                          icon: Icons.build_outlined,
                          tokens: tokens,
                        ),
                        _divider(tokens),
                        _InfoRow(
                          label: AppLocalizations.of(context).lastActiveLabel,
                          value: tunnel.lastActiveRelative,
                          icon: Icons.access_time_rounded,
                          tokens: tokens,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent actions ──────────────────────────────
                  Text(
                    AppLocalizations.of(context).recentActionsLabel,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tunnel.recentActions.isEmpty)
                    Text(
                      AppLocalizations.of(context).noRecentActions,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          for (
                            int i = 0;
                            i < tunnel.recentActions.length;
                            i++
                          ) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: tokens.border.withValues(alpha: 0.3),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.terminal_rounded,
                                    color: tokens.fgDim,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      tunnel.recentActions[i],
                                      style: TextStyle(
                                        color: tokens.fgBright,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Disconnect button ───────────────────────────
                  if (tunnel.status != TunnelStatus.disconnected)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Disconnected ${tunnel.machineName}',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_off_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).disconnect),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF44336),
                          side: const BorderSide(
                            color: Color(0xFFF44336),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(OrchestraColorTokens tokens) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Divider(height: 1, color: tokens.border.withValues(alpha: 0.3)),
  );
}

// ── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.tokens,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final OrchestraColorTokens tokens;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: tokens.fgDim, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
