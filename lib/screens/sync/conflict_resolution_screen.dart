import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/change_tracker.dart';
import 'package:orchestra/core/sync/conflict_resolver.dart';
import 'package:orchestra/core/sync/sync_engine.dart';
import 'package:orchestra/core/sync/sync_models.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_button.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ---------------------------------------------------------------------------
// Conflicts list provider
// ---------------------------------------------------------------------------

/// Loads all unresolved conflicts from the [ChangeTracker].
final unresolvedConflictsProvider = FutureProvider<List<ConflictRecord>>((
  ref,
) async {
  final tracker = ref.watch(changeTrackerProvider);
  return tracker.getUnresolvedConflicts();
});

// ---------------------------------------------------------------------------
// Conflict Resolution Screen
// ---------------------------------------------------------------------------

/// Full-screen UI for reviewing and resolving sync conflicts.
///
/// Shows a list of unresolved conflicts. Tapping one opens a side-by-side
/// diff view where the user can choose Keep Local, Keep Remote, or Merge.
class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final conflictsAsync = ref.watch(unresolvedConflictsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).syncConflicts),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: tokens.accent),
            onPressed: () => ref.invalidate(unresolvedConflictsProvider),
            tooltip: AppLocalizations.of(context).refresh,
          ),
        ],
      ),
      body: conflictsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: tokens.accent)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: tokens.fgDim, size: 48),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).failedToLoadConflicts,
                  style: TextStyle(color: tokens.fgBright, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: tokens.fgMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: tokens.accent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noConflicts,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).allDataInSync,
                    style: TextStyle(color: tokens.fgMuted, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: conflicts.length,
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return _ConflictTile(
                conflict: conflict,
                onTap: () => _openConflictDetail(context, ref, conflict),
              );
            },
          );
        },
      ),
    );
  }

  void _openConflictDetail(
    BuildContext context,
    WidgetRef ref,
    ConflictRecord conflict,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConflictDetailScreen(conflict: conflict),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conflict list tile
// ---------------------------------------------------------------------------

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.conflict, required this.onTap});

  final ConflictRecord conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          // Icon indicating conflict type.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Conflict details.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${conflict.entityType.toUpperCase()} / ${conflict.entityId}',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Local: ${conflict.localDelta.operation.name}  |  '
                  'Remote: ${conflict.remoteDelta.operation.name}',
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(conflict.detectedAt),
                  style: TextStyle(color: tokens.fgDim, fontSize: 11),
                ),
              ],
            ),
          ),

          Icon(Icons.chevron_right, color: tokens.fgDim, size: 18),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} '
        '${_pad(local.hour)}:${_pad(local.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ---------------------------------------------------------------------------
// Conflict detail / diff screen
// ---------------------------------------------------------------------------

class _ConflictDetailScreen extends ConsumerStatefulWidget {
  const _ConflictDetailScreen({required this.conflict});

  final ConflictRecord conflict;

  @override
  ConsumerState<_ConflictDetailScreen> createState() =>
      _ConflictDetailScreenState();
}

class _ConflictDetailScreenState extends ConsumerState<_ConflictDetailScreen> {
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final conflict = widget.conflict;
    final localData = conflict.localDelta.data ?? {};
    final remoteData = conflict.remoteDelta.data ?? {};

