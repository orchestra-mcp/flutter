import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-screen selection state — stores selected entity IDs.

class SelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String id) {
    final copy = Set<String>.from(state);
    if (copy.contains(id)) {
      copy.remove(id);
    } else {
      copy.add(id);
    }
    state = copy;
  }

  void clear() => state = {};

  void selectAll(Iterable<String> ids) => state = ids.toSet();
}

final notesSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final agentsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final skillsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final workflowsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final docsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final delegationsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final projectsSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);
final terminalSelectionProvider =
    NotifierProvider<SelectionNotifier, Set<String>>(SelectionNotifier.new);

/// Extension for toggling an ID in a set (returns a new set).
extension SelectionToggle on Set<String> {
  Set<String> toggled(String id) {
    final copy = Set<String>.from(this);
    if (copy.contains(id)) {
      copy.remove(id);
    } else {
      copy.add(id);
    }
    return copy;
  }
}
