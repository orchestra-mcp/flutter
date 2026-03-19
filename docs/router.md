# Router

GoRouter v17 configuration with auth guard, shell routes, and 40+ named paths.

## Usage

```dart
// Navigate to a route
context.go(Routes.summary);
context.go(Routes.project('abc'));
context.push(Routes.search);

// Watch current location
final router = ref.watch(routerProvider);
```

## Auth Guard

`GoRouter.redirect` checks `authProvider` state on every navigation:

| Auth State | Destination | Redirect |
|-----------|------------|---------|
| `AuthUnauthenticated` | any protected route | `/login` |
| `AuthAuthenticated` | `/login` or `/register` | `/summary` |
| `AuthLoading` / `null` | any | no redirect |

`_AuthStateNotifier` wraps Riverpod `ref.listen(authProvider)` as a `ChangeNotifier`, passed to `GoRouter.refreshListenable` so the router re-evaluates redirect on every auth state change.

## Route Structure

```
/splash                        (public)
/onboarding                    (public)
/login                         (public)
/register                      (public)
/forgot-password               (public)
/reset-password                (public)
/two-factor                    (public)
/magic-login                   (public)
/passkey                       (public)
/auth/callback                 (public)
/auth/magic                    (public)

ShellRoute → _AppShell (GlassNavBar + GlassHeader)
  /summary
  /notifications

/search                        (modal, no shell)
/projects
/projects/:id
/projects/:id/tree
/library/notes
/library/notes/:id
/library/agents
/library/agents/:id
/library/skills
/library/skills/:id
/library/workflows
/library/workflows/:id
/library/docs
/library/docs/:id
/library/delegations
/library/sessions
/health
/settings
/settings/profile
/settings/team
/settings/appearance
/settings/security
/settings/notifications
/settings/about
```

## Routes Constants

All paths are defined as static constants on `Routes`:

```dart
Routes.splash           // '/splash'
Routes.login            // '/login'
Routes.summary          // '/summary'
Routes.project('id')    // '/projects/id'
Routes.note('id')       // '/library/notes/id'
Routes.settingsProfile  // '/settings/profile'
```

## Provider

```dart
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
```

The `_AppShell` placeholder will be replaced by the real `GlassNavBar` + `GlassHeader` in FEAT-SDL.
