import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed pin state for API-only entities
/// (agents, skills, workflows, docs, delegations).
///
/// Notes and Projects use their own repository/ORM pinned field instead.
class PinStoreNotifier extends Notifier<Set<String>> {
  PinStoreNotifier(this._key);

  final String _key;

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key);
    if (ids != null) {
      state = ids.toSet();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  bool isPinned(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final copy = Set<String>.from(state);
    if (copy.contains(id)) {
      copy.remove(id);
    } else {
      copy.add(id);
    }
    state = copy;
    await _save();
  }

  Future<void> pin(String id) async {
    if (!state.contains(id)) {
      state = {...state, id};
      await _save();
    }
  }

  Future<void> unpin(String id) async {
    if (state.contains(id)) {
      final copy = Set<String>.from(state)..remove(id);
      state = copy;
      await _save();
    }
  }
}

/// One provider per entity type.
final agentsPinProvider = NotifierProvider<PinStoreNotifier, Set<String>>(
  () => PinStoreNotifier('pinned_agents'),
);

final skillsPinProvider = NotifierProvider<PinStoreNotifier, Set<String>>(
  () => PinStoreNotifier('pinned_skills'),
);

final workflowsPinProvider = NotifierProvider<PinStoreNotifier, Set<String>>(
  () => PinStoreNotifier('pinned_workflows'),
);

final docsPinProvider = NotifierProvider<PinStoreNotifier, Set<String>>(
  () => PinStoreNotifier('pinned_docs'),
);

final delegationsPinProvider = NotifierProvider<PinStoreNotifier, Set<String>>(
  () => PinStoreNotifier('pinned_delegations'),
);
