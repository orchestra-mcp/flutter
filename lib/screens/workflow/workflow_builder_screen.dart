import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orchestra/core/api/library_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/workflow/providers/workflow_builder_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ── Workflow Builder Screen ──────────────────────────────────────────────────

/// Full-screen visual workflow builder.
///
/// Layout (desktop):
///   ┌─ AppBar ─────────────────────────────────────────────────────────┐
///   │ [←]  Workflow Builder  [YAML]  [Export Pack]  [Save]            │
///   ├────────────────────────────────┬─────────────────────────────────┤
///   │  Canvas (flow diagram)         │  Inspector panel                │
///   │  • draggable state nodes       │  • state / transition / gate    │
///   │  • arrows for transitions      │    detail editor                │
///   │  • tap node to inspect         │  • attach skill / agent         │
///   └────────────────────────────────┴─────────────────────────────────┘
class WorkflowBuilderScreen extends ConsumerStatefulWidget {
  const WorkflowBuilderScreen({super.key, this.workflowId});

  /// If set, loads an existing workflow for editing.
  final String? workflowId;

  @override
  ConsumerState<WorkflowBuilderScreen> createState() =>
      _WorkflowBuilderScreenState();
}

class _WorkflowBuilderScreenState extends ConsumerState<WorkflowBuilderScreen> {
  bool _loading = false;
  bool _showYaml = false;
  // Which state index is selected in the inspector (-1 = none).
  int _selectedState = -1;
  int _selectedTransition = -1;
  int _selectedGate = -1;

  // Node positions on canvas (keyed by state id).
  final Map<String, Offset> _nodePositions = {};

