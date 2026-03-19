import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-entity color and icon overrides, persisted via SharedPreferences.
///
/// Keys are entity IDs (note IDs, project IDs, agent names, etc.).
/// Values are serialised as `{"color":"#RRGGBB","icon":12345}` where icon is
/// the Material icon codepoint.
class EntityCustomization {
  const EntityCustomization({this.color, this.iconCodePoint});

  final Color? color;
  final int? iconCodePoint;

  IconData? get icon =>
      iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : null;

  Map<String, dynamic> toJson() => {
        if (color != null) 'color': '#${color!.toARGB32().toRadixString(16).padLeft(8, '0')}',
        if (iconCodePoint != null) 'icon': iconCodePoint,
      };

  factory EntityCustomization.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json['color'] is String) {
      final hex = (json['color'] as String).replaceFirst('#', '');
      color = Color(int.parse(hex, radix: 16));
    }
    return EntityCustomization(
      color: color,
      iconCodePoint: json['icon'] as int?,
    );
  }

  EntityCustomization copyWith({Color? color, int? iconCodePoint}) {
    return EntityCustomization(
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}

/// Riverpod notifier that manages per-entity customizations.
///
/// State is a map of entity ID → [EntityCustomization].
class EntityCustomizationNotifier extends Notifier<Map<String, EntityCustomization>> {
  static const _prefsKey = 'entity_customizations';

  @override
  Map<String, EntityCustomization> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, EntityCustomization>{};
      for (final entry in decoded.entries) {
        map[entry.key] =
            EntityCustomization.fromJson(entry.value as Map<String, dynamic>);
      }
      state = map;
    } catch (_) {
      // Corrupted data — start fresh.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    for (final entry in state.entries) {
      encoded[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  /// Get the customization for an entity, or null.
  EntityCustomization? get(String entityId) => state[entityId];

  /// Set the color for an entity.
  Future<void> setColor(String entityId, Color color) async {
    final existing = state[entityId] ?? const EntityCustomization();
    state = {...state, entityId: existing.copyWith(color: color)};
    await _save();
  }

  /// Set the icon for an entity.
  Future<void> setIcon(String entityId, int iconCodePoint) async {
    final existing = state[entityId] ?? const EntityCustomization();
    state = {...state, entityId: existing.copyWith(iconCodePoint: iconCodePoint)};
    await _save();
  }
}

/// Global provider for entity customizations.
final entityCustomizationProvider =
    NotifierProvider<EntityCustomizationNotifier, Map<String, EntityCustomization>>(
  EntityCustomizationNotifier.new,
);
