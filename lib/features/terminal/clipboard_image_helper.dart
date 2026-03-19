import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

/// Checks the system clipboard for image data. If found, saves it to a
/// temporary file and returns the absolute path. Returns `null` when the
/// clipboard contains no image.
///
/// Only supported on desktop platforms (macOS, Windows, Linux).
Future<String?> getClipboardImagePath() async {
  if (kIsWeb) return null;

  try {
    final Uint8List? imageBytes = await Pasteboard.image;
    if (imageBytes == null || imageBytes.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final filePath = '${tempDir.path}/orchestra-paste-$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    return filePath;
  } catch (_) {
    return null;
  }
}
