# Orchestra Desktop Installer

The installer flow detects, downloads, and installs the Orchestra CLI binary on macOS, Windows, and Linux. It is skipped entirely on web (`kIsWeb`) and mobile platforms.

## Files

| File | Purpose |
|------|---------|
| `lib/core/installer/install_progress_model.dart` | `InstallStage` enum and `InstallProgress` immutable model |
| `lib/core/installer/orchestra_detector.dart` | `OrchestraDetector` — finds binary, reads installed version |
| `lib/screens/installer/orchestra_installer.dart` | Downloads, verifies, and installs the binary |
| `lib/screens/installer/installer_screen.dart` | Full-screen installer UI (Welcome → Progress → Done / Error) |

## Detection

`OrchestraDetector.check()` searches candidate paths in order:

**macOS / Linux**
1. `~/.orchestra/bin/orchestra`
2. `/usr/local/bin/orchestra`
3. `/opt/homebrew/bin/orchestra`
4. `/usr/bin/orchestra`
5. Shell fallback: `which orchestra`

**Windows**
1. `%USERPROFILE%\.orchestra\bin\orchestra.exe`
2. `C:\Program Files\Orchestra\orchestra.exe`
3. Shell fallback: `where orchestra`

## Install Progress Model

```dart
enum InstallStage {
  checking, fetchingVersion, downloading,
  extracting, installing, verifying, done, error,
}

class InstallProgress {
  final InstallStage stage;
  final int percent;      // 0–100
  final String message;
  final String? error;    // non-null when stage == error
}
```

## Platform Assets

| Platform | Asset |
|----------|-------|
| macOS arm64 | `orchestra_darwin_arm64.tar.gz` |
| macOS amd64 | `orchestra_darwin_amd64.tar.gz` |
| Windows | `orchestra_windows_amd64.zip` |
| Linux amd64 | `orchestra_linux_amd64.tar.gz` |
| Linux arm64 | `orchestra_linux_arm64.tar.gz` |

## Post-Install Steps

- **macOS**: removes quarantine flag via `xattr -dr com.apple.quarantine`
- **Windows**: appends install path to `HKCU\Environment\Path`
- **Linux**: writes `.desktop` file and creates symlink in `~/.local/bin`

## UI States

1. **Welcome** — animated pulse, auto-advances after 1 s
2. **Progress** — stage label, `LinearProgressIndicator`, last 3 log lines
3. **Done** — green checkmark, version badge, Get Started button
4. **Error** — error message, Retry button, Install Manually link
