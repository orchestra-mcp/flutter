import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/health/nutrition_manager.dart';

void main() {
  group('FoodItem', () {
    group('fromJson', () {
      test('parses complete JSON with all fields', () {
        final item = FoodItem.fromJson({
          'id': 'test_food',
          'title': {
            'en': 'Test Food',
            'ar':
                '\u0637\u0639\u0627\u0645 \u0627\u062e\u062a\u0628\u0627\u0631',
          },
          'category': 'protein',
          'trigger_conditions': ['ibs', 'gerd'],
          'sort_order': 5,
        });
        expect(item.id, 'test_food');
        expect(item.category, FoodCategory.protein);
        expect(item.triggerConditions, [
          TriggerCondition.ibs,
          TriggerCondition.gerd,
        ]);
        expect(item.sortOrder, 5);
        expect(item.isSafe, false);
      });

      test('parses map title correctly', () {
        final item = FoodItem.fromJson({
          'id': 'map_title',
          'title': {
            'en': 'Chicken',
            'ar': '\u062f\u062c\u0627\u062c',
            'fr': 'Poulet',
          },
          'category': 'protein',
        });
        expect(item.title['en'], 'Chicken');
        expect(item.title['ar'], '\u062f\u062c\u0627\u062c');
        expect(item.title['fr'], 'Poulet');
        expect(item.title.length, 3);
      });

      test('converts string title to single-entry en map', () {
        final item = FoodItem.fromJson({
          'id': 'str_title',
          'title': 'Rice Bowl',
          'category': 'carb',
        });
        expect(item.title, {'en': 'Rice Bowl'});
      });

      test('defaults null title to Unknown en map', () {
        final item = FoodItem.fromJson({
          'id': 'null_title',
          'title': null,
          'category': 'snack',
        });
        expect(item.title, {'en': 'Unknown'});
      });

      test('defaults missing id to empty string', () {
        final item = FoodItem.fromJson({'title': 'Test', 'category': 'fat'});
        expect(item.id, '');
      });

      test('parses all category values correctly', () {
        for (final cat in ['protein', 'carb', 'fat', 'drink', 'snack']) {
          final item = FoodItem.fromJson({
            'id': 'cat_$cat',
            'title': cat,
            'category': cat,
          });
          final expected = switch (cat) {
            'protein' => FoodCategory.protein,
            'carb' => FoodCategory.carb,
            'fat' => FoodCategory.fat,
            'drink' => FoodCategory.drink,
            _ => FoodCategory.snack,
          };
          expect(
            item.category,
            expected,
            reason: 'Category "$cat" should parse correctly',
          );
        }
      });

      test('defaults unknown category to snack', () {
        final item = FoodItem.fromJson({
          'id': 'unk_cat',
          'title': 'Mystery',
          'category': 'dessert',
        });
        expect(item.category, FoodCategory.snack);
      });

      test('defaults missing category to snack', () {
        final item = FoodItem.fromJson({'id': 'no_cat', 'title': 'No Cat'});
        expect(item.category, FoodCategory.snack);
      });

      test('parses all trigger condition values', () {
        final item = FoodItem.fromJson({
          'id': 'all_trig',
          'title': 'All Triggers',
          'category': 'snack',
          'trigger_conditions': ['ibs', 'gerd', 'gout', 'fattyLiver'],
        });
        expect(item.triggerConditions, [
          TriggerCondition.ibs,
          TriggerCondition.gerd,
          TriggerCondition.gout,
          TriggerCondition.fattyLiver,
        ]);
      });

      test('defaults unknown trigger to fattyLiver', () {
        final item = FoodItem.fromJson({
          'id': 'unk_trig',
          'title': 'Unknown Trigger',
          'category': 'snack',
          'trigger_conditions': ['unknown_condition'],
        });
        expect(item.triggerConditions, [TriggerCondition.fattyLiver]);
      });

      test('defaults missing trigger_conditions to empty list', () {
        final item = FoodItem.fromJson({
          'id': 'no_trig',
          'title': 'Safe Food',
          'category': 'protein',
        });
        expect(item.triggerConditions, isEmpty);
        expect(item.isSafe, true);
      });

      test('defaults missing sort_order to 0', () {
        final item = FoodItem.fromJson({
          'id': 'no_sort',
          'title': 'Unsorted',
          'category': 'carb',
        });
        expect(item.sortOrder, 0);
      });
    });

    group('toJson', () {
      test('roundtrip produces equivalent map', () {
        final original = {
          'id': 'roundtrip',
          'title': {
            'en': 'Grilled Chicken',
            'ar': '\u062f\u062c\u0627\u062c \u0645\u0634\u0648\u064a',
          },
          'category': 'protein',
          'trigger_conditions': ['ibs', 'gerd'],
          'sort_order': 3,
        };
        final item = FoodItem.fromJson(original);
        final json = item.toJson();

        expect(json['id'], 'roundtrip');
        expect(json['title'], {
          'en': 'Grilled Chicken',
          'ar': '\u062f\u062c\u0627\u062c \u0645\u0634\u0648\u064a',
        });
        expect(json['category'], 'protein');
        expect(json['trigger_conditions'], ['ibs', 'gerd']);
        expect(json['sort_order'], 3);
      });

      test('toJson for safe food has empty trigger_conditions', () {
        final item = FoodItem.fromJson({
          'id': 'safe',
          'title': 'Safe Item',
          'category': 'protein',
        });
        final json = item.toJson();
        expect(json['trigger_conditions'], isEmpty);
      });

      test('toJson keys match expected set', () {
        final item = FoodItem.fromJson({
          'id': 'keys',
          'title': 'T',
          'category': 'fat',
        });
        final json = item.toJson();
        expect(json.keys.toSet(), {
          'id',
          'title',
          'category',
          'trigger_conditions',
          'sort_order',
        });
      });
    });

    group('localizedName', () {
      test('returns correct locale when present', () {
        final item = FoodItem.fromJson({
          'id': 'loc',
          'title': {
            'en': 'Chicken',
            'ar': '\u062f\u062c\u0627\u062c',
            'fr': 'Poulet',
          },
          'category': 'protein',
        });
        expect(item.localizedName('fr'), 'Poulet');
        expect(item.localizedName('ar'), '\u062f\u062c\u0627\u062c');
      });

      test('falls back to en when locale is missing', () {
        final item = FoodItem.fromJson({
          'id': 'fb',
          'title': {'en': 'Chicken', 'ar': '\u062f\u062c\u0627\u062c'},
          'category': 'protein',
        });
        expect(item.localizedName('de'), 'Chicken');
      });

      test('falls back to first value when en is also missing', () {
        final item = FoodItem.fromJson({
          'id': 'no_en',
          'title': {'fr': 'Poulet', 'es': 'Pollo'},
          'category': 'protein',
        });
        // Neither 'de' nor 'en' exists, so first value is returned
        expect(item.localizedName('de'), 'Poulet');
      });
    });

    group('name', () {
      test('returns English title', () {
        final item = FoodItem.fromJson({
          'id': 'en_name',
          'title': {'en': 'Oats', 'ar': '\u0634\u0648\u0641\u0627\u0646'},
          'category': 'carb',
        });
        expect(item.name, 'Oats');
      });

      test('falls back to first value when en is missing', () {
        final item = FoodItem.fromJson({
          'id': 'no_en_name',
          'title': {'fr': 'Avoine'},
          'category': 'carb',
        });
        expect(item.name, 'Avoine');
      });
    });

    group('isSafe', () {
      test('returns true when no trigger conditions', () {
        final item = FoodItem.fromJson({
          'id': 'safe',
          'title': 'Safe Food',
          'category': 'protein',
        });
        expect(item.isSafe, true);
      });

      test('returns false when has trigger conditions', () {
        final item = FoodItem.fromJson({
          'id': 'unsafe',
          'title': 'Unsafe Food',
          'category': 'snack',
          'trigger_conditions': ['gout'],
        });
        expect(item.isSafe, false);
      });

      test('returns false when has multiple trigger conditions', () {
        final item = FoodItem.fromJson({
          'id': 'multi',
          'title': 'Multi Trigger',
          'category': 'fat',
          'trigger_conditions': ['ibs', 'gerd', 'gout'],
        });
        expect(item.isSafe, false);
      });
    });
  });

  group('FoodRegistry', () {
    group('allFoods', () {
      test('has exactly 28 items', () {
        expect(FoodRegistry.allFoods.length, 28);
      });

      test('all have non-empty ids', () {
        for (final food in FoodRegistry.allFoods) {
          expect(
            food.id,
            isNotEmpty,
            reason: 'Food item should have a non-empty id',
          );
        }
      });

      test('all have unique ids', () {
        final ids = FoodRegistry.allFoods.map((f) => f.id).toSet();
        expect(ids.length, FoodRegistry.allFoods.length);
      });

      test('all have en and ar titles', () {
        for (final food in FoodRegistry.allFoods) {
          expect(
            food.title.containsKey('en'),
            isTrue,
            reason: '${food.id} should have en title',
          );
          expect(
            food.title.containsKey('ar'),
            isTrue,
            reason: '${food.id} should have ar title',
          );
          expect(
            food.title['en'],
            isNotEmpty,
            reason: '${food.id} en title should not be empty',
          );
          expect(
            food.title['ar'],
            isNotEmpty,
            reason: '${food.id} ar title should not be empty',
          );
        }
      });

      test('sorted by sortOrder', () {
        for (int i = 1; i < FoodRegistry.allFoods.length; i++) {
          expect(
            FoodRegistry.allFoods[i].sortOrder,
            greaterThanOrEqualTo(FoodRegistry.allFoods[i - 1].sortOrder),
            reason:
                '${FoodRegistry.allFoods[i].id} (${FoodRegistry.allFoods[i].sortOrder}) '
                'should come after ${FoodRegistry.allFoods[i - 1].id} (${FoodRegistry.allFoods[i - 1].sortOrder})',
          );
        }
      });

      test('contains both safe and trigger foods', () {
        final safe = FoodRegistry.allFoods.where((f) => f.isSafe).length;
        final trigger = FoodRegistry.allFoods.where((f) => !f.isSafe).length;
        expect(safe, greaterThan(0));
        expect(trigger, greaterThan(0));
      });
    });

    group('findByName', () {
      test('finds by exact English name', () {
        final rice = FoodRegistry.findByName('Rice');
        expect(rice, isNotNull);
        expect(rice!.id, 'rice');
        expect(rice.name, 'Rice');
      });

      test('finds case-insensitively', () {
        final chicken = FoodRegistry.findByName('grilled chicken');
        expect(chicken, isNotNull);
        expect(chicken!.id, 'grilled_chicken');
      });

      test('returns null for unknown name', () {
        expect(FoodRegistry.findByName('Pizza'), isNull);
      });

      test('returns null for empty string', () {
        expect(FoodRegistry.findByName(''), isNull);
      });

      test('returns null for Arabic name (searches by en only)', () {
        // findByName uses .name which returns en title
        expect(FoodRegistry.findByName('\u0623\u0631\u0632'), isNull);
      });
    });

    group('safeFoods', () {
      test('only returns items with no trigger conditions', () {
        for (final food in FoodRegistry.safeFoods) {
          expect(
            food.isSafe,
            isTrue,
            reason: '${food.name} in safeFoods should have no triggers',
          );
          expect(
            food.triggerConditions,
            isEmpty,
            reason: '${food.name} should have empty triggerConditions',
          );
        }
      });

      test('does not contain any trigger foods', () {
        final safeIds = FoodRegistry.safeFoods.map((f) => f.id).toSet();
        final triggerFoods = FoodRegistry.allFoods.where((f) => !f.isSafe);
        for (final trigger in triggerFoods) {
          expect(
            safeIds.contains(trigger.id),
            isFalse,
            reason:
                '${trigger.name} is a trigger food and should not be in safeFoods',
          );
        }
      });

      test('count equals allFoods minus trigger foods', () {
        final triggerCount = FoodRegistry.allFoods
            .where((f) => !f.isSafe)
            .length;
        expect(
          FoodRegistry.safeFoods.length,
          FoodRegistry.allFoods.length - triggerCount,
        );
      });
    });
  });
}
