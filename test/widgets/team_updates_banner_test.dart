import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/sync/team_sync_provider.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/l10n/app_localizations.dart';
import 'package:orchestra/widgets/team_updates_banner.dart';

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

final _statusWithUpdates = TeamUpdateStatus(
  availableUpdates: 5,
  updates: [
    TeamUpdateEntry(
      entityType: 'note',
      entityId: 'n1',
      entityTitle: 'Meeting Notes',
      teamId: 'team-1',
      teamName: 'Engineering',
      authorName: 'Alice',
      fromVersion: 1,
      toVersion: 2,
      updatedAt: DateTime.utc(2026, 3, 17, 10),
    ),
    TeamUpdateEntry(
      entityType: 'note',
      entityId: 'n2',
      entityTitle: 'Standup',
      teamId: 'team-1',
      teamName: 'Engineering',
      authorName: 'Bob',
      fromVersion: 1,
      toVersion: 3,
      updatedAt: DateTime.utc(2026, 3, 17, 11),
    ),
    TeamUpdateEntry(
      entityType: 'project',
      entityId: 'p1',
      entityTitle: 'Orchestra',
      teamId: 'team-1',
      teamName: 'Engineering',
      authorName: 'Carol',
      fromVersion: 2,
      toVersion: 4,
      updatedAt: DateTime.utc(2026, 3, 17, 12),
    ),
    TeamUpdateEntry(
      entityType: 'skill',
      entityId: 's1',
      entityTitle: 'Deploy',
      teamId: 'team-2',
      teamName: 'DevOps',
      authorName: 'Dave',
      fromVersion: 1,
      toVersion: 2,
      updatedAt: DateTime.utc(2026, 3, 17, 9),
    ),
    TeamUpdateEntry(
      entityType: 'workflow',
      entityId: 'w1',
      entityTitle: 'Default',
      teamId: 'team-1',
      teamName: 'Engineering',
      authorName: 'Eve',
      fromVersion: 1,
      toVersion: 2,
      updatedAt: DateTime.utc(2026, 3, 17, 8),
    ),
  ],
  checkedAt: DateTime.utc(2026, 3, 17, 12),
);

final _statusNoUpdates = TeamUpdateStatus(
  availableUpdates: 0,
  checkedAt: DateTime.utc(2026, 3, 17, 12),
);

Widget _buildApp({required TeamUpdateStatus status}) {
  return ProviderScope(
    overrides: [teamUpdatesProvider.overrideWith((ref) async => status)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, navigator) =>
          ThemeTokens(tokens: _testTokens, child: navigator!),
      home: const Scaffold(
        body: SingleChildScrollView(child: TeamUpdatesBanner()),
      ),
    ),
  );
}