  @override
  void initState() {
    super.initState();
    if (widget.workflowId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(workflowBuilderProvider.notifier)
          .loadWorkflow(widget.workflowId!);
      _initNodePositions();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.wbLoadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initNodePositions() {
    final draft = ref.read(workflowBuilderProvider);
    double x = 80;
    for (final s in draft.states) {
      if (!_nodePositions.containsKey(s.id)) {
        _nodePositions[s.id] = Offset(x, 120);
        x += 180;
      }
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final id = await ref.read(workflowBuilderProvider.notifier).save();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id != null ? l10n.wbSaved(id) : l10n.wbUpdated),
          ),
        );
        if (widget.workflowId == null && id != null) {
          context.replace('/library/workflows/$id/build');
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.wbSaveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showExportSheet() {
    final draft = ref.read(workflowBuilderProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(draft: draft),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final draft = ref.watch(workflowBuilderProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bgAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.name.isEmpty ? l10n.wbNewWorkflow : draft.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: tokens.fgBright,
              ),
            ),
            if (draft.projectId.isNotEmpty)
              Text(
                draft.projectId,
                style: TextStyle(fontSize: 11, color: tokens.fgMuted),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.code_rounded, size: 16, color: tokens.accent),
            label: Text(
              l10n.wbYaml,
              style: TextStyle(fontSize: 12, color: tokens.accent),
            ),
            onPressed: () => setState(() => _showYaml = !_showYaml),
          ),
          TextButton.icon(
            icon: Icon(Icons.upload_rounded, size: 16, color: tokens.accent),
            label: Text(
              l10n.wbExportPack,
              style: TextStyle(fontSize: 12, color: tokens.accent),
            ),
            onPressed: _showExportSheet,
          ),
          const SizedBox(width: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.wbSave, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: tokens.accent))
          : _showYaml
          ? _YamlPreview(draft: draft)
          : Row(
              children: [
                // ── Canvas ──────────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: _WorkflowCanvas(
                    draft: draft,
                    nodePositions: _nodePositions,
                    selectedState: _selectedState,
                    onNodeTap: (i) => setState(() {
                      _selectedState = i;
                      _selectedTransition = -1;
                      _selectedGate = -1;
                    }),
                    onNodeMove: (id, pos) =>
                        setState(() => _nodePositions[id] = pos),
                    onTransitionTap: (i) => setState(() {
                      _selectedTransition = i;
                      _selectedState = -1;
                      _selectedGate = -1;
                    }),
                    onAddState: () {
                      ref.read(workflowBuilderProvider.notifier).addState();
                      final draft = ref.read(workflowBuilderProvider);
                      final last = draft.states.last;
                      _nodePositions[last.id] = Offset(
                        80.0 + (draft.states.length - 1) * 180,
                        120,
                      );
                    },
                    onAddTransition: () => ref
                        .read(workflowBuilderProvider.notifier)
                        .addTransition(),
                  ),
                ),
                // ── Inspector ────────────────────────────────────────────
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: tokens.bgAlt,
                    border: Border(
                      left: BorderSide(color: tokens.border, width: 1),
                    ),
                  ),
                  child: _Inspector(
                    draft: draft,
                    selectedState: _selectedState,
                    selectedTransition: _selectedTransition,
                    selectedGate: _selectedGate,
                    onSelectGate: (i) => setState(() {
                      _selectedGate = i;
                      _selectedState = -1;
                      _selectedTransition = -1;
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Canvas ───────────────────────────────────────────────────────────────────

class _WorkflowCanvas extends StatelessWidget {
  const _WorkflowCanvas({
    required this.draft,
    required this.nodePositions,
    required this.selectedState,
    required this.onNodeTap,
    required this.onNodeMove,
    required this.onTransitionTap,
    required this.onAddState,
    required this.onAddTransition,
  });

  final WorkflowDraft draft;
  final Map<String, Offset> nodePositions;
  final int selectedState;
  final void Function(int) onNodeTap;
  final void Function(String, Offset) onNodeMove;
  final void Function(int) onTransitionTap;
  final VoidCallback onAddState;
  final VoidCallback onAddTransition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);

    return Stack(
      children: [
        // Grid background
        CustomPaint(painter: _GridPainter(tokens), size: Size.infinite),

        // Transition arrows (drawn under nodes)
        CustomPaint(
          painter: _TransitionPainter(
            draft: draft,
            positions: nodePositions,
            tokens: tokens,
          ),
          size: Size.infinite,
        ),

        // Tap targets for transitions (invisible, on top of arrows)
        ...List.generate(draft.transitions.length, (i) {
          final t = draft.transitions[i];
          final from = nodePositions[t.from];
          final to = nodePositions[t.to];
          if (from == null || to == null) return const SizedBox.shrink();
          final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
          return Positioned(
            left: mid.dx - 16,
            top: mid.dy - 16,
            child: GestureDetector(
              onTap: () => onTransitionTap(i),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.gate != null && t.gate!.isNotEmpty
                      ? tokens.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: t.gate != null && t.gate!.isNotEmpty
                    ? Icon(Icons.lock_rounded, size: 14, color: tokens.accent)
                    : null,
              ),
            ),
          );
        }),

        // State nodes
        ...List.generate(draft.states.length, (i) {
          final s = draft.states[i];
          final pos = nodePositions[s.id] ?? Offset(80 + i * 180.0, 120);
          return _DraggableNode(
            key: ValueKey('node-${s.id}'),
            state: s,
            position: pos,
            isSelected: selectedState == i,
            isInitial: draft.initialState == s.id,
            onTap: () => onNodeTap(i),
            onMove: (newPos) => onNodeMove(s.id, newPos),
            tokens: tokens,
          );
        }),

        // Toolbar (bottom-left)
        Positioned(
          left: 16,
          bottom: 16,
          child: Row(
            children: [
              _CanvasButton(
                icon: Icons.add_circle_outline_rounded,
                label: l10n.wbAddState,
                onTap: onAddState,
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _CanvasButton(
                icon: Icons.arrow_forward_rounded,
                label: l10n.wbAddTransition,
                onTap: onAddTransition,
                tokens: tokens,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.tokens);
  final OrchestraColorTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tokens.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _TransitionPainter extends CustomPainter {
  _TransitionPainter({
    required this.draft,
    required this.positions,
    required this.tokens,
  });

  final WorkflowDraft draft;
  final Map<String, Offset> positions;
  final OrchestraColorTokens tokens;

  static const _nodeW = 140.0;
  static const _nodeH = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = tokens.fgMuted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final gatePaint = Paint()
      ..color = tokens.accent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final t in draft.transitions) {
      final from = positions[t.from];
      final to = positions[t.to];
      if (from == null || to == null) continue;

      final hasGate = t.gate != null && t.gate!.isNotEmpty;
      final paint = hasGate ? gatePaint : arrowPaint;

      final start = Offset(from.dx + _nodeW, from.dy + _nodeH / 2);
      final end = Offset(to.dx, to.dy + _nodeH / 2);

      // Curved path
      final cp1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
      final cp2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);

      // Arrow head
      const arrowLen = 8.0;
      const arrowAngle = 0.4;
      final dx = end.dx - cp2.dx;
      final dy = end.dy - cp2.dy;
      final angle = math.atan2(dy, dx);
      final arrowHead = Paint()
        ..color = hasGate
            ? tokens.accent.withValues(alpha: 0.8)
            : tokens.fgMuted.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      final p1 = Offset(
        end.dx - arrowLen * math.cos(angle - arrowAngle),
        end.dy - arrowLen * math.sin(angle - arrowAngle),
      );
      final p2 = Offset(
        end.dx - arrowLen * math.cos(angle + arrowAngle),
        end.dy - arrowLen * math.sin(angle + arrowAngle),
      );
      canvas.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close(),
        arrowHead,
      );
    }
  }

  @override
  bool shouldRepaint(_TransitionPainter old) =>
      old.draft != draft || old.positions != positions;
}

class _DraggableNode extends StatelessWidget {
  const _DraggableNode({
    super.key,
    required this.state,
    required this.position,
    required this.isSelected,
    required this.isInitial,
    required this.onTap,
    required this.onMove,
    required this.tokens,
  });

  final WorkflowState state;
  final Offset position;
  final bool isSelected;
  final bool isInitial;
  final VoidCallback onTap;
  final void Function(Offset) onMove;
  final OrchestraColorTokens tokens;

  Color get _nodeColor {
    if (state.terminal) return const Color(0xFF10B981);
    if (state.activeWork) return const Color(0xFF6366F1);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (d) => onMove(position + d.delta),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 140,
          height: 56,
          decoration: BoxDecoration(
            color: tokens.bgAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? tokens.accent
                  : _nodeColor.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _nodeColor.withValues(alpha: isSelected ? 0.3 : 0.1),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 1 : 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _nodeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.fgBright,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (isInitial)
                            _NodeBadge(
                              l10n.wbBadgeStart,
                              const Color(0xFF3B82F6),
                            ),
                          if (state.terminal)
                            _NodeBadge(
                              l10n.wbBadgeEnd,
                              const Color(0xFF10B981),
                            ),
                          if (state.skillSlug != null)
                            _NodeBadge(
                              l10n.wbBadgeSkill,
                              const Color(0xFFF97316),
                            ),
                          if (state.agentSlug != null)
                            _NodeBadge(
                              l10n.wbBadgeAgent,
                              const Color(0xFFA78BFA),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeBadge extends StatelessWidget {
  const _NodeBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 3, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CanvasButton extends StatelessWidget {
  const _CanvasButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tokens.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: tokens.fgBright,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inspector ────────────────────────────────────────────────────────────────

class _Inspector extends ConsumerWidget {
  const _Inspector({
    required this.draft,
    required this.selectedState,
    required this.selectedTransition,
    required this.selectedGate,
    required this.onSelectGate,
  });

  final WorkflowDraft draft;
  final int selectedState;
  final int selectedTransition;
  final int selectedGate;
  final void Function(int) onSelectGate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final notifier = ref.read(workflowBuilderProvider.notifier);

    Widget body;
    if (selectedState >= 0 && selectedState < draft.states.length) {
      body = _StateInspector(
        key: ValueKey('state-$selectedState'),
        draft: draft,
        index: selectedState,
        notifier: notifier,
        tokens: tokens,
      );
    } else if (selectedTransition >= 0 &&
        selectedTransition < draft.transitions.length) {
      body = _TransitionInspector(
        key: ValueKey('transition-$selectedTransition'),
        draft: draft,
        index: selectedTransition,
        notifier: notifier,
        tokens: tokens,
        onSelectGate: onSelectGate,
      );
    } else if (selectedGate >= 0 && selectedGate < draft.gates.length) {
      body = _GateInspector(
        key: ValueKey('gate-$selectedGate'),
        draft: draft,
        index: selectedGate,
        notifier: notifier,
        tokens: tokens,
      );
    } else {
      body = _WorkflowInspector(
        draft: draft,
        notifier: notifier,
        tokens: tokens,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gates list in inspector header
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Text(
                l10n.wbInspector,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tokens.fgMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (selectedState >= 0)
                Text(
                  l10n.wbInspectorState,
                  style: TextStyle(fontSize: 11, color: tokens.accent),
                ),
              if (selectedTransition >= 0)
                Text(
                  l10n.wbInspectorTransition,
                  style: TextStyle(fontSize: 11, color: tokens.accent),
                ),
              if (selectedGate >= 0)
                Text(
                  l10n.wbInspectorGate,
                  style: TextStyle(fontSize: 11, color: tokens.accent),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: SingleChildScrollView(child: body)),
        // Gates quick-access strip
        if (draft.gates.isNotEmpty) ...[
          const Divider(height: 1),
          _GatesStrip(
            draft: draft,
            selectedGate: selectedGate,
            onSelect: onSelectGate,
            notifier: notifier,
            tokens: tokens,
          ),
        ],
      ],
    );
  }
}

// ── Workflow-level inspector (nothing selected) ───────────────────────────────

class _WorkflowInspector extends ConsumerStatefulWidget {
  const _WorkflowInspector({
    required this.draft,
    required this.notifier,
    required this.tokens,
  });
  final WorkflowDraft draft;
  final WorkflowBuilderNotifier notifier;
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_WorkflowInspector> createState() => _WorkflowInspectorState();
}

class _WorkflowInspectorState extends ConsumerState<_WorkflowInspector> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _projectCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _descCtrl = TextEditingController(text: widget.draft.description);
    _projectCtrl = TextEditingController(text: widget.draft.projectId);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _projectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.tokens;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.wbSectionWorkflow, t),
          _InspectorField(
            label: l10n.wbFieldName,
            ctrl: _nameCtrl,
            tokens: t,
            onChanged: widget.notifier.setName,
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldDescription,
            ctrl: _descCtrl,
            tokens: t,
            onChanged: widget.notifier.setDescription,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldProjectId,
            ctrl: _projectCtrl,
            tokens: t,
            onChanged: widget.notifier.setProjectId,
            hint: l10n.wbProjectIdHint,
          ),
          const SizedBox(height: 8),
          _InspectorDropdown<String>(
            label: l10n.wbFieldInitialState,
            value: widget.draft.initialState,
            items: widget.draft.states.map((s) => s.id).toList(),
            labelFor: (id) => widget.draft.states
                .firstWhere(
                  (s) => s.id == id,
                  orElse: () => WorkflowState(id: id, label: id),
                )
                .label,
            tokens: t,
            onChanged: widget.notifier.setInitialState,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.wbSetAsDefault,
                style: TextStyle(fontSize: 12, color: t.fgMuted),
              ),
              const Spacer(),
              Switch(
                value: widget.draft.isDefault,
                activeThumbColor: t.accent,
                onChanged: widget.notifier.setIsDefault,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel(l10n.wbSectionGates, t),
          OutlinedButton.icon(
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(l10n.wbAddGate, style: const TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.accent,
              side: BorderSide(color: t.accent.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: widget.notifier.addGate,
          ),
          // Validation hints
          if (!widget.draft.hasTerminalState)
            _ValidationHint(l10n.wbNoTerminalState, t),
          if (!widget.draft.initialStateValid)
            _ValidationHint(l10n.wbInvalidInitialState, t),
        ],
      ),
    );
  }
}

// ── State inspector ───────────────────────────────────────────────────────────

class _StateInspector extends ConsumerStatefulWidget {
  const _StateInspector({
    super.key,
    required this.draft,
    required this.index,
    required this.notifier,
    required this.tokens,
  });
  final WorkflowDraft draft;
  final int index;
  final WorkflowBuilderNotifier notifier;
  final OrchestraColorTokens tokens;

  @override
  ConsumerState<_StateInspector> createState() => _StateInspectorState();
}

class _StateInspectorState extends ConsumerState<_StateInspector> {
  late TextEditingController _idCtrl;
  late TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.draft.states[widget.index];
    _idCtrl = TextEditingController(text: s.id);
    _labelCtrl = TextEditingController(text: s.label);
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  WorkflowState get _current => widget.draft.states[widget.index];

  void _update(WorkflowState updated) =>
      widget.notifier.updateState(widget.index, updated);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.tokens;
    final s = _current;

    // Load skills + agents from library provider
    final asyncSkills = ref.watch(skillsProvider);
    final asyncAgents = ref.watch(agentsProvider);

    final skillNames = asyncSkills.maybeWhen(
      data: (list) => list
          .map((m) => (m['slug'] ?? m['name'] ?? '') as String)
          .where((n) => n.isNotEmpty)
          .toList(),
      orElse: () => <String>[],
    );
    final agentNames = asyncAgents.maybeWhen(
      data: (list) => list
          .map((m) => (m['slug'] ?? m['name'] ?? '') as String)
          .where((n) => n.isNotEmpty)
          .toList(),
      orElse: () => <String>[],
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.wbSectionState, t),
          _InspectorField(
            label: l10n.wbFieldStateId,
            ctrl: _idCtrl,
            tokens: t,
            onChanged: (v) => _update(s.copyWith(id: v)),
            hint: l10n.wbStateIdHint,
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldStateLabel,
            ctrl: _labelCtrl,
            tokens: t,
            onChanged: (v) => _update(s.copyWith(label: v)),
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            label: l10n.wbToggleTerminal,
            value: s.terminal,
            tokens: t,
            onChanged: (v) => _update(s.copyWith(terminal: v)),
          ),
          _ToggleRow(
            label: l10n.wbToggleActiveWork,
            value: s.activeWork,
            tokens: t,
            onChanged: (v) => _update(s.copyWith(activeWork: v)),
          ),
          const SizedBox(height: 12),
          _SectionLabel(l10n.wbSectionAttachedSkill, t),
          _LibraryPicker(
            label: l10n.wbBadgeSkill,
            currentValue: s.skillSlug,
            options: skillNames,
            icon: Icons.bolt_rounded,
            color: const Color(0xFFF97316),
            tokens: t,
            onPick: (slug) => _update(s.copyWith(skillSlug: slug)),
            onClear: () => _update(s.copyWith(clearSkill: true)),
          ),
          const SizedBox(height: 8),
          _SectionLabel(l10n.wbSectionAttachedAgent, t),
          _LibraryPicker(
            label: l10n.wbBadgeAgent,
            currentValue: s.agentSlug,
            options: agentNames,
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFFA78BFA),
            tokens: t,
            onPick: (slug) => _update(s.copyWith(agentSlug: slug)),
            onClear: () => _update(s.copyWith(clearAgent: true)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: Colors.redAccent,
            ),
            label: Text(
              l10n.wbRemoveState,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
            onPressed: () => widget.notifier.removeState(widget.index),
          ),
        ],
      ),
    );
  }
}

// ── Transition inspector ──────────────────────────────────────────────────────

class _TransitionInspector extends StatelessWidget {
  const _TransitionInspector({
    super.key,
    required this.draft,
    required this.index,
    required this.notifier,
    required this.tokens,
    required this.onSelectGate,
  });
  final WorkflowDraft draft;
  final int index;
  final WorkflowBuilderNotifier notifier;
  final OrchestraColorTokens tokens;
  final void Function(int) onSelectGate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = draft.transitions[index];
    final stateIds = draft.states.map((s) => s.id).toList();
    final gateIds = draft.gates.map((g) => g.id).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.wbSectionTransition, tokens),
          _InspectorDropdown<String>(
            label: l10n.wbFieldFrom,
            value: t.from,
            items: stateIds,
            labelFor: (id) => draft.states
                .firstWhere(
                  (s) => s.id == id,
                  orElse: () => WorkflowState(id: id, label: id),
                )
                .label,
            tokens: tokens,
            onChanged: (v) => notifier.updateTransition(
              index,
              WorkflowTransition(from: v, to: t.to, gate: t.gate),
            ),
          ),
          const SizedBox(height: 8),
          _InspectorDropdown<String>(
            label: l10n.wbFieldTo,
            value: t.to,
            items: stateIds,
            labelFor: (id) => draft.states
                .firstWhere(
                  (s) => s.id == id,
                  orElse: () => WorkflowState(id: id, label: id),
                )
                .label,
            tokens: tokens,
            onChanged: (v) => notifier.updateTransition(
              index,
              WorkflowTransition(from: t.from, to: v, gate: t.gate),
            ),
          ),
          const SizedBox(height: 8),
          // Gate selector
          Row(
            children: [
              Expanded(
                child: _InspectorDropdown<String>(
                  label: l10n.wbFieldGateOptional,
                  value: t.gate ?? '',
                  items: ['', ...gateIds],
                  labelFor: (id) => id.isEmpty ? l10n.wbGateNone : id,
                  tokens: tokens,
                  onChanged: (v) => notifier.updateTransition(
                    index,
                    WorkflowTransition(
                      from: t.from,
                      to: t.to,
                      gate: v.isEmpty ? null : v,
                    ),
                  ),
                ),
              ),
              if (t.gate != null && t.gate!.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: tokens.accent,
                  ),
                  tooltip: l10n.wbEditGateTooltip,
                  onPressed: () {
                    final i = draft.gates.indexWhere((g) => g.id == t.gate);
                    if (i >= 0) onSelectGate(i);
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: Colors.redAccent,
            ),
            label: Text(
              l10n.wbRemoveTransition,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
            onPressed: () => notifier.removeTransition(index),
          ),
        ],
      ),
    );
  }
}

// ── Gate inspector ────────────────────────────────────────────────────────────

class _GateInspector extends StatefulWidget {
  const _GateInspector({
    super.key,
    required this.draft,
    required this.index,
    required this.notifier,
    required this.tokens,
  });
  final WorkflowDraft draft;
  final int index;
  final WorkflowBuilderNotifier notifier;
  final OrchestraColorTokens tokens;

