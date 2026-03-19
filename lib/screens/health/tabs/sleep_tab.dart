import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/health_service.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:powersync/powersync.dart' hide Column;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Sleep state
// ---------------------------------------------------------------------------

class SleepEntry {
  const SleepEntry({
    required this.bedtime,
    required this.wakeTime,
    required this.qualityRating,
    required this.loggedAt,
  });

  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;

  /// 1-5 star quality rating.
  final int qualityRating;
  final DateTime loggedAt;

  /// Calculate sleep duration in hours, accounting for overnight sleep.
  double get durationHours {
    final bedMinutes = bedtime.hour * 60 + bedtime.minute;
    final rawWakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    final wakeMinutes = rawWakeMinutes <= bedMinutes
        ? rawWakeMinutes + 24 * 60
        : rawWakeMinutes;
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  String get durationDisplay {
    final h = durationHours.floor();
    final m = ((durationHours - h) * 60).round();
    return '${h}h ${m}m';
  }

  /// Bedtime as fractional hour (0-24+), shifted so values near midnight
  /// cluster together. E.g. 23:30 = 23.5, 00:30 = 24.5.
  double get bedtimeAsHour {
    final h = bedtime.hour + bedtime.minute / 60.0;
    // Shift early-morning bedtimes past midnight to keep them near late-night
    return h < 12 ? h + 24.0 : h;
  }

  /// Wake time as fractional hour (0-24).
  double get wakeTimeAsHour => wakeTime.hour + wakeTime.minute / 60.0;
}

class SleepState {
  const SleepState({
    this.entries = const [],
    this.bedtime = const TimeOfDay(hour: 23, minute: 0),
    this.wakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.qualityRating = 3,
  });

  final List<SleepEntry> entries;
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final int qualityRating;

  double get currentDurationHours {
    final bedMinutes = bedtime.hour * 60 + bedtime.minute;
    final rawWakeMinutes = wakeTime.hour * 60 + wakeTime.minute;
    final wakeMinutes = rawWakeMinutes <= bedMinutes
        ? rawWakeMinutes + 24 * 60
        : rawWakeMinutes;
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  String get currentDurationDisplay {
    final h = currentDurationHours.floor();
    final m = ((currentDurationHours - h) * 60).round();
    return '${h}h ${m}m';
  }

  double? get averageDuration {
    if (entries.isEmpty) return null;
    final total = entries.fold<double>(0, (sum, e) => sum + e.durationHours);
    return total / entries.length;
  }

  double? get averageQuality {
    if (entries.isEmpty) return null;
    final total = entries.fold<int>(0, (sum, e) => sum + e.qualityRating);
    return total / entries.length;
  }

  /// Sleep debt in hours. Positive means deficit (avg < 7h).
  /// Returns null when there are no entries.
  double? get sleepDebt {
    final avg = averageDuration;
    if (avg == null) return null;
    return (7.0 - avg).clamp(0.0, double.infinity);
  }

  /// Consistency score from 0 to 100 based on standard deviation of bedtimes
  /// and wake times. Lower variation = higher score.
  /// Returns null when fewer than 2 entries.
  int? get consistencyScore {
    if (entries.length < 2) return null;

    double stddev(List<double> values) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final sqDiffs = values.map((v) => (v - mean) * (v - mean));
      return math.sqrt(sqDiffs.reduce((a, b) => a + b) / values.length);
    }

    final bedStd = stddev(entries.map((e) => e.bedtimeAsHour).toList());
    final wakeStd = stddev(entries.map((e) => e.wakeTimeAsHour).toList());

    // Combined deviation in minutes. Perfect = 0, terrible >= 120 min.
    final combinedMinutes = (bedStd + wakeStd) * 60.0;
    final score = ((1.0 - (combinedMinutes / 120.0)) * 100).round().clamp(
      0,
      100,
    );
    return score;
  }

