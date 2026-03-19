# Summary Screen

`lib/screens/summary/summary_screen.dart` — the main dashboard shown after login. Displays six reactive `GlassCard` widgets in a `CustomScrollView` with pull-to-refresh.

## Cards

| Card | Data Source | Route |
|------|-------------|-------|
| Projects | Active project count, in-progress feature count | `/projects` |
| Features | Completed today, open bugs, in-review count, weekly progress | — |
| Health | Today's steps, hydration ml, sleep hours | `/health` |
| Agents | Active session count, last agent name | `/library/agents` |
| Notifications | Unread count, latest notification preview | `/notifications` |
| Quick Actions | New Feature, New Note, Start Session buttons | Various |

## Pull-to-Refresh

Wraps the scroll view in a `RefreshIndicator`. On pull, calls `SyncEngine.sync()` to fetch the latest data from the server and update all Drift reactive streams.

## State

`summary_provider.dart` — Riverpod provider that watches all six Drift reactive queries and returns a `SummaryData` model. Cards subscribe individually to their relevant streams to minimise rebuilds.
