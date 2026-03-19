# Health Managers

Three Riverpod `Notifier` providers that track daily wellness metrics.

## HydrationManager (`lib/features/health/hydration_manager.dart`)

Tracks daily water intake in millilitres.

- **Goal**: 2 000 ml/day
- `log(ml)` — adds intake, clamped to twice the goal
- `reset()` — clears for a new day
- Provider: `hydrationProvider`

## CaffeineManager (`lib/features/health/caffeine_manager.dart`)

Tracks daily caffeine intake in milligrams.

- **Safe limit**: 400 mg/day
- `log(mg)` — adds intake
- `isOverLimit` — `true` when state exceeds 400 mg
- `reset()` — clears for a new day
- Provider: `caffeineProvider`

## PomodoroManager (`lib/features/health/pomodoro_manager.dart`)

Classic Pomodoro timer with phase transitions.

| Phase | Duration |
|-------|----------|
| Work | 25 min |
| Short break | 5 min |
| Long break (every 4 sessions) | 15 min |

- `start()` — begins a work session
- `pause()` / `resume()` — pause/resume the current phase
- `reset()` — returns to idle state
- Provider: `pomodoroProvider`

`PomodoroState` exposes: `phase`, `remainingSeconds`, `completedSessions`, `isRunning`.
