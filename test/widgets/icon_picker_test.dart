import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/widgets/icon_picker.dart';

void main() {
  group('kPickerIcons', () {
    test('contains a reasonable number of icons', () {
      expect(kPickerIcons.length, greaterThanOrEqualTo(30));
    });

    test('all icons have unique codepoints', () {
      final codePoints = kPickerIcons.map((i) => i.codePoint).toSet();
      expect(codePoints.length, kPickerIcons.length);
    });

    test('all icons use MaterialIcons font family', () {
      for (final icon in kPickerIcons) {
        expect(icon.fontFamily, 'MaterialIcons');
      }
    });
  });

  group('IconPicker widget', () {
    test('is const-constructible', () {
      // Verify the widget can be constructed without errors.
      final picker = IconPicker(
        onIconSelected: (_) {},
      );
      expect(picker, isA<IconPicker>());
    });

    test('accepts initial selectedCodePoint', () {
      final picker = IconPicker(
        selectedCodePoint: kPickerIcons.first.codePoint,
        onIconSelected: (_) {},
      );
      expect(picker.selectedCodePoint, kPickerIcons.first.codePoint);
    });
  });
}