  @override
  State<_GateInspector> createState() => _GateInspectorState();
}

class _GateInspectorState extends State<_GateInspector> {
  late TextEditingController _idCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _sectionCtrl;
  late TextEditingController _patternsCtrl;
  late TextEditingController _docsFolderCtrl;
  late TextEditingController _skippableCtrl;

  @override
  void initState() {
    super.initState();
    final g = widget.draft.gates[widget.index];
    _idCtrl = TextEditingController(text: g.id);
    _labelCtrl = TextEditingController(text: g.label);
    _sectionCtrl = TextEditingController(text: g.requiredSection);
    _patternsCtrl = TextEditingController(text: g.filePatterns.join('\n'));
    _docsFolderCtrl = TextEditingController(text: g.docsFolder);
    _skippableCtrl = TextEditingController(text: g.skippableFor.join(', '));
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _labelCtrl.dispose();
    _sectionCtrl.dispose();
    _patternsCtrl.dispose();
    _docsFolderCtrl.dispose();
    _skippableCtrl.dispose();
    super.dispose();
  }

  WorkflowGate get _current => widget.draft.gates[widget.index];

  void _update(WorkflowGate updated) =>
      widget.notifier.updateGate(widget.index, updated);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.tokens;
    final g = _current;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.wbSectionGate, t),
          _InspectorField(
            label: l10n.wbFieldGateId,
            ctrl: _idCtrl,
            tokens: t,
            hint: l10n.wbGateIdHint,
            onChanged: (v) => _update(g.copyWith(id: v)),
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldGateLabel,
            ctrl: _labelCtrl,
            tokens: t,
            onChanged: (v) => _update(g.copyWith(label: v)),
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldRequiredSection,
            ctrl: _sectionCtrl,
            tokens: t,
            hint: l10n.wbRequiredSectionHint,
            onChanged: (v) => _update(g.copyWith(requiredSection: v)),
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldFilePatterns,
            ctrl: _patternsCtrl,
            tokens: t,
            hint: l10n.wbFilePatternsHint,
            maxLines: 3,
            onChanged: (v) => _update(
              g.copyWith(
                filePatterns: v
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldDocsFolder,
            ctrl: _docsFolderCtrl,
            tokens: t,
            hint: l10n.wbDocsFolderHint,
            onChanged: (v) => _update(g.copyWith(docsFolder: v.trim())),
          ),
          const SizedBox(height: 8),
          _InspectorField(
            label: l10n.wbFieldSkippableFor,
            ctrl: _skippableCtrl,
            tokens: t,
            hint: l10n.wbSkippableForHint,
            onChanged: (v) => _update(
              g.copyWith(
                skippableFor: v
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: Colors.redAccent,
            ),
            label: Text(
              l10n.wbRemoveGate,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
            onPressed: () => widget.notifier.removeGate(widget.index),
          ),
        ],
      ),
    );
  }
}

