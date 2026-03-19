import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/health_service.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vitals tab — steps, energy, heart rate, sleep, weight, blood oxygen,
/// respiratory rate, and Zepp Scale manual input.
///
/// Shows a permission-gated empty state when the health service has not been
/// authorised. Refreshes live metrics (heart rate, energy, SpO2, breathing)
/// every 30 seconds via a periodic timer.
class VitalsTab extends ConsumerStatefulWidget {
  const VitalsTab({super.key});

  @override
  ConsumerState<VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends ConsumerState<VitalsTab> {
  static const _permissionKey = 'health_permissions_granted';
  static const _liveRefreshInterval = Duration(seconds: 30);

  bool _isLoading = true;
  bool _hasPermissions = false;
  bool _dataLoading = false;

  // Vitals data
  int? _steps;
  int? _heartRate;
  double? _calories;
  ({int min, int max})? _heartRateRange;
  double? _sleepHours;
  double? _weight;
  double? _bloodOxygen;
  double? _respiratoryRate;

  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _startLiveRefresh() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(_liveRefreshInterval, (_) => _loadLiveData());
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedGranted = prefs.getBool(_permissionKey) ?? false;

    if (cachedGranted) {
      // Trust the cached grant — HealthKit's hasPermissions() returns false
      // for read-only permissions on iOS (Apple privacy design), so
      // re-verifying would always clear the cache and show the empty state.
      if (mounted) {
        setState(() {
          _hasPermissions = true;
          _isLoading = false;
        });
      }
      await _loadData();
      _startLiveRefresh();
      return;
    }

    // No cached grant — check if permissions were granted in a previous
    // app install (works on Android/macOS, unreliable on iOS).
    final healthService = ref.read(healthServiceProvider);
    final granted = await healthService.hasPermissions();
    if (mounted) {
      setState(() {
        _hasPermissions = granted;
        _isLoading = false;
      });
    }
    if (granted) {
      await prefs.setBool(_permissionKey, true);
      await _loadData();
      _startLiveRefresh();
    }
  }

