import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/mcp/mcp_provider.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class WorkflowState {
  WorkflowState({
    required this.id,
    required this.label,
    this.terminal = false,
    this.activeWork = false,
    this.skillSlug,
    this.agentSlug,
  });

  String id;
  String label;
  bool terminal;
  bool activeWork;

  /// Optional skill attached to this phase (from .claude/skills/).
  String? skillSlug;

  /// Optional agent attached to this phase (from .claude/agents/).
  String? agentSlug;

  WorkflowState copyWith({
    String? id,
    String? label,
    bool? terminal,
    bool? activeWork,
    String? skillSlug,
    String? agentSlug,
    bool clearSkill = false,
    bool clearAgent = false,
  }) => WorkflowState(
    id: id ?? this.id,
    label: label ?? this.label,
    terminal: terminal ?? this.terminal,
    activeWork: activeWork ?? this.activeWork,
    skillSlug: clearSkill ? null : (skillSlug ?? this.skillSlug),
    agentSlug: clearAgent ? null : (agentSlug ?? this.agentSlug),
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'terminal': terminal,
    'active_work': activeWork,
    // skill/agent are metadata stored in the state map for UI round-trips
    if (skillSlug != null) 'skill': skillSlug,
    if (agentSlug != null) 'agent': agentSlug,
  };

  factory WorkflowState.fromJson(String id, Map<String, dynamic> json) =>
      WorkflowState(
        id: id,
        label: json['label'] as String? ?? id,
        terminal: json['terminal'] as bool? ?? false,
        activeWork: json['active_work'] as bool? ?? false,
        skillSlug: json['skill'] as String?,
        agentSlug: json['agent'] as String?,
      );
}

class WorkflowTransition {
  WorkflowTransition({required this.from, required this.to, this.gate});

  String from;
  String to;
  String? gate;

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    if (gate != null && gate!.isNotEmpty) 'gate': gate,
  };

  factory WorkflowTransition.fromJson(Map<String, dynamic> json) =>
      WorkflowTransition(
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        gate: json['gate'] as String?,
      );
}

class WorkflowGate {
  WorkflowGate({
    required this.id,
    required this.label,
    this.requiredSection = '',
    this.filePatterns = const [],
    this.docsFolder = '',
    this.skippableFor = const [],
  });

  String id;
  String label;
  String requiredSection;
  List<String> filePatterns;
  String docsFolder;
  List<String> skippableFor;

  WorkflowGate copyWith({
    String? id,
    String? label,
    String? requiredSection,
    List<String>? filePatterns,
    String? docsFolder,
    List<String>? skippableFor,
  }) => WorkflowGate(
    id: id ?? this.id,
    label: label ?? this.label,
    requiredSection: requiredSection ?? this.requiredSection,
    filePatterns: filePatterns ?? this.filePatterns,
    docsFolder: docsFolder ?? this.docsFolder,
    skippableFor: skippableFor ?? this.skippableFor,
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'required_section': requiredSection,
    'file_patterns': filePatterns,
    if (docsFolder.isNotEmpty) 'docs_folder': docsFolder,
    'skippable_for': skippableFor,
  };

