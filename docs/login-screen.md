# Login Screen

The login screen (`lib/screens/auth/login_screen.dart`) provides email/password authentication with social OAuth, magic link, and passkey options.

## Layout

A glass card is centred on a gradient mesh background derived from the active `OrchestraTheme` accent colour. From top to bottom the card contains:

1. Orchestra SVG logo (72 dp)
2. Email `TextField` (email keyboard type, auto-focus)
3. Password `TextField` (obscured by default, eye-icon toggle)
4. Full-width **Continue** `GlassButton` with accent gradient
5. Supplementary links: *Don't have an account?*, *Sign in without password*, *Sign in with Passkey*
6. Social OAuth row (Google, GitHub, Discord, Slack) — only providers returned by `GET /api/auth/providers` are shown

## Auth Flow

- **Email/password** — calls `AuthRepository.login(email, password)`. On success navigates to `/summary` or `/onboarding` depending on the `onboarding_done` flag. On failure an inline error message is shown below the password field (no dialog).
- **Social OAuth** — opens the provider OAuth URL via `url_launcher`; the deep-link handler at `/auth/callback` exchanges the code.
- **Magic link** — triggers the magic-link flow which sends a one-time link to the user's email.
- **Passkey** — navigates to `/passkey` for WebAuthn-based authentication.

## Analytics

A login event is logged via `AnalyticsService` on every successful authentication. The `method` property is set to `email` or the OAuth provider name (e.g. `github`).

## Related Files

- `lib/screens/auth/login_screen.dart` — main screen widget
- `test/screens/auth/login_screen_test.dart` — widget tests
- `lib/core/auth/auth_repository.dart` — authentication data layer
- `docs/auth.md` — broader authentication architecture
