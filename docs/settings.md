# Settings Screen

## Overview

The Settings screen (`lib/screens/settings/settings_screen.dart`) is a `ConsumerStatefulWidget` presenting a tabbed interface for user preferences and account management.

## Tabs

| Tab | Route | Description |
|-----|-------|-------------|
| Profile | `/settings/profile` | Display name, avatar, email |
| Team | `/settings/team` | Team members and invite links |
| Appearance | `/settings/appearance` | Theme selector (25 themes), font size |
| Security | `/settings/security` | Password, 2FA, passkeys, active sessions |
| Notifications | `/settings/notifications` | Push, email and in-app notification toggles |

## Navigation

Accessed from the shell via `/settings`. Each tab corresponds to a sub-route so deep-linking directly to a tab is supported (e.g. `/settings/appearance`).

## Design

Uses the glass card design language. Each tab renders a `ListView` of `_SettingsSection` widgets containing `_SettingsTile` rows. Token colors are used throughout — no hardcoded hex values.
