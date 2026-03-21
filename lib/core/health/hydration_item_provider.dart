import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/hydration_item.dart';

/// Provides the list of available hydration items.
///
/// Currently returns local preset data. Future: fetches from admin panel API
/// with PowerSync sync for offline support.
final hydrationItemsProvider = Provider<List<HydrationItem>>((ref) {
  // TODO: Fetch from admin API -> PowerSync `hydration_items` table.
  // For now, use the local preset seeder data.
  return hydrationItemPresets;
});
