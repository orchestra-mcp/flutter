import 'package:flutter/material.dart';
import 'package:orchestra/core/mcp/scope_resolver.dart';

/// Small pill badge showing "Global" or "Workspace" scope.
class ScopeBadge extends StatelessWidget {
  const ScopeBadge({super.key, required this.scope});

  final ItemScope scope;

  @override
  Widget build(BuildContext context) {
    final isGlobal = scope == ItemScope.global;
    final color = isGlobal ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);
    final label = isGlobal ? 'Global' : 'Workspace';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Inline scope indicator — just the text, no background.
class ScopeLabel extends StatelessWidget {
  const ScopeLabel({super.key, required this.scope});

  final ItemScope scope;

  @override
  Widget build(BuildContext context) {
    if (scope != ItemScope.global) return const SizedBox.shrink();

    return Text(
      'Global',
      style: TextStyle(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Publish status indicator dot.
class PublishStatusDot extends StatelessWidget {
  const PublishStatusDot({super.key, required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: synced ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
      ),
    );
  }
}
