# Notifications Screen

`lib/features/notifications/notifications_screen.dart` — real-time notification feed with swipe actions.

## Layout

Two-section `ListView`: **Updates** (feature changes, mentions) and **Health Alerts**, separated by `SliverPersistentHeader` labels.

Each row shows a type-specific icon, bold title, 1-line muted body, relative timestamp, and an unread blue dot when `isRead == false`.

## Interactions

- **Swipe left** — marks notification as read via `NotificationsDao.markRead(id)`
- **Tap** — navigates to source (`/projects/:id`, `/health`, or mention source)
- **Pull-to-refresh** — calls `SyncEngine.sync()` and marks all visible notifications read
- **Mark all read** button in header calls `NotificationsDao.markAllRead()`

## Empty State

`GlassCard` centred with `notifications_none` icon and "All caught up" label.

## State

`notifications_provider.dart` — Riverpod `StreamProvider` merging the Drift `NotificationsDao.watchAll()` stream with the `WsProvider` real-time stream. A separate unread-count stream drives the nav bar badge.
