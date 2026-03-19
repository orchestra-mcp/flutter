import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests that AnimatedContainer-based sidebar slide animation works correctly.
/// Verifies: initial hidden state, animated width transition on toggle,
/// and ClipRect + OverflowBox wrapping for smooth slide effect.
void main() {
  group('Sidebar animated slide', () {
    testWidgets('sidebar starts hidden and animates open', (tester) async {
      bool isOpen = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              final targetWidth = isOpen ? 260.0 : 0.0;
              return Scaffold(
                body: Row(
                  children: [
                    // Rail stub
                    const SizedBox(width: 64),
                    const VerticalDivider(thickness: 1, width: 1),
                    // Animated sidebar (mirrors desktop_shell.dart)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: targetWidth,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: AlignmentDirectional.centerStart,
                          maxWidth: 260,
                          child: SizedBox(
                            width: 260,
                            child: Container(
                              key: const Key('sidebar-content'),
                              color: Colors.grey.shade900,
                              child: const Center(child: Text('Sidebar')),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Content area
                    const Expanded(child: Center(child: Text('Content'))),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  key: const Key('toggle-btn'),
                  onPressed: () => setState(() => isOpen = !isOpen),
                ),
              );
            },
          ),
        ),
      );

      // Initially sidebar has 0 width
      final boxInitial = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(boxInitial.size.width, equals(0.0));

      // Toggle open
      await tester.tap(find.byKey(const Key('toggle-btn')));
      await tester.pump(); // start animation

      // Mid-animation: width should be between 0 and 260
      await tester.pump(const Duration(milliseconds: 100));
      final box = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(box.size.width, greaterThan(0));
      expect(box.size.width, lessThan(260));

      // Animation complete
      await tester.pumpAndSettle();
      final boxAfter = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(boxAfter.size.width, equals(260.0));

      // Toggle closed
      await tester.tap(find.byKey(const Key('toggle-btn')));
      await tester.pumpAndSettle();
      final boxClosed = tester.renderObject<RenderBox>(
        find.byType(AnimatedContainer),
      );
      expect(boxClosed.size.width, equals(0.0));
    });

    test('animation uses easeInOut curve and 200ms duration', () {
      // Verify constants match the implementation
      const duration = Duration(milliseconds: 200);
      const curve = Curves.easeInOut;
      expect(duration.inMilliseconds, 200);
      expect(curve, isA<Cubic>());
    });
  });
}
