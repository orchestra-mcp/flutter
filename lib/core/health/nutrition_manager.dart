import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Food Registry
// ---------------------------------------------------------------------------

enum FoodCategory { protein, carb, fat, drink, snack }

enum TriggerCondition { ibs, gerd, gout, fattyLiver }

class FoodItem {
  const FoodItem({
    this.id = '',
    required this.title,
    required this.category,
    this.triggerConditions = const [],
    this.sortOrder = 0,
  });

  final String id;

  /// JSON map: `{"en": "Grilled Chicken", "ar": "دجاج مشوي"}`.
  /// When from admin panel, this column stores JSONB.
  final Map<String, String> title;

  final FoodCategory category;
  final List<TriggerCondition> triggerConditions;

  /// Display order in the list.
  final int sortOrder;

  bool get isSafe => triggerConditions.isEmpty;

  /// Resolve the title for the given locale, falling back to English.
  String localizedName(String locale) =>
      title[locale] ?? title['en'] ?? title.values.first;

  /// Legacy getter for backward compatibility with code using `.name`.
  String get name => title['en'] ?? title.values.first;

  /// Create from API/database JSON row.
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final Map<String, String> titleMap;
    if (rawTitle is Map) {
      titleMap = rawTitle.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (rawTitle is String) {
      titleMap = {'en': rawTitle};
    } else {
      titleMap = {'en': 'Unknown'};
    }

    final rawTriggers = json['trigger_conditions'] as List<dynamic>? ?? [];
    final triggers = rawTriggers.map((t) {
      final s = t.toString().toLowerCase();
      return switch (s) {
        'ibs' => TriggerCondition.ibs,
        'gerd' => TriggerCondition.gerd,
        'gout' => TriggerCondition.gout,
        _ => TriggerCondition.fattyLiver,
      };
    }).toList();

    final rawCat = (json['category'] as String?) ?? 'snack';
    final category = switch (rawCat) {
      'protein' => FoodCategory.protein,
      'carb' => FoodCategory.carb,
      'fat' => FoodCategory.fat,
      'drink' => FoodCategory.drink,
      _ => FoodCategory.snack,
    };

    final id = json['id']?.toString() ?? '';
    final sortOrder = (json['sort_order'] as num?)?.toInt() ?? 0;

    return FoodItem(
      id: id,
      title: titleMap,
      category: category,
      triggerConditions: triggers,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'trigger_conditions': triggerConditions.map((t) => t.name).toList(),
    'sort_order': sortOrder,
  };
}

class FoodRegistry {
  FoodRegistry._();