  factory WorkflowGate.fromJson(String id, Map<String, dynamic> json) =>
      WorkflowGate(
        id: id,
        label: json['label'] as String? ?? id,
        requiredSection: json['required_section'] as String? ?? '',
        filePatterns:
            (json['file_patterns'] as List<dynamic>?)?.cast<String>() ?? [],
        docsFolder: json['docs_folder'] as String? ?? '',
        skippableFor:
            (json['skippable_for'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

class WorkflowDraft {
  WorkflowDraft({
    this.id,
    this.projectId = '',
    this.name = '',
    this.description = '',
    this.initialState = '',
    this.isDefault = true,
    List<WorkflowState>? states,
    List<WorkflowTransition>? transitions,
    List<WorkflowGate>? gates,
  }) : states = states ?? [],
       transitions = transitions ?? [],
       gates = gates ?? [];

  final String? id; // null = new workflow
  String projectId;
  String name;
  String description;
  String initialState;
  bool isDefault;
  List<WorkflowState> states;
  List<WorkflowTransition> transitions;
  List<WorkflowGate> gates;

  bool get hasTerminalState => states.any((s) => s.terminal);
  bool get initialStateValid =>
      initialState.isNotEmpty && states.any((s) => s.id == initialState);

  WorkflowDraft copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    String? initialState,
    bool? isDefault,
    List<WorkflowState>? states,
    List<WorkflowTransition>? transitions,
    List<WorkflowGate>? gates,
  }) => WorkflowDraft(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    description: description ?? this.description,
    initialState: initialState ?? this.initialState,
    isDefault: isDefault ?? this.isDefault,
    states: states ?? this.states,
    transitions: transitions ?? this.transitions,
    gates: gates ?? this.gates,
  );

  /// Build the states map for MCP create_workflow / update_workflow.
  Map<String, dynamic> statesMap() => {
    for (final s in states) s.id: s.toJson(),
  };

  /// Build the transitions list for MCP.
  List<Map<String, dynamic>> transitionsList() =>
      transitions.map((t) => t.toJson()).toList();

  /// Build the gates map for MCP.
  Map<String, dynamic> gatesMap() => {for (final g in gates) g.id: g.toJson()};

  /// Serialize to YAML string for pack export.
  String toYaml() {
    final buf = StringBuffer();
    buf.writeln('name: $name');
    if (description.isNotEmpty) buf.writeln('description: $description');
    buf.writeln('initial_state: $initialState');
    buf.writeln();
    buf.writeln('states:');
    for (final s in states) {
      buf.writeln('  ${s.id}:');
      buf.writeln('    label: ${s.label}');
      buf.writeln('    terminal: ${s.terminal}');
      buf.writeln('    active_work: ${s.activeWork}');
    }
    if (transitions.isNotEmpty) {
      buf.writeln();
      buf.writeln('transitions:');
      for (final t in transitions) {
        buf.writeln('  - from: ${t.from}');
        buf.writeln('    to: ${t.to}');
        if (t.gate != null && t.gate!.isNotEmpty) {
          buf.writeln('    gate: ${t.gate}');
        }
      }
    }
    if (gates.isNotEmpty) {
      buf.writeln();
      buf.writeln('gates:');
      for (final g in gates) {
        buf.writeln('  ${g.id}:');
        buf.writeln('    label: ${g.label}');
        buf.writeln('    required_section: ${g.requiredSection}');
        if (g.filePatterns.isNotEmpty) {
          buf.writeln('    file_patterns:');
          for (final p in g.filePatterns) {
            buf.writeln('      - $p');
          }
        } else {
          buf.writeln('    file_patterns: []');
        }
        if (g.docsFolder.isNotEmpty) {
          buf.writeln('    docs_folder: ${g.docsFolder}');
        }
        if (g.skippableFor.isNotEmpty) {
          buf.writeln('    skippable_for:');
          for (final k in g.skippableFor) {
            buf.writeln('      - $k');
          }
        } else {
          buf.writeln('    skippable_for: []');
        }
      }
    }
    return buf.toString();
  }

  /// Build pack.json content for export.
  String toPackJson(String packName) {
    final slug = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
    final skillNames = states
        .where((s) => s.activeWork)
        .map((s) => '$slug-${s.id}')
        .toList();
    final map = {
      'name': 'github.com/your-org/pack-$slug',
      'description': description.isNotEmpty
          ? description
          : 'Custom $name workflow',
      'version': '0.1.0',
      'type': 'pack',
      'license': 'MIT',
      'stacks': ['*'],
      'contents': {
        'skills': skillNames,
        'agents': <String>[],
        'hooks': <String>[],
        'workflows': ['$slug.yaml'],
      },
      'tags': ['workflow', slug],
    };
    const enc = JsonEncoder.withIndent('    ');
    return enc.convert(map);
  }

  factory WorkflowDraft.fromMcpResult(Map<String, dynamic> json) {
    final statesRaw = json['states'] as Map<String, dynamic>? ?? {};
    final transRaw = json['transitions'] as List<dynamic>? ?? [];
    final gatesRaw = json['gates'] as Map<String, dynamic>? ?? {};
    return WorkflowDraft(
      id: json['id'] as String?,
      projectId: json['project_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      initialState: json['initial_state'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      states: statesRaw.entries
          .map(
            (e) =>
                WorkflowState.fromJson(e.key, e.value as Map<String, dynamic>),
          )
          .toList(),
      transitions: transRaw
          .map((e) => WorkflowTransition.fromJson(e as Map<String, dynamic>))
          .toList(),
      gates: gatesRaw.entries
          .map(
            (e) =>
                WorkflowGate.fromJson(e.key, e.value as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class WorkflowBuilderNotifier extends Notifier<WorkflowDraft> {
  @override
  WorkflowDraft build() => WorkflowDraft(
    name: '',
    states: [
      WorkflowState(id: 'todo', label: 'To Do'),
      WorkflowState(id: 'in-progress', label: 'In Progress', activeWork: true),
      WorkflowState(id: 'done', label: 'Done', terminal: true),
    ],
    transitions: [
      WorkflowTransition(from: 'todo', to: 'in-progress'),
      WorkflowTransition(from: 'in-progress', to: 'done'),
    ],
    initialState: 'todo',
  );

  void loadFromMcp(Map<String, dynamic> json) {
    state = WorkflowDraft.fromMcpResult(json);
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setProjectId(String v) => state = state.copyWith(projectId: v);
  void setInitialState(String id) => state = state.copyWith(initialState: id);
  void setIsDefault(bool v) => state = state.copyWith(isDefault: v);

  // ── States ──

  void addState() {
    final id = 'state-${state.states.length + 1}';
    state = state.copyWith(
      states: [
        ...state.states,
        WorkflowState(id: id, label: 'New State'),
      ],
    );
  }

  void updateState(int index, WorkflowState updated) {
    final list = [...state.states];
    // If id changed, update all transitions + gates referencing old id.
    final oldId = list[index].id;
    list[index] = updated;
    var transitions = state.transitions;
    if (oldId != updated.id) {
      transitions = transitions
          .map(
            (t) => WorkflowTransition(
              from: t.from == oldId ? updated.id : t.from,
              to: t.to == oldId ? updated.id : t.to,
              gate: t.gate,
            ),
          )
          .toList();
    }
    state = state.copyWith(
      states: list,
      transitions: transitions,
      initialState: state.initialState == oldId
          ? updated.id
          : state.initialState,
    );
  }

  void removeState(int index) {
    final id = state.states[index].id;
    state = state.copyWith(
      states: [...state.states]..removeAt(index),
      transitions: state.transitions
          .where((t) => t.from != id && t.to != id)
          .toList(),
      initialState: state.initialState == id ? '' : state.initialState,
    );
  }

  // ── Transitions ──

  void addTransition() {
    if (state.states.length < 2) return;
    state = state.copyWith(
      transitions: [
        ...state.transitions,
        WorkflowTransition(
          from: state.states.first.id,
          to: state.states.last.id,
        ),
      ],
    );
  }

  void updateTransition(int index, WorkflowTransition updated) {
    final list = [...state.transitions];
    list[index] = updated;
    state = state.copyWith(transitions: list);
  }

  void removeTransition(int index) {
    state = state.copyWith(
      transitions: [...state.transitions]..removeAt(index),
    );
  }

  // ── Gates ──

  void addGate() {
    final id = 'gate_${state.gates.length + 1}';
    state = state.copyWith(
      gates: [
        ...state.gates,
        WorkflowGate(id: id, label: 'New Gate'),
      ],
    );
  }

  void updateGate(int index, WorkflowGate updated) {
    final list = [...state.gates];
    final oldId = list[index].id;
    list[index] = updated;
    // Update any transitions referencing this gate.
    var transitions = state.transitions;
    if (oldId != updated.id) {
      transitions = transitions
          .map(
            (t) => WorkflowTransition(
              from: t.from,
              to: t.to,
              gate: t.gate == oldId ? updated.id : t.gate,
            ),
          )
          .toList();
    }
    state = state.copyWith(gates: list, transitions: transitions);
  }

  void removeGate(int index) {
    final id = state.gates[index].id;
    state = state.copyWith(
      gates: [...state.gates]..removeAt(index),
      transitions: state.transitions
          .map(
            (t) => WorkflowTransition(
              from: t.from,
              to: t.to,
              gate: t.gate == id ? null : t.gate,
            ),
          )
          .toList(),
    );
  }

  // ── MCP save ──

  Future<String?> save() async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final draft = state;
    if (draft.id == null) {
      final result = await mcp.callTool('create_workflow', {
        if (draft.projectId.isNotEmpty) 'project_id': draft.projectId,
        'name': draft.name,
        if (draft.description.isNotEmpty) 'description': draft.description,
        'initial_state': draft.initialState,
        'states': draft.statesMap(),
        'transitions': draft.transitionsList(),
        'gates': draft.gatesMap(),
        'is_default': draft.isDefault,
      });
      return result['workflow_id'] as String?;
    } else {
      await mcp.callTool('update_workflow', {
        'workflow_id': draft.id,
        'name': draft.name,
        if (draft.description.isNotEmpty) 'description': draft.description,
        'initial_state': draft.initialState,
        'states': draft.statesMap(),
        'transitions': draft.transitionsList(),
        'gates': draft.gatesMap(),
        'is_default': draft.isDefault,
      });
      return draft.id;
    }
  }

  Future<void> loadWorkflow(String workflowId) async {
    final mcp = await ref.read(mcpConnectionProvider.future);
    final result = await mcp.callTool('get_workflow', {
      'workflow_id': workflowId,
    });
    loadFromMcp(result);
  }
}

final workflowBuilderProvider =
    NotifierProvider<WorkflowBuilderNotifier, WorkflowDraft>(
      WorkflowBuilderNotifier.new,
    );
