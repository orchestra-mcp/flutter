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
// Weight state
// ---------------------------------------------------------------------------

class WeightEntry {
  const WeightEntry({required this.kg, required this.timestamp});
  final double kg;
  final DateTime timestamp;
}

class WeightState {
  const WeightState({this.entries = const [], this.heightCm = 175.0});

  final List<WeightEntry> entries;
  final double heightCm;

  double? get latestKg => entries.isNotEmpty ? entries.last.kg : null;

  double? get bmi {
    final w = latestKg;
    if (w == null || heightCm <= 0) return null;
    final hm = heightCm / 100;
    return w / (hm * hm);
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return '--';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  /// Delta between the last two entries, or null if fewer than 2 entries.
  double? get weightDelta {
    if (entries.length < 2) return null;
    return entries.last.kg - entries[entries.length - 2].kg;
  }

  /// Weekly summary computed from entries within the last 7 days.
  /// Returns null if fewer than 3 qualifying entries exist.
  WeightWeeklySummary? get weeklySummary {
    if (entries.length < 3) return null;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final weekEntries = entries
        .where((e) => e.timestamp.isAfter(cutoff))
        .toList();
    if (weekEntries.length < 3) {
      // Fallback: use the last 7 entries if we don't have 3+ in the past week
      final fallback = entries.length >= 3
          ? entries.sublist(entries.length - math.min(7, entries.length))
          : null;
      if (fallback == null || fallback.length < 3) return null;
      return _computeSummary(fallback);
    }
    return _computeSummary(weekEntries);
  }

  static WeightWeeklySummary _computeSummary(List<WeightEntry> subset) {
    final values = subset.map((e) => e.kg).toList();
    final minKg = values.reduce(math.min);
    final maxKg = values.reduce(math.max);
    final avgKg = values.reduce((a, b) => a + b) / values.length;
    final change = values.last - values.first;
    return WeightWeeklySummary(
      minKg: minKg,
      maxKg: maxKg,
      avgKg: avgKg,
      changeKg: change,
      entryCount: values.length,
    );
  }

  WeightState copyWith({List<WeightEntry>? entries, double? heightCm}) {
    return WeightState(
      entries: entries ?? this.entries,
      heightCm: heightCm ?? this.heightCm,
    );
  }
}

/// Summary statistics for recent weight entries.
class WeightWeeklySummary {
  const WeightWeeklySummary({
    required this.minKg,
    required this.maxKg,
    required this.avgKg,
    required this.changeKg,
    required this.entryCount,
  });
  final double minKg;
  final double maxKg;
  final double avgKg;
  final double changeKg;
  final int entryCount;
}

// ---------------------------------------------------------------------------
// Weight notifier
// ---------------------------------------------------------------------------

class WeightNotifier extends Notifier<WeightState> {
  static const _uuid = Uuid();

  PowerSyncDatabase get _db => ref.read(powersyncDatabaseProvider);

  @override
  WeightState build() {
    _watchWeightEntries();
    return const WeightState();
  }

  void _watchWeightEntries() {
    final stream = _db.watch(
      'SELECT * FROM health_snapshots ORDER BY snapshot_date DESC',
    );

    StreamSubscription<dynamic>? sub;
    sub = stream.listen((results) {
      final entries = <WeightEntry>[];
      for (final row in results) {
        final kg = (row['weight_kg'] as num?)?.toDouble();
        if (kg == null || kg <= 0) continue;
        final dateStr =
            row['snapshot_date'] as String? ??
            row['created_at'] as String? ??
            '';
        entries.add(
          WeightEntry(
            kg: kg,
            timestamp: DateTime.tryParse(dateStr) ?? DateTime.now(),
          ),
        );
      }

      state = state.copyWith(entries: entries);
    });

    ref.onDispose(() => sub?.cancel());
  }

  Future<void> logWeight(double kg) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nowUtc = now.toUtc().toIso8601String();

    // Persist to PowerSync (syncs to all devices via batch CRUD).
    // user_id=0 is a placeholder — server replaces it with real user_id from JWT.
    await _db.execute(
      'INSERT INTO health_snapshots (id, user_id, snapshot_date, weight_kg, created_at, updated_at) '
      'VALUES (?, 0, ?, ?, ?, ?)',
      [_uuid.v4(), dateStr, kg, nowUtc, nowUtc],
    );

