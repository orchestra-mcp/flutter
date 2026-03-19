import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/storage/entity_customization_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EntityCustomization', () {
    test('toJson serialises color and icon', () {
      const cust = EntityCustomization(
        color: Color(0xFF8B5CF6),
        iconCodePoint: 0xe1d7,
      );
      final json = cust.toJson();
      expect(json['color'], isA<String>());
      expect(json['icon'], 0xe1d7);
    });

    test('fromJson round-trips correctly', () {
      const original = EntityCustomization(
        color: Color(0xFF38BDF8),
        iconCodePoint: 0xe1a3,
      );
      final json = original.toJson();
      final restored = EntityCustomization.fromJson(json);
      expect(restored.color, original.color);
      expect(restored.iconCodePoint, original.iconCodePoint);
    });

    test('fromJson handles missing fields', () {
      final cust = EntityCustomization.fromJson({});
      expect(cust.color, isNull);
      expect(cust.iconCodePoint, isNull);
      expect(cust.icon, isNull);
    });

    test('icon getter returns IconData from codepoint', () {
      const cust = EntityCustomization(iconCodePoint: 0xe1d7);
      expect(cust.icon, isNotNull);
      expect(cust.icon!.codePoint, 0xe1d7);
      expect(cust.icon!.fontFamily, 'MaterialIcons');
    });

    test('icon getter returns null when no codepoint', () {
      const cust = EntityCustomization();
      expect(cust.icon, isNull);
    });

    test('copyWith preserves existing values', () {
      const cust = EntityCustomization(
        color: Color(0xFFFF0000),
        iconCodePoint: 100,
      );
      final updated = cust.copyWith(color: const Color(0xFF00FF00));
      expect(updated.color, const Color(0xFF00FF00));
      expect(updated.iconCodePoint, 100);
    });
  });

  group('EntityCustomizationNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(entityCustomizationProvider), isEmpty);
    });

    test('setColor stores color for entity', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(entityCustomizationProvider.notifier)
          .setColor('note-1', const Color(0xFF8B5CF6));

      final state = container.read(entityCustomizationProvider);
      expect(state['note-1'], isNotNull);
      expect(state['note-1']!.color, const Color(0xFF8B5CF6));
    });

    test('setIcon stores icon for entity', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(entityCustomizationProvider.notifier)
          .setIcon('project-1', 0xe1d7);

      final state = container.read(entityCustomizationProvider);
      expect(state['project-1'], isNotNull);
      expect(state['project-1']!.iconCodePoint, 0xe1d7);
    });

    test('setColor and setIcon on same entity preserves both', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(entityCustomizationProvider.notifier);
      await notifier.setColor('item-1', const Color(0xFFEC4899));
      await notifier.setIcon('item-1', 0xe1a3);

      final cust = container.read(entityCustomizationProvider)['item-1']!;
      expect(cust.color, const Color(0xFFEC4899));
      expect(cust.iconCodePoint, 0xe1a3);
    });

    test('get returns null for unknown entity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(entityCustomizationProvider.notifier).get('unknown'),
        isNull,
      );
    });

    test('persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(entityCustomizationProvider.notifier)
          .setColor('persist-test', const Color(0xFF4ADE80));

      // Verify it was saved
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('entity_customizations');
      expect(raw, isNotNull);
      expect(raw!, contains('persist-test'));
    });

    test('multiple entities are independent', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(entityCustomizationProvider.notifier);
      await notifier.setColor('a', const Color(0xFFFF0000));
      await notifier.setColor('b', const Color(0xFF00FF00));

      final state = container.read(entityCustomizationProvider);
      expect(state['a']!.color, const Color(0xFFFF0000));
      expect(state['b']!.color, const Color(0xFF00FF00));
    });
  });
}