// ── Gates strip ───────────────────────────────────────────────────────────────

class _GatesStrip extends StatelessWidget {
  const _GatesStrip({
    required this.draft,
    required this.selectedGate,
    required this.onSelect,
    required this.notifier,
    required this.tokens,
  });
  final WorkflowDraft draft;
  final int selectedGate;
  final void Function(int) onSelect;
  final WorkflowBuilderNotifier notifier;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: tokens.bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.wbGatesHeader,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tokens.fgMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: notifier.addGate,
                child: Icon(Icons.add_rounded, size: 14, color: tokens.accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(draft.gates.length, (i) {
              final g = draft.gates[i];
              final selected = selectedGate == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? tokens.accent.withValues(alpha: 0.15)
                        : tokens.bgAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? tokens.accent : tokens.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: selected ? tokens.accent : tokens.fgMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        g.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected ? tokens.accent : tokens.fgBright,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Library Picker ────────────────────────────────────────────────────────────

class _LibraryPicker extends StatelessWidget {
  const _LibraryPicker({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.icon,
    required this.color,
    required this.tokens,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final String? currentValue;
  final List<String> options;
  final IconData icon;
  final Color color;
  final OrchestraColorTokens tokens;
  final void Function(String) onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (currentValue != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                currentValue!,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded, size: 14, color: tokens.fgMuted),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    if (options.isEmpty) {
      return Text(
        l10n.wbNoItemsInstalled(label.toLowerCase()),
        style: TextStyle(fontSize: 11, color: tokens.fgMuted),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: l10n.wbAttachItem(label),
        labelStyle: TextStyle(fontSize: 12, color: tokens.fgMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      initialValue: null,
      hint: Text(
        l10n.wbSelectItem(label),
        style: TextStyle(fontSize: 12, color: tokens.fgMuted),
      ),
      items: options
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 6),
                  Text(s, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onPick(v);
      },
    );
  }
}

// ── YAML preview ─────────────────────────────────────────────────────────────

class _YamlPreview extends StatelessWidget {
  const _YamlPreview({required this.draft});
  final WorkflowDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final yaml = draft.toYaml();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border),
            ),
            child: SelectableText(
              yaml,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ),
        Positioned(
          top: 28,
          right: 28,
          child: IconButton(
            icon: Icon(Icons.copy_rounded, size: 16, color: tokens.fgMuted),
            tooltip: l10n.wbCopyYaml,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: yaml));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.wbYamlCopied)));
            },
          ),
        ),
      ],
    );
  }
}

