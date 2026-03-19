import 'dart:io';

import 'package:flutter/foundation.dart';

/// True when running on a desktop OS (macOS, Windows, Linux) and not web.
bool get isDesktop =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// True when running on a mobile OS (Android, iOS) and not web.
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// True when running as a compiled web app.
bool get isWeb => kIsWeb;

/// True when running on an Apple OS (iOS or macOS) and not web.
bool get isApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);
