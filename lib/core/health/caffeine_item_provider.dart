import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'caffeine_item.dart';

/// Provides the list of available caffeine items.
///
/// Currently returns local preset data. Future: fetches from admin panel API
/// with PowerSync sync for offline support.
final caffeineItemsProvider = Provider<List<CaffeineItem>>((ref) {
  // TODO: Fetch from admin API → PowerSync `caffeine_items` table.
  // For now, use the local preset seeder data.
  return caffeineItemPresets;
});
