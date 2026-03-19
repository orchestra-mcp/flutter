# Nutrition Manager and Shutdown Manager

## Nutrition Manager (`lib/core/health/nutrition_manager.dart`)

### FoodRegistry

Static registry of 29 foods across 4 condition groups:

| Group | Examples |
|-------|---------|
| IBS/GERD triggers | Whole Egg, Falafel, Deep Fried, Raw Onion, Raw Garlic, Cheddar/Yellow Cheese |
| Gout triggers | Red Meat, Liver, Duck, Beans, Lentils, Legumes |
| Fatty liver triggers | Refined Sugar, Honey, Nutella, Jam, White Flour, Mixed Carbs |
| Safe foods | Grilled Chicken, White Fish, Cottage Cheese, Greek Yogurt, Oats, Whole Wheat, Rice, Olive Oil, Avocado |

### NutritionState

- `safetyScore` — `(safe meals / total) * 100`
- `status` — `allSafe (≥75) / warning (50–75) / critical (<50)`
- `maxRiceRuleTriggered` — `true` when Rice portion > 5 spoons today
- `logMeal(food, portionSpoons)` — appends entry, triggers hygiene notification
- `removeEntry(id)` — removes entry by ID

### Provider
```dart
final nutritionProvider = NotifierProvider<NutritionNotifier, NutritionState>(...);
```

---

## Shutdown Manager (`lib/core/health/shutdown_manager.dart`)

### ShutdownState

- `shutdownWindowHours` — default 4 h before sleep
- `shutdownTime` — `targetSleepTime - shutdownWindowHours`
- `phase` — `inactive / active / violated`
- `flareRisk` — `none / moderate / high`
- `allowedDuringShutdown` — `['Water', 'Chamomile Tea', 'Anise Tea']`

### Key Behaviour
- `configure(targetSleepTime, shutdownWindowHours)` — sets sleep time and starts 1-second countdown timer
- `startShutdown()` / `endShutdown()` — manually control shutdown phase
- `addTask(task)` / `completeTask(task)` — manage planned shutdown tasks
- Timer auto-activates shutdown when `shutdownTime` is reached

### Provider
```dart
final shutdownProvider = NotifierProvider<ShutdownNotifier, ShutdownState>(...);
```

## Related Files
- `lib/core/health/nutrition_manager.dart`
- `lib/core/health/shutdown_manager.dart`
- `test/core/health/nutrition_manager_test.dart`
