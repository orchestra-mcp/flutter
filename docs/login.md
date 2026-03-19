# Login Screen

The login screen (`lib/screens/auth/login_screen.dart`) provides email/password authentication with social OAuth, magic link, and passkey entry points.

## Layout

A glass card is centered on a gradient mesh background derived from the theme accent color. The Orchestra logo (72 px SVG) sits at the top of the card, followed by:

- **Email** — `TextField` with `TextInputType.emailAddress`
- **Password** — `TextField` with `obscureText` and a show/hide toggle icon
- **Continue** — full-width `GlassButton` with gradient accent colors
- **Secondary links** — "Don't have an account" (→ `/register`), "Sign in without password" (magic link), "Sign in with Passkey" (→ `/passkey`)
- **Social OAuth row** — buttons rendered only for providers returned by `GET /api/auth/providers`

## Auth Flow

1. User enters email and password and taps Continue.
2. `AuthRepository.login(email, password)` is called; the button shows a loading indicator.
3. On success, the router reads the `onboarding_done` SharedPreferences flag and navigates to `/summary` or `/onboarding`.
4. On failure, an inline error message is shown below the password field (no dialog).

## Social OAuth

- Each enabled provider button launches an OAuth URL via `url_launcher`.
- A deep-link handler at `/auth/callback` completes the code exchange.

## Analytics

A `login` event is logged with `method: email` or `method: oauth` on successful authentication.