    // Collect all keys from both sides for diff view.
    final allKeys = <String>{...localData.keys, ...remoteData.keys}.toList()
      ..sort();

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(
          '${conflict.entityType} / ${conflict.entityId}',
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header labels ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).localThisDevice,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Icon(
                      Icons.compare_arrows,
                      color: tokens.fgDim,
                      size: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).remoteServer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.accentAlt,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Side-by-side diff ──────────────────────────────────────────
          Expanded(
            child: allKeys.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context).noDataToCompare,
                      style: TextStyle(color: tokens.fgMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: allKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final key = allKeys[index];
                      final localVal = localData[key];
                      final remoteVal = remoteData[key];
                      final isDifferent =
                          localVal?.toString() != remoteVal?.toString();

                      return _DiffRow(
                        fieldName: key,
                        localValue: localVal?.toString() ?? '(absent)',
                        remoteValue: remoteVal?.toString() ?? '(absent)',
                        isDifferent: isDifferent,
                      );
                    },
                  ),
          ),

          // ── Action buttons ─────────────────────────────────────────────
          GlassCard(
            borderRadius: 0,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassButton(
                  label: AppLocalizations.of(context).keepLocal,
                  icon: Icons.phone_android,
                  isLoading: _isResolving,
                  onPressed: () => _resolve(ResolutionKind.useLocal),
                ),
                const SizedBox(height: 10),
                GlassButton(
                  label: AppLocalizations.of(context).keepRemote,
                  icon: Icons.cloud_outlined,
                  isLoading: _isResolving,
                  onPressed: () => _resolve(ResolutionKind.useRemote),
                ),
                const SizedBox(height: 10),
                _MergeButton(
                  isLoading: _isResolving,
                  onPressed: () => _openMergeEditor(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(ResolutionKind resolution) async {
    setState(() => _isResolving = true);
    try {
      final tracker = ref.read(changeTrackerProvider);
      final conflict = widget.conflict;

      // Determine the winning delta.
      SyncDelta winning;
      switch (resolution) {
        case ResolutionKind.useLocal:
          winning = conflict.localDelta;
        case ResolutionKind.useRemote:
          winning = conflict.remoteDelta;
        case ResolutionKind.merged:
        case ResolutionKind.manual:
          winning = conflict.remoteDelta;
      }

      // Re-record the winning change so it gets pushed on next sync.
      if (resolution == ResolutionKind.useLocal) {
        await tracker.recordChange(
          entityType: winning.entityType,
          entityId: winning.entityId,
          operation: winning.operation,
          data: winning.data,
        );
      }

      // Remove the conflict from storage.
      await tracker.removeConflict(conflict.id);

      // Trigger a sync to push the resolution.
      ref.read(syncEngineNotifierProvider.notifier).fullSync();

      // Invalidate the conflicts list.
      ref.invalidate(unresolvedConflictsProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  void _openMergeEditor(BuildContext context) {
    final conflict = widget.conflict;
    Navigator.of(context)
        .push(
          MaterialPageRoute<Map<String, dynamic>?>(
            builder: (_) => _MergeEditorScreen(conflict: conflict),
          ),
        )
        .then((mergedData) {
          if (mergedData != null) {
            _resolveWithMergedData(mergedData);
          }
        });
  }

  Future<void> _resolveWithMergedData(Map<String, dynamic> mergedData) async {
    setState(() => _isResolving = true);
    try {
      final tracker = ref.read(changeTrackerProvider);
      final conflict = widget.conflict;

      // Record the merged version as a new change.
      await tracker.recordChange(
        entityType: conflict.localDelta.entityType,
        entityId: conflict.localDelta.entityId,
        operation: SyncOperation.update,
        data: mergedData,
      );

      await tracker.removeConflict(conflict.id);
      ref.read(syncEngineNotifierProvider.notifier).fullSync();
      ref.invalidate(unresolvedConflictsProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Diff row widget
// ---------------------------------------------------------------------------

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
    required this.isDifferent,
  });

  final String fieldName;
  final String localValue;
  final String remoteValue;
  final bool isDifferent;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field name label.
          Row(
            children: [
              if (isDifferent)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                fieldName,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Side-by-side values.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Local value.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDifferent
                        ? tokens.accent.withValues(alpha: 0.08)
                        : tokens.bgAlt.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: isDifferent
                        ? Border.all(
                            color: tokens.accent.withValues(alpha: 0.25),
                          )
                        : null,
                  ),
                  child: Text(
                    localValue,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Remote value.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDifferent
                        ? tokens.accentAlt.withValues(alpha: 0.08)
                        : tokens.bgAlt.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: isDifferent
                        ? Border.all(
                            color: tokens.accentAlt.withValues(alpha: 0.25),
                          )
                        : null,
                  ),
                  child: Text(
                    remoteValue,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Merge button (outlined style, distinct from GlassButton)
// ---------------------------------------------------------------------------

class _MergeButton extends StatelessWidget {
  const _MergeButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.accent,
                ),
              )
            : Icon(Icons.merge_type, color: tokens.accent, size: 20),
        label: Text(
          AppLocalizations.of(context).mergeEditManually,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Merge editor screen
// ---------------------------------------------------------------------------

/// Allows the user to manually edit field values to create a merged version.
class _MergeEditorScreen extends StatefulWidget {
  const _MergeEditorScreen({required this.conflict});

  final ConflictRecord conflict;

  @override
  State<_MergeEditorScreen> createState() => _MergeEditorScreenState();
}

class _MergeEditorScreenState extends State<_MergeEditorScreen> {
  late Map<String, TextEditingController> _controllers;
  late List<String> _allKeys;

  @override
  void initState() {
    super.initState();
    final localData = widget.conflict.localDelta.data ?? {};
    final remoteData = widget.conflict.remoteDelta.data ?? {};
    _allKeys = <String>{...localData.keys, ...remoteData.keys}.toList()..sort();

    // Pre-populate each field with the remote value (user can edit).
    _controllers = {};
    for (final key in _allKeys) {
      final remoteVal = remoteData[key];
      final localVal = localData[key];
      // Default to remote; fall back to local if remote is absent.
      final initial = (remoteVal ?? localVal)?.toString() ?? '';
      _controllers[key] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).mergeEditor,
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: tokens.bg,
        foregroundColor: tokens.fgBright,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveMerge,
            child: Text(
              AppLocalizations.of(context).save,
              style: TextStyle(
                color: tokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _allKeys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final key = _allKeys[index];
          final localData = widget.conflict.localDelta.data ?? {};
          final remoteData = widget.conflict.remoteDelta.data ?? {};
          final localVal = localData[key]?.toString() ?? '(absent)';
          final remoteVal = remoteData[key]?.toString() ?? '(absent)';
          final isDifferent = localVal != remoteVal;

          return GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field label with hint values.
                Row(
                  children: [
                    if (isDifferent)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      key,
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (isDifferent) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _PickHint(
                        label: AppLocalizations.of(context).local,
                        color: tokens.accent,
                        onTap: () {
                          _controllers[key]!.text = localVal;
                        },
                      ),
                      const SizedBox(width: 8),
                      _PickHint(
                        label: AppLocalizations.of(context).remote,
                        color: tokens.accentAlt,
                        onTap: () {
                          _controllers[key]!.text = remoteVal;
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _controllers[key],
                  maxLines: null,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: tokens.bgAlt.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.borderFaint),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tokens.accent),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _saveMerge() {
    final merged = <String, dynamic>{};
    for (final key in _allKeys) {
      final text = _controllers[key]!.text;
      if (text.isNotEmpty && text != '(absent)') {
        merged[key] = text;
      }
    }
    Navigator.of(context).pop(merged);
  }
}

// ---------------------------------------------------------------------------
// Pick hint chip (tap to fill a field from local or remote)
// ---------------------------------------------------------------------------

class _PickHint extends StatelessWidget {
  const _PickHint({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label == 'Local'
              ? AppLocalizations.of(context).useLocal
              : AppLocalizations.of(context).useRemote,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
