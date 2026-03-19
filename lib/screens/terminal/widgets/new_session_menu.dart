import 'package:flutter/material.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Popup menu that offers three session-creation options:
/// Terminal, SSH, and Claude.
class NewSessionMenu extends StatelessWidget {
  const NewSessionMenu({
    super.key,
    required this.onTerminal,
    required this.onSsh,
    required this.onClaude,
  });

  final VoidCallback onTerminal;
  final VoidCallback onSsh;
  final VoidCallback onClaude;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return PopupMenuButton<_SessionKind>(
      onSelected: (kind) {
        switch (kind) {
          case _SessionKind.terminal:
            onTerminal();
          case _SessionKind.ssh:
            onSsh();
          case _SessionKind.claude:
            onClaude();
        }
      },
      icon: Icon(Icons.add, color: tokens.fgBright),
      tooltip: AppLocalizations.of(context).newSessionTooltip,
      color: tokens.bgAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: tokens.borderFaint),
      ),
      offset: const Offset(0, 40),
      itemBuilder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return [
          if (isDesktop)
            _buildItem(
              tokens: tokens,
              value: _SessionKind.terminal,
              icon: Icons.terminal_rounded,
              label: l10n.newSessionTerminal,
            ),
          _buildItem(
            tokens: tokens,
            value: _SessionKind.ssh,
            icon: Icons.public_rounded,
            label: l10n.newSessionSsh,
          ),
          _buildItem(
            tokens: tokens,
            value: _SessionKind.claude,
            icon: Icons.smart_toy_rounded,
            label: l10n.newSessionClaude,
          ),
        ];
      },
    );
  }

  PopupMenuEntry<_SessionKind> _buildItem({
    required OrchestraColorTokens tokens,
    required _SessionKind value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<_SessionKind>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.fgMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SessionKind { terminal, ssh, claude }
