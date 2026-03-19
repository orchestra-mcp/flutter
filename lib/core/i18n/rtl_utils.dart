import 'package:flutter/material.dart';

abstract final class RtlUtils {
  static bool isRtl(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  static IconData dirIcon(
    BuildContext context, {
    required IconData ltr,
    required IconData rtl,
  }) =>
      isRtl(context) ? rtl : ltr;

  static TextAlign textAlign(BuildContext context) =>
      isRtl(context) ? TextAlign.right : TextAlign.left;

  static TextDirection textDir(BuildContext context) =>
      Directionality.of(context);

  static EdgeInsets symmetric({
    required BuildContext context,
    required double start,
    required double end,
  }) =>
      isRtl(context)
          ? EdgeInsets.only(left: end, right: start)
          : EdgeInsets.only(left: start, right: end);
}
