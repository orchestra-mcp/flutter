import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/api/api_provider.dart';
import 'package:orchestra/core/providers/health_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';

/// Health notifications settings tab — mirrors the Swift health-debug
/// ProfileSettingsView notification section. Loads from healthProfileProvider,
/// saves individual field changes immediately via updateHealthProfile.
class HealthSettingsTab extends ConsumerStatefulWidget {
  const HealthSettingsTab({super.key});

  @override
  ConsumerState<HealthSettingsTab> createState() => _HealthSettingsTabState();
}

class _HealthSettingsTabState extends ConsumerState<HealthSettingsTab> {
  /// Local overrides applied optimistically while a save is in flight.
  Map<String, dynamic>? _pendingProfile;
  bool _saving = false;

  // ── Persistence ──────────────────────────────────────────────────────────

  /// Saves a single field update, applying it optimistically to the UI.
  Future<void> _save(
    String key,
    dynamic value,
    Map<String, dynamic> current,
  ) async {
    final updated = {...current, key: value};
    setState(() {
      _pendingProfile = updated;
      _saving = true;
    });
    try {
      await ref.read(apiClientProvider).updateHealthProfile({key: value});
      ref.invalidate(healthProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToSaveSetting}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingProfile = null;
          _saving = false;
        });
      }
    }
  }

  /// Saves two fields atomically (used for hour+minute time pairs).
  Future<void> _saveTimePair(
    String hourKey,
    int hour,
    String minuteKey,
    int minute,
    Map<String, dynamic> current,
  ) async {
    final updated = {...current, hourKey: hour, minuteKey: minute};
    setState(() {
      _pendingProfile = updated;
      _saving = true;
    });
    try {
      await ref.read(apiClientProvider).updateHealthProfile({
        hourKey: hour,
        minuteKey: minute,
      });
      ref.invalidate(healthProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).failedToSaveSetting}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingProfile = null;
          _saving = false;
        });
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  int _intVal(Map<String, dynamic> p, String key, [int fallback = 0]) =>
      (p[key] as num?)?.toInt() ?? fallback;

  bool _boolVal(Map<String, dynamic> p, String key) => p[key] == true;

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(
    Map<String, dynamic> profile,
    String hourKey,
    String minuteKey,
  ) async {
    final currentHour = _intVal(profile, hourKey);
    final currentMinute = _intVal(profile, minuteKey);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked != null && mounted) {
      await _saveTimePair(
        hourKey,
        picked.hour,
        minuteKey,
        picked.minute,
        profile,
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(healthProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: tokens.fgDim),
              const SizedBox(height: 12),
              Text(
                l10n.healthSettingsFailedToLoadProfile,
                style: TextStyle(color: tokens.fgBright, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '$error',
                style: TextStyle(color: tokens.fgDim, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.invalidate(healthProfileProvider),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      ),
      data: (raw) {
        final profile = _pendingProfile ?? raw;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Notifications section ────────────────────────────────────
            _sectionHeader(tokens, l10n.healthSettingsNotifications),
            const SizedBox(height: 12),
            _buildNotificationsSection(tokens, profile, l10n),

            const SizedBox(height: 28),

            // ── Sleep section ────────────────────────────────────────────
            _sectionHeader(tokens, l10n.healthSettingsSleep),
            const SizedBox(height: 12),
            _buildSleepSection(tokens, profile, l10n),
          ],
        );
      },
    );
  }

  // ── Notifications section ──────────────────────────────────────────────

  Widget _buildNotificationsSection(
    OrchestraColorTokens tokens,
    Map<String, dynamic> profile,
    AppLocalizations l10n,
  ) {
    final weightEnabled = _boolVal(profile, 'weightAlertEnabled');
    final hygieneEnabled = _boolVal(profile, 'hygieneAlertEnabled');
    final pomStartEnabled = _boolVal(profile, 'pomodoroStartAlertEnabled');
    final pomEndEnabled = _boolVal(profile, 'pomodoroEndAlertEnabled');
    final mealEnabled = _boolVal(profile, 'mealReminderEnabled');
    final coffeeEnabled = _boolVal(profile, 'coffeeAlertEnabled');
    final hydrationEnabled = _boolVal(profile, 'hydrationAlertEnabled');
    final movementEnabled = _boolVal(profile, 'movementAlertEnabled');

    // Collect all row widgets so we can insert dividers between them.
    final List<Widget> rows = [];

    // 1. Weight Check-in
    rows.add(
      _ToggleRow(
        icon: Icons.monitor_weight_outlined,
        label: l10n.healthSettingsWeightCheckin,
        subtitle: l10n.healthSettingsWeightCheckinSub,
        value: weightEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('weightAlertEnabled', v, profile),
      ),
    );
    if (weightEnabled) {
      rows.add(
        _TimePickerRow(
          icon: Icons.schedule_rounded,
          label: l10n.healthSettingsAlertTime,
          subtitle: l10n.healthSettingsAlertTimeSub,
          time: _formatTime(
            _intVal(profile, 'weightAlertHour', 8),
            _intVal(profile, 'weightAlertMinute'),
          ),
          tokens: tokens,
          onTap: _saving
              ? null
              : () =>
                    _pickTime(profile, 'weightAlertHour', 'weightAlertMinute'),
        ),
      );
      rows.add(
        _StepperRow(
          icon: Icons.calendar_today_rounded,
          label: l10n.healthSettingsDelayDays,
          subtitle: l10n.healthSettingsDelayDaysSub,
          value: _intVal(profile, 'weightAlertDelayDays', 1),
          min: 1,
          max: 14,
          step: 1,
          unit: l10n.healthSettingsDaysUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('weightAlertDelayDays', v, profile),
        ),
      );
    }

    // 2. Hygiene Reminder
    rows.add(
      _ToggleRow(
        icon: Icons.clean_hands_outlined,
        label: l10n.healthSettingsHygieneReminder,
        subtitle: l10n.healthSettingsHygieneReminderSub,
        value: hygieneEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('hygieneAlertEnabled', v, profile),
      ),
    );
    if (hygieneEnabled) {
      rows.add(
        _StepperRow(
          icon: Icons.calendar_today_rounded,
          label: l10n.healthSettingsDelayDays,
          subtitle: l10n.healthSettingsDelayDaysSub,
          value: _intVal(profile, 'hygieneAlertDelayDays', 1),
          min: 1,
          max: 7,
          step: 1,
          unit: l10n.healthSettingsDaysUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('hygieneAlertDelayDays', v, profile),
        ),
      );
    }

    // 3. Pomodoro Start Alert
    rows.add(
      _ToggleRow(
        icon: Icons.play_circle_outline_rounded,
        label: l10n.healthSettingsPomodoroStartAlert,
        subtitle: l10n.healthSettingsPomodoroStartAlertSub,
        value: pomStartEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('pomodoroStartAlertEnabled', v, profile),
      ),
    );
    if (pomStartEnabled) {
      rows.add(
        _StepperRow(
          icon: Icons.timer_outlined,
          label: l10n.healthSettingsLeadTime,
          subtitle: l10n.healthSettingsLeadTimeStartSub,
          value: _intVal(profile, 'pomodoroStartLeadMinutes', 5),
          min: 5,
          max: 60,
          step: 5,
          unit: l10n.healthSettingsMinUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('pomodoroStartLeadMinutes', v, profile),
        ),
      );
    }

    // 4. Pomodoro End Alert
    rows.add(
      _ToggleRow(
        icon: Icons.stop_circle_outlined,
        label: l10n.healthSettingsPomodoroEndAlert,
        subtitle: l10n.healthSettingsPomodoroEndAlertSub,
        value: pomEndEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('pomodoroEndAlertEnabled', v, profile),
      ),
    );
    if (pomEndEnabled) {
      rows.add(
        _StepperRow(
          icon: Icons.timer_outlined,
          label: l10n.healthSettingsLeadTime,
          subtitle: l10n.healthSettingsLeadTimeEndSub,
          value: _intVal(profile, 'pomodoroEndLeadMinutes', 5),
          min: 5,
          max: 60,
          step: 5,
          unit: l10n.healthSettingsMinUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('pomodoroEndLeadMinutes', v, profile),
        ),
      );
    }

    // 5. Heart Rate High
    rows.add(
      _StepperRow(
        icon: Icons.heart_broken_rounded,
        label: l10n.healthSettingsHeartRateHigh,
        subtitle: l10n.healthSettingsHeartRateHighSub,
        value: _intVal(profile, 'heartRateHighThreshold', 120),
        min: 80,
        max: 200,
        step: 5,
        unit: l10n.healthSettingsBpmUnit,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('heartRateHighThreshold', v, profile),
      ),
    );

    // 6. Heart Rate Low
    rows.add(
      _StepperRow(
        icon: Icons.favorite_border_rounded,
        label: l10n.healthSettingsHeartRateLow,
        subtitle: l10n.healthSettingsHeartRateLowSub,
        value: _intVal(profile, 'heartRateLowThreshold', 50),
        min: 30,
        max: 70,
        step: 5,
        unit: l10n.healthSettingsBpmUnit,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('heartRateLowThreshold', v, profile),
      ),
    );

    // 7. Meal Reminder
    rows.add(
      _ToggleRow(
        icon: Icons.restaurant_outlined,
        label: l10n.healthSettingsMealReminder,
        subtitle: l10n.healthSettingsMealReminderSub,
        value: mealEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('mealReminderEnabled', v, profile),
      ),
    );

    // 8. Coffee Time
    rows.add(
      _ToggleRow(
        icon: Icons.coffee_outlined,
        label: l10n.healthSettingsCoffeeTime,
        subtitle: l10n.healthSettingsCoffeeTimeSub,
        value: coffeeEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('coffeeAlertEnabled', v, profile),
      ),
    );
    if (coffeeEnabled) {
      rows.add(
        _TimePickerRow(
          icon: Icons.schedule_rounded,
          label: l10n.healthSettingsCutoffTime,
          subtitle: l10n.healthSettingsCutoffTimeSub,
          time: _formatTime(
            _intVal(profile, 'coffeeAlertHour', 14),
            _intVal(profile, 'coffeeAlertMinute'),
          ),
          tokens: tokens,
          onTap: _saving
              ? null
              : () =>
                    _pickTime(profile, 'coffeeAlertHour', 'coffeeAlertMinute'),
        ),
      );
    }

    // 9. Hydration Alert
    rows.add(
      _ToggleRow(
        icon: Icons.water_drop_outlined,
        label: l10n.healthSettingsHydrationAlert,
        subtitle: l10n.healthSettingsHydrationAlertSub,
        value: hydrationEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('hydrationAlertEnabled', v, profile),
      ),
    );
    if (hydrationEnabled) {
      rows.add(
        _StepperRow(
          icon: Icons.timer_outlined,
          label: l10n.healthSettingsAlertGap,
          subtitle: l10n.healthSettingsAlertGapSub,
          value: _intVal(profile, 'hydrationAlertGapMinutes', 60),
          min: 30,
          max: 180,
          step: 15,
          unit: l10n.healthSettingsMinUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('hydrationAlertGapMinutes', v, profile),
        ),
      );
    }

    // 10. Movement Alert
    rows.add(
      _ToggleRow(
        icon: Icons.directions_walk_rounded,
        label: l10n.healthSettingsMovementAlert,
        subtitle: l10n.healthSettingsMovementAlertSub,
        value: movementEnabled,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('movementAlertEnabled', v, profile),
      ),
    );
    if (movementEnabled) {
      rows.add(
        _StepperRow(
          icon: Icons.timer_outlined,
          label: l10n.healthSettingsInterval,
          subtitle: l10n.healthSettingsIntervalSub,
          value: _intVal(profile, 'movementAlertIntervalMinutes', 60),
          min: 30,
          max: 120,
          step: 15,
          unit: l10n.healthSettingsMinUnit,
          tokens: tokens,
          onChanged: _saving
              ? null
              : (v) => _save('movementAlertIntervalMinutes', v, profile),
        ),
      );
    }

    // 11. GERD Warning
    rows.add(
      _StepperRow(
        icon: Icons.warning_amber_rounded,
        label: l10n.healthSettingsGerdWarning,
        subtitle: l10n.healthSettingsGerdWarningSub,
        value: _intVal(profile, 'gerdShutdownLeadMinutes', 30),
        min: 5,
        max: 60,
        step: 5,
        unit: l10n.healthSettingsMinUnit,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('gerdShutdownLeadMinutes', v, profile),
      ),
    );

    return _buildGroupBox(tokens, rows);
  }

  // ── Sleep section ──────────────────────────────────────────────────────

  Widget _buildSleepSection(
    OrchestraColorTokens tokens,
    Map<String, dynamic> profile,
    AppLocalizations l10n,
  ) {
    final rows = <Widget>[
      // 12. Bedtime
      _TimePickerRow(
        icon: Icons.bedtime_outlined,
        label: l10n.healthSettingsBedtime,
        subtitle: l10n.healthSettingsBedtimeSub,
        time: _formatTime(
          _intVal(profile, 'sleepBedtimeHour', 23),
          _intVal(profile, 'sleepBedtimeMinute'),
        ),
        tokens: tokens,
        onTap: _saving
            ? null
            : () =>
                  _pickTime(profile, 'sleepBedtimeHour', 'sleepBedtimeMinute'),
      ),

      // 13. Shutdown Window
      _StepperRow(
        icon: Icons.power_settings_new_rounded,
        label: l10n.healthSettingsShutdownWindow,
        subtitle: l10n.healthSettingsShutdownWindowSub,
        value: _intVal(profile, 'shutdownWindowHours', 2),
        min: 1,
        max: 6,
        step: 1,
        unit: l10n.healthSettingsHrsUnit,
        tokens: tokens,
        onChanged: _saving
            ? null
            : (v) => _save('shutdownWindowHours', v, profile),
      ),
    ];

    return _buildGroupBox(tokens, rows);
  }

  // ── Shared UI builders ─────────────────────────────────────────────────

  Widget _sectionHeader(OrchestraColorTokens tokens, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: tokens.fgBright,
    ),
  );

  /// Wraps a list of row widgets in a decorated container with dividers.
  Widget _buildGroupBox(OrchestraColorTokens tokens, List<Widget> rows) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: tokens.border.withValues(alpha: 0.4),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

