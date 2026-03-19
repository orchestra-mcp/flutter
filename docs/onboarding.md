# Onboarding Flow

## Overview

Multi-step onboarding flow collecting user profile, team setup, and health baseline.

## Screens

### `lib/screens/onboarding/onboarding_screen.dart`

Five-page `PageView` with progress dots, Skip/Next/Back navigation. Pages:

1. Name — first and last name fields
2. Profile — bio and position
3. Gender — radio selection
4. Team — create or join with name/invite code
5. Health Baseline — weight, height, water goal, sleep schedule

### `lib/screens/onboarding/onboarding_page.dart`

Reusable page widget with GlassCard container and gradient mesh background.

## Completion

`OnboardingProvider.complete()` persists data to Drift, calls `POST /api/onboarding`, sets `onboarding_done` in SharedPreferences, and navigates to `/login`.
