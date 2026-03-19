# Health Integration

## Overview

Orchestra integrates with platform health SDKs to surface biometric and activity data in the Health tab. The `HealthKitService` provides a unified API over both Apple HealthKit (iOS/macOS) and Google Health Connect (Android 9+).

## HealthKitService (`lib/features/health/health_kit_service.dart`)

Singleton accessed via `HealthKitService.instance`.

### Permissions

Call `requestAuthorization()` before reading any data. This requests read access for:

- `STEPS`
- `ACTIVE_ENERGY_BURNED`
- `HEART_RATE`
- `BODY_MASS`
- `BODY_FAT_PERCENTAGE`
- `SLEEP_ASLEEP`

`hasPermissions()` returns a `bool` and can be checked before reading to avoid triggering the permission dialog again.

### Available Metrics

| Method | Returns | Notes |
|--------|---------|-------|
| `getTodaySteps()` | `int?` | Steps from midnight to now |
| `getTodayEnergy()` | `double?` | kcal burned today |
| `getLatestHeartRate()` | `int?` | Most recent BPM sample |
| `getLatestWeight()` | `double?` | Most recent body mass in kg |
| `getBodyFat()` | `double?` | Most recent body fat % |
| `getSleepHours(date)` | `double?` | Total sleep hours for that night |
| `getHeartRateRange(date)` | `({int min, int max})?` | HR range for a given day |

All methods return `null` when health data is unavailable (web, unsupported platform, or permission denied).

## Platform Notes

- **iOS / macOS**: Apple HealthKit — user prompted once per session.
- **Android**: Google Health Connect — requires Android 9+; user redirected to Health Connect app to grant permissions.
- **Web / Desktop (other)**: `HealthStub` (`lib/platform/stub/health_stub.dart`) is used; all methods return `null`; UI shows "Not available" placeholder.
