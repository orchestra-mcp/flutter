# Authenticated Web Routes

Authenticated web routes are screen adaptations optimised for the browser viewport. They sit inside `WebShell` (NavigationRail on wide, BottomNavigationBar on narrow).

## Files

| File | Route | Description |
|------|-------|-------------|
| `lib/screens/web/dashboard/dashboard_screen.dart` | `/dashboard` | Stats grid + activity feed |
| `lib/screens/web/features_list_screen.dart` | `/features` | Global feature DataTable |

## Dashboard Screen

`DashboardScreen` renders a 2-column `GridView` of stat cards on viewports >= 600 px, collapsing to 1 column on narrow screens.

### Stat Cards

| Card | Icon | Value source |
|------|------|-------------|
| Active Projects | folder | Project count |
| In-Progress Features | task_alt | Feature count |
| Open Bugs | bug_report | Bug count |
| In Review | rate_review | Review queue |

Below the grid a **Recent Activity** list shows the 5 most recent workflow events with icon, title, and relative timestamp.

## Features List Screen

`FeaturesListScreen` renders a horizontally-scrollable `DataTable` of all features across every project.

### Columns

| Column | Notes |
|--------|-------|
| ID | Monospace, accent-coloured |
| Title | Max 280 px, ellipsis overflow |
| Project | Muted text |
| Status | Colour-coded pill badge |
| Priority | P0–P3 |
| Kind | feature / bug / hotfix / chore |

### Status Colours

| Status | Colour |
|--------|--------|
| done | Green `#4CAF50` |
| in-progress | Blue `#2196F3` |
| in-review | Orange `#FF9800` |
| in-testing | Purple `#9C27B0` |
| todo | Grey `#9E9E9E` |

## Adding New Authenticated Routes

1. Create the screen widget in `lib/screens/web/<section>/`.
2. Add a `GoRoute` entry in `lib/core/router/app_router.dart`.
3. Add a `NavigationRailDestination` entry in `WebShell._destinations`.