  SleepState copyWith({
    List<SleepEntry>? entries,
    TimeOfDay? bedtime,
    TimeOfDay? wakeTime,
    int? qualityRating,
  }) {
    return SleepState(
      entries: entries ?? this.entries,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      qualityRating: qualityRating ?? this.qualityRating,
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep notifier
// ---------------------------------------------------------------------------

class SleepNotifier extends Notifier<SleepState> {
  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  SleepState build() {
    _watchSleepEntries();
    return const SleepState();
  }

  void _watchSleepEntries() {
    final stream = _db.watch(
      'SELECT * FROM sleep_logs ORDER BY logged_at DESC',
    );

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final entries = <SleepEntry>[];
      for (final row in results) {
        final bedStr = row['bed_time'] as String? ?? '';
        final wakeStr = row['wake_time'] as String? ?? '';
        final loggedStr =
            row['logged_at'] as String? ?? row['created_at'] as String? ?? '';

        final bedParts = bedStr.split(':');
        final wakeParts = wakeStr.split(':');
        if (bedParts.length < 2 || wakeParts.length < 2) continue;

        entries.add(
          SleepEntry(
            bedtime: TimeOfDay(
              hour: int.tryParse(bedParts[0]) ?? 23,
              minute: int.tryParse(bedParts[1]) ?? 0,
            ),
            wakeTime: TimeOfDay(
              hour: int.tryParse(wakeParts[0]) ?? 7,
              minute: int.tryParse(wakeParts[1]) ?? 0,
            ),
            qualityRating: (row['quality_rating'] as int?) ?? 3,
            loggedAt: DateTime.tryParse(loggedStr) ?? DateTime.now(),
          ),
        );
      }

      state = state.copyWith(entries: entries);
    });

    ref.onDispose(() => sub?.cancel());
  }

  void setBedtime(TimeOfDay time) {
    state = state.copyWith(bedtime: time);
  }

  void setWakeTime(TimeOfDay time) {
    state = state.copyWith(wakeTime: time);
  }

  void setQuality(int rating) {
    state = state.copyWith(qualityRating: rating.clamp(1, 5));
  }

  Future<void> logSleep() async {
    final entry = SleepEntry(
      bedtime: state.bedtime,
      wakeTime: state.wakeTime,
      qualityRating: state.qualityRating,
      loggedAt: DateTime.now(),
    );

    // Persist to PowerSync sleep_logs (syncs to all devices via batch CRUD).
    // user_id=0 is a placeholder — server replaces it with real user_id from JWT.
    final now = DateTime.now().toUtc().toIso8601String();
    final bedStr =
        '${state.bedtime.hour.toString().padLeft(2, '0')}:${state.bedtime.minute.toString().padLeft(2, '0')}';
    final wakeStr =
        '${state.wakeTime.hour.toString().padLeft(2, '0')}:${state.wakeTime.minute.toString().padLeft(2, '0')}';

    await _db.execute(
      'INSERT INTO sleep_logs (id, user_id, bed_time, wake_time, quality_rating, duration_hours, logged_at, created_at, updated_at) '
      'VALUES (?, 0, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        bedStr,
        wakeStr,
        state.qualityRating,
        entry.durationHours,
        now,
        now,
        now,
      ],
    );

    state = state.copyWith(entries: [entry, ...state.entries]);
  }

  void reset() => state = const SleepState();
}

final sleepProvider = NotifierProvider<SleepNotifier, SleepState>(
  SleepNotifier.new,
);

// ---------------------------------------------------------------------------
// Sleep tab
// ---------------------------------------------------------------------------

/// Sleep tab -- bedtime/wake time pickers, duration display, quality rating.
/// Also shows last night's sleep data from HealthKit when available.
class SleepTab extends ConsumerStatefulWidget {
  const SleepTab({super.key});

  @override
  ConsumerState<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends ConsumerState<SleepTab> {
  double? _healthKitSleepHours;
  bool _healthKitLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthKitSleep();
  }

