# Authentication

Riverpod AsyncNotifier state machine with secure token storage.

## Usage

```dart
// Watch auth state
final authState = ref.watch(authProvider);

authState.when(
  loading: () => LoadingWidget(),
  error: (e, _) => ErrorWidget(e.toString()),
  data: (state) => switch (state) {
    AuthAuthenticated(:final user) => HomeScreen(user: user),
    AuthUnauthenticated() => LoginScreen(),
    AuthLoading() => SplashScreen(),
  },
);

// Login
await ref.read(authProvider.notifier).login(email, password);

// Logout
await ref.read(authProvider.notifier).logout();

// Current user
final user = ref.read(authProvider.notifier).currentUser;
```

## State Machine

```
AuthLoading → AuthAuthenticated (token valid + /api/me success)
           → AuthUnauthenticated (no token or /api/me fails)
```

## Token Storage

`flutter_secure_storage` keys:
- `orchestra_access_token`
- `orchestra_refresh_token`

## User Model

| Field | Type | Notes |
|-------|------|-------|
| id | String | Server-assigned |
| email | String | — |
| name | String | Falls back to display_name |
| avatarUrl | String? | — |
| role | String | `admin` or `member` |
| teamId | String? | — |
| workspaceId | String? | — |
| createdAt | DateTime | — |
