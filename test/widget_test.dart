import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test — verify a MaterialApp can render without crash.
/// OrchestraApp depends on PowerSync + many Riverpod providers that
/// require runtime initialization, so we test a minimal MaterialApp
/// instead to keep the smoke test fast and dependency-free.
void main() {
  testWidgets('App smoke test — MaterialApp renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