  Future<void> _requestPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final granted = await healthService.requestPermissions();
    if (mounted) {
      setState(() {
        _hasPermissions = granted;
      });
    }
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionKey, true);
      await _loadData();
      _startLiveRefresh();
    }
  }

  /// Full data load — fetches all vitals.
  Future<void> _loadData() async {
    setState(() => _dataLoading = true);
    final hs = ref.read(healthServiceProvider);
    final now = DateTime.now();
    try {
      final results = await Future.wait([
        hs.getSteps(now),            // 0
        hs.getHeartRate(now),         // 1
        hs.getActiveCalories(now),    // 2
        hs.getHeartRateRange(now),    // 3
        hs.getSleepHours(now),        // 4
        hs.getLatestWeight(),         // 5
        hs.getBloodOxygen(now),       // 6
        hs.getRespiratoryRate(now),   // 7
      ]);
      if (mounted) {
        setState(() {
          _steps = results[0] as int?;
          _heartRate = results[1] as int?;
          _calories = results[2] as double?;
          _heartRateRange = results[3] as ({int min, int max})?;
          _sleepHours = results[4] as double?;
          _weight = results[5] as double?;
          _bloodOxygen = results[6] as double?;
          _respiratoryRate = results[7] as double?;
          _dataLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dataLoading = false);
      }
    }
  }

  /// Live refresh — only fetches rapidly-changing metrics.
  Future<void> _loadLiveData() async {
    final hs = ref.read(healthServiceProvider);
    final now = DateTime.now();
    try {
      final results = await Future.wait([
        hs.getHeartRate(now),
        hs.getActiveCalories(now),
        hs.getBloodOxygen(now),
        hs.getRespiratoryRate(now),
        hs.getSteps(now),
      ]);
      if (mounted) {
        setState(() {
          _heartRate = results[0] as int?;
          _calories = results[1] as double?;
          _bloodOxygen = results[2] as double?;
          _respiratoryRate = results[3] as double?;
          _steps = results[4] as int?;
        });
      }
    } catch (_) {
      // Silent — live refresh failures are non-critical.
    }
  }

  Future<void> _onRefresh() async {
    if (_hasPermissions) {
      await _loadData();
    } else {
      await _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: tokens.accent),
      );
    }

    if (!_hasPermissions) {
      return _EmptyState(
        tokens: tokens,
        onConnect: _requestPermissions,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        children: [
          // Steps
          _StepsCard(
            tokens: tokens,
            steps: _steps,
            isLoading: _dataLoading,
          ),
          const SizedBox(height: 12),

          // Energy + Heart Rate
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  tokens: tokens,
                  title: l10n.energy,
                  value: _calories != null
                      ? _formatNumber(_calories!.round())
                      : null,
                  unit: l10n.unitKcal,
                  icon: Icons.bolt_rounded,
                  iconColor: null,
                  isLoading: _dataLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeartRateCard(
                  tokens: tokens,
                  bpm: _heartRate,
                  range: _heartRateRange,
                  isLoading: _dataLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sleep + Weight
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  tokens: tokens,
                  title: l10n.sleep,
                  value: _sleepHours != null
                      ? _sleepHours!.toStringAsFixed(1)
                      : null,
                  unit: l10n.unitHours,
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF7C4DFF),
                  isLoading: _dataLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  tokens: tokens,
                  title: l10n.weight,
                  value: _weight != null
                      ? _weight!.toStringAsFixed(1)
                      : null,
                  unit: AppLocalizations.of(context).unitKg,
                  icon: Icons.monitor_weight_rounded,
                  iconColor: const Color(0xFF26A69A),
                  isLoading: _dataLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Blood Oxygen + Respiratory Rate
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  tokens: tokens,
                  title: l10n.bloodOxygen,
                  value: _bloodOxygen != null
                      ? '${_bloodOxygen!.round()}'
                      : null,
                  unit: AppLocalizations.of(context).unitPercent,
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF42A5F5),
                  isLoading: _dataLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  tokens: tokens,
                  title: l10n.breathing,
                  value: _respiratoryRate != null
                      ? _respiratoryRate!.toStringAsFixed(1)
                      : null,
                  unit: l10n.unitBreathsPerMin,
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF66BB6A),
                  isLoading: _dataLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Zepp Scale
          _ZeppScaleSection(tokens: tokens, healthKitWeight: _weight),
        ],
      ),
    );
  }
}

String _formatNumber(int n) {
  if (n < 1000) return n.toString();
  final str = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
    buf.write(str[i]);
  }
  return buf.toString();
}

