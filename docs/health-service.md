# Health Service

`HealthKitService` (`lib/features/health/health_kit_service.dart`) provides a unified interface for reading health data from Apple HealthKit (iOS/macOS) and Google Health Connect (Android). All methods return `null` on unsupported platforms (web, desktop without the health package configured).

## Usage

```dart
final service = HealthKitService.instance;

// Request permissions first
final granted = await service.requestAuthorization();
if (!granted) return;

// Read data
final steps = await service.getTodaySteps();
final bpm   = await service.getLatestHeartRate();
```

## Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `requestAuthorization()` | `Future<bool>` | Requests read permissions. Must be called first. |
| `hasPermissions()` | `Future<bool>` | Checks whether permissions are currently granted. |
| `getTodaySteps()` | `Future<int?>` | Steps from midnight today to now. |
| `getTodayEnergy()` | `Future<double?>` | Active energy burned today in kcal. |
| `getLatestHeartRate()` | `Future<int?>` | Most recent heart rate sample in bpm. |
| `getLatestWeight()` | `Future<double?>` | Most recent body mass in kg. |
| `getBodyFat()` | `Future<double?>` | Most recent body fat percentage. |
| `getSleepHours(DateTime)` | `Future<double?>` | Total sleep hours for the given night. |
| `getHeartRateRange(DateTime)` | `Future<({int min, int max})?>` | Min/max bpm for the given day. |

## Platform Support

| Platform | Backend |
|----------|---------|
| iOS / macOS | Apple HealthKit |
| Android 9+ | Google Health Connect |
| Web / Desktop | Returns `null` for all methods |

## Permissions Requested

`STEPS`, `ACTIVE_ENERGY_BURNED`, `HEART_RATE`, `BODY_MASS`, `BODY_FAT_PERCENTAGE`, `SLEEP_ASLEEP`
