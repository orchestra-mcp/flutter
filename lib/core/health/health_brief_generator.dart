import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/health/caffeine_manager.dart';
import 'package:orchestra/core/health/health_service.dart';
import 'package:orchestra/core/health/hydration_manager.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';
import 'package:orchestra/core/health/pomodoro_manager.dart';
import 'package:orchestra/core/health/shutdown_manager.dart';
import 'package:orchestra/core/storage/storage_provider.dart';
import 'package:orchestra/features/health/health_provider.dart';

/// Aggregates health data from all providers and HealthKit, generates an
/// AI-powered health brief via MCP `ai_prompt`, and saves it as a tagged note.
class HealthBriefGenerator {
  const HealthBriefGenerator(this._ref);

  final Ref _ref;

  /// Generates a health brief and saves it as a note.
  ///
  /// Returns the note ID on success, or `null` on failure.
  Future<String?> generateAndSave() async {
    final mcp = _ref.read(mcpClientProvider);
    if (mcp == null) return null;

    // 1. Gather health context from providers
    final context = await _buildHealthContext();

    // 2. Send to AI
    final prompt = _buildPrompt(context);
    try {
      final result = await mcp.callTool('ai_prompt', {
        'prompt': prompt,
        'system_prompt': _systemPrompt,
        'wait': true,
        'model': 'sonnet',
        'permission_mode': 'bypassPermissions',
        'max_budget': 0.05,
      }, timeout: const Duration(seconds: 120));

      // Extract AI response text
      final briefContent = _extractText(result);
      if (briefContent == null || briefContent.isEmpty) return null;

      // 3. Save as note with health tags
      final now = DateTime.now();
      final title = 'Health Brief — ${now.month}/${now.day}/${now.year}';
      final repo = _ref.read(noteRepositoryProvider);
      final note = await repo.create(
        title: title,
        content: briefContent,
        tags: ['health', 'health-brief'],
      );

      // Trigger notes refresh
      _ref.read(notesRefreshProvider.notifier).refresh();

      return note.id;
    } catch (e) {
      debugPrint('[HealthBrief] Generation failed: $e');
      return null;
    }
  }