// ── Toggle row (switch) ──────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.tokens,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final OrchestraColorTokens tokens;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon, tokens: tokens),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: tokens.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Stepper row (+/- buttons with value) ─────────────────────────────────────

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.tokens,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final OrchestraColorTokens tokens;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final canDecrement = value - step >= min;
    final canIncrement = value + step <= max;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon, tokens: tokens),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
              ],
            ),
          ),
          // Stepper control
          Container(
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  enabled: canDecrement && onChanged != null,
                  tokens: tokens,
                  onTap: canDecrement && onChanged != null
                      ? () => onChanged!(value - step)
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$value $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.fgBright,
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  enabled: canIncrement && onChanged != null,
                  tokens: tokens,
                  onTap: canIncrement && onChanged != null
                      ? () => onChanged!(value + step)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time picker row ──────────────────────────────────────────────────────────

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.time,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String time;
  final OrchestraColorTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconBox(icon: icon, tokens: tokens),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.fgBright,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: tokens.fgDim),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.fgBright,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

// ── Shared small widgets ─────────────────────────────────────────────────────

/// 32x32 accent-tinted icon container used by all row types.
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.tokens});

  final IconData icon;
  final OrchestraColorTokens tokens;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 16, color: tokens.accent),
      ),
    );
  }
}

/// A single +/- button inside the stepper control.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final OrchestraColorTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: true,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? tokens.accent
                : tokens.fgDim.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