// ---------------------------------------------------------------------------
// Empty state — shown when health permissions are not granted
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.tokens,
    required this.onConnect,
  });

  final OrchestraColorTokens tokens;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monitor_heart_outlined,
                color: tokens.accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noResults,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).connectHealthDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).connectHealthService,
                child: FilledButton.icon(
                  onPressed: onConnect,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(AppLocalizations.of(context).connectHealth),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: tokens.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onConnect,
              child: Text(
                AppLocalizations.of(context).help,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Steps card
// ---------------------------------------------------------------------------

class _StepsCard extends StatelessWidget {
  const _StepsCard({
    required this.tokens,
    required this.steps,
    required this.isLoading,
  });

  final OrchestraColorTokens tokens;
  final int? steps;
  final bool isLoading;

  static const _goal = 10000;

  @override
  Widget build(BuildContext context) {
    final displaySteps = steps ?? 0;
    final progress = (displaySteps / _goal).clamp(0.0, 1.0);
    final hasData = steps != null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk_rounded,
                  color: tokens.accent, size: 18),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).steps,
                  style: TextStyle(
                      color: tokens.fgBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.fgMuted,
                  ),
                )
              else
                Text(
                  hasData ? '$displaySteps / $_goal' : '\u2014 / $_goal',
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasData ? _formatNumber(displaySteps) : '\u2014',
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hasData ? progress : 0,
              backgroundColor: tokens.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              minHeight: 6,
            ),
          ),
          if (hasData) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [FlSpot(0, displaySteps.toDouble())],
                      isCurved: true,
                      color: tokens.accent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: tokens.accent.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).today,
                style: TextStyle(color: tokens.fgDim, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic metric card
// ---------------------------------------------------------------------------

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.tokens,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isLoading,
    this.iconColor,
  });

  final OrchestraColorTokens tokens;
  final String title;
  final String? value;
  final String unit;
  final IconData icon;
  final bool isLoading;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? tokens.accent, size: 16),
              const SizedBox(width: 4),
              Text(title,
                  style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.fgMuted,
              ),
            )
          else
            Text(value ?? '\u2014',
                style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
          Text(unit,
              style: TextStyle(color: tokens.fgDim, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heart rate card
// ---------------------------------------------------------------------------

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({
    required this.tokens,
    required this.bpm,
    required this.range,
    required this.isLoading,
  });

  final OrchestraColorTokens tokens;
  final int? bpm;
  final ({int min, int max})? range;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Color(0xFFF44336), size: 16),
              const SizedBox(width: 4),
              Text(AppLocalizations.of(context).heartRate,
                  style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.fgMuted,
              ),
            )
          else
            Text(bpm != null ? '$bpm' : '\u2014',
                style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 26,
                    fontWeight: FontWeight.w700)),
          Text(AppLocalizations.of(context).unitBpm,
              style: TextStyle(color: tokens.fgDim, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            range != null
                ? AppLocalizations.of(context).heartRateRange(range!.min, range!.max)
                : AppLocalizations.of(context).noRangeData,
            style: TextStyle(color: tokens.fgMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zepp Scale section
// ---------------------------------------------------------------------------

class _ZeppScaleSection extends StatefulWidget {
  const _ZeppScaleSection({
    required this.tokens,
    this.healthKitWeight,
  });

  final OrchestraColorTokens tokens;
  final double? healthKitWeight;

  @override
  State<_ZeppScaleSection> createState() => _ZeppScaleSectionState();
}

class _ZeppScaleSectionState extends State<_ZeppScaleSection> {
  late final TextEditingController _weightCtrl;
  final _bodyFatCtrl = TextEditingController(text: '22.1');
  final _metAgeCtrl = TextEditingController(text: '34');
  final _visceralCtrl = TextEditingController(text: '8');
  final _waterCtrl = TextEditingController(text: '57.3');

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.healthKitWeight?.toStringAsFixed(1) ?? '82.4',
    );
  }

  @override
  void didUpdateWidget(_ZeppScaleSection old) {
    super.didUpdateWidget(old);
    if (widget.healthKitWeight != null &&
        old.healthKitWeight != widget.healthKitWeight) {
      _weightCtrl.text = widget.healthKitWeight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _metAgeCtrl.dispose();
    _visceralCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final metAge = int.tryParse(_metAgeCtrl.text) ?? 0;
    final metAgeColor =
        metAge <= 35 ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scale_rounded, color: tokens.accent, size: 18),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).zeppScale,
                  style: TextStyle(
                      color: tokens.fgBright,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ZeppField(
                    controller: _weightCtrl,
                    label: AppLocalizations.of(context).weight,
                    unit: AppLocalizations.of(context).unitKg,
                    tokens: tokens),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ZeppField(
                    controller: _bodyFatCtrl,
                    label: AppLocalizations.of(context).bodyFat,
                    unit: AppLocalizations.of(context).unitPercent,
                    tokens: tokens),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ZeppField(
                  controller: _metAgeCtrl,
                  label: AppLocalizations.of(context).metabolicAge,
                  unit: AppLocalizations.of(context).unitYears,
                  tokens: tokens,
                  valueColor: metAgeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ZeppField(
                  controller: _visceralCtrl,
                  label: AppLocalizations.of(context).visceralFat,
                  unit: '1\u201312',
                  tokens: tokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ZeppField(
            controller: _waterCtrl,
            label: AppLocalizations.of(context).bodyWater,
            unit: AppLocalizations.of(context).unitPercent,
            tokens: tokens,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.bg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppLocalizations.of(context).saveMeasurements),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeppField extends StatelessWidget {
  const _ZeppField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.tokens,
    this.valueColor,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final OrchestraColorTokens tokens;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        color: valueColor ?? tokens.fgBright,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        labelStyle: TextStyle(color: tokens.fgMuted, fontSize: 12),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}
