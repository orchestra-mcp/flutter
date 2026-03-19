# Auth Screens

Authentication UI for the Orchestra Flutter app. All screens use the glass card design language centered on a gradient mesh background.

## Screens

### Login Screen (`lib/screens/auth/login_screen.dart`)

Entry point for returning users. Features:

- Orchestra SVG logo (72px) at the top of the card
- Email field with email keyboard type
- Password field with obscureText toggle (show/hide eye icon)
- "Continue" GlassButton (full-width, gradient accent colors)
- Inline error display below the password field on failure (no dialogs)
- "Don't have an account?" link navigating to `/register`
- "Sign in without password" link triggering the magic link flow
- "Sign in with Passkey" link navigating to `/passkey`
- Social OAuth row (Google, GitHub, Discord, Slack) — providers fetched from `GET /api/auth/providers` and rendered only when enabled

On successful login the user is routed to `/summary` or `/onboarding` depending on the `onboarding_done` flag. A `login` analytics event is logged with `method: email | oauth`.

### Register Screen (`lib/screens/auth/register_screen.dart`)

New account creation. Features:

- Full name, email, and password fields
- Real-time password strength indicator
- Terms of service checkbox
- Calls `AuthRepository.register(name, email, password)` on submit
- Routes to `/onboarding` on success

### Forgot Password Screen (`lib/screens/auth/forgot_password_screen.dart`)

Password reset via magic link. Features:

- Email input field
- Sends magic link via `AuthRepository.requestPasswordReset(email)`
- Shows a success state with re-send option after submission
- Back link to `/login`

### Reset Password Screen (`lib/screens/auth/reset_password_screen.dart`)

Consumed from the magic link deep-link (`/auth/reset?token=...`). Features:

- New password and confirm password fields
- Real-time match validation — "Continue" is disabled until passwords match
- Calls `AuthRepository.resetPassword(token, newPassword)`
- Routes to `/login` on success

### Two-Factor Screen (`lib/screens/auth/two_factor_screen.dart`)

TOTP / SMS verification after primary credential check. Features:

- 6-digit OTP input (auto-advances focus per digit)
- Auto-submits when all 6 digits are entered
- Resend button with a 30-second cooldown countdown
- Calls `AuthRepository.verifyOtp(code)`
- Routes to `/summary` or `/onboarding` on success

## Navigation

```
/login          → LoginScreen
/register       → RegisterScreen
/forgot         → ForgotPasswordScreen
/reset          → ResetPasswordScreen (requires token query param)
/two-factor     → TwoFactorScreen
/passkey        → PasskeyScreen
```

## Dependencies

- `AuthRepository` — handles all API calls
- `url_launcher` — opens OAuth provider URLs in the system browser
- Deep-link handler registered at `/auth/callback` for OAuth code exchange
