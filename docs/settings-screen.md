# Settings Screen

The settings screen (`lib/screens/settings/settings_screen.dart`) provides a tabbed interface for all user preferences.

## Tabs

| # | Tab | Content |
|---|-----|---------|
| 1 | Profile | Name, bio, avatar, timezone |
| 2 | Team | Team name or invite code, member list |
| 3 | Appearance | Theme picker, font size, language |
| 4 | Security | Password change, passkey, 2FA toggle |
| 5 | Notifications | Push notification preferences |

## Implementation

`SettingsScreen` is a `ConsumerStatefulWidget` using a `TabController` (via `SingleTickerProviderStateMixin`) to manage the five tabs. Each tab is a separate widget in `lib/screens/settings/tabs/`.

## Related Files

- `lib/screens/settings/settings_screen.dart`
- `lib/screens/settings/tabs/profile_settings_tab.dart`
- `lib/screens/settings/tabs/appearance_settings_tab.dart`
- `lib/screens/settings/tabs/security_settings_tab.dart`
- `lib/screens/settings/tabs/notifications_settings_tab.dart`
