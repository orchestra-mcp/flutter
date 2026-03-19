import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/sync/sync_conflict_models.dart';
import 'package:orchestra/core/sync/sync_conflict_resolver.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Public API ──────────────────────────────────────────────────────────────

/// Shows a bottom sheet for resolving a [SyncConflict].
///
/// Returns the resolved [SyncConflict] or null if the user dismissed.
Future<SyncConflict?> showConflictResolutionSheet(
  BuildContext context,
  SyncConflict conflict,
) {
  return showModalBottomSheet<SyncConflict>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConflictSheet(conflict: conflict),
  );
}

// ── Sheet widget ────────────────────────────────────────────────────────────

class _ConflictSheet extends ConsumerStatefulWidget {
  const _ConflictSheet({required this.conflict});
  final SyncConflict conflict;

  @override
  ConsumerState<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends ConsumerState<_ConflictSheet> {
  /// Per-field choices: true = keep local, false = keep remote.
  late final Map<String, bool> _fieldChoices;

  @override
  void initState() {
    super.initState();
    // Default: keep remote for all fields.
    _fieldChoices = {
      for (final diff in widget.conflict.diffs)
        if (diff.hasConflict) diff.field: false,
    };
  }

  void _resolve(ConflictResolution strategy) {
    final SyncConflict resolved;
    switch (strategy) {
      case ConflictResolution.keepLocal:
        resolved = resolveKeepLocal(widget.conflict);
      case ConflictResolution.keepRemote:
        resolved = resolveKeepRemote(widget.conflict);
      case ConflictResolution.merge:
        resolved = resolveMerge(widget.conflict, _fieldChoices);
    }

    ref
        .read(syncConflictsProvider.notifier)
        .resolveConflict(
          widget.conflict.entityType,
          widget.conflict.entityId,
          resolved,
        );
    Navigator.pop(context, resolved);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final conflict = widget.conflict;
    final conflictingDiffs = conflict.diffs
        .where((d) => d.hasConflict)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.fgDim.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).syncConflict,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${conflict.entityTitle} (${conflict.entityType})',
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _VersionBadge(
                  label: AppLocalizations.of(
                    context,
                  ).syncConflictLocalVersion(conflict.localVersion),
                  color: const Color(0xFF38BDF8),
                  tokens: tokens,
                ),
                const SizedBox(width: 6),
                _VersionBadge(
                  label: AppLocalizations.of(
                    context,
                  ).syncConflictRemoteVersion(conflict.remoteVersion),
                  color: const Color(0xFFF97316),
                  tokens: tokens,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),

          // ── Field diffs ──────────────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: conflictingDiffs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final diff = conflictingDiffs[i];
                final keepLocal = _fieldChoices[diff.field] ?? false;
                return _FieldDiffCard(
                  diff: diff,
                  keepLocal: keepLocal,
                  tokens: tokens,
                  onToggle: (value) {
                    setState(() {
                      _fieldChoices[diff.field] = value;
                    });
                  },
                );
              },
            ),
          ),

          Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),

          // ── Action buttons ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context).keepLocal,
                    icon: Icons.phone_android_rounded,
                    color: const Color(0xFF38BDF8),
                    tokens: tokens,
                    onTap: () => _resolve(ConflictResolution.keepLocal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context).keepRemote,
                    icon: Icons.cloud_rounded,
                    color: const Color(0xFFF97316),
                    tokens: tokens,
                    onTap: () => _resolve(ConflictResolution.keepRemote),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context).merge,
                    icon: Icons.merge_rounded,
                    color: const Color(0xFF4ADE80),
                    tokens: tokens,
                    onTap: () => _resolve(ConflictResolution.merge),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldDiffCard extends StatelessWidget {
  const _FieldDiffCard({
    required this.diff,
    required this.keepLocal,
    required this.tokens,
    required this.onToggle,
  });
  final FieldDiff diff;
  final bool keepLocal;
  final OrchestraColorTokens tokens;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                diff.isTextContent
                    ? Icons.text_fields_rounded
                    : Icons.data_object_rounded,
                size: 14,
                color: tokens.fgMuted,
              ),
              const SizedBox(width: 6),
              Text(
                diff.field,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (diff.isTextContent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context).syncConflictText,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Toggle: local ↔ remote
              GestureDetector(
                onTap: () => onToggle(!keepLocal),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: keepLocal
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                        : const Color(0xFFF97316).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    keepLocal
                        ? AppLocalizations.of(context).local
                        : AppLocalizations.of(context).remote,
                    style: TextStyle(
                      color: keepLocal
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFFF97316),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Local value
          _ValueRow(
            label: AppLocalizations.of(context).local,
            value: _displayValue(diff.localValue, context),
            color: const Color(0xFF38BDF8),
            isSelected: keepLocal,
          ),
          const SizedBox(height: 4),
          // Remote value
          _ValueRow(
            label: AppLocalizations.of(context).remote,
            value: _displayValue(diff.remoteValue, context),
            color: const Color(0xFFF97316),
            isSelected: !keepLocal,
          ),
        ],
      ),
    );
  }

  String _displayValue(dynamic value, BuildContext context) {
    if (value == null) return AppLocalizations.of(context).syncConflictEmpty;
    final str = value.toString();
    if (str.length > 120) return '${str.substring(0, 120)}…';
    return str;
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.color,
    required this.isSelected,
  });
  final String label;
  final String value;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: isSelected ? 1.0 : 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(color: color.withValues(alpha: 0.3))
                  : null,
            ),
            child: Text(
              value,
              style: TextStyle(
                color: isSelected ? tokens.fgBright : tokens.fgDim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.tokens,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