  // TODO: Fetch from admin panel API with JSON title column.
  // Preset seeder data with en/ar translations.
  static const allFoods = <FoodItem>[
    // IBS / GERD triggers
    FoodItem(
      id: 'whole_egg',
      title: {'en': 'Whole Egg', 'ar': 'بيضة كاملة'},
      category: FoodCategory.protein,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 0,
    ),
    FoodItem(
      id: 'falafel',
      title: {'en': 'Falafel', 'ar': 'فلافل'},
      category: FoodCategory.snack,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 1,
    ),
    FoodItem(
      id: 'deep_fried',
      title: {'en': 'Deep Fried', 'ar': 'مقلي'},
      category: FoodCategory.snack,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 2,
    ),
    FoodItem(
      id: 'raw_onion',
      title: {'en': 'Raw Onion', 'ar': 'بصل نيء'},
      category: FoodCategory.snack,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 3,
    ),
    FoodItem(
      id: 'raw_garlic',
      title: {'en': 'Raw Garlic', 'ar': 'ثوم نيء'},
      category: FoodCategory.snack,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 4,
    ),
    FoodItem(
      id: 'cheddar_cheese',
      title: {'en': 'Cheddar Cheese', 'ar': 'جبنة شيدر'},
      category: FoodCategory.fat,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 5,
    ),
    FoodItem(
      id: 'yellow_cheese',
      title: {'en': 'Yellow Cheese', 'ar': 'جبنة صفراء'},
      category: FoodCategory.fat,
      triggerConditions: [TriggerCondition.ibs, TriggerCondition.gerd],
      sortOrder: 6,
    ),
    // Gout triggers
    FoodItem(
      id: 'red_meat',
      title: {'en': 'Red Meat', 'ar': 'لحم أحمر'},
      category: FoodCategory.protein,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 7,
    ),
    FoodItem(
      id: 'liver',
      title: {'en': 'Liver', 'ar': 'كبدة'},
      category: FoodCategory.protein,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 8,
    ),
    FoodItem(
      id: 'duck',
      title: {'en': 'Duck', 'ar': 'بط'},
      category: FoodCategory.protein,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 9,
    ),
    FoodItem(
      id: 'beans',
      title: {'en': 'Beans', 'ar': 'فاصوليا'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 10,
    ),
    FoodItem(
      id: 'lentils',
      title: {'en': 'Lentils', 'ar': 'عدس'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 11,
    ),
    FoodItem(
      id: 'legumes',
      title: {'en': 'Legumes', 'ar': 'بقوليات'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.gout],
      sortOrder: 12,
    ),
    // Fatty liver triggers
    FoodItem(
      id: 'refined_sugar',
      title: {'en': 'Refined Sugar', 'ar': 'سكر مكرر'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 13,
    ),
    FoodItem(
      id: 'honey',
      title: {'en': 'Honey', 'ar': 'عسل'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 14,
    ),
    FoodItem(
      id: 'nutella',
      title: {'en': 'Nutella', 'ar': 'نوتيلا'},
      category: FoodCategory.fat,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 15,
    ),
    FoodItem(
      id: 'jam',
      title: {'en': 'Jam', 'ar': 'مربى'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 16,
    ),
    FoodItem(
      id: 'white_flour',
      title: {'en': 'White Flour', 'ar': 'دقيق أبيض'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 17,
    ),
    FoodItem(
      id: 'mixed_carbs',
      title: {'en': 'Mixed Carbs', 'ar': 'كربوهيدرات مختلطة'},
      category: FoodCategory.carb,
      triggerConditions: [TriggerCondition.fattyLiver],
      sortOrder: 18,
    ),
    // Safe foods
    FoodItem(
      id: 'grilled_chicken',
      title: {'en': 'Grilled Chicken', 'ar': 'دجاج مشوي'},
      category: FoodCategory.protein,
      sortOrder: 19,
    ),
    FoodItem(
      id: 'white_fish',
      title: {'en': 'White Fish', 'ar': 'سمك أبيض'},
      category: FoodCategory.protein,
      sortOrder: 20,
    ),
    FoodItem(
      id: 'cottage_cheese',
      title: {'en': 'Cottage Cheese', 'ar': 'جبنة قريش'},
      category: FoodCategory.protein,
      sortOrder: 21,
    ),
    FoodItem(
      id: 'greek_yogurt',
      title: {'en': 'Greek Yogurt', 'ar': 'زبادي يوناني'},
      category: FoodCategory.protein,
      sortOrder: 22,
    ),
    FoodItem(
      id: 'oats',
      title: {'en': 'Oats', 'ar': 'شوفان'},
      category: FoodCategory.carb,
      sortOrder: 23,
    ),
    FoodItem(
      id: 'whole_wheat',
      title: {'en': 'Whole Wheat', 'ar': 'قمح كامل'},
      category: FoodCategory.carb,
      sortOrder: 24,
    ),
    FoodItem(
      id: 'rice',
      title: {'en': 'Rice', 'ar': 'أرز'},
      category: FoodCategory.carb,
      sortOrder: 25,
    ),
    FoodItem(
      id: 'olive_oil',
      title: {'en': 'Olive Oil', 'ar': 'زيت زيتون'},
      category: FoodCategory.fat,
      sortOrder: 26,
    ),
    FoodItem(
      id: 'avocado',
      title: {'en': 'Avocado', 'ar': 'أفوكادو'},
      category: FoodCategory.fat,
      sortOrder: 27,
    ),
  ];

  static List<FoodItem> get safeFoods =>
      allFoods.where((f) => f.isSafe).toList();

  static FoodItem? findByName(String name) {
    try {
      return allFoods.firstWhere(
        (f) => f.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Nutrition Manager
// ---------------------------------------------------------------------------

enum NutritionStatus { allSafe, warning, critical }

class NutritionEntry {
  const NutritionEntry({
    required this.id,
    required this.food,
    required this.portionSpoons,
    required this.timestamp,
  });
  final String id;
  final FoodItem food;
  final double portionSpoons;
  final DateTime timestamp;
}

class NutritionState {
  const NutritionState({
    this.entries = const [],
    this.dailyGoalKcal = 2000,
    this.isLoading = false,
    this.error,
  });

  final List<NutritionEntry> entries;
  final int dailyGoalKcal;
  final bool isLoading;
  final String? error;

  List<NutritionEntry> get todayEntries {
    final today = DateTime.now();
    return entries
        .where(
          (e) =>
              e.timestamp.year == today.year &&
              e.timestamp.month == today.month &&
              e.timestamp.day == today.day,
        )
        .toList();
  }

  double get safetyScore {
    final today = todayEntries;
    if (today.isEmpty) return 100;
    final safe = today.where((e) => e.food.isSafe).length;
    return (safe / today.length) * 100;
  }

  NutritionStatus get status {
    final s = safetyScore;
    if (s >= 75) return NutritionStatus.allSafe;
    if (s >= 50) return NutritionStatus.warning;
    return NutritionStatus.critical;
  }

  bool get maxRiceRuleTriggered {
    return todayEntries.any(
      (e) => e.food.name == 'Rice' && e.portionSpoons > 5,
    );
  }

  NutritionState copyWith({
    List<NutritionEntry>? entries,
    int? dailyGoalKcal,
    bool? isLoading,
    String? error,
  }) {
    return NutritionState(
      entries: entries ?? this.entries,
      dailyGoalKcal: dailyGoalKcal ?? this.dailyGoalKcal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — PowerSync-backed
// ---------------------------------------------------------------------------

class NutritionNotifier extends Notifier<NutritionState> {
  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  NutritionState build() {
    // Watch PowerSync for today's nutrition data.
    _watchNutrition();
    return const NutritionState(isLoading: true);
  }

  void _watchNutrition() {
    final stream = _db.watch('SELECT * FROM meal_logs ORDER BY created_at ASC');

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final now = DateTime.now();
      final entries = <NutritionEntry>[];
      for (final row in results) {
        final loggedStr =
            (row['logged_at'] as String?) ??
            (row['created_at'] as String?) ??
            '';
        final ts = DateTime.tryParse(loggedStr)?.toLocal();
        if (ts == null) continue;
        if (ts.year != now.year || ts.month != now.month || ts.day != now.day) {
          continue;
        }

        final foodName = row['name'] as String? ?? 'Unknown';
        final food =
            FoodRegistry.findByName(foodName) ??
            FoodItem(title: {'en': foodName}, category: FoodCategory.snack);
        entries.add(
          NutritionEntry(
            id: row['id'] as String? ?? '',
            food: food,
            portionSpoons: 1.0,
            timestamp: ts,
          ),
        );
      }

      state = NutritionState(entries: entries);
    });

    ref.onDispose(() => sub?.cancel());
  }

  /// Log a meal entry for today.
  ///
  /// Writes to local PowerSync SQLite — auto-syncs to PostgreSQL and
  /// propagates to all connected devices.
  Future<void> logMeal(FoodItem food, double portionSpoons) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final entry = NutritionEntry(
      id: id,
      food: food,
      portionSpoons: portionSpoons,
      timestamp: now,
    );

    // Optimistic local state update.
    state = state.copyWith(entries: [...state.entries, entry]);

    // Write to local PowerSync SQLite — auto-syncs to PostgreSQL via the
    // connector's uploadData method, then replicates to all devices.
    await _db.execute(
      'INSERT INTO meal_logs(id, user_id, name, is_safe, category, triggers, logged_at, created_at, updated_at) '
      'VALUES(?, 0, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        food.name,
        food.isSafe ? 1 : 0,
        food.category.name,
        food.triggerConditions.map((t) => t.name).join(','),
        now.toIso8601String(),
        now.toIso8601String(),
        now.toIso8601String(),
      ],
    );
    debugPrint(
      '[Nutrition] logged ${food.name} x$portionSpoons spoons → PowerSync auto-sync',
    );
  }

  void removeEntry(String id) {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();

  void reset() => state = const NutritionState();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final nutritionProvider = NotifierProvider<NutritionNotifier, NutritionState>(
  NutritionNotifier.new,
);
