import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/devtools/providers/devtools_selection_provider.dart';
import 'package:orchestra/features/devtools/providers/log_runner_provider.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Status helpers ──────────────────────────────────────────────────────────

Color _statusColor(String status) {
  return switch (status) {
    'running' => const Color(0xFF22C55E),
    'finished' => const Color(0xFF6B7280),
    'failed' => const Color(0xFFEF4444),
    _ => const Color(0xFF6B7280),
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'running' => Icons.play_circle_filled_rounded,
    'finished' => Icons.check_circle_rounded,
    'failed' => Icons.error_rounded,
    _ => Icons.help_outline_rounded,
  };
}

// ── Main screen ─────────────────────────────────────────────────────────────

/// Log Runner screen — list-first master/detail on desktop and mobile.
///
/// Desktop: Full-width process list → click → output viewer detail.
/// Mobile: Same list → detail navigation.
class LogRunnerScreen extends ConsumerStatefulWidget {
  const LogRunnerScreen({super.key});

  @override
  ConsumerState<LogRunnerScreen> createState() => _LogRunnerScreenState();
}

class _LogRunnerScreenState extends ConsumerState<LogRunnerScreen> {
  String? _selectedProcessId;
  List<String> _outputLines = [];
  bool _autoScroll = true;
  bool _isLoadingOutput = false;
  Timer? _pollTimer;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchPattern = '';

