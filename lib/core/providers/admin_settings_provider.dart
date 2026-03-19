import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';

/// Admin settings provider keyed by setting key (e.g. "general", "smtp").
///
/// Usage: `ref.watch(adminSettingProvider('general'))`
final adminSettingProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, key) {
      return ref.watch(apiClientProvider).getAdminSetting(key);
    });
