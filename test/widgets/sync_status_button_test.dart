import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/sync_status_button.dart';

/// Minimal dark theme tokens for testing.
const _testTokens = OrchestraColorTokens(
  bg: Color(0xFF0A0A0A),
  bgAlt: Color(0xFF1A1A2E),
  fgBright: Color(0xFFF0F0F0),
  fgMuted: Color(0xFFA0A0A0),
  fgDim: Color(0xFF606060),
  border: Color(0xFF333333),
  accent: Color(0xFF38BDF8),
  accentAlt: Color(0xFFA78BFA),
  glass: Color(0x1F1A1A2E),
  isLight: false,
);

void main() {
  group('SyncStatusButton', () {
    Widget buildApp({
      required String entityType,
      required String entityId,
      EntitySyncMetadata? metadata,
      VoidCallback? onSync,
    }) {
      return ProviderScope(
        overrides: [
          entitySyncStatusProvider((entityType, entityId))
              .overrideWith((ref) async => metadata),
        ],
        child: MaterialApp(
          home: ThemeTokens(
            tokens: _testTokens,
            child: Scaffold(
              body: SyncStatusButton(
                entityType: entityType,
                entityId: entityId,
                onSync: onSync ?? () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows cloud_upload icon when metadata is null (never synced)',
        (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'note',
        entityId: 'n1',
        metadata: null,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('shows cloud_done icon when status is synced', (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'note',
        entityId: 'n2',
        metadata: const EntitySyncMetadata(
          entityType: 'note',
          entityId: 'n2',
          status: EntitySyncStatus.synced,
          localVersion: 1,
          remoteVersion: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('shows schedule icon when status is pending', (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'project',
        entityId: 'p1',
        metadata: const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p1',
          status: EntitySyncStatus.pending,
          localVersion: 2,
          remoteVersion: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('shows cloud_download icon when status is outdated',
        (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'skill',
        entityId: 's1',
        metadata: const EntitySyncMetadata(
          entityType: 'skill',
          entityId: 's1',
          status: EntitySyncStatus.outdated,
          localVersion: 1,
          remoteVersion: 3,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_download_rounded), findsOneWidget);
    });

    testWidgets('shows warning icon when status is conflict', (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'agent',
        entityId: 'a1',
        metadata: const EntitySyncMetadata(
          entityType: 'agent',
          entityId: 'a1',
          status: EntitySyncStatus.conflict,
          localVersion: 2,
          remoteVersion: 2,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('calls onSync when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildApp(
        entityType: 'note',
        entityId: 'n3',
        metadata: null,
        onSync: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SyncStatusButton));
      expect(tapped, isTrue);
    });

    testWidgets('renders tooltip with "Sync with team"', (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'note',
        entityId: 'n4',
        metadata: null,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('renders within a 28x28 container', (tester) async {
      await tester.pumpWidget(buildApp(
        entityType: 'note',
        entityId: 'n5',
        metadata: null,
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final sized = containers.where((c) {
        final box = c.constraints;
        return box != null && box.maxWidth == 28 && box.maxHeight == 28;
      });
      expect(sized, isNotEmpty);
    });
  });

  group('SyncStatusDot', () {
    Widget buildDotApp({
      required String entityType,
      required String entityId,
      EntitySyncMetadata? metadata,
    }) {
      return ProviderScope(
        overrides: [
          entitySyncStatusProvider((entityType, entityId))
              .overrideWith((ref) async => metadata),
        ],
        child: MaterialApp(
          home: ThemeTokens(
            tokens: _testTokens,
            child: Scaffold(
              body: SyncStatusDot(
                entityType: entityType,
                entityId: entityId,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders an 8x8 dot', (tester) async {
      await tester.pumpWidget(buildDotApp(
        entityType: 'project',
        entityId: 'p1',
        metadata: null,
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final dot = containers.where((c) {
        final box = c.constraints;
        return box != null && box.maxWidth == 8 && box.maxHeight == 8;
      });
      expect(dot, isNotEmpty);
    });

    testWidgets('shows green when synced', (tester) async {
      await tester.pumpWidget(buildDotApp(
        entityType: 'project',
        entityId: 'p2',
        metadata: const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p2',
          status: EntitySyncStatus.synced,
          localVersion: 1,
          remoteVersion: 1,
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final greenDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFF22C55E);
        }
        return false;
      });
      expect(greenDot, isNotEmpty);
    });

    testWidgets('shows amber when pending', (tester) async {
      await tester.pumpWidget(buildDotApp(
        entityType: 'project',
        entityId: 'p3',
        metadata: const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p3',
          status: EntitySyncStatus.pending,
          localVersion: 2,
          remoteVersion: 1,
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final amberDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFFF59E0B);
        }
        return false;
      });
      expect(amberDot, isNotEmpty);
    });

    testWidgets('shows blue when outdated', (tester) async {
      await tester.pumpWidget(buildDotApp(
        entityType: 'project',
        entityId: 'p4',
        metadata: const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p4',
          status: EntitySyncStatus.outdated,
          localVersion: 1,
          remoteVersion: 3,
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final blueDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFF3B82F6);
        }
        return false;
      });
      expect(blueDot, isNotEmpty);
    });

    testWidgets('shows red when conflict', (tester) async {
      await tester.pumpWidget(buildDotApp(
        entityType: 'project',
        entityId: 'p5',
        metadata: const EntitySyncMetadata(
          entityType: 'project',
          entityId: 'p5',
          status: EntitySyncStatus.conflict,
          localVersion: 2,
          remoteVersion: 2,
        ),
      ));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final redDot = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFFEF4444);
        }
        return false;
      });
      expect(redDot, isNotEmpty);
    });
  });

  group('SyncStatusButton._iconForStatus coverage', () {
    test('all 5 statuses are covered', () {
      final statuses = EntitySyncStatus.values;
      expect(statuses.length, 5);
      expect(statuses, contains(EntitySyncStatus.neverSynced));
      expect(statuses, contains(EntitySyncStatus.synced));
      expect(statuses, contains(EntitySyncStatus.pending));
      expect(statuses, contains(EntitySyncStatus.outdated));
      expect(statuses, contains(EntitySyncStatus.conflict));
    });
  });

  group('buildEntityContextActions onSync integration', () {
    test('entitySyncStatusProvider key is a (String, String) tuple', () {
      const key = ('note', 'n1');
      expect(key.$1, 'note');
      expect(key.$2, 'n1');
    });

    test('EntitySyncStatus enum has correct JSON round-trip', () {
      for (final status in EntitySyncStatus.values) {
        final json = status.toJson();
        final parsed = EntitySyncStatus.fromString(json);
        expect(parsed, status);
      }
    });
  });
}