  Future<String> _buildHealthContext() async {
    final lines = <String>[];

    // Local manager data
    final hydration = _ref.read(hydrationProvider);
    final caffeine = _ref.read(caffeineProvider);
    final nutrition = _ref.read(nutritionProvider);
    final pomodoro = _ref.read(pomodoroProvider);
    final shutdown = _ref.read(shutdownProvider);

    // Health scores
    final summary = _ref.read(healthProvider);
    final ctx = summary.healthContext;
    if (ctx != null) {
      lines.add('## Health Scores');
      lines.add(ctx.summary);
      lines.add('');
    }

    // Hydration details
    lines.add('## Hydration');
    lines.add('- Total: ${hydration.totalMl}ml / ${hydration.goalMl}ml goal');
    lines.add('- Status: ${hydration.status.name}');
    lines.add('- Entries today: ${hydration.entries.length}');
    if (hydration.goutFlushRecommendation) {
      lines.add('- WARNING: Gout flush recommended (< 1500ml)');
    }
    lines.add('');

    // Caffeine details
    lines.add('## Caffeine');
    lines.add('- Total: ${caffeine.totalMg}mg');
    lines.add('- Status: ${caffeine.status.name}');
    lines.add('- Clean transition: ${caffeine.cleanTransitionPercent.round()}%');
    if (caffeine.overDailyLimit) {
      lines.add('- WARNING: Over daily limit (> 400mg)');
    }
    for (final entry in caffeine.entries) {
      lines.add('  - ${entry.type.name}: ${entry.mg}mg');
    }
    lines.add('');

    // Nutrition details
    lines.add('## Nutrition');
    lines.add('- Safety score: ${nutrition.safetyScore.round()}%');
    lines.add('- Status: ${nutrition.status.name}');
    lines.add('- Meals today: ${nutrition.todayEntries.length}');
    if (nutrition.maxRiceRuleTriggered) {
      lines.add('- WARNING: Rice limit exceeded (> 5 spoons)');
    }
    for (final entry in nutrition.todayEntries) {
      final safe = entry.food.isSafe ? 'safe' : 'trigger';
      lines.add(
        '  - ${entry.food.localizedName("en")} '
        '(${entry.food.category.name}, $safe)',
      );
    }
    lines.add('');

    // Pomodoro details
    lines.add('## Focus (Pomodoro)');
    lines.add(
      '- Completed: ${pomodoro.completedToday} / ${pomodoro.dailyTarget} target',
    );
    lines.add('- Current phase: ${pomodoro.phase.name}');
    lines.add('');

    // Shutdown details
    lines.add('## Shutdown Routine');
    lines.add('- Phase: ${shutdown.phase.name}');
    if (shutdown.targetSleepTime != null) {
      lines.add('- Target sleep: ${shutdown.targetSleepTime}');
    }
    if (shutdown.plannedTasks.isNotEmpty) {
      lines.add(
        '- Tasks: ${shutdown.completedTasks.length}/${shutdown.plannedTasks.length} completed',
      );
    }
    lines.add('- Flare risk: ${shutdown.flareRisk.name}');
    lines.add('');

    // HealthKit vitals (if available)
    try {
      final hs = _ref.read(healthServiceProvider);
      final now = DateTime.now();
      final steps = await hs.getSteps(now);
      final hr = await hs.getHeartRate(now);
      final sleep = await hs.getSleepHours(now);
      final calories = await hs.getActiveCalories(now);
      final weight = await hs.getLatestWeight();
      final oxygen = await hs.getBloodOxygen(now);
      final respiratory = await hs.getRespiratoryRate(now);

      lines.add('## Vitals (HealthKit)');
      if (steps != null) lines.add('- Steps: $steps');
      if (hr != null) lines.add('- Heart rate: $hr bpm');
      if (sleep != null) lines.add('- Sleep: ${sleep.toStringAsFixed(1)} hours');
      if (calories != null) {
        lines.add('- Active calories: ${calories.round()} kcal');
      }
      if (weight != null) lines.add('- Weight: ${weight.toStringAsFixed(1)} kg');
      if (oxygen != null) lines.add('- Blood oxygen: ${oxygen.round()}%');
      if (respiratory != null) {
        lines.add('- Respiratory rate: ${respiratory.round()} breaths/min');
      }
      lines.add('');
    } catch (_) {
      // HealthKit not available on this platform
    }

    return lines.join('\n');
  }

  String _buildPrompt(String healthData) {
    return 'Generate a comprehensive health brief based on the following data:\n\n'
        '$healthData\n\n'
        'Provide actionable insights, highlight wins, flag concerns, '
        'and give specific recommendations for the rest of the day.';
  }

  static const _systemPrompt =
      'You are a personal health analyst. Generate a well-structured markdown '
      'health brief from the provided data. Include:\n'
      '1. **Summary** — 2-3 sentence overall assessment\n'
      '2. **Wins** — What the user is doing well today\n'
      '3. **Concerns** — Areas that need attention (hydration, triggers, caffeine, etc.)\n'
      '4. **Recommendations** — Specific, actionable steps for the rest of the day\n'
      '5. **Health Conditions** — Note any IBS/GERD/gout/fatty liver triggers found in meals\n\n'
      'Use markdown headers, bullet points, and emoji sparingly for readability. '
      'Be encouraging but honest. Focus on the data provided, not generic advice.';

  String? _extractText(Map<String, dynamic> result) {
    // Check for tool-level error
    if (result['isError'] == true) return null;

    final content = result['content'];
    if (content is List && content.isNotEmpty) {
      final first = content[0];
      if (first is Map && first['type'] == 'text') {
        return first['text'] as String?;
      }
    }
    return result['text'] as String? ??
        result['response'] as String?;
  }
}
