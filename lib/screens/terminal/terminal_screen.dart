import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/dio_provider.dart';
import 'package:orchestra/core/auth/token_storage.dart';
import 'package:orchestra/core/config/env.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/terminal/terminal_session_model.dart';
import 'package:orchestra/features/terminal/terminal_sessions_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/screens/terminal/widgets/terminal_content.dart';
import 'package:orchestra/screens/terminal/widgets/terminal_toolbar.dart';
import 'package:orchestra/widgets/entity_context_actions.dart';
import 'package:orchestra/widgets/entity_search_bar.dart';
import 'package:orchestra/widgets/glass_list_tile.dart';

/// Main terminal screen with two modes:
///   1. Sessions list (default on mobile) — cards for each terminal session.
///   2. Terminal view — active terminal content when a session is tapped.
///
/// On desktop the sidebar handles session selection so the screen shows the
/// terminal view directly. On mobile the sessions list is shown first.
class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _showingTerminal = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final sessions = ref.watch(terminalSessionsProvider);
    final activeId = ref.watch(activeTerminalIdProvider);

    // On desktop, always show terminal view (sidebar handles list).
    // On mobile, show list first, switch to terminal view when session selected.
    if (isDesktop || _showingTerminal) {
      final activeSession = sessions.isEmpty
          ? null
          : sessions.where((s) => s.id == activeId).firstOrNull ??
              sessions.first;

      if (activeSession != null) {
        // Ensure activeId matches the displayed session.
        if (activeSession.id != activeId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeTerminalIdProvider.notifier).set(activeSession.id);
          });
        }
        return _buildTerminalView(context, tokens, sessions, activeSession);
      }
    }

    return _buildSessionsList(context, tokens, sessions);
  }

  // ── Sessions list mode ──────────────────────────────────────────────────────

  Widget _buildSessionsList(
    BuildContext context,
    OrchestraColorTokens tokens,
    List<TerminalSessionModel> sessions,
  ) {
    final l10n = AppLocalizations.of(context);
    final q = _search.toLowerCase();
    final filtered = q.isEmpty
        ? sessions
        : sessions.where((s) => s.label.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: Search + Add ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: EntitySearchBar(
                      hintText: l10n.searchTerminalHint,
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      tokens: tokens,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_rounded,
                        color: tokens.accent, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: tokens.accent.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showCreateSheet(context, tokens),
                  ),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: sessions.isEmpty
                  ? _buildEmptyState(context, tokens)
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            l10n.terminalNoMatchingSessions,
                            style: TextStyle(color: tokens.fgMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _buildSessionTile(context, tokens, filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single session tile ─────────────────────────────────────────────────────

  Widget _buildSessionTile(
    BuildContext context,
    OrchestraColorTokens tokens,
    TerminalSessionModel session,
  ) {
    final l10n = AppLocalizations.of(context);
    final cust = ref.watch(entityCustomizationProvider)[session.id];

    final statusColor = switch (session.status) {
      TerminalSessionStatus.connected => Colors.green,
      TerminalSessionStatus.connecting => Colors.orange,
      TerminalSessionStatus.disconnected => tokens.fgDim,
      TerminalSessionStatus.error => Colors.red,
    };
    final typeLabel = switch (session.type) {
      TerminalSessionType.terminal => l10n.terminalTypeLocal,
      TerminalSessionType.ssh => l10n.terminalTypeSsh,
      TerminalSessionType.claude => l10n.terminalTypeClaude,
      TerminalSessionType.remote => l10n.terminalTypeRemote,
    };
    final typeIcon = switch (session.type) {
      TerminalSessionType.terminal => Icons.terminal_rounded,
      TerminalSessionType.ssh => Icons.public_rounded,
      TerminalSessionType.claude => Icons.smart_toy_rounded,
      TerminalSessionType.remote => Icons.cloud_rounded,
    };

    return GlassListTile(
      leadingIcon: cust?.icon ?? typeIcon,
      leadingColor: cust?.color ?? statusColor,
      label: session.label,
      description: '$typeLabel \u00b7 ${session.status.name}',
      trailing: _StatusDot(color: statusColor),
      onTap: () {
        ref.read(activeTerminalIdProvider.notifier).set(session.id);
        setState(() => _showingTerminal = true);
      },
      onDelete: () =>
          ref.read(terminalSessionsProvider.notifier).removeSession(session.id),
      contextMenuActions: buildEntityContextActions(
        l10n: l10n,
        onRename: () async {
          final name = await showRenameDialog(
            context,
            currentName: session.label,
          );
          if (name != null) {
            ref
                .read(terminalSessionsProvider.notifier)
                .renameSession(session.id, name);
          }
        },
        onChangeIcon: () => pickAndSaveIcon(
          context,
          ref,
          session.id,
          currentCodePoint: cust?.iconCodePoint,
        ),
        onChangeColor: () => pickAndSaveColor(
          context,
          ref,
          session.id,
          currentColor: cust?.color,
        ),
        onDelete: () => ref
            .read(terminalSessionsProvider.notifier)
            .removeSession(session.id),
      ),
    );
  }

  // ── Terminal view mode ──────────────────────────────────────────────────────

  Widget _buildTerminalView(
    BuildContext context,
    OrchestraColorTokens tokens,
    List<TerminalSessionModel> sessions,
    TerminalSessionModel activeSession,
  ) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bgAlt,
        surfaceTintColor: Colors.transparent,
        leading: isDesktop
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: tokens.fgBright),
                onPressed: () => setState(() => _showingTerminal = false),
              ),
        title: Text(
          activeSession.label,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
        actions: [
          // New session shortcut.
          IconButton(
            icon: Icon(Icons.add_rounded, color: tokens.fgMuted, size: 22),
            tooltip: l10n.createSession,
            onPressed: () => _showCreateSheet(context, tokens),
          ),
          // Close active session.
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.fgMuted, size: 20),
            tooltip: l10n.endSession,
            onPressed: () {
              ref
                  .read(terminalSessionsProvider.notifier)
                  .removeSession(activeSession.id);
              // Return to list if no sessions remain.
              final remaining = ref.read(terminalSessionsProvider);
              if (remaining.isEmpty) {
                setState(() => _showingTerminal = false);
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: tokens.border),
        ),
      ),
      body: Column(
        children: [
          if (isDesktop) TerminalToolbar(sessionId: activeSession.id),
          Expanded(
            child: TerminalContent(
              key: ValueKey(activeSession.id),
              sessionId: activeSession.id,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_rounded, size: 48, color: tokens.fgDim),
            const SizedBox(height: 16),
            Text(
              l10n.noTerminalSessions,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.terminalCreateToStart,
              style: TextStyle(color: tokens.fgMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateSheet(context, tokens),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.newSession),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.isLight ? Colors.white : tokens.bg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create session bottom sheet ─────────────────────────────────────────────

  void _showCreateSheet(BuildContext context, OrchestraColorTokens tokens) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Material(
              color: tokens.bgAlt,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: tokens.fgDim.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        l10n.newSession,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Local Terminal (desktop only)
                    if (isDesktop)
                      ListTile(
                        leading:
                            Icon(Icons.terminal_rounded, color: tokens.accent),
                        title: Text(l10n.terminalLocalTitle,
                            style: TextStyle(color: tokens.fgBright)),
                        subtitle: Text(l10n.terminalLocalSubtitle,
                            style: TextStyle(color: tokens.fgMuted)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final s = await ref
                              .read(terminalSessionsProvider.notifier)
                              .createTerminalSession();
                          ref
                              .read(activeTerminalIdProvider.notifier)
                              .set(s.id);
                          setState(() => _showingTerminal = true);
                        },
                      ),

                    // SSH
                    ListTile(
                      leading:
                          Icon(Icons.public_rounded, color: tokens.accent),
                      title: Text(l10n.terminalTypeSsh,
                          style: TextStyle(color: tokens.fgBright)),
                      subtitle: Text(l10n.terminalSshSubtitle,
                          style: TextStyle(color: tokens.fgMuted)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showSshDialog(context, tokens);
                      },
                    ),

                    // Claude Code (desktop only)
                    if (isDesktop)
                      ListTile(
                        leading: Icon(Icons.smart_toy_rounded,
                            color: tokens.accent),
                        title: Text(l10n.terminalClaudeTitle,
                            style: TextStyle(color: tokens.fgBright)),
                        subtitle: Text(l10n.terminalClaudeSubtitle,
                            style: TextStyle(color: tokens.fgMuted)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final s = await ref
                              .read(terminalSessionsProvider.notifier)
                              .createClaudeSession();
                          ref
                              .read(activeTerminalIdProvider.notifier)
                              .set(s.id);
                          setState(() => _showingTerminal = true);
                        },
                      ),

                    // Remote Terminal
                    ListTile(
                      leading:
                          Icon(Icons.cloud_rounded, color: tokens.accent),
                      title: Text(l10n.terminalRemoteTitle,
                          style: TextStyle(color: tokens.fgBright)),
                      subtitle: Text(l10n.terminalRemoteSubtitle,
                          style: TextStyle(color: tokens.fgMuted)),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _connectRemoteTerminal(context, tokens);
                      },
                    ),

                    // Extra padding so items aren't hidden behind nav bar.
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Remote terminal: local WiFi first, cloud tunnel fallback ────────────────

  Future<void> _connectRemoteTerminal(
      BuildContext context, OrchestraColorTokens tokens) async {
    // Step 1: Try direct local WiFi connection.
    final localUrl = 'ws://${Env.mcpHost}:9201/ws';
    if (await _canReachLocal(Env.mcpHost, 9201)) {
      debugPrint('[Terminal] Connecting via local WiFi: $localUrl');
      await _createRemote(localUrl);
      return;
    }

    // Step 2: Local unreachable — fall back to cloud tunnel.
    debugPrint('[Terminal] Local unreachable, trying cloud tunnel...');
    if (!mounted) return;

    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get<List<dynamic>>(
        '/api/tunnels',
        queryParameters: {'status': 'online'},
      );
      final tunnels = (resp.data ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (tunnels.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(l10n.terminalNoMachinesOnline)),
          );
        }
        return;
      }

      final tunnel = tunnels.first;
      final tunnelId = tunnel['id'] as String;
      final authToken = await const TokenStorage().getAccessToken() ?? '';
      final wsScheme =
          Env.apiBaseUrl.startsWith('https') ? 'wss' : 'ws';
      final httpBase =
          Env.apiBaseUrl.replaceFirst(RegExp(r'^https?'), wsScheme);
      final tunnelUrl = '$httpBase/api/tunnels/$tunnelId/ws?token=$authToken';

      debugPrint('[Terminal] Connecting via cloud tunnel: $tunnelId');
      await _createRemote(tunnelUrl);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.terminalConnectionFailed(e.toString()))),
        );
      }
    }
  }

  /// Quick TCP connect check to see if the desktop web-gate is reachable.
  Future<bool> _canReachLocal(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createRemote(String wsUrl) async {
    final s = await ref
        .read(terminalSessionsProvider.notifier)
        .createRemoteSession(
          tunnelId: 'auto',
          baseUrl: wsUrl,
          authToken: '',
        );
    ref.read(activeTerminalIdProvider.notifier).set(s.id);
    setState(() => _showingTerminal = true);
  }

  // ── SSH connection dialog ───────────────────────────────────────────────────

  void _showSshDialog(BuildContext context, OrchestraColorTokens tokens) {
    final hostCtrl = TextEditingController();
    final userCtrl = TextEditingController(text: 'root');
    final portCtrl = TextEditingController(text: '22');
    final passCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context);

        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text(l10n.sshConnection,
              style: TextStyle(color: tokens.fgBright)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SshField(
                  controller: hostCtrl,
                  label: l10n.host,
                  hint: 'e.g. 192.168.1.10',
                  tokens: tokens,
                ),
                const SizedBox(height: 12),
                _SshField(
                  controller: userCtrl,
                  label: l10n.user,
                  hint: 'root',
                  tokens: tokens,
                ),
                const SizedBox(height: 12),
                _SshField(
                  controller: portCtrl,
                  label: l10n.port,
                  hint: '22',
                  tokens: tokens,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _SshField(
                  controller: passCtrl,
                  label: l10n.password,
                  hint: l10n.optional,
                  tokens: tokens,
                  obscure: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: TextStyle(color: tokens.fgMuted)),
            ),
            TextButton(
              onPressed: () async {
                final host = hostCtrl.text.trim();
                final user = userCtrl.text.trim();
                final port =
                    int.tryParse(portCtrl.text.trim()) ?? 22;
                final pass = passCtrl.text.isNotEmpty
                    ? passCtrl.text
                    : null;

                if (host.isEmpty || user.isEmpty) return;

                Navigator.pop(ctx);

                final s = await ref
                    .read(terminalSessionsProvider.notifier)
                    .createSshSession(
                      host: host,
                      user: user,
                      port: port,
                      password: pass,
                    );
                ref.read(activeTerminalIdProvider.notifier).set(s.id);
                setState(() => _showingTerminal = true);
              },
              child: Text(l10n.connect,
                  style: TextStyle(color: tokens.accent)),
            ),
          ],
        );
      },
    ).then((_) {
      hostCtrl.dispose();
      userCtrl.dispose();
      portCtrl.dispose();
      passCtrl.dispose();
    });
  }
}

// ── Status dot widget ─────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ── SSH form field ────────────────────────────────────────────────────────────

class _SshField extends StatelessWidget {
  const _SshField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.tokens,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final OrchestraColorTokens tokens;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: tokens.fgBright),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: tokens.fgDim),
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.borderFaint),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
