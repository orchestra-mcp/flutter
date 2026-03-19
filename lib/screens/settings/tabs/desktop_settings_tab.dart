import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Mock orchestrator connection state.
enum _OrchestratorStatus { connected, disconnected }

/// Desktop settings tab -- orchestrator status, terminal config, workspace manager.
class DesktopSettingsTab extends ConsumerStatefulWidget {
  const DesktopSettingsTab({super.key});

  @override
  ConsumerState<DesktopSettingsTab> createState() => _DesktopSettingsTabState();
}

class _DesktopSettingsTabState extends ConsumerState<DesktopSettingsTab> {
  // ── Orchestrator status (mock) ───────────────────────────────────────────
  _OrchestratorStatus _status = _OrchestratorStatus.connected;
  final String _orchestratorVersion = '1.0.4';
  final Duration _uptime = const Duration(hours: 3, minutes: 42);

  // ── Terminal config ──────────────────────────────────────────────────────
  String _selectedShell = '/bin/zsh';
  double _termFontSize = 13;
  String _termColorScheme = 'One Dark';

  static const _shells = ['/bin/zsh', '/bin/bash', '/bin/fish', '/bin/sh'];
  static const _colorSchemes = [
    'One Dark',
    'Solarized',
    'Monokai',
    'Dracula',
    'Nord',
    'Catppuccin',
  ];

  // ── Workspaces (mock) ────────────────────────────────────────────────────
  final List<_Workspace> _workspaces = [
    const _Workspace(
      id: 'WS-001',
      name: 'orchestra-agents',
      path: '/Users/user/Sites/orchestra-agents',
      isActive: true,
    ),
    const _Workspace(
      id: 'WS-002',
      name: 'my-app',
      path: '/Users/user/Projects/my-app',
      isActive: false,
    ),
  ];

  final _addWorkspaceNameCtrl = TextEditingController();
  final _addWorkspacePathCtrl = TextEditingController();

  @override
  void dispose() {
    _addWorkspaceNameCtrl.dispose();
    _addWorkspacePathCtrl.dispose();
    super.dispose();
  }

  void _switchWorkspace(int index) {
    setState(() {
      for (var i = 0; i < _workspaces.length; i++) {
        _workspaces[i] = _workspaces[i].copyWith(isActive: i == index);
      }
    });
  }

  void _addWorkspace() {
    final name = _addWorkspaceNameCtrl.text.trim();
    final path = _addWorkspacePathCtrl.text.trim();
    if (name.isEmpty || path.isEmpty) return;

    setState(() {
      _workspaces.add(
        _Workspace(
          id: 'WS-${_workspaces.length + 1}'.padLeft(3, '0'),
          name: name,
          path: path,
          isActive: false,
        ),
      );
      _addWorkspaceNameCtrl.clear();
      _addWorkspacePathCtrl.clear();
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Orchestrator Status ──────────────────────────────────────────
        _sectionHeader(tokens, 'Orchestrator Status'),
        const SizedBox(height: 12),
        _buildOrchestratorCard(tokens),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Terminal Configuration ──────────────────────────────────────
        _sectionHeader(tokens, 'Terminal Configuration'),
        const SizedBox(height: 12),
        _buildTerminalConfig(tokens),

        const SizedBox(height: 28),
        Divider(color: tokens.border.withValues(alpha: 0.4)),
        const SizedBox(height: 20),

        // ── Workspace Manager ───────────────────────────────────────────
        _sectionHeader(tokens, 'Workspace Manager'),
        const SizedBox(height: 12),
        _buildWorkspaceManager(tokens),
      ],
    );
  }

  // ── Orchestrator status card ────────────────────────────────────────────