  // List-level search
  String _listSearch = '';
  final _listSearchController = TextEditingController();

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _listSearchController.dispose();
    super.dispose();
  }

  // ── Process selection ───────────────────────────────────────────────

  void _selectProcess(String processId) {
    setState(() {
      _selectedProcessId = processId;
      _outputLines = [];
      _searchPattern = '';
      _searchController.clear();
    });
    _fetchOutput(processId);
    _startPolling(processId);
  }

  void _goBack() {
    _pollTimer?.cancel();
    setState(() {
      _selectedProcessId = null;
      _outputLines = [];
      _searchPattern = '';
      _searchController.clear();
    });
  }

  // ── Output fetching ─────────────────────────────────────────────────

  Future<void> _fetchOutput(String processId) async {
    if (!mounted) return;
    setState(() => _isLoadingOutput = true);

    try {
      final notifier = ref.read(logRunnerProvider.notifier);
      final lines = await notifier.getOutput(processId);
      if (mounted && _selectedProcessId == processId) {
        setState(() {
          _outputLines = lines;
          _isLoadingOutput = false;
        });
        if (_autoScroll) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOutput = false);
      }
    }
  }

  void _startPolling(String processId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _selectedProcessId != processId) {
        _pollTimer?.cancel();
        return;
      }
      final List<LogProcess> processes =
          ref.read(logRunnerProvider).value ?? [];
      final LogProcess? process =
          processes.where((LogProcess p) => p.id == processId).firstOrNull;
      if (process == null || !process.isRunning) {
        unawaited(_fetchOutput(processId));
        _pollTimer?.cancel();
        return;
      }
      unawaited(_fetchOutput(processId));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _killProcess(String processId) async {
    final tokens = ThemeTokens.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgAlt,
        title: Text('Kill Process', style: TextStyle(color: tokens.fgBright)),
        content: Text(
          'Are you sure you want to kill this process?',
          style: TextStyle(color: tokens.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kill', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(logRunnerProvider.notifier).kill(processId);
    }
  }

  Future<void> _restartProcess(String processId) async {
    await ref.read(logRunnerProvider.notifier).restart(processId);
    unawaited(_fetchOutput(processId));
    _startPolling(processId);
  }

  void _showRunDialog() {
    final commandCtrl = TextEditingController();
    final wdCtrl = TextEditingController();
    final tokens = ThemeTokens.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tokens.bgAlt,
          title: Text('Run Command', style: TextStyle(color: tokens.fgBright)),
          content: SizedBox(
            width: isDesktop ? 420 : double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commandCtrl,
                  autofocus: true,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontFamily: 'JetBrains Mono',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Command',
                    labelStyle: TextStyle(color: tokens.fgDim),
                    hintText: 'npm run dev',
                    hintStyle:
                        TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.borderFaint),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                  onSubmitted: (_) {
                    final cmd = commandCtrl.text.trim();
                    if (cmd.isEmpty) return;
                    Navigator.pop(ctx);
                    _runCommand(cmd, wdCtrl.text.trim());
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wdCtrl,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontFamily: 'JetBrains Mono',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Working Directory (optional)',
                    labelStyle: TextStyle(color: tokens.fgDim),
                    hintText: '/path/to/project',
                    hintStyle:
                        TextStyle(color: tokens.fgDim.withValues(alpha: 0.5)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.borderFaint),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: tokens.fgMuted)),
            ),
            TextButton(
              onPressed: () {
                final cmd = commandCtrl.text.trim();
                if (cmd.isEmpty) return;
                Navigator.pop(ctx);
                _runCommand(cmd, wdCtrl.text.trim());
              },
              child: Text('Run', style: TextStyle(color: tokens.accent)),
            ),
          ],
        );
      },
    ).then((_) {
      commandCtrl.dispose();
      wdCtrl.dispose();
    });
  }

  Future<void> _runCommand(String command, String workingDirectory) async {
    final process = await ref.read(logRunnerProvider.notifier).run(
          command,
          workingDirectory: workingDirectory.isEmpty ? null : workingDirectory,
        );
    _selectProcess(process.id);
  }

  // ── Filtered output lines ───────────────────────────────────────────

  List<_IndexedLine> get _filteredLines {
    if (_searchPattern.isEmpty) {
      return _outputLines
          .asMap()
          .entries
          .map((e) => _IndexedLine(e.key + 1, e.value))
          .toList();
    }
    try {
      final regex = RegExp(_searchPattern, caseSensitive: false);
      return _outputLines
          .asMap()
          .entries
          .where((e) => regex.hasMatch(e.value))
          .map((e) => _IndexedLine(e.key + 1, e.value))
          .toList();
    } catch (_) {
      final lower = _searchPattern.toLowerCase();
      return _outputLines
          .asMap()
          .entries
          .where((e) => e.value.toLowerCase().contains(lower))
          .map((e) => _IndexedLine(e.key + 1, e.value))
          .toList();
    }
  }

  LogProcess? get _selectedProcess {
    if (_selectedProcessId == null) return null;
    final processes = ref.read(logRunnerProvider).value ?? [];
    return processes
        .where((LogProcess p) => p.id == _selectedProcessId)
        .firstOrNull;
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    // On desktop the global sidebar drives selection — sync from shared provider.
    if (isDesktop) {
      final providerId = ref.watch(selectedProcessIdProvider);
      if (providerId != null && providerId != _selectedProcessId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectProcess(providerId);
        });
      }
      // Always show detail on desktop (sidebar is the list).
      if (_selectedProcessId != null) return _buildOutputDetail(tokens);
      return _buildDesktopEmpty(tokens);
    }

    if (_selectedProcessId == null) {
      return _buildProcessList(tokens);
    }
    return _buildOutputDetail(tokens);
  }

  Widget _buildDesktopEmpty(OrchestraColorTokens tokens) {
    return Scaffold(
      backgroundColor: tokens.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_rounded,
                size: 48, color: tokens.fgDim.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Select a process',
                style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Choose a process from the sidebar, or tap + to run a command.',
                style: TextStyle(color: tokens.fgDim, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Process list (full-width) ──────────────────────────────────────

  Widget _buildProcessList(OrchestraColorTokens tokens) {
    final asyncProcesses = ref.watch(logRunnerProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, color: tokens.accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Log Runner',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                // Search bar
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _listSearchController,
                      style: TextStyle(color: tokens.fgBright, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search processes...',
                        hintStyle: TextStyle(
                          color: tokens.fgDim.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: tokens.fgDim,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        filled: true,
                        fillColor: tokens.bgAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _listSearch = v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Run button
                FilledButton.icon(
                  onPressed: _showRunDialog,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Run', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor:
                        tokens.isLight ? Colors.white : tokens.bg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Process tiles
          Expanded(
            child: asyncProcesses.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: tokens.accent),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load processes:\n$e',
                    style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (processes) {
                final filtered = _listSearch.isEmpty
                    ? processes
                    : processes
                        .where(
                          (p) => p.command
                              .toLowerCase()
                              .contains(_listSearch.toLowerCase()),
                        )
                        .toList();

                if (processes.isEmpty) {
                  return _buildEmptyProcesses(tokens);
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No processes match "$_listSearch"',
                      style: TextStyle(color: tokens.fgDim, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildProcessTile(tokens, filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProcesses(OrchestraColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal_rounded,
              size: 40,
              color: tokens.fgDim.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No processes',
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Run a command to start a background process.',
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showRunDialog,
              icon: Icon(Icons.play_arrow_rounded, size: 16, color: tokens.accent),
              label: Text(
                'Run a command',
                style: TextStyle(color: tokens.accent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessTile(OrchestraColorTokens tokens, LogProcess process) {
    final statusColor = _statusColor(process.status);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.zero,
      borderRadius: 12,
      onTap: () => _selectProcess(process.id),
      child: Row(
        children: [
          // Status indicator
          if (process.isRunning)
            _PulsingDot(color: statusColor)
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 12),

          // Command + metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  process.command,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'JetBrains Mono',
                    fontFamilyFallback: const ['monospace'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        process.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (process.pid != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'PID ${process.pid}',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                    if (process.uptime != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        process.uptime!,
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action buttons
          if (process.isRunning)
            _SmallIconButton(
              icon: Icons.stop_rounded,
              color: const Color(0xFFEF4444),
              tooltip: 'Kill',
              onTap: () => _killProcess(process.id),
            ),
          _SmallIconButton(
            icon: Icons.refresh_rounded,
            color: tokens.fgMuted,
            tooltip: 'Restart',
            onTap: () => _restartProcess(process.id),
          ),
          const SizedBox(width: 4),

          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: tokens.fgDim.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // ── Output detail view ────────────────────────────────────────────

  Widget _buildOutputDetail(OrchestraColorTokens tokens) {
    final process = _selectedProcess;
    final filtered = _filteredLines;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          // Back bar / top bar
          Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              border: Border(
                bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: tokens.fgBright,
                    size: 20,
                  ),
                  onPressed: _goBack,
                  tooltip: 'Back to processes',
                ),

                // Status icon
                Icon(
                  _statusIcon(process?.status ?? 'unknown'),
                  color: _statusColor(process?.status ?? 'unknown'),
                  size: 16,
                ),
                const SizedBox(width: 8),

                // Command
                Expanded(
                  child: Text(
                    process?.command ?? '',
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                      fontFamilyFallback: const ['monospace'],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // PID
                if (process?.pid != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'PID ${process!.pid}',
                      style: TextStyle(color: tokens.fgDim, fontSize: 11),
                    ),
                  ),

                // Refresh
                _SmallIconButton(
                  icon: Icons.refresh_rounded,
                  color: tokens.fgMuted,
                  tooltip: 'Refresh output',
                  onTap: () => _fetchOutput(_selectedProcessId!),
                ),
                const SizedBox(width: 4),

                // Auto-scroll toggle
                _SmallIconButton(
                  icon: _autoScroll
                      ? Icons.vertical_align_bottom_rounded
                      : Icons.vertical_align_center_rounded,
                  color: _autoScroll ? tokens.accent : tokens.fgDim,
                  tooltip: _autoScroll ? 'Auto-scroll: ON' : 'Auto-scroll: OFF',
                  onTap: () {
                    setState(() => _autoScroll = !_autoScroll);
                    if (_autoScroll) _scrollToBottom();
                  },
                ),

                // Kill / Restart if running
                if (process != null && process.isRunning) ...[
                  const SizedBox(width: 4),
                  _SmallIconButton(
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFEF4444),
                    tooltip: 'Kill',
                    onTap: () => _killProcess(_selectedProcessId!),
                  ),
                ],
                const SizedBox(width: 4),
                _SmallIconButton(
                  icon: Icons.refresh_outlined,
                  color: tokens.fgMuted,
                  tooltip: 'Restart',
                  onTap: () => _restartProcess(_selectedProcessId!),
                ),
              ],
            ),
          ),

          // Terminal output
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF0D1117),
              child: _isLoadingOutput && _outputLines.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: tokens.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            _searchPattern.isNotEmpty
                                ? 'No lines match the pattern'
                                : 'No output yet',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontFamily: 'JetBrains Mono',
                              fontFamilyFallback: ['monospace'],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildOutputLine(tokens, filtered[index]);
                          },
                        ),
            ),
          ),

          // Bottom bar: search + line count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              border: Border(
                top: BorderSide(color: tokens.borderFaint, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: tokens.fgDim, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 12,
                        fontFamily: 'JetBrains Mono',
                        fontFamilyFallback: const ['monospace'],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Filter by regex...',
                        hintStyle: TextStyle(
                          color: tokens.fgDim.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: tokens.borderFaint),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: tokens.borderFaint),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: tokens.accent),
                        ),
                        suffixIcon: _searchPattern.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchPattern = '');
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: tokens.fgDim,
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() => _searchPattern = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _searchPattern.isNotEmpty
                      ? '${filtered.length} / ${_outputLines.length} lines'
                      : '${_outputLines.length} lines',
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Single output line ────────────────────────────────────────────

  Widget _buildOutputLine(OrchestraColorTokens tokens, _IndexedLine item) {
    final hasMatch = _searchPattern.isNotEmpty;
    Widget lineText;

    if (hasMatch) {
      lineText = _HighlightedText(text: item.text, pattern: _searchPattern);
    } else {
      lineText = Text(
        item.text,
        style: const TextStyle(
          color: Color(0xFF39D353),
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['monospace'],
          height: 1.5,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '${item.lineNumber}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tokens.fgDim.withValues(alpha: 0.4),
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
                fontFamilyFallback: const ['monospace'],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 18,
            color: tokens.fgDim.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 12),
          Expanded(child: lineText),
        ],
      ),
    );
  }
}

// ── Indexed line model ──────────────────────────────────────────────────────

class _IndexedLine {
  final int lineNumber;
  final String text;

  const _IndexedLine(this.lineNumber, this.text);
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
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Small icon button ───────────────────────────────────────────────────────

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ── Highlighted text with regex matches ─────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.pattern});

  final String text;
  final String pattern;

  @override
  Widget build(BuildContext context) {
    if (pattern.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: Color(0xFF39D353),
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['monospace'],
          height: 1.5,
        ),
      );
    }

    RegExp regex;
    try {
      regex = RegExp(pattern, caseSensitive: false);
    } catch (_) {
      return Text(
        text,
        style: const TextStyle(
          color: Color(0xFF39D353),
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['monospace'],
          height: 1.5,
        ),
      );
    }

    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: Color(0xFF39D353),
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['monospace'],
          height: 1.5,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Color(0x66FBBF24),
          color: Color(0xFFFBBF24),
          fontWeight: FontWeight.w700,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF39D353),
          fontSize: 12,
          fontFamily: 'JetBrains Mono',
          fontFamilyFallback: ['monospace'],
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
