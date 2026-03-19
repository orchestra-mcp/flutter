import 'package:flutter/material.dart';

/// Small badge indicating whether a record comes from the global DB or the
/// workspace DB. Helps users understand where the data is persisted.
///
/// Shows GLOBAL (indigo) for items from `~/.orchestra/db/global.db` and
/// WORKSPACE (sky blue) for items from the per-workspace DB.
class DbSourceBadge extends StatelessWidget {
  const DbSourceBadge({super.key, required this.source});

  /// The data source: `"global"` or `"workspace"` (default).
  final String source;

  @override
  Widget build(BuildContext context) {
    final isGlobal = source == 'global';
    final color = isGlobal ? const Color(0xFF6366F1) : const Color(0xFF0EA5E9);
    final label = isGlobal ? 'GLOBAL' : 'WORKSPACE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
