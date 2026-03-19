import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/app.dart';

void main() {
  testWidgets('OrchestraApp renders scaffold smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: OrchestraApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
