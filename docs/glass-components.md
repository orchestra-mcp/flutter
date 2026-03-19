# Liquid Glass Component Library

Foundational glass morphism UI components located in `lib/design/components/`.

## Components

### GlassCard (`glass_card.dart`)

`StatelessWidget` with frosted-glass appearance. Uses `BackdropFilter` with `ImageFilter.blur(sigmaX: 20, sigmaY: 20)` over a `Container` whose `BoxDecoration` sets:

- Background: theme `bg` at 15% opacity (light) or 12% opacity (dark)
- Border radius: 16 (configurable)
- Border: white at 20% opacity
- Gradient: white 10% → transparent (top-left → bottom-right)

Parameters: `child`, `padding` (default `EdgeInsets.all(16)`), `margin`, `borderRadius`, `onTap`.

### GlassBackground (`glass_background.dart`)

Full-screen `Stack` with theme-coloured base and two static blurred blob circles using the accent colour at 8% opacity.

### GlassButton (`glass_button.dart`)

Accent-gradient button (height 52, border radius 12). Supports `isLoading` (20 px white `CircularProgressIndicator`), `isDisabled` (0.5 opacity), optional `icon`, and `onPressed`.

### GlassSheet (`glass_sheet.dart`)

`showGlassSheet()` helper that calls `showModalBottomSheet` with a transparent background. Renders a drag-handle pill above a `GlassCard`-wrapped child. Accepts `fullHeight` to occupy the screen minus 48 dp.

## Related Files

- `lib/design/components/glass_card.dart`
- `lib/design/components/glass_background.dart`
- `lib/design/components/glass_button.dart`
- `lib/design/components/glass_sheet.dart`
- `test/design/components/glass_card_test.dart`
- `test/design/components/glass_button_test.dart`