void main() {
  group('BannerDismissedNotifier', () {
    test('starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(bannerDismissedProvider), false);
    });

    test('dismiss sets to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(bannerDismissedProvider.notifier).dismiss();
      expect(container.read(bannerDismissedProvider), true);
    });

    test('reset sets back to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(bannerDismissedProvider.notifier).dismiss();
      container.read(bannerDismissedProvider.notifier).reset();
      expect(container.read(bannerDismissedProvider), false);
    });
  });

  group('PullInProgressNotifier', () {
    test('starts as false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(pullInProgressProvider), false);
    });

    test('set changes value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pullInProgressProvider.notifier).set(true);
      expect(container.read(pullInProgressProvider), true);
      container.read(pullInProgressProvider.notifier).set(false);
      expect(container.read(pullInProgressProvider), false);
    });
  });

  group('TeamUpdateStatus model', () {
    test('stores fields correctly', () {
      final status = TeamUpdateStatus(
        availableUpdates: 3,
        checkedAt: DateTime.utc(2026, 3, 17),
      );
      expect(status.availableUpdates, 3);
      expect(status.updates, isEmpty);
      expect(status.checkedAt, DateTime.utc(2026, 3, 17));
    });

    test('stores update entries', () {
      expect(_statusWithUpdates.availableUpdates, 5);
      expect(_statusWithUpdates.updates, hasLength(5));
    });

    test('zero updates', () {
      expect(_statusNoUpdates.availableUpdates, 0);
      expect(_statusNoUpdates.updates, isEmpty);
    });

    test('fromJson with updates', () {
      final json = {
        'available_updates': 1,
        'updates': [
          {
            'entity_type': 'note',
            'entity_id': 'n1',
            'entity_title': 'Test',
            'team_id': 'team-1',
            'team_name': 'Eng',
            'author_name': 'Alice',
            'from_version': 1,
            'to_version': 2,
            'updated_at': '2026-03-17T10:00:00Z',
          },
        ],
        'checked_at': '2026-03-17T12:00:00Z',
      };
      final status = TeamUpdateStatus.fromJson(json);
      expect(status.availableUpdates, 1);
      expect(status.updates, hasLength(1));
      expect(status.updates.first.entityType, 'note');
      expect(status.updates.first.entityTitle, 'Test');
    });
  });

  group('TeamUpdateEntry model', () {
    test('stores all fields', () {
      final entry = TeamUpdateEntry(
        entityType: 'skill',
        entityId: 's1',
        entityTitle: 'Deploy',
        teamId: 'team-2',
        teamName: 'DevOps',
        authorName: 'Dave',
        fromVersion: 1,
        toVersion: 2,
        updatedAt: DateTime.utc(2026, 3, 17, 9),
      );
      expect(entry.entityType, 'skill');
      expect(entry.entityId, 's1');
      expect(entry.entityTitle, 'Deploy');
      expect(entry.teamId, 'team-2');
      expect(entry.teamName, 'DevOps');
      expect(entry.authorName, 'Dave');
      expect(entry.fromVersion, 1);
      expect(entry.toVersion, 2);
    });

    test('fromJson', () {
      final json = {
        'entity_type': 'doc',
        'entity_id': 'd1',
        'entity_title': 'API Reference',
        'team_id': 'team-1',
        'team_name': 'Eng',
        'author_name': 'Bob',
        'from_version': 3,
        'to_version': 5,
        'updated_at': '2026-03-17',
      };
      final entry = TeamUpdateEntry.fromJson(json);
      expect(entry.entityType, 'doc');
      expect(entry.entityTitle, 'API Reference');
      expect(entry.fromVersion, 3);
      expect(entry.toVersion, 5);
    });
  });

  group('TeamUpdatesBanner widget', () {
    testWidgets('shows banner with updates', (tester) async {
      await tester.pumpWidget(_buildApp(status: _statusWithUpdates));
      await tester.pumpAndSettle();

      expect(find.textContaining('5 updates available'), findsOneWidget);
      expect(find.text('Pull Updates'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('shows entity type breakdown chips', (tester) async {
      await tester.pumpWidget(_buildApp(status: _statusWithUpdates));
      await tester.pumpAndSettle();

      // 2 notes, 1 project, 1 skill, 1 workflow
      expect(find.text('2 notes'), findsOneWidget);
      expect(find.text('1 project'), findsOneWidget);
      expect(find.text('1 skill'), findsOneWidget);
      expect(find.text('1 workflow'), findsOneWidget);
    });

    testWidgets('hides when no updates', (tester) async {
      await tester.pumpWidget(_buildApp(status: _statusNoUpdates));
      await tester.pumpAndSettle();

      expect(find.text('Pull Updates'), findsNothing);
      expect(find.textContaining('updates available'), findsNothing);
    });

    testWidgets('dismiss hides banner', (tester) async {
      await tester.pumpWidget(_buildApp(status: _statusWithUpdates));
      await tester.pumpAndSettle();

      expect(find.textContaining('5 updates available'), findsOneWidget);

      // Tap the "Later" button
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.textContaining('updates available'), findsNothing);
    });

    testWidgets('close icon dismisses banner', (tester) async {
      await tester.pumpWidget(_buildApp(status: _statusWithUpdates));
      await tester.pumpAndSettle();

      // Tap the close icon (X)
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('updates available'), findsNothing);
    });

    testWidgets('singular update text', (tester) async {
      final singleUpdate = TeamUpdateStatus(
        availableUpdates: 1,
        updates: [
          TeamUpdateEntry(
            entityType: 'note',
            entityId: 'n1',
            entityTitle: 'Test',
            teamId: 'team-1',
            teamName: 'Eng',
            authorName: 'Alice',
            fromVersion: 1,
            toVersion: 2,
            updatedAt: DateTime.utc(2026, 3, 17),
          ),
        ],
        checkedAt: DateTime.utc(2026, 3, 17),
      );
      await tester.pumpWidget(_buildApp(status: singleUpdate));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 update available'), findsOneWidget);
      expect(find.text('1 note'), findsOneWidget);
    });
  });
}
