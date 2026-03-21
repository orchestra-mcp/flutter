import 'package:flutter/material.dart';

/// A water/hydration item with multi-language title support.
///
/// The [title] field stores a JSON map of locale -> name, e.g.:
/// ```json
/// {"en": "Small Glass", "ar": "\u0643\u0648\u0628 \u0635\u063a\u064a\u0631"}
/// ```
///
/// When fetched from the admin panel API, items come with translated titles.
/// The local seeder provides preset data for offline/first-launch use.
class HydrationItem {
  const HydrationItem({
    required this.id,
    required this.title,
    required this.ml,
    required this.icon,
    this.sortOrder = 0,
  });

  final String id;

  /// JSON map: `{"en": "Small Glass", "ar": "\u0643\u0648\u0628 \u0635\u063a\u064a\u0631"}`.
  /// When from admin panel, this column stores JSONB.
  final Map<String, String> title;

  /// Volume in millilitres.
  final int ml;

  /// Material icon code point or SF Symbol name.
  final IconData icon;

  /// Display order in the list.
  final int sortOrder;

  /// Resolve the title for the given locale, falling back to English.
  String localizedTitle(String locale) =>
      title[locale] ?? title['en'] ?? title.values.first;

  /// Create from API/database JSON row.
  factory HydrationItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final Map<String, String> titleMap;
    if (rawTitle is Map) {
      titleMap = rawTitle.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (rawTitle is String) {
      titleMap = {'en': rawTitle};
    } else {
      titleMap = {'en': 'Unknown'};
    }

    return HydrationItem(
      id: json['id']?.toString() ?? '',
      title: titleMap,
      ml: (json['ml'] as num?)?.toInt() ?? 0,
      icon: Icons.water_drop_rounded,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'ml': ml,
    'sort_order': sortOrder,
  };
}

/// Preset hydration items -- seeds the local database on first launch.
/// These match the admin panel defaults and can be overridden via API sync.
const hydrationItemPresets = <HydrationItem>[
  HydrationItem(
    id: 'small_glass',
    title: {
      'en': 'Small Glass',
      'ar': '\u0643\u0648\u0628 \u0635\u063a\u064a\u0631',
    },
    ml: 150,
    icon: Icons.local_drink_rounded,
    sortOrder: 0,
  ),
  HydrationItem(
    id: 'medium_glass',
    title: {
      'en': 'Medium Glass',
      'ar': '\u0643\u0648\u0628 \u0645\u062a\u0648\u0633\u0637',
    },
    ml: 250,
    icon: Icons.water_drop_rounded,
    sortOrder: 1,
  ),
  HydrationItem(
    id: 'large_glass',
    title: {
      'en': 'Large Glass',
      'ar': '\u0643\u0648\u0628 \u0643\u0628\u064a\u0631',
    },
    ml: 350,
    icon: Icons.water_drop_rounded,
    sortOrder: 2,
  ),
  HydrationItem(
    id: 'bottle',
    title: {'en': 'Bottle', 'ar': '\u0632\u062c\u0627\u062c\u0629'},
    ml: 500,
    icon: Icons.water_rounded,
    sortOrder: 3,
  ),
  HydrationItem(
    id: 'large_bottle',
    title: {
      'en': 'Large Bottle',
      'ar': '\u0632\u062c\u0627\u062c\u0629 \u0643\u0628\u064a\u0631\u0629',
    },
    ml: 750,
    icon: Icons.water_rounded,
    sortOrder: 4,
  ),
];
