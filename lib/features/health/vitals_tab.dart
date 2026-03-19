import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/features/health/health_provider.dart';
import 'package:orchestra/l10n/app_localizations.dart';

// ─── Vitals Tab ───────────────────────────────────────────────────────────────

/// Displays steps, energy, heart rate GlassCards plus Zepp Scale manual inputs.
class VitalsTab extends ConsumerStatefulWidget {
  const VitalsTab({super.key});

  @override
  ConsumerState<VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends ConsumerState<VitalsTab> {
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _metAgeCtrl = TextEditingController();
  final _visceralCtrl = TextEditingController();
  final _bodyWaterCtrl = TextEditingController();

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _metAgeCtrl.dispose();
    _visceralCtrl.dispose();
    _bodyWaterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(healthProvider);

    // Placeholder step data for the 7-day sparkline.
    const stepHistory = [
      6200.0,
      8400.0,
      5100.0,
      9800.0,
      7300.0,
      10200.0,
      8700.0,
    ];
    final stepsToday = data.todaySteps;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Steps card
          _VitalCard(
            tokens: tokens,
            title: l10n.steps,
            icon: Icons.directions_walk_outlined,
            color: const Color(0xFF4CAF50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$stepsToday',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (stepsToday / 10000).clamp(0.0, 1.0),
                  backgroundColor: tokens.border,
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stepsToday} / 10 000',
                  style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: stepHistory
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFF4CAF50),
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.12),
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

          // Energy card
          _VitalCard(
            tokens: tokens,
            title: l10n.energy,
            icon: Icons.bolt_outlined,
            color: const Color(0xFFFF9800),
            child: Row(
              children: [
                Text(
                  '1 840 kcal',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                Text(
                  '+120 vs yesterday',
                  style: TextStyle(color: tokens.fgMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Heart rate card
          _VitalCard(
            tokens: tokens,
            title: l10n.heartRate,
            icon: Icons.favorite_outline,
            color: const Color(0xFFF44336),
            child: Row(
              children: [
                Text(
                  '72 bpm',
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vitalsMin(58),
                      style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                    ),
                    Text(
                      l10n.vitalsMax(104),
                      style: TextStyle(color: tokens.fgMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Zepp Scale section
          Text(
            l10n.zeppScale,
            style: TextStyle(
              color: tokens.fgBright,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ZeppInput(
            label: l10n.weightKg,
            controller: _weightCtrl,
            tokens: tokens,
          ),
          _ZeppInput(
            label: l10n.bodyFatPercent,
            controller: _bodyFatCtrl,
            tokens: tokens,
          ),
          _ZeppInputColored(
            label: l10n.metabolicAge,
            hint: l10n.vitalsMetabolicTarget,
            controller: _metAgeCtrl,
            tokens: tokens,
            targetBelow: 35,
          ),
          _ZeppInput(
            label: l10n.visceralFatRange,
            controller: _visceralCtrl,
            tokens: tokens,
          ),
          _ZeppInput(
            label: l10n.bodyWaterPercent,
            controller: _bodyWaterCtrl,
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

// ─── Vital card wrapper ───────────────────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.tokens,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final OrchestraColorTokens tokens;
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─── Zepp input rows ──────────────────────────────────────────────────────────

class _ZeppInput extends StatelessWidget {
  const _ZeppInput({
    required this.label,
    required this.controller,
    required this.tokens,
  });

  final String label;
  final TextEditingController controller;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: tokens.fgBright, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: tokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tokens.border),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZeppInputColored extends StatefulWidget {
  const _ZeppInputColored({
    required this.label,
    required this.hint,
    required this.controller,
    required this.tokens,
    required this.targetBelow,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final OrchestraColorTokens tokens;
  final double targetBelow;

  @override
  State<_ZeppInputColored> createState() => _ZeppInputColoredState();
}

class _ZeppInputColoredState extends State<_ZeppInputColored> {
  Color _valueColor(String text) {
    final val = double.tryParse(text);
    if (val == null) return widget.tokens.fgBright;
    return val < widget.targetBelow
        ? const Color(0xFF4CAF50)
        : const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(color: widget.tokens.fgMuted, fontSize: 13),
                ),
                Text(
                  widget.hint,
                  style: TextStyle(color: widget.tokens.fgMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, v, __) => TextField(
                controller: widget.controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: _valueColor(v.text), fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: widget.tokens.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.tokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: widget.tokens.border),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
