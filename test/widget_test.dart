import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/app.dart';
import 'package:orchestra/core/powersync/powersync_provider.dart';

void main() {
  testWidgets('OrchestraApp renders scaffold smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // PowerSync isn't initialized in tests — stub it to avoid StateError.
          powersyncDatabaseProvider.overrideWith(
            (ref) => throw UnimplementedError(),
          ),
        ],
        child: const OrchestraApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
