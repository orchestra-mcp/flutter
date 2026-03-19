import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/glass_card.dart';
import 'package:shimmer/shimmer.dart';

/// Nutrition tab — log meals, view safety score, category breakdown,
/// trigger warnings, and food registry.
class NutritionTab extends ConsumerWidget {
  const NutritionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);

    // Loading state — full shimmer skeleton
    if (state.isLoading && state.entries.isEmpty) {
      return const _ShimmerSkeleton();
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: tokens.accent,
      backgroundColor: tokens.bgAlt,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Error banner
          if (state.error != null)
            _ErrorBanner(
              error: state.error!,
              tokens: tokens,
              onRetry: notifier.refresh,
            ),

          // Safety score card — arc gauge
          _SafetyScoreCard(state: state, tokens: tokens),
          const SizedBox(height: 16),

          // Trigger condition warnings
          if (_triggeredConditions(state).isNotEmpty) ...[
            _TriggerWarningsCard(
              conditions: _triggeredConditions(state),
              tokens: tokens,
            ),
            const SizedBox(height: 16),
          ],

          // Category breakdown
          if (state.todayEntries.isNotEmpty) ...[
            _CategoryBreakdownCard(
              entries: state.todayEntries,
              tokens: tokens,
            ),
            const SizedBox(height: 16),
          ],

          // Log meal
          _LogMealCard(tokens: tokens, notifier: notifier),
          const SizedBox(height: 16),

          // Today's log — or empty state
          if (state.todayEntries.isNotEmpty)
            _TodaysLogCard(
              entries: state.todayEntries,
              tokens: tokens,
              notifier: notifier,
            )
          else
            const _EmptyMealState(),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: notifier.reset,
              child: Text(
                l10n.resetToday,
                style: TextStyle(color: tokens.fgMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Collect the unique trigger conditions from today's entries.
  Set<TriggerCondition> _triggeredConditions(NutritionState state) {
    final conditions = <TriggerCondition>{};
    for (final entry in state.todayEntries) {
      conditions.addAll(entry.food.triggerConditions);
    }
    return conditions;
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading skeleton
// ---------------------------------------------------------------------------

class _ShimmerSkeleton extends StatelessWidget {
  const _ShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final baseColor = tokens.bgAlt;
    final highlightColor = tokens.border.withValues(alpha: 0.15);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Score card placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Log meal placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          // Log entries placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error banner with retry
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.error,
    required this.tokens,
    required this.onRetry,
  });

  final String error;
  final OrchestraColorTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withValues(alpha: 0.1),
          border: Border.all(
            color: const Color(0xFFF44336).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFF44336),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).retry,
                  style: const TextStyle(
                    color: Color(0xFFF44336),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
// Safety score card with arc gauge
// ---------------------------------------------------------------------------

class _SafetyScoreCard extends StatelessWidget {
  const _SafetyScoreCard({required this.state, required this.tokens});

  final NutritionState state;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          _ArcGauge(score: state.safetyScore, tokens: tokens),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).safetyScore,
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusChip(status: state.status, tokens: tokens),
                if (state.maxRiceRuleTriggered)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      AppLocalizations.of(context).maxRiceRuleTriggered,
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 11,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppLocalizations.of(context).itemsLoggedToday(state.todayEntries.length),
                    style: TextStyle(
                      color: tokens.fgDim,
                      fontSize: 11,
                    ),
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

// ---------------------------------------------------------------------------
// Arc gauge — replaces simple circle score badge
// ---------------------------------------------------------------------------

class _ArcGauge extends StatelessWidget {
  const _ArcGauge({required this.score, required this.tokens});

  final double score;
  final OrchestraColorTokens tokens;

  Color get _color {
    if (score >= 75) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _ArcGaugePainter(
          score: score,
          activeColor: _color,
          trackColor: tokens.border.withValues(alpha: 0.15),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toInt().toString(),
                style: TextStyle(
                  color: _color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              Text(
                AppLocalizations.of(context).outOf100,
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({
    required this.score,
    required this.activeColor,
    required this.trackColor,
  });

  final double score;
  final Color activeColor;
  final Color trackColor;

  static const double _startAngle = 135.0; // degrees
  static const double _sweepAngle = 270.0; // degrees

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Track arc (background)
    canvas.drawArc(
      rect,
      _degToRad(_startAngle),
      _degToRad(_sweepAngle),
      false,
      trackPaint,
    );

    // Active arc (score)
    final scoreSweep = (_sweepAngle * (score / 100)).clamp(0.0, _sweepAngle);
    if (scoreSweep > 0) {
      canvas.drawArc(
        rect,
        _degToRad(_startAngle),
        _degToRad(scoreSweep),
        false,
        activePaint,
      );
    }
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.trackColor != trackColor;
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.tokens});

  final NutritionStatus status;
  final OrchestraColorTokens tokens;

  String _label(AppLocalizations l10n) {
    switch (status) {
      case NutritionStatus.allSafe:
        return l10n.nutritionAllSafe;
      case NutritionStatus.warning:
        return l10n.nutritionWarning;
      case NutritionStatus.critical:
        return l10n.nutritionCritical;
    }
  }

  Color get _color {
    switch (status) {
      case NutritionStatus.allSafe:
        return const Color(0xFF4CAF50);
      case NutritionStatus.warning:
        return const Color(0xFFFF9800);
      case NutritionStatus.critical:
        return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(_label(l10n), style: TextStyle(color: _color, fontSize: 11)),
    );
  }
}

// ---------------------------------------------------------------------------
// Trigger condition warnings card
// ---------------------------------------------------------------------------

class _TriggerWarningsCard extends StatelessWidget {
  const _TriggerWarningsCard({
    required this.conditions,
    required this.tokens,
  });

  final Set<TriggerCondition> conditions;
  final OrchestraColorTokens tokens;

  static Map<TriggerCondition, String> _conditionLabels(AppLocalizations l10n) => {
    TriggerCondition.ibs: l10n.conditionIbs,
    TriggerCondition.gerd: l10n.conditionGerd,
    TriggerCondition.gout: l10n.conditionGout,
    TriggerCondition.fattyLiver: l10n.conditionFattyLiver,
  };

  static const _conditionIcons = <TriggerCondition, IconData>{
    TriggerCondition.ibs: Icons.warning_amber_rounded,
    TriggerCondition.gerd: Icons.local_fire_department_rounded,
    TriggerCondition.gout: Icons.healing_rounded,
    TriggerCondition.fattyLiver: Icons.monitor_heart_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = _conditionLabels(l10n);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFFFF9800),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.flareRisk,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _conditionIcons[c] ?? Icons.warning_amber_rounded,
                      color: const Color(0xFFFF9800),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[c] ?? c.name,
                      style: const TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category breakdown card
// ---------------------------------------------------------------------------

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.entries,
    required this.tokens,
  });

  final List<NutritionEntry> entries;
  final OrchestraColorTokens tokens;

  static Map<FoodCategory, String> _categoryLabels(AppLocalizations l10n) => {
    FoodCategory.protein: l10n.categoryProtein,
    FoodCategory.carb: l10n.categoryCarbs,
    FoodCategory.fat: l10n.categoryFats,
    FoodCategory.drink: l10n.categoryDrinks,
    FoodCategory.snack: l10n.categorySnacks,
  };

  static const _categoryIcons = <FoodCategory, IconData>{
    FoodCategory.protein: Icons.egg_alt_outlined,
    FoodCategory.carb: Icons.grain_outlined,
    FoodCategory.fat: Icons.water_drop_outlined,
    FoodCategory.drink: Icons.local_cafe_outlined,
    FoodCategory.snack: Icons.cookie_outlined,
  };

  static const _categoryColors = <FoodCategory, Color>{
    FoodCategory.protein: Color(0xFF42A5F5),
    FoodCategory.carb: Color(0xFFFFCA28),
    FoodCategory.fat: Color(0xFFEF5350),
    FoodCategory.drink: Color(0xFF26C6DA),
    FoodCategory.snack: Color(0xFFAB47BC),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = _categoryLabels(l10n);

    // Count items per category
    final counts = <FoodCategory, int>{};
    for (final entry in entries) {
      counts[entry.food.category] =
          (counts[entry.food.category] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final total = entries.length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.componentBreakdown,
            style: TextStyle(
              color: tokens.fgBright,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Stacked horizontal bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: counts.entries.map((e) {
                  final fraction = e.value / total;
                  final color =
                      _categoryColors[e.key] ?? tokens.accent;
                  return Expanded(
                    flex: (fraction * 1000).round(),
                    child: Container(color: color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category rows
          ...FoodCategory.values
              .where((cat) => counts.containsKey(cat))
              .map((cat) {
            final count = counts[cat]!;
            final color =
                _categoryColors[cat] ?? tokens.accent;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _categoryIcons[cat] ?? Icons.circle,
                    color: tokens.fgMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      labels[cat] ?? cat.name,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    l10n.nItemsPlural(count),
                    style: TextStyle(
                      color: tokens.fgMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log meal card
// ---------------------------------------------------------------------------

class _LogMealCard extends StatefulWidget {
  const _LogMealCard({required this.tokens, required this.notifier});

  final OrchestraColorTokens tokens;
  final NutritionNotifier notifier;

  @override
  State<_LogMealCard> createState() => _LogMealCardState();
}

class _LogMealCardState extends State<_LogMealCard> {
  FoodItem? _selectedFood;
  double _spoons = 2.0;
  String _query = '';

  List<FoodItem> get _filtered {
    final foods = FoodRegistry.allFoods;
    if (_query.isEmpty) return foods;
    final q = _query.toLowerCase();
    return foods.where((f) {
      return f.title.values.any((v) => v.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.logMeal,
            style: TextStyle(
              color: tokens.fgBright,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          // Search field
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: tokens.fgBright, fontSize: 14),
            cursorColor: tokens.accent,
            decoration: InputDecoration(
              hintText: l10n.addMeal,
              hintStyle: TextStyle(color: tokens.fgDim, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  color: tokens.fgDim, size: 18),
              filled: true,
              fillColor: tokens.bg.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: tokens.borderFaint, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: tokens.borderFaint, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.accent),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Searchable food list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final f = _filtered[i];
                final isSelected = _selectedFood == f;
                final name = f.localizedName(locale);
                return Dismissible(
                  key: ValueKey(f.name),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (_) async {
                    setState(() => _selectedFood = f);
                    return false;
                  },
                  background: Container(
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsetsDirectional.only(start: 16),
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: tokens.accent, size: 20),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFood = f),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: tokens.accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            f.isSafe
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: f.isSafe
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isSelected
                                    ? tokens.accent
                                    : tokens.fgBright,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!f.isSafe)
                            ...f.triggerConditions.map((t) => Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 4),
                                  child: Text(
                                    t.name.toUpperCase(),
                                    style: TextStyle(
                                        color: const Color(0xFFFF9800)
                                            .withValues(alpha: 0.7),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600),
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                AppLocalizations.of(context).portionSpoons(_spoons.toStringAsFixed(1)),
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
              Expanded(
                child: Slider(
                  value: _spoons,
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  activeColor: tokens.accent,
                  inactiveColor: tokens.border.withValues(alpha: 0.3),
                  onChanged: (v) => setState(() => _spoons = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedFood == null
                  ? null
                  : () {
                      widget.notifier.logMeal(_selectedFood!, _spoons);
                      setState(() {
                        _selectedFood = null;
                        _spoons = 2.0;
                      });
                    },
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.bg,
                disabledBackgroundColor:
                    tokens.accent.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(AppLocalizations.of(context).logMeal),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's log card
// ---------------------------------------------------------------------------

class _TodaysLogCard extends StatelessWidget {
  const _TodaysLogCard({
    required this.entries,
    required this.tokens,
    required this.notifier,
  });

  final List<NutritionEntry> entries;
  final OrchestraColorTokens tokens;
  final NutritionNotifier notifier;

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).today,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context).nItemsPlural(entries.length),
                style: TextStyle(
                  color: tokens.fgDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.reversed.take(8).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        e.food.isSafe
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        color: e.food.isSafe
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.food.localizedName(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            color: tokens.fgBright,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(e.timestamp),
                        style: TextStyle(
                          color: tokens.fgDim,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.portionSpoons.toStringAsFixed(1)} sp',
                        style: TextStyle(
                          color: tokens.fgMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => notifier.removeEntry(e.id),
                        child: Icon(
                          Icons.close,
                          color: tokens.fgDim,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty meal state
// ---------------------------------------------------------------------------

class _EmptyMealState extends StatelessWidget {
  const _EmptyMealState();

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return GlassCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Icon(
              Icons.restaurant_menu_rounded,
              color: tokens.fgDim,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noResults,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).addMeal,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.fgDim,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
