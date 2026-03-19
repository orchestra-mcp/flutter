# Auth Register, Forgot Password, Reset Password, and 2FA Screens

## Overview

Authentication screens for registration, password recovery, and two-factor authentication.

## Screens

### Register Screen (`lib/screens/auth/register_screen.dart`)

Glass card layout with email, password, and confirm password fields. Validates password match and minimum length before calling `AuthRepository.register()`.

### Forgot Password Screen (`lib/screens/auth/forgot_password_screen.dart`)

Email input with send reset link action. Shows success state with 60-second countdown for resend.

### Reset Password Screen (`lib/screens/auth/reset_password_screen.dart`)

Reads token from URL query params. New password and confirm fields with match validation.

### Two Factor Screen (`lib/screens/auth/two_factor_screen.dart`)

Six single-digit fields with auto-advance focus. Auto-submits on last digit. 30-second resend countdown.
