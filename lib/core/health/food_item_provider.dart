import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';

/// Provides the list of available food items.
///
/// Currently returns preset data from FoodRegistry. Future: fetches from
/// admin panel API with PowerSync sync for offline support.
final foodItemsProvider = Provider<List<FoodItem>>((ref) {
  // TODO: Fetch from admin API -> PowerSync `food_items` table.
  // For now, use the local preset seeder data.
  return FoodRegistry.allFoods;
});
