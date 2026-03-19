import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Empty state widget that prompts mobile users to install the desktop app
/// when no data is available. On desktop/web, shows a simple empty message.
class MobileEmptyState extends StatelessWidget {
  const MobileEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: tokens.fgDim),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (isMobile) ...[
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.accent.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.desktop_mac_rounded,
                          size: 18, color: tokens.accent),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Install Orchestra Desktop to sync data',
                          style: TextStyle(
                            color: tokens.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse('https://orchestra-mcp.dev'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'orchestra-mcp.dev',
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: tokens.accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