    state = state.copyWith(
      entries: [
        WeightEntry(kg: kg, timestamp: now),
        ...state.entries,
      ],
    );
  }

  void setHeight(double cm) {
    state = state.copyWith(heightCm: cm);
  }

  void reset() => state = const WeightState();

  /// Pull-to-refresh: reload from PowerSync.
  Future<void> refresh() async {
    final rows = await _db.getAll(
      'SELECT * FROM health_snapshots ORDER BY snapshot_date DESC',
    );
    final entries = <WeightEntry>[];
    for (final row in rows) {
      final kg = (row['weight_kg'] as num?)?.toDouble();
      if (kg == null || kg <= 0) continue;
      final dateStr =
          row['snapshot_date'] as String? ?? row['created_at'] as String? ?? '';
      entries.add(
        WeightEntry(
          kg: kg,
          timestamp: DateTime.tryParse(dateStr) ?? DateTime.now(),
        ),
      );
    }
    state = state.copyWith(entries: entries);
  }
}

final weightProvider = NotifierProvider<WeightNotifier, WeightState>(
  WeightNotifier.new,
);

// ---------------------------------------------------------------------------
// Weight tab
// ---------------------------------------------------------------------------

/// Weight tab -- entry form, BMI display, weight delta, weekly summary,
/// trend chart with min/max labels, pull-to-refresh, and enhanced empty state.
class WeightTab extends ConsumerStatefulWidget {
  const WeightTab({super.key});

  @override
  ConsumerState<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends ConsumerState<WeightTab> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController(text: '175');

  double? _healthKitWeight;
  double? _healthKitBodyFat;
  bool _healthKitLoading = true;
  bool _healthConnected = false;

  @override
  void initState() {
    super.initState();
    _loadHealthKitData();
  }

