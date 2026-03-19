import 'package:flutter/material.dart';

/// A caffeine drink item with multi-language title support.
///
/// The [title] field stores a JSON map of locale → name, e.g.:
/// ```json
/// {"en": "Espresso", "ar": "إسبريسو", "fr": "Espresso"}
/// ```
///
/// When fetched from the admin panel API, items come with translated titles.
/// The local seeder provides preset data for offline/first-launch use.
class CaffeineItem {
  const CaffeineItem({
    required this.id,
    required this.title,
    required this.mg,
    required this.icon,
    this.isSugarBased = false,
    this.sortOrder = 0,
  });

  final String id;

  /// JSON map: `{"en": "Espresso", "ar": "إسبريسو"}`.
  /// When from admin panel, this column stores JSONB.
  final Map<String, String> title;

  /// Caffeine content in milligrams.
  final int mg;

  /// Material icon code point or SF Symbol name.
  final IconData icon;

  /// Whether this drink contains added sugar (e.g., Red Bull, energy drinks).
  final bool isSugarBased;

  /// Display order in the list.
  final int sortOrder;

  /// Resolve the title for the given locale, falling back to English.
  String localizedTitle(String locale) =>
      title[locale] ?? title['en'] ?? title.values.first;

  /// Create from API/database JSON row.
  factory CaffeineItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final Map<String, String> titleMap;
    if (rawTitle is Map) {
      titleMap = rawTitle.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (rawTitle is String) {
      titleMap = {'en': rawTitle};
    } else {
      titleMap = {'en': 'Unknown'};
    }

    return CaffeineItem(
      id: json['id']?.toString() ?? '',
      title: titleMap,
      mg: (json['mg'] as num?)?.toInt() ?? 0,
      icon: Icons.coffee_rounded,
      isSugarBased:
          json['is_sugar_based'] == true || json['is_sugar_based'] == 1,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mg': mg,
    'is_sugar_based': isSugarBased,
    'sort_order': sortOrder,
  };
}

/// Preset caffeine items — seeds the local database on first launch.
/// These match the admin panel defaults and can be overridden via API sync.
const caffeineItemPresets = <CaffeineItem>[
  CaffeineItem(
    id: 'espresso',
    title: {'en': 'Espresso', 'ar': 'إسبريسو'},
    mg: 63,
    icon: Icons.coffee_rounded,
    sortOrder: 0,
  ),
  CaffeineItem(
    id: 'black_coffee',
    title: {'en': 'Black Coffee', 'ar': 'قهوة سوداء'},
    mg: 95,
    icon: Icons.local_cafe_rounded,
    sortOrder: 1,
  ),
  CaffeineItem(
    id: 'cold_brew',
    title: {'en': 'Cold Brew', 'ar': 'كولد برو'},
    mg: 200,
    icon: Icons.water_rounded,
    sortOrder: 2,
  ),
  CaffeineItem(
    id: 'matcha',
    title: {'en': 'Matcha', 'ar': 'ماتشا'},
    mg: 70,
    icon: Icons.eco_rounded,
    sortOrder: 3,
  ),
  CaffeineItem(
    id: 'green_tea',
    title: {'en': 'Green Tea', 'ar': 'شاي أخضر'},
    mg: 28,
    icon: Icons.emoji_nature_rounded,
    sortOrder: 4,
  ),
  CaffeineItem(
    id: 'red_bull',
    title: {'en': 'Red Bull', 'ar': 'ريد بول'},
    mg: 80,
    icon: Icons.bolt_rounded,
    isSugarBased: true,
    sortOrder: 5,
  ),
  CaffeineItem(
    id: 'other',
    title: {'en': 'Other', 'ar': 'أخرى'},
    mg: 50,
    icon: Icons.add_circle_outline_rounded,
    sortOrder: 6,
  ),
];
