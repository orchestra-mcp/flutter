# HealthKit and Health Connect Service

## Overview

`HealthKitService` provides a unified API over Apple HealthKit (iOS/macOS) and Google Health Connect (Android). Returns `null` for all data methods when permissions are not granted or the platform is unsupported.

## File

`lib/features/health/health_kit_service.dart`

## API

| Method | Returns | Description |
|--------|---------|-------------|
| `requestAuthorization()` | `Future<bool>` | Requests STEPS, ACTIVE_ENERGY_BURNED, HEART_RATE, BODY_MASS, BODY_FAT_PERCENTAGE, SLEEP_ASLEEP |
| `hasPermissions()` | `Future<bool>` | Checks existing permission state |
| `getTodaySteps()` | `Future<int?>` | Steps from midnight to now |
| `getTodayEnergy()` | `Future<double?>` | Active energy (kcal) today |
| `getLatestHeartRate()` | `Future<int?>` | Most recent heart rate sample (bpm) |
| `getLatestWeight()` | `Future<double?>` | Most recent body mass (kg) |
| `getBodyFat()` | `Future<double?>` | Most recent body fat percentage |
| `getSleepHours(date)` | `Future<double?>` | Total sleep hours for a given night |
| `getHeartRateRange(date)` | `Future<({int min, int max})?>` | Min/max bpm for a given day |

## Platform Notes

- **iOS/macOS**: reads Apple HealthKit via `health` package v12.2.0
- **Android**: reads Google Health Connect (requires Android 9+)
- **Web/Desktop**: all methods return `null`