  Future<void> _loadHealthKitData() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPerms = prefs.getBool('health_permissions_granted') ?? false;
    if (!hasPerms) {
      if (mounted) {
        setState(() {
          _healthKitLoading = false;
          _healthConnected = false;
        });
      }
      return;
    }
    _healthConnected = true;
    final hs = ref.read(healthServiceProvider);
    final results = await Future.wait([hs.getLatestWeight(), hs.getBodyFat()]);
    if (mounted) {
      setState(() {
        _healthKitWeight = results[0];
        _healthKitBodyFat = results[1];
        _healthKitLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _logWeight() {
    final kg = double.tryParse(_weightController.text);
    if (kg == null || kg <= 0) return;
    ref.read(weightProvider.notifier).logWeight(kg);
    _weightController.clear();
  }

  void _updateHeight() {
    final cm = double.tryParse(_heightController.text);
    if (cm == null || cm <= 0) return;
    ref.read(weightProvider.notifier).setHeight(cm);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(weightProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(weightProvider.notifier).refresh(),
          _loadHealthKitData(),
        ]);
      },
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // HealthKit weight card
          _HealthKitWeightCard(
            weight: _healthKitWeight,
            bodyFat: _healthKitBodyFat,
            isLoading: _healthKitLoading,
            isConnected: _healthConnected,
            tokens: tokens,
          ),
          const SizedBox(height: 16),

          // BMI display card
          GlassCard(
            child: Row(
              children: [
                _BmiCircle(bmi: state.bmi, tokens: tokens),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bmiLabel,
                        style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.bmi?.toStringAsFixed(1) ?? '--',
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _BmiCategoryBadge(
                        category: state.bmiCategory,
                        tokens: tokens,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.today,
                      style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.latestKg != null
                          ? '${state.latestKg!.toStringAsFixed(1)} kg'
                          : '-- kg',
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Weight change indicator
                    if (state.weightDelta != null)
                      _WeightDeltaChip(
                        delta: state.weightDelta!,
                        tokens: tokens,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly summary insight card (3+ entries required)
          if (state.weeklySummary != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _WeeklySummaryCard(
                summary: state.weeklySummary!,
                tokens: tokens,
              ),
            ),

          // Weight entry form
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.logWeight,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(color: tokens.fgBright, fontSize: 15),
                        decoration: _inputDecoration(
                          tokens: tokens,
                          label: l10n.weightKg,
                          hint: 'e.g. 82.4',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(color: tokens.fgBright, fontSize: 15),
                        decoration: _inputDecoration(
                          tokens: tokens,
                          label: l10n.heightCm,
                          hint: '175',
                        ),
                        onChanged: (_) => _updateHeight(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _logWeight,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.logWeight),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: tokens.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trend line chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      color: tokens.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.weight,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.entries.length < 2)
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).logAtLeast2Entries,
                        style: TextStyle(color: tokens.fgDim, fontSize: 13),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: _TrendPlaceholder(
                      entries: state.entries,
                      tokens: tokens,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log history or empty state
          if (state.entries.isEmpty)
            _EmptyState(tokens: tokens)
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.recent,
                        style: TextStyle(
                          color: tokens.fgBright,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${state.entries.length} entries',
                        style: TextStyle(color: tokens.fgDim, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...state.entries.reversed
                      .take(10)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (mapEntry) => _HistoryRow(
                          entry: mapEntry.value,
                          previousEntry: mapEntry.key < state.entries.length - 1
                              ? state.entries.reversed.toList().elementAtOrNull(
                                  mapEntry.key + 1,
                                )
                              : null,
                          tokens: tokens,
                        ),
                      ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: ref.read(weightProvider.notifier).reset,
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

  InputDecoration _inputDecoration({
    required OrchestraColorTokens tokens,
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: tokens.fgMuted, fontSize: 12),
      hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
      filled: true,
      fillColor: tokens.bgAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: tokens.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}

// ---------------------------------------------------------------------------
// HealthKit weight card — shows latest weight from Apple Health
// ---------------------------------------------------------------------------

class _HealthKitWeightCard extends StatelessWidget {
  const _HealthKitWeightCard({
    required this.weight,
    required this.bodyFat,
    required this.isLoading,
    required this.isConnected,
    required this.tokens,
  });

  final double? weight;
  final double? bodyFat;
  final bool isLoading;
  final bool isConnected;
  final OrchestraColorTokens tokens;

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
                color: const Color(0xFF26A69A),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isConnected
                    ? AppLocalizations.of(context).weight
                    : AppLocalizations.of(context).connectHealth,
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
          if (!isConnected && !isLoading)
            Text(
              '${AppLocalizations.of(context).connectHealth}\n'
              '${AppLocalizations.of(context).logWeightManually}',
              style: TextStyle(color: tokens.fgDim, fontSize: 12, height: 1.5),
            )
          else if (isLoading)
            Text(
              AppLocalizations.of(context).loading,
              style: TextStyle(color: tokens.fgDim, fontSize: 13),
            )
          else if (weight != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  weight!.toStringAsFixed(1),
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
                    'kg',
                    style: TextStyle(color: tokens.fgDim, fontSize: 14),
                  ),
                ),
                if (bodyFat != null) ...[
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bodyFat!.toStringAsFixed(1)}% body fat',
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).latestFromAppleHealth,
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
// Empty state illustration
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.monitor_weight_outlined,
              color: tokens.accent.withValues(alpha: 0.6),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).logWeight,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).weightEmptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.fgDim, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmptyFeaturePill(
                icon: Icons.show_chart_rounded,
                label: AppLocalizations.of(context).trends,
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _EmptyFeaturePill(
                icon: Icons.insights_rounded,
                label: AppLocalizations.of(context).insights,
                tokens: tokens,
              ),
              const SizedBox(width: 8),
              _EmptyFeaturePill(
                icon: Icons.analytics_outlined,
                label: AppLocalizations.of(context).bmiLabel,
                tokens: tokens,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _EmptyFeaturePill extends StatelessWidget {
  const _EmptyFeaturePill({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.accent.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tokens.accent.withValues(alpha: 0.7), size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tokens.accent.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weight delta chip (shows change from last entry)
// ---------------------------------------------------------------------------

class _WeightDeltaChip extends StatelessWidget {
  const _WeightDeltaChip({required this.delta, required this.tokens});

  final double delta;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isLoss = delta < 0;
    final isFlat = delta.abs() < 0.05;

    final Color chipColor;
    final IconData chipIcon;
    final String chipText;

    if (isFlat) {
      chipColor = const Color(0xFF9E9E9E);
      chipIcon = Icons.horizontal_rule_rounded;
      chipText = '0.0 kg';
    } else if (isLoss) {
      chipColor = const Color(0xFF4CAF50);
      chipIcon = Icons.arrow_downward_rounded;
      chipText = '${delta.abs().toStringAsFixed(1)} kg';
    } else {
      chipColor = const Color(0xFFFF9800);
      chipIcon = Icons.arrow_upward_rounded;
      chipText = '+${delta.toStringAsFixed(1)} kg';
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: chipColor, size: 12),
          const SizedBox(width: 3),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly summary card
// ---------------------------------------------------------------------------

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({required this.summary, required this.tokens});

  final WeightWeeklySummary summary;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isGain = summary.changeKg > 0.05;
    final isLoss = summary.changeKg < -0.05;

    final Color trendColor;
    final IconData trendIcon;
    final String trendLabel;

    if (isLoss) {
      trendColor = const Color(0xFF4CAF50);
      trendIcon = Icons.trending_down_rounded;
      trendLabel = 'Down ${summary.changeKg.abs().toStringAsFixed(1)} kg';
    } else if (isGain) {
      trendColor = const Color(0xFFFF9800);
      trendIcon = Icons.trending_up_rounded;
      trendLabel = 'Up ${summary.changeKg.abs().toStringAsFixed(1)} kg';
    } else {
      trendColor = const Color(0xFF2196F3);
      trendIcon = Icons.trending_flat_rounded;
      trendLabel = AppLocalizations.of(context).trendStable;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: tokens.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).weekSummary,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: trendColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      trendLabel,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: AppLocalizations.of(context).statMin,
                  value: '${summary.minKg.toStringAsFixed(1)} kg',
                  color: const Color(0xFF2196F3),
                  tokens: tokens,
                ),
              ),
              _VerticalDivider(tokens: tokens),
              Expanded(
                child: _SummaryMetric(
                  label: AppLocalizations.of(context).statMax,
                  value: '${summary.maxKg.toStringAsFixed(1)} kg',
                  color: const Color(0xFFFF9800),
                  tokens: tokens,
                ),
              ),
              _VerticalDivider(tokens: tokens),
              Expanded(
                child: _SummaryMetric(
                  label: AppLocalizations.of(context).statAvg,
                  value: '${summary.avgKg.toStringAsFixed(1)} kg',
                  color: tokens.accent,
                  tokens: tokens,
                ),
              ),
              _VerticalDivider(tokens: tokens),
              Expanded(
                child: _SummaryMetric(
                  label: AppLocalizations.of(context).statEntries,
                  value: '${summary.entryCount}',
                  color: tokens.fgMuted,
                  tokens: tokens,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.tokens,
  });

  final String label;
  final String value;
  final Color color;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.fgDim,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.tokens});

  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: tokens.border.withValues(alpha: 0.2),
    );
  }
}

// ---------------------------------------------------------------------------
// History row with per-entry delta
// ---------------------------------------------------------------------------

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    this.previousEntry,
    required this.tokens,
  });

  final WeightEntry entry;
  final WeightEntry? previousEntry;
  final OrchestraColorTokens tokens;

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m/$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final delta = previousEntry != null ? entry.kg - previousEntry!.kg : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_rounded, color: tokens.accent, size: 14),
          const SizedBox(width: 6),
          Text(
            '${entry.kg.toStringAsFixed(1)} kg',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (delta != null && delta.abs() >= 0.05) ...[
            const SizedBox(width: 6),
            _MiniDelta(delta: delta, tokens: tokens),
          ],
          const Spacer(),
          Text(
            _formatDate(entry.timestamp),
            style: TextStyle(color: tokens.fgDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniDelta extends StatelessWidget {
  const _MiniDelta({required this.delta, required this.tokens});

  final double delta;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isLoss = delta < 0;
    final color = isLoss ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final prefix = isLoss ? '' : '+';

    return Text(
      '$prefix${delta.toStringAsFixed(1)}',
      style: TextStyle(
        color: color.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BMI circle
// ---------------------------------------------------------------------------

class _BmiCircle extends StatelessWidget {
  const _BmiCircle({required this.bmi, required this.tokens});

  final double? bmi;
  final OrchestraColorTokens tokens;

  Color get _color {
    final b = bmi;
    if (b == null) return const Color(0xFF9E9E9E);
    if (b < 18.5) return const Color(0xFF2196F3);
    if (b < 25) return const Color(0xFF4CAF50);
    if (b < 30) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.monitor_weight_rounded, color: _color, size: 26),
    );
  }
}

// ---------------------------------------------------------------------------
// BMI category badge
// ---------------------------------------------------------------------------

class _BmiCategoryBadge extends StatelessWidget {
  const _BmiCategoryBadge({required this.category, required this.tokens});

  final String category;
  final OrchestraColorTokens tokens;

  Color get _color {
    switch (category) {
      case 'Underweight':
        return const Color(0xFF2196F3);
      case 'Normal':
        return const Color(0xFF4CAF50);
      case 'Overweight':
        return const Color(0xFFFF9800);
      case 'Obese':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _localizedCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (category) {
      case 'Underweight':
        return l10n.bmiUnderweight;
      case 'Normal':
        return l10n.bmiNormal;
      case 'Overweight':
        return l10n.bmiOverweight;
      case 'Obese':
        return l10n.bmiObese;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _localizedCategory(context),
        style: TextStyle(color: _color, fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chart with min/max Y-axis labels
// ---------------------------------------------------------------------------

class _TrendPlaceholder extends StatelessWidget {
  const _TrendPlaceholder({required this.entries, required this.tokens});

  final List<WeightEntry> entries;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const SizedBox.shrink();
    }

    final values = entries.map((e) => e.kg).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);

    // Pad the range slightly for visual breathing room
    final displayMin = minVal - 1;
    final displayMax = maxVal + 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-axis labels (min/max)
        SizedBox(
          width: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  displayMax.toStringAsFixed(1),
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  ((displayMax + displayMin) / 2).toStringAsFixed(1),
                  style: TextStyle(
                    color: tokens.fgDim.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  displayMin.toStringAsFixed(1),
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chart area
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _TrendPainter(
              entries: entries,
              lineColor: tokens.accent,
              dotColor: tokens.accent,
              gridColor: tokens.border.withValues(alpha: 0.2),
              fillColor: tokens.accent.withValues(alpha: 0.06),
              minLabelColor: const Color(0xFF2196F3),
              maxLabelColor: const Color(0xFFFF9800),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.entries,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.fillColor,
    required this.minLabelColor,
    required this.maxLabelColor,
  });

  final List<WeightEntry> entries;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final Color fillColor;
  final Color minLabelColor;
  final Color maxLabelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    const topPad = 4.0;
    const bottomPad = 4.0;
    final chartHeight = size.height - topPad - bottomPad;

    final values = entries.map((e) => e.kg).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxVal = values.reduce((a, b) => a > b ? a : b) + 1;
    final range = maxVal - minVal;
    if (range <= 0) return;

    // Find min/max indices for annotation dots
    int minIdx = 0;
    int maxIdx = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] < values[minIdx]) minIdx = i;
      if (values[i] > values[maxIdx]) maxIdx = i;
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y =
          topPad + chartHeight - ((values[i] - minVal) / range) * chartHeight;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Close fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i < 4; i++) {
      final y = topPad + (i / 3) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw gradient fill under the line
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    canvas.drawPath(path, linePaint);

    // Draw dots
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (i == minIdx) {
        // Min dot: blue ring
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = minLabelColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = minLabelColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else if (i == maxIdx) {
        // Max dot: orange ring
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = maxLabelColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = maxLabelColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        // Normal dot
        canvas.drawCircle(point, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.entries.length != entries.length || old.lineColor != lineColor;
}
