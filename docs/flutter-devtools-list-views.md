# Flutter DevTools — List Views & Startup Data Loading

## Overview

The DevTools section in the Flutter app now follows the same list-first pattern used by Notes, Docs, Skills, and Agents. All five sub-sections load their data from MCP at app startup and display live item counts in the sidebar.

## Architecture

### Startup Prefetch

`lib/features/devtools/providers/devtools_startup_provider.dart`

`devtoolsPrefetchProvider` fires `Future.wait` on all five DevTools providers in parallel the moment `DesktopShell` renders. Each provider call is wrapped in `catchError` so a single MCP failure does not block the rest.

```dart
final devtoolsPrefetchProvider = FutureProvider<bool>((ref) async {
  await Future.wait([
    ref.read(apiCollectionProvider.future).catchError((_) => []),
    ref.read(secretsProvider.future).catchError((_) => []),
    ref.read(databaseBrowserProvider.future).catchError((_) => []),
    ref.read(logRunnerProvider.future).catchError((_) => []),
    ref.read(promptsProvider.future).catchError((_) => []),
  ]);
  return true;
});
```

`DesktopShell.build` watches this provider so prefetch begins immediately on shell startup — before the user ever taps DevTools.

### Sidebar Item Counts

`_DevToolsSidebar` (in `desktop_shell.dart`) is now a `ConsumerWidget`. It reads `.value?.length` from each cached provider and passes the count as the `subtitle` field on `_SidebarItem`. Counts appear instantly when data has loaded; no count is shown while loading or on error.

| Section | MCP Tool | Provider |
|---------|----------|----------|
| API Collections | `api_list_collections` | `apiCollectionProvider` |
| Database | `db_list_connections` | `databaseBrowserProvider` |
| Log Runner | `log_run_list` | `logRunnerProvider` |
| Secrets | `list_secrets` | `secretsProvider` |
| Prompts | `list_prompts` | `promptsProvider` |

### API Collections Screen

`lib/screens/devtools/api_collections_screen.dart`

Refactored from a Postman-style 3-pane layout (collections sidebar always visible) to a proper list-first master/detail:

- **Left pane (260 px)**: search bar + list of collection tiles. Each tile shows name, base URL subtitle, and endpoint count badge. Expandable to reveal endpoints. Delete button per collection.
- **Right pane**: `ApiRequestBuilder` + `ApiResponseViewer` when an endpoint is selected; placeholder illustration when nothing is selected.
- **Mobile**: collections list → builder/response stack (same behaviour as before).

The other four screens (Secrets, Database, Log Runner, Prompts) were already list-based and required no structural changes — they benefit from startup prefetch automatically.

## Data Flow

```
DesktopShell.build
  └─ ref.watch(devtoolsPrefetchProvider)        ← triggers parallel fetch
       ├─ apiCollectionProvider   (api_list_collections)
       ├─ secretsProvider         (list_secrets)
       ├─ databaseBrowserProvider (db_list_connections)
       ├─ logRunnerProvider       (log_run_list)
       └─ promptsProvider         (list_prompts)

_DevToolsSidebar (ConsumerWidget)
  └─ reads .value?.length from each provider → shows count badge

ApiCollectionsScreen
  └─ ref.watch(apiCollectionProvider) → already warm, renders instantly
```

## Files Changed

| File | Change |
|------|--------|
| `lib/features/devtools/providers/devtools_startup_provider.dart` | New — parallel prefetch provider |
| `lib/screens/devtools/api_collections_screen.dart` | Refactored — list-first layout with search |
| `lib/screens/shell/desktop_shell.dart` | `_DevToolsSidebar` → `ConsumerWidget` with counts; `DesktopShell` watches prefetch provider |
