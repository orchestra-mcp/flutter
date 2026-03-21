import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/hydration_item.dart';

void main() {
  group('HydrationItem', () {
    group('fromJson', () {
      test('parses map title correctly', () {
        final item = HydrationItem.fromJson({
          'id': 'test',
          'title': {'en': 'Water', 'ar': '\u0645\u0627\u0621'},
          'ml': 250,
        });
        expect(item.id, 'test');
        expect(item.ml, 250);
        expect(item.title['en'], 'Water');
        expect(item.title['ar'], '\u0645\u0627\u0621');
      });

      test('converts string title to single-entry en map', () {
        final item = HydrationItem.fromJson({
          'id': 'str',
          'title': 'Plain Water',
          'ml': 100,
        });
        expect(item.title, {'en': 'Plain Water'});
      });

      test('defaults null title to Unknown en map', () {
        final item = HydrationItem.fromJson({
          'id': 'x',
          'title': null,
          'ml': 200,
        });
        expect(item.title, {'en': 'Unknown'});
      });

      test('defaults missing title to Unknown en map', () {
        final item = HydrationItem.fromJson({
          'id': 'x',
          'ml': 200,
        });
        expect(item.title, {'en': 'Unknown'});
      });

      test('defaults missing id to empty string', () {
        final item = HydrationItem.fromJson({
          'title': 'Tea',
          'ml': 150,
        });
        expect(item.id, '');
      });

      test('defaults null id to empty string', () {
        final item = HydrationItem.fromJson({
          'id': null,
          'title': 'Tea',
          'ml': 150,
        });
        expect(item.id, '');
      });

      test('defaults missing ml to 0', () {
        final item = HydrationItem.fromJson({
          'id': 'no_ml',
          'title': 'Empty',
        });
        expect(item.ml, 0);
      });

      test('defaults null ml to 0', () {
        final item = HydrationItem.fromJson({
          'id': 'null_ml',
          'title': 'Empty',
          'ml': null,
        });
        expect(item.ml, 0);
      });

      test('parses sort_order from JSON', () {
        final item = HydrationItem.fromJson({
          'id': 'sorted',
          'title': 'X',
          'ml': 100,
          'sort_order': 7,
        });
        expect(item.sortOrder, 7);
      });

      test('defaults missing sort_order to 0', () {
        final item = HydrationItem.fromJson({
          'id': 'no_sort',
          'title': 'X',
          'ml': 100,
        });
        expect(item.sortOrder, 0);
      });

      test('converts numeric id to string', () {
        final item = HydrationItem.fromJson({
          'id': 42,
          'title': 'Num',
          'ml': 100,
        });
        expect(item.id, '42');
      });

      test('handles double ml value by truncating to int', () {
        final item = HydrationItem.fromJson({
          'id': 'dbl',
          'title': 'Dbl',
          'ml': 123.7,
        });
        expect(item.ml, 123);
      });
    });

    group('toJson', () {
      test('roundtrip produces equivalent map', () {
        final original = {
          'id': 'roundtrip',
          'title': {'en': 'Sparkling Water', 'ar': '\u0645\u0627\u0621 \u063a\u0627\u0632\u064a\u0629'},
          'ml': 330,
          'sort_order': 2,
        };
        final item = HydrationItem.fromJson(original);
        final json = item.toJson();

        expect(json['id'], 'roundtrip');
        expect(json['title'], {'en': 'Sparkling Water', 'ar': '\u0645\u0627\u0621 \u063a\u0627\u0632\u064a\u0629'});
        expect(json['ml'], 330);
        expect(json['sort_order'], 2);
      });

      test('toJson does not include icon field', () {
        final item = HydrationItem.fromJson({
          'id': 'no_icon',
          'title': 'Test',
          'ml': 100,
        });
        final json = item.toJson();
        expect(json.containsKey('icon'), isFalse);
      });

      test('toJson keys match expected set', () {
        final item = HydrationItem.fromJson({
          'id': 'keys',
          'title': 'T',
          'ml': 50,
        });
        final json = item.toJson();
        expect(json.keys.toSet(), {'id', 'title', 'ml', 'sort_order'});
      });
    });

    group('localizedTitle', () {
      test('returns correct locale when present', () {
        final item = HydrationItem.fromJson({
          'id': 'loc',
          'title': {'en': 'Water', 'ar': '\u0645\u0627\u0621', 'fr': 'Eau'},
          'ml': 250,
        });
        expect(item.localizedTitle('fr'), 'Eau');
        expect(item.localizedTitle('ar'), '\u0645\u0627\u0621');
      });

      test('falls back to en when locale is missing', () {
        final item = HydrationItem.fromJson({
          'id': 'fb',
          'title': {'en': 'Water', 'ar': '\u0645\u0627\u0621'},
          'ml': 250,
        });
        expect(item.localizedTitle('de'), 'Water');
      });

      test('falls back to first value when en is also missing', () {
        final item = HydrationItem.fromJson({
          'id': 'no_en',
          'title': {'fr': 'Eau', 'es': 'Agua'},
          'ml': 250,
        });
        // Neither 'de' nor 'en' exists, so first value is returned
        expect(item.localizedTitle('de'), 'Eau');
      });

      test('returns en when requesting en explicitly', () {
        final item = HydrationItem.fromJson({
          'id': 'en_req',
          'title': {'en': 'Juice', 'ar': '\u0639\u0635\u064a\u0631'},
          'ml': 200,
        });
        expect(item.localizedTitle('en'), 'Juice');
      });
    });

    group('hydrationItemPresets', () {
      test('has exactly 5 items', () {
        expect(hydrationItemPresets.length, 5);
      });

      test('all have non-empty ids', () {
        for (final item in hydrationItemPresets) {
          expect(item.id, isNotEmpty, reason: 'Preset item should have a non-empty id');
        }
      });

      test('all have unique ids', () {
        final ids = hydrationItemPresets.map((i) => i.id).toSet();
        expect(ids.length, hydrationItemPresets.length);
      });

      test('all have en and ar titles', () {
        for (final item in hydrationItemPresets) {
          expect(item.title.containsKey('en'), isTrue,
              reason: '${item.id} should have en title');
          expect(item.title.containsKey('ar'), isTrue,
              reason: '${item.id} should have ar title');
          expect(item.title['en'], isNotEmpty,
              reason: '${item.id} en title should not be empty');
          expect(item.title['ar'], isNotEmpty,
              reason: '${item.id} ar title should not be empty');
        }
      });

      test('all have positive ml values', () {
        for (final item in hydrationItemPresets) {
          expect(item.ml, greaterThan(0),
              reason: '${item.id} should have positive ml');
        }
      });

      test('are sorted by sortOrder', () {
        for (int i = 1; i < hydrationItemPresets.length; i++) {
          expect(
            hydrationItemPresets[i].sortOrder,
            greaterThanOrEqualTo(hydrationItemPresets[i - 1].sortOrder),
            reason:
                '${hydrationItemPresets[i].id} should come after ${hydrationItemPresets[i - 1].id}',
          );
        }
      });

      test('ml values increase with larger items', () {
        // small_glass < medium_glass < large_glass < bottle < large_bottle
        for (int i = 1; i < hydrationItemPresets.length; i++) {
          expect(
            hydrationItemPresets[i].ml,
            greaterThan(hydrationItemPresets[i - 1].ml),
            reason:
                '${hydrationItemPresets[i].id} (${hydrationItemPresets[i].ml}ml) '
                'should be larger than ${hydrationItemPresets[i - 1].id} (${hydrationItemPresets[i - 1].ml}ml)',
          );
        }
      });
    });
  });
}
