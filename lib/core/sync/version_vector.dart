/// Version vector implementation for causal ordering of distributed changes.
///
/// Each node (client device) maintains a counter. By comparing vectors we
/// can determine whether two changes are causally ordered or concurrent.
class VersionVector {
  const VersionVector(this._clocks);

  /// Create an empty version vector (all counters at zero).
  factory VersionVector.empty() => const VersionVector({});

  /// Internal map of nodeId -> logical counter.
  final Map<String, int> _clocks;

  // ── Accessors ──────────────────────────────────────────────────────────

  /// Get the counter for a specific node. Returns 0 if the node is unknown.
  int operator [](String nodeId) => _clocks[nodeId] ?? 0;

  /// All node IDs that have been observed.
  Set<String> get nodes => _clocks.keys.toSet();

  /// Whether this vector has no entries.
  bool get isEmpty => _clocks.isEmpty;

  /// The number of distinct nodes tracked.
  int get length => _clocks.length;

  // ── Operations ─────────────────────────────────────────────────────────

  /// Increment the counter for [nodeId] and return a new vector.
  VersionVector increment(String nodeId) {
    final updated = Map<String, int>.from(_clocks);
    updated[nodeId] = (updated[nodeId] ?? 0) + 1;
    return VersionVector(updated);
  }

  /// Merge two version vectors by taking the max of each counter.
  /// Returns a new vector that dominates both inputs.
  VersionVector merge(VersionVector other) {
    final merged = Map<String, int>.from(_clocks);
    for (final entry in other._clocks.entries) {
      final current = merged[entry.key] ?? 0;
      if (entry.value > current) {
        merged[entry.key] = entry.value;
      }
    }
    return VersionVector(merged);
  }

  // ── Ordering ───────────────────────────────────────────────────────────

  /// Returns `true` if this vector causally happens-before [other].
  ///
  /// Formally: for every node N, `this[N] <= other[N]` and there exists
  /// at least one node M where `this[M] < other[M]`.
  bool happensBefore(VersionVector other) {
    bool strictlyLess = false;
    // Check all nodes in this vector.
    for (final node in _clocks.keys) {
      final mine = _clocks[node] ?? 0;
      final theirs = other._clocks[node] ?? 0;
      if (mine > theirs) return false;
      if (mine < theirs) strictlyLess = true;
    }
    // Check nodes only in other.
    for (final node in other._clocks.keys) {
      if (!_clocks.containsKey(node)) {
        final theirs = other._clocks[node] ?? 0;
        if (theirs > 0) strictlyLess = true;
      }
    }
    return strictlyLess;
  }

  /// Returns `true` if the two vectors are concurrent (neither causally
  /// precedes the other).
  bool concurrent(VersionVector other) =>
      !happensBefore(other) && !other.happensBefore(this) && this != other;

  /// Returns `true` if this vector dominates (happens-after) [other].
  bool happensAfter(VersionVector other) => other.happensBefore(this);

  // ── Equality ───────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VersionVector) return false;
    // Gather all nodes from both vectors.
    final allNodes = {..._clocks.keys, ...other._clocks.keys};
    for (final node in allNodes) {
      if ((_clocks[node] ?? 0) != (other._clocks[node] ?? 0)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll(_clocks.entries.map((e) => Object.hash(e.key, e.value)));

  // ── Serialization ──────────────────────────────────────────────────────

  /// Serialize to a JSON-compatible map: `{ "nodeId": counter, ... }`.
  Map<String, dynamic> toJson() =>
      _clocks.map((key, value) => MapEntry(key, value));

  /// Deserialize from a JSON map.
  factory VersionVector.fromJson(Map<String, dynamic> json) {
    final clocks = <String, int>{};
    for (final entry in json.entries) {
      clocks[entry.key] = (entry.value as num).toInt();
    }
    return VersionVector(clocks);
  }

  @override
  String toString() {
    final entries = _clocks.entries.map((e) => '${e.key}:${e.value}');
    return 'VV{${entries.join(', ')}}';
  }
}
