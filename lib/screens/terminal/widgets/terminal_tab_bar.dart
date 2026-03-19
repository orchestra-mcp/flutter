import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Horizontal scrollable tab bar for terminal sessions.
///
/// Each tab shows a type icon, the session label, a connection status
/// indicator dot, and a close button. An add (+) button at the end opens
/// the [onNewSession] callback.
class TerminalTabBar extends ConsumerWidget {
  const TerminalTabBar({super.key, required this.onNewSession});

  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final sessions = ref.watch(terminalSessionsProvider);
    final activeId = ref.watch(activeTerminalIdProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(bottom: BorderSide(color: tokens.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  for (final session in sessions)
                    _SessionTab(
                      session: session,
                      isActive: session.id == activeId,
                      tokens: tokens,
                      onTap: () {
                        ref
                            .read(activeTerminalIdProvider.notifier)
                            .set(session.id);
                      },
                      onClose: () {
                        ref
                            .read(terminalSessionsProvider.notifier)
                            .removeSession(session.id);
                      },
                    ),
                ],
              ),
            ),
          ),
          _AddButton(tokens: tokens, onTap: onNewSession),
        ],
      ),
    );
  }
}

// ── Individual session tab ───────────────────────────────────────────────────

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.session,
    required this.isActive,
    required this.tokens,
    required this.onTap,
    required this.onClose,
  });

  final TerminalSessionModel session;
  final bool isActive;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onClose;

  IconData get _typeIcon {
    switch (session.type) {
      case TerminalSessionType.terminal:
        return Icons.terminal_rounded;
      case TerminalSessionType.ssh:
        return Icons.public_rounded;
      case TerminalSessionType.claude:
        return Icons.smart_toy_rounded;
      case TerminalSessionType.remote:
        return Icons.cloud_rounded;
    }
  }

  Color get _statusColor {
    switch (session.status) {
      case TerminalSessionStatus.connected:
        return const Color(0xFF4ADE80); // green
      case TerminalSessionStatus.connecting:
        return const Color(0xFFFACC15); // yellow
      case TerminalSessionStatus.error:
        return const Color(0xFFEF4444); // red
      case TerminalSessionStatus.disconnected:
        return const Color(0xFF9CA3AF); // grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.only(left: 8, right: 2),
        decoration: BoxDecoration(
          color: isActive
              ? tokens.accent.withValues(alpha: 0.15)
              : tokens.bgAlt,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(
                  color: tokens.accent.withValues(alpha: 0.4),
                  width: 0.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),

            // Type icon
            Icon(
              _typeIcon,
              size: 14,
              color: isActive ? tokens.accent : tokens.fgMuted,
            ),
            const SizedBox(width: 6),

            // Label
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                session.label,
                style: TextStyle(
                  color: isActive ? tokens.fgBright : tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),

            // Close button
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, size: 12, color: tokens.fgDim),
                padding: EdgeInsets.zero,
                splashRadius: 12,
                tooltip: AppLocalizations.of(context).terminalTabCloseSession,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.tokens, required this.onTap});

  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(Icons.add_rounded, size: 16, color: tokens.fgMuted),
          padding: EdgeInsets.zero,
          splashRadius: 14,
          tooltip: AppLocalizations.of(context).terminalTabNewSession,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}
