import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/screens/web/admin/admin_shell.dart';

void main() {
  group('AdminShell', () {
    test('widget type is accessible', () {
      const shell = AdminShell();
      expect(shell, isA<Widget>());
    });

    test('uses IndexedStack (not KeyedSubtree) for body transitions', () {
      // Read source and verify structural pattern.
      // Fully pumping AdminShell requires mocking 7 admin page providers
      // that fire Dio HTTP calls on mount, so we verify at the source level.
      final source = File(
        'lib/screens/web/admin/admin_shell.dart',
      ).readAsStringSync();

      expect(source, contains('IndexedStack'));
      expect(source, isNot(contains('KeyedSubtree')));
    });

    test('body is wrapped in ClipRect to prevent overflow bleed', () {
      final source = File(
        'lib/screens/web/admin/admin_shell.dart',
      ).readAsStringSync();

      expect(source, contains('ClipRect'));
    });
  });
}
