import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Generates a unique file name by inserting a timestamp before the extension.
/// e.g. `document.pdf` → `document_1710000000000.pdf`
String uniqueFileName(String name) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final dot = name.lastIndexOf('.');
  if (dot == -1) return '${name}_$ts';
  return '${name.substring(0, dot)}_$ts${name.substring(dot)}';
}

/// Captures a [RepaintBoundary] as a PNG image with a theme-based gradient
/// background and shares it via the native share sheet.
Future<void> exportWidgetAsImage({
  required GlobalKey repaintKey,
  required OrchestraColorTokens tokens,
  required String fileName,
  double pixelRatio = 3.0,
  double padding = 40.0,
}) async {
  final boundary =
      repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  // Capture the widget
  final widgetImage = await boundary.toImage(pixelRatio: pixelRatio);
  final widgetW = widgetImage.width.toDouble();
  final widgetH = widgetImage.height.toDouble();

  // Final canvas size with padding
  final scaledPadding = padding * pixelRatio;
  final canvasW = widgetW + scaledPadding * 2;
  final canvasH = widgetH + scaledPadding * 2;

  // Build gradient colors from theme
  final gradientColors = tokens.isLight
      ? [
          tokens.accent.withValues(alpha: 0.12),
          tokens.bg,
          tokens.accentAlt.withValues(alpha: 0.08),
        ]
      : [
          tokens.accent.withValues(alpha: 0.25),
          tokens.bg,
          tokens.accentAlt.withValues(alpha: 0.15),
        ];

  // Paint gradient background + widget image
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Gradient background
  final bgRect = ui.Rect.fromLTWH(0, 0, canvasW, canvasH);
  final gradient = ui.Gradient.linear(
    ui.Offset.zero,
    ui.Offset(canvasW, canvasH),
    gradientColors,
    [0.0, 0.5, 1.0],
  );
  canvas.drawRect(bgRect, ui.Paint()..shader = gradient);

  // Draw widget image centered with padding
  canvas.drawImage(
    widgetImage,
    ui.Offset(scaledPadding, scaledPadding),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );

  final picture = recorder.endRecording();
  final composited = await picture.toImage(canvasW.toInt(), canvasH.toInt());
  final byteData =
      await composited.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return;

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${uniqueFileName(fileName)}');
  await file.writeAsBytes(byteData.buffer.asUint8List());

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)]),
  );
}