  Future<void> _loadHealthKitSleep() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPerms = prefs.getBool('health_permissions_granted') ?? false;
    if (!hasPerms) {
      if (mounted) setState(() => _healthKitLoading = false);
      return;
    }
    final hs = ref.read(healthServiceProvider);
    final hours = await hs.getSleepHours(DateTime.now());
    if (mounted) {
      setState(() {
        _healthKitSleepHours = hours;
        _healthKitLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sleepProvider);
    final notifier = ref.read(sleepProvider.notifier);

    return RefreshIndicator(
      onRefresh: _loadHealthKitSleep,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // HealthKit sleep data card
          _HealthKitSleepCard(
            sleepHours: _healthKitSleepHours,
            isLoading: _healthKitLoading,
            tokens: tokens,
          ),
          const SizedBox(height: 16),

          // Duration display card
          GlassCard(
            child: Column(
              children: [
                _DurationDisplay(
                  duration: state.currentDurationHours,
                  durationText: state.currentDurationDisplay,
                  tokens: tokens,
                ),
                const SizedBox(height: 8),
                _DurationQualityLabel(
                  hours: state.currentDurationHours,
                  tokens: tokens,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Time pickers
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleep,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimePicker(
                        label: l10n.bedtime,
                        icon: Icons.bedtime_rounded,
                        time: state.bedtime,
                        tokens: tokens,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: state.bedtime,
                          );
                          if (picked != null) notifier.setBedtime(picked);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: tokens.fgDim,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: _TimePicker(
                        label: l10n.ready,
                        icon: Icons.wb_sunny_rounded,
                        time: state.wakeTime,
                        tokens: tokens,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: state.wakeTime,
                          );
                          if (picked != null) notifier.setWakeTime(picked);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quality rating
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sleep,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _StarRating(
                  rating: state.qualityRating,
                  tokens: tokens,
                  onChanged: notifier.setQuality,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _qualityLabel(state.qualityRating),
                    style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                notifier.logSleep();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.sleepLogged),
                    backgroundColor: tokens.bgAlt,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l10n.logSleep),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Empty state -- shown when no entries yet
          if (state.entries.isEmpty) _SleepEmptyState(tokens: tokens),

          // Sleep debt indicator
          if (state.entries.isNotEmpty &&
              state.sleepDebt != null &&
              state.sleepDebt! > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SleepDebtIndicator(
                debtHours: state.sleepDebt!,
                averageDuration: state.averageDuration!,
                tokens: tokens,
              ),
            ),

          // Consistency score
          if (state.consistencyScore != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ConsistencyScoreCard(
                score: state.consistencyScore!,
                tokens: tokens,
              ),
            ),

          // Averages card with visual quality gauge
          if (state.entries.isNotEmpty)
            _AveragesCard(
              averageDuration: state.averageDuration,
              averageQuality: state.averageQuality,
              entryCount: state.entries.length,
              tokens: tokens,
            ),
          if (state.entries.isNotEmpty) const SizedBox(height: 16),

          // Recent log
          if (state.entries.isNotEmpty)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recent,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.entries.reversed
                      .take(7)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bedtime_rounded,
                                color: tokens.accent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                e.durationDisplay,
                                style: TextStyle(
                                  color: tokens.fgBright,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < e.qualityRating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: i < e.qualityRating
                                      ? const Color(0xFFFFB74D)
                                      : tokens.fgDim,
                                  size: 14,
                                );
                              }),
                              const Spacer(),
                              Text(
                                _formatDate(e.loggedAt),
                                style: TextStyle(
                                  color: tokens.fgDim,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: ref.read(sleepProvider.notifier).reset,
              child: Text(
                l10n.resetToDefaults,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _qualityLabel(int rating) {
    final l10n = AppLocalizations.of(context);
    switch (rating) {
      case 1:
        return l10n.sleepVeryPoor;
      case 2:
        return l10n.sleepPoor;
      case 3:
        return l10n.sleepFair;
      case 4:
        return l10n.sleepGood;
      case 5:
        return l10n.sleepExcellent;
      default:
        return '';
    }
  }

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$m/$d';
  }
}

// ---------------------------------------------------------------------------
// HealthKit sleep card — shows last night's data from Apple Health
// ---------------------------------------------------------------------------

class _HealthKitSleepCard extends StatelessWidget {
  const _HealthKitSleepCard({
    required this.sleepHours,
    required this.isLoading,
    required this.tokens,
  });

  final double? sleepHours;
  final bool isLoading;
  final OrchestraColorTokens tokens;

  Color _sleepColor(double hours) {
    if (hours >= 7 && hours <= 9) return const Color(0xFF4CAF50);
    if (hours >= 6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _sleepLabel(BuildContext context, double hours) {
    final l10n = AppLocalizations.of(context);
    if (hours >= 7 && hours <= 9) return l10n.goodRest;
    if (hours >= 6) return l10n.couldBeBetter;
    return l10n.sleepDeficit;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: const Color(0xFF7C4DFF),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).sleep,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.fgMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Text(
              AppLocalizations.of(context).loading,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            )
          else if (sleepHours != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sleepHours!.toStringAsFixed(1),
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'hours',
                    style: TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _sleepColor(sleepHours!).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _sleepLabel(context, sleepHours!),
                    style: TextStyle(
                      color: _sleepColor(sleepHours!),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (sleepHours! / 8.0).clamp(0.0, 1.0),
                backgroundColor: tokens.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _sleepColor(sleepHours!),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: 8 hours',
              style: TextStyle(color: tokens.fgDim, fontSize: 10),
            ),
          ] else
            Text(
              AppLocalizations.of(context).noResults,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _SleepEmptyState extends StatelessWidget {
  const _SleepEmptyState({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.accent.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.nights_stay_rounded,
              color: tokens.accent.withValues(alpha: 0.7),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).logSleep,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).sleepEmptyState,
            style: TextStyle(color: tokens.fgDim, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sleep debt indicator
// ---------------------------------------------------------------------------

class _SleepDebtIndicator extends StatelessWidget {
  const _SleepDebtIndicator({
    required this.debtHours,
    required this.averageDuration,
    required this.tokens,
  });

  final double debtHours;
  final double averageDuration;
  final OrchestraColorTokens tokens;

  /// Severity: mild (< 1h), moderate (1-2h), severe (> 2h).
  _DebtSeverity get _severity {
    if (debtHours < 1.0) return _DebtSeverity.mild;
    if (debtHours < 2.0) return _DebtSeverity.moderate;
    return _DebtSeverity.severe;
  }

  Color get _color {
    switch (_severity) {
      case _DebtSeverity.mild:
        return const Color(0xFFFFB74D); // amber
      case _DebtSeverity.moderate:
        return const Color(0xFFFF9800); // orange
      case _DebtSeverity.severe:
        return const Color(0xFFF44336); // red
    }
  }

  IconData get _icon {
    switch (_severity) {
      case _DebtSeverity.mild:
        return Icons.info_outline_rounded;
      case _DebtSeverity.moderate:
        return Icons.warning_amber_rounded;
      case _DebtSeverity.severe:
        return Icons.error_outline_rounded;
    }
  }

  String get _message {
    final debtDisplay = debtHours.toStringAsFixed(1);
    final avgDisplay = averageDuration.toStringAsFixed(1);
    switch (_severity) {
      case _DebtSeverity.mild:
        return 'Averaging ${avgDisplay}h -- slightly below the 7h minimum. '
            '${debtDisplay}h sleep debt per night.';
      case _DebtSeverity.moderate:
        return 'Averaging ${avgDisplay}h -- you are building ${debtDisplay}h '
            'of sleep debt nightly. Consider an earlier bedtime.';
      case _DebtSeverity.severe:
        return 'Averaging only ${avgDisplay}h -- ${debtDisplay}h below the '
            'minimum. This level of sleep debt affects health and cognition.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.15),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).sleep,
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _message,
                  style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DebtSeverity { mild, moderate, severe }

// ---------------------------------------------------------------------------
// Consistency score card
// ---------------------------------------------------------------------------

class _ConsistencyScoreCard extends StatelessWidget {
  const _ConsistencyScoreCard({required this.score, required this.tokens});

  final int score;
  final OrchestraColorTokens tokens;

  Color get _color {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFFB74D);
    return const Color(0xFFF44336);
  }

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (score >= 80) return l10n.scheduleConsistent;
    if (score >= 50) return l10n.scheduleVariable;
    return l10n.scheduleIrregular;
  }

  String _description(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (score >= 80) return l10n.scheduleConsistentMsg;
    if (score >= 50) return l10n.scheduleVariableMsg;
    return l10n.scheduleIrregularMsg;
  }

  @override
  Widget build(BuildContext context) {
    final progress = score / 100.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: _color, size: 18),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).sleep,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _label(context),
                  style: TextStyle(
                    color: _color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: tokens.border.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _description(context),
            style: TextStyle(color: tokens.fgDim, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Averages card with quality gauge
// ---------------------------------------------------------------------------

class _AveragesCard extends StatelessWidget {
  const _AveragesCard({
    required this.averageDuration,
    required this.averageQuality,
    required this.entryCount,
    required this.tokens,
  });

  final double? averageDuration;
  final double? averageQuality;
  final int entryCount;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).summary,
            style: TextStyle(
              color: tokens.fgBright,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: AppLocalizations.of(context).avgDuration,
                value: averageDuration != null
                    ? '${averageDuration!.toStringAsFixed(1)}h'
                    : '--',
                tokens: tokens,
              ),
              Container(
                width: 1,
                height: 32,
                color: tokens.border.withValues(alpha: 0.3),
              ),
              _StatColumn(
                label: AppLocalizations.of(context).statEntries,
                value: entryCount.toString(),
                tokens: tokens,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quality gauge
          if (averageQuality != null) ...[
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).avgQuality,
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${averageQuality!.toStringAsFixed(1)} / 5',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _QualityGauge(quality: averageQuality!, tokens: tokens),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quality gauge (visual arc for average quality)
// ---------------------------------------------------------------------------

class _QualityGauge extends StatelessWidget {
  const _QualityGauge({required this.quality, required this.tokens});

  /// Average quality value from 1.0 to 5.0.
  final double quality;
  final OrchestraColorTokens tokens;

  Color get _gaugeColor {
    if (quality >= 4.0) return const Color(0xFF4CAF50);
    if (quality >= 3.0) return const Color(0xFFFFB74D);
    if (quality >= 2.0) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _qualityWord(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (quality >= 4.5) return l10n.sleepExcellent;
    if (quality >= 3.5) return l10n.sleepGood;
    if (quality >= 2.5) return l10n.sleepFair;
    if (quality >= 1.5) return l10n.sleepPoor;
    return l10n.sleepVeryPoor;
  }

  @override
  Widget build(BuildContext context) {
    // Gauge fills from 0% (quality=1) to 100% (quality=5).
    final fill = ((quality - 1.0) / 4.0).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 80,
          child: CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _ArcGaugePainter(
              progress: fill,
              trackColor: tokens.border.withValues(alpha: 0.2),
              fillColor: _gaugeColor,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: _gaugeColor, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      _qualityWord(context),
                      style: TextStyle(
                        color: _gaugeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Scale labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1', style: TextStyle(color: tokens.fgDim, fontSize: 10)),
            Text('2', style: TextStyle(color: tokens.fgDim, fontSize: 10)),
            Text('3', style: TextStyle(color: tokens.fgDim, fontSize: 10)),
            Text('4', style: TextStyle(color: tokens.fgDim, fontSize: 10)),
            Text('5', style: TextStyle(color: tokens.fgDim, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Arc gauge painter
// ---------------------------------------------------------------------------

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - strokeWidth / 2;

    // Semi-circle arc (180 degrees, from left to right).
    const startAngle = math.pi; // 180 degrees (left)
    const sweepTotal = math.pi; // 180 degrees sweep

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw track
    canvas.drawArc(rect, startAngle, sweepTotal, false, trackPaint);

    // Draw filled portion
    if (progress > 0) {
      canvas.drawArc(rect, startAngle, sweepTotal * progress, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}

// ---------------------------------------------------------------------------
// Duration display
// ---------------------------------------------------------------------------

class _DurationDisplay extends StatelessWidget {
  const _DurationDisplay({
    required this.duration,
    required this.durationText,
    required this.tokens,
  });

  final double duration;
  final String durationText;
  final OrchestraColorTokens tokens;

  Color get _ringColor {
    if (duration >= 7 && duration <= 9) return const Color(0xFF4CAF50);
    if (duration >= 6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    // Progress based on 8h target
    final progress = (duration / 8.0).clamp(0.0, 1.0);

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: tokens.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bedtime_rounded, color: tokens.accent, size: 18),
              const SizedBox(height: 4),
              Text(
                durationText,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                AppLocalizations.of(context).sleepTarget(8),
                style: TextStyle(color: tokens.fgDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Duration quality label
// ---------------------------------------------------------------------------

class _DurationQualityLabel extends StatelessWidget {
  const _DurationQualityLabel({required this.hours, required this.tokens});

  final double hours;
  final OrchestraColorTokens tokens;

  String _label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (hours >= 7 && hours <= 9) return l10n.optimalSleep;
    if (hours >= 6) return l10n.belowRecommended;
    if (hours < 6) return l10n.tooLittleSleep;
    return l10n.moreThanNeeded;
  }

  Color get _color {
    if (hours >= 7 && hours <= 9) return const Color(0xFF4CAF50);
    if (hours >= 6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(context),
        style: TextStyle(color: _color, fontSize: 12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time picker tile
// ---------------------------------------------------------------------------

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.label,
    required this.icon,
    required this.time,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final TimeOfDay time;
  final OrchestraColorTokens tokens;
  final VoidCallback onTap;

  String get _timeStr {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.bgAlt,
          border: Border.all(color: tokens.border.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: tokens.accent, size: 20),
            const SizedBox(height: 6),
            Text(
              _timeStr,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Star rating
// ---------------------------------------------------------------------------

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.tokens,
    required this.onChanged,
  });

  final int rating;
  final OrchestraColorTokens tokens;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final filled = starIndex <= rating;
        return GestureDetector(
          onTap: () => onChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? const Color(0xFFFFB74D) : tokens.fgDim,
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat column
// ---------------------------------------------------------------------------

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: tokens.fgMuted, fontSize: 11)),
      ],
    );
  }
}
