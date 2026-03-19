# Theme System

25 themes across 4 groups. Persisted via SharedPreferences, reactive via Riverpod.

## Usage

```dart
// Watch current theme
final theme = ref.watch(themeProvider);

// Change theme
ref.read(themeProvider.notifier).setTheme('dracula');

// Access color tokens in widgets
final tokens = ThemeTokens.of(context);
Container(color: tokens.glass); // glass tint
```

## Themes

| Group | Count | Examples |
|-------|-------|---------|
| Orchestra | 6 | orchestra, midnight, aurora, ocean, forest, sunset |
| Material | 4 | material-deep-purple, material-teal, material-blue, material-green |
| Popular | 8 | github-dark, dracula, nord, catppuccin-mocha, solarized-dark |
| Classic | 7 | classic-dark, tokyo-night, one-dark, gruvbox-dark, high-contrast |

## Glass Rule

- Dark themes: `bg.withValues(alpha: 0.12)`
- Light themes: `bg.withValues(alpha: 0.15)`