// ── Export sheet ──────────────────────────────────────────────────────────────

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.draft});
  final WorkflowDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = ThemeTokens.of(context);
    final yaml = draft.toYaml();
    final packJson = draft.toPackJson(draft.name);
    final slug = draft.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                l10n.wbExportTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.fgBright,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.wbExportSubtitle,
                style: TextStyle(fontSize: 12, color: tokens.fgMuted),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _ExportFile(
                    filename: 'pack.json',
                    content: packJson,
                    icon: Icons.data_object_rounded,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 10),
                  _ExportFile(
                    filename: 'workflow/$slug.yaml',
                    content: yaml,
                    icon: Icons.account_tree_rounded,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.wbNextSteps,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _Step(l10n.wbStep1(slug), tokens),
                          _Step(l10n.wbStep2(slug), tokens),
                          _Step(l10n.wbStep3(slug), tokens),
                          _Step(l10n.wbStep4, tokens),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportFile extends StatelessWidget {
  const _ExportFile({
    required this.filename,
    required this.content,
    required this.icon,
    required this.tokens,
  });
  final String filename;
  final String content;
  final IconData icon;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgAlt,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: tokens.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: tokens.fgMuted),
                const SizedBox(width: 6),
                Text(
                  filename,
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.wbFileCopied(filename))),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: tokens.fgMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              content.length > 600
                  ? '${content.substring(0, 600)}\n...'
                  : content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: tokens.fgMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.text, this.tokens);
  final String text;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: tokens.fgMuted, height: 1.4),
    ),
  );
}

// ── Shared inspector widgets ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.tokens);
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: tokens.fgMuted,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _ValidationHint extends StatelessWidget {
  const _ValidationHint(this.message, this.tokens);
  final String message;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ),
      ],
    ),
  );
}

class _InspectorField extends StatelessWidget {
  const _InspectorField({
    required this.label,
    required this.ctrl,
    required this.tokens,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController ctrl;
  final OrchestraColorTokens tokens;
  final void Function(String) onChanged;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(fontSize: 12, color: tokens.fgBright),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 12, color: tokens.fgMuted),
        hintStyle: TextStyle(fontSize: 11, color: tokens.fgMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }
}

class _InspectorDropdown<T> extends StatelessWidget {
  const _InspectorDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.labelFor,
    required this.tokens,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelFor;
  final OrchestraColorTokens tokens;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: tokens.fgMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      items: items
          .map(
            (v) => DropdownMenuItem<T>(
              value: v,
              child: Text(
                labelFor(v),
                style: TextStyle(fontSize: 12, color: tokens.fgBright),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.tokens,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final OrchestraColorTokens tokens;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: tokens.fgMuted),
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: tokens.accent,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    ),
  );
}
