# Magic Login & Passkey Screens

Authentication screens for password-free sign-in, located in
`lib/screens/auth/`.

## Magic Login Screen

`lib/screens/auth/magic_login_screen.dart`

A `ConsumerStatefulWidget` that lets users sign in without a password by
receiving a one-time magic link via email.

### Layout

- **Email form view** — text field for email address, "Send magic link"
  `ElevatedButton`, back link to `/login`, and an optional `_ErrorBanner`.
- **Confirmation view** — shown after a successful API call via
  `AnimatedSwitcher` (350 ms fade). Displays a mail icon, "Check your email"
  heading, the submitted email address, and a "Back to sign in" button.

### State

| Field | Type | Purpose |
|-------|------|---------|
| `_emailCtrl` | `TextEditingController` | Email input |
| `_loading` | `bool` | Disables button and shows spinner |
| `_sent` | `bool` | Switches form → confirmation view |
| `_error` | `String?` | Shows inline error banner |

### API call

```dart
await ref.read(authRepositoryProvider).loginWithMagicLink(email);
```

On success, `_sent = true` triggers the `AnimatedSwitcher` transition. The
actual deep-link token exchange is handled by the `/auth/magic` GoRouter route,
which navigates to `/summary` or `/onboarding`.

---

## Passkey Screen

`lib/screens/auth/passkey_screen.dart`

A `ConsumerStatefulWidget` that invokes the platform biometric / device-PIN
credential picker via the `local_auth` package.

### Layout

- Animated fingerprint → check-mark icon (`AnimatedContainer`,
  `Curves.elasticOut`)
- "Sign in with Passkey" heading
- "Authenticate with Passkey" `ElevatedButton.icon` — shows spinner while
  authenticating, switches to green success state on completion
- Back link to `/login`

### Authentication flow

```dart
final authenticated = await LocalAuthentication().authenticate(
  localizedReason: 'Sign in to Orchestra',
);
```

`biometricOnly` defaults to `false` so users can fall back to their device PIN
or password. On success the button turns green for 600 ms before navigating to
`/summary` via GoRouter.

### State

| Field | Type | Purpose |
|-------|------|---------|
| `_loading` | `bool` | Shows spinner in button |
| `_succeeded` | `bool` | Green success state + auto-navigate |
| `_error` | `String?` | Shows inline error banner |

---

## Shared Helpers

Both screens use private `_GlassCard` and `_ErrorBanner` widgets defined at the
bottom of each file. These follow the same pattern as the rest of the auth
screen family (`login_screen.dart`, `register_screen.dart`).