  Widget _buildOrchestratorCard(OrchestraColorTokens tokens) {
    final isConnected = _status == _OrchestratorStatus.connected;
    final statusColor = isConnected
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    final statusLabel = isConnected ? 'Connected' : 'Disconnected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          // Status indicator row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _status = isConnected
                        ? _OrchestratorStatus.disconnected
                        : _OrchestratorStatus.connected;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: tokens.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: Text(
                  isConnected ? 'Disconnect' : 'Reconnect',
                  style: TextStyle(fontSize: 12, color: tokens.fgMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(tokens, 'Version', 'v$_orchestratorVersion'),
          const SizedBox(height: 8),
          _infoRow(
            tokens,
            'Uptime',
            '${_uptime.inHours}h ${_uptime.inMinutes.remainder(60)}m',
          ),
          const SizedBox(height: 8),
          _infoRow(tokens, 'Transport', 'In-process (stdio)'),
        ],
      ),
    );
  }

  Widget _infoRow(OrchestraColorTokens tokens, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: tokens.fgDim)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tokens.fgMuted,
          ),
        ),
      ],
    );
  }

  // ── Terminal config ─────────────────────────────────────────────────────

  Widget _buildTerminalConfig(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default shell
        _fieldLabel(tokens, 'Default Shell'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          tokens: tokens,
          value: _selectedShell,
          items: _shells,
          labelBuilder: (s) => s,
          onChanged: (v) {
            if (v != null) setState(() => _selectedShell = v);
          },
        ),

        const SizedBox(height: 16),

        // Font size
        _fieldLabel(tokens, 'Font Size'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _termFontSize,
                min: 10,
                max: 24,
                divisions: 14,
                activeColor: tokens.accent,
                inactiveColor: tokens.border,
                onChanged: (v) => setState(() => _termFontSize = v),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.bgAlt,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.border),
              ),
              child: Text(
                '${_termFontSize.round()}px',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.fgBright,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Color scheme
        _fieldLabel(tokens, 'Color Scheme'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          tokens: tokens,
          value: _termColorScheme,
          items: _colorSchemes,
          labelBuilder: (s) => s,
          onChanged: (v) {
            if (v != null) setState(() => _termColorScheme = v);
          },
        ),
      ],
    );
  }

  // ── Workspace manager ───────────────────────────────────────────────────

  Widget _buildWorkspaceManager(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _workspaces.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _WorkspaceRow(
            workspace: _workspaces[i],
            tokens: tokens,
            onSwitch: () => _switchWorkspace(i),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddWorkspaceDialog(tokens),
            icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
            label: Text(
              'Add Workspace',
              style: TextStyle(color: tokens.accent, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: tokens.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddWorkspaceDialog(OrchestraColorTokens tokens) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text(
          'Add Workspace',
          style: TextStyle(color: tokens.fgBright, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(tokens, _addWorkspaceNameCtrl, 'Workspace name'),
            const SizedBox(height: 10),
            _dialogField(tokens, _addWorkspacePathCtrl, 'Folder path'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: TextStyle(color: tokens.fgMuted),
            ),
          ),
          TextButton(
            onPressed: _addWorkspace,
            child: Text(
              AppLocalizations.of(context).add,
              style: TextStyle(color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );

  Widget _fieldLabel(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.fgDim,
      letterSpacing: 0.4,
    ),
  );

  Widget _buildDropdown<T>({
    required OrchestraColorTokens tokens,
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: tokens.bgAlt,
          style: TextStyle(fontSize: 14, color: tokens.fgBright),
          icon: Icon(
            Icons.expand_more_rounded,
            color: tokens.fgMuted,
            size: 20,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dialogField(
    OrchestraColorTokens tokens,
    TextEditingController ctrl,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: tokens.fgBright, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: tokens.fgDim),
        filled: true,
        fillColor: tokens.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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

// ── Workspace model ─────────────────────────────────────────────────────────

class _Workspace {
  const _Workspace({
    required this.id,
    required this.name,
    required this.path,
    required this.isActive,
  });

  final String id;
  final String name;
  final String path;
  final bool isActive;

  _Workspace copyWith({
    String? id,
    String? name,
    String? path,
    bool? isActive,
  }) {
    return _Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ── Workspace row widget ────────────────────────────────────────────────────

class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspace,
    required this.tokens,
    required this.onSwitch,
  });

  final _Workspace workspace;
  final OrchestraColorTokens tokens;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: workspace.isActive ? tokens.accent : tokens.border,
          width: workspace.isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_rounded,
              size: 16,
              color: workspace.isActive ? tokens.accent : tokens.fgMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workspace.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.fgBright,
                  ),
                ),
                Text(
                  workspace.path,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (workspace.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.accent,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onSwitch,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: tokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Switch',
                style: TextStyle(fontSize: 11, color: tokens.fgMuted),
              ),
            ),
        ],
      ),
    );
  }
}
