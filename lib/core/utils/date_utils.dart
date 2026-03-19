import 'package:intl/intl.dart';

/// Returns a human-readable relative date string, e.g. "2h ago", "yesterday",
/// "Mar 12".
String formatRelative(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final today = DateTime(now.year, now.month, now.day);
  final dtDay = DateTime(dt.year, dt.month, dt.day);
  final dayDiff = today.difference(dtDay).inDays;

  if (dayDiff == 1) return 'yesterday';
  if (dayDiff < 7) return '${dayDiff}d ago';

  // Same year → "Mar 12", different year → "Mar 12, 2024"
  if (dt.year == now.year) {
    return DateFormat('MMM d').format(dt);
  }
  return DateFormat('MMM d, y').format(dt);
}

/// Returns an ISO 8601 string with UTC timezone, e.g.
/// "2025-01-01T12:00:00.000Z".
String formatISO(DateTime dt) => dt.toUtc().toIso8601String();

/// Parses an ISO 8601 string into a [DateTime] in local time.
/// Returns [DateTime.now()] on parse failure.
DateTime parseISO(String s) => DateTime.tryParse(s)?.toLocal() ?? DateTime.now();
