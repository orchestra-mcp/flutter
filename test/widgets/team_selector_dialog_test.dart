import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/sync/team_management_provider.dart';
import 'package:orchestra/core/sync/team_management_service.dart';
import 'package:orchestra/core/sync/team_share_models.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/widgets/team_selector_dialog.dart';

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

final _twoTeams = TeamSelectorData(
  teams: [
    Team(id: 'team-1', name: 'Engineering', createdAt: DateTime.utc(2026)),
    Team(id: 'team-2', name: 'Design', createdAt: DateTime.utc(2026)),
  ],
  membersByTeamId: {
    'team-1': const [
      TeamMember(
        id: 'u1',
        name: 'Alice',
        email: 'alice@test.com',
        role: 'admin',
        isOnline: true,
      ),
      TeamMember(
        id: 'u2',
        name: 'Bob',
        email: 'bob@test.com',
        role: 'member',
        isOnline: false,
      ),
    ],
    'team-2': const [TeamMember(id: 'u3', name: 'Carol', role: 'member')],
  },
);

const _noTeams = TeamSelectorData(teams: [], membersByTeamId: {});

Widget _buildApp({required TeamSelectorData selectorData, Widget? child}) {
  return ProviderScope(
    overrides: [
      teamSelectorDataProvider.overrideWith((ref) async => selectorData),
    ],
    child: MaterialApp(
      builder: (context, navigator) =>
          ThemeTokens(tokens: _testTokens, child: navigator!),
      home: Scaffold(
        body: Builder(
          builder: (context) =>
              child ??
              ElevatedButton(
                onPressed: () => showTeamSelectorDialog(
                  context: context,
                  entityType: 'note',
                  entityId: 'n1',
                ),
                child: const Text('Open'),
              ),
        ),
      ),
    ),
  );
}

void main() {
  group('TeamShareSelection', () {
    test('stores all fields correctly', () {
      const selection = TeamShareSelection(
        teamId: 'team-1',
        shareWithAll: false,
        memberIds: ['u1', 'u2'],
        permission: SharePermission.write,
      );
      expect(selection.teamId, 'team-1');
      expect(selection.shareWithAll, false);
      expect(selection.memberIds, ['u1', 'u2']);
      expect(selection.permission, SharePermission.write);
    });

    test('stores share-with-all selection', () {
      const selection = TeamShareSelection(
        teamId: 'team-2',
        shareWithAll: true,
        memberIds: [],
        permission: SharePermission.read,
      );
      expect(selection.shareWithAll, true);
      expect(selection.memberIds, isEmpty);
    });
  });

  group('TeamSelectorDialog widget', () {
    testWidgets('shows header text', (tester) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Share note'), findsOneWidget);
      expect(
        find.text('Select a team and choose who to share with'),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no teams', (tester) async {
      await tester.pumpWidget(_buildApp(selectorData: _noTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('No teams found'), findsOneWidget);
      expect(
        find.text('Join or create a team to start sharing'),
        findsOneWidget,
      );
    });

    testWidgets('shows team chips', (tester) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Design'), findsOneWidget);
    });

    testWidgets('selecting a team shows share controls', (tester) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Initially no share button
      expect(find.text('Share'), findsNothing);

      // Tap a team
      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();

      // Now share controls visible
      expect(find.text('Share with entire team'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows permission selector after team selection', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('cancel dismisses without result', (tester) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Share note'), findsNothing);
    });

    testWidgets('share button is enabled when team selected with share-all', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(selectorData: _twoTeams));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Engineering'));
      await tester.pumpAndSettle();

      // Share button should be enabled (share-with-all is default true)
      final shareButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Share'),
      );
      expect(shareButton.onPressed, isNotNull);
    });
  });

  group('SelectedTeamNotifier', () {
    test('starts as null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(selectedTeamProvider), isNull);
    });

    test('select sets team id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedTeamProvider.notifier).select('team-1');
      expect(container.read(selectedTeamProvider), 'team-1');
    });

    test('clear resets to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedTeamProvider.notifier).select('team-1');
      container.read(selectedTeamProvider.notifier).clear();
      expect(container.read(selectedTeamProvider), isNull);
    });
  });

  group('SelectedMembersNotifier', () {
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(selectedMembersProvider), isEmpty);
    });

    test('toggle adds and removes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedMembersProvider.notifier).toggle('u1');
      expect(container.read(selectedMembersProvider), {'u1'});
      container.read(selectedMembersProvider.notifier).toggle('u2');
      expect(container.read(selectedMembersProvider), {'u1', 'u2'});
      container.read(selectedMembersProvider.notifier).toggle('u1');
      expect(container.read(selectedMembersProvider), {'u2'});
    });

    test('selectAll replaces current', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedMembersProvider.notifier).toggle('u1');
      container.read(selectedMembersProvider.notifier).selectAll({'u3', 'u4'});
      expect(container.read(selectedMembersProvider), {'u3', 'u4'});
    });

    test('clear empties set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedMembersProvider.notifier).toggle('u1');
      container.read(selectedMembersProvider.notifier).clear();
      expect(container.read(selectedMembersProvider), isEmpty);
    });
  });

  group('ShareModeNotifier', () {
    test('defaults to true (share with all)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(shareWithAllProvider), true);
    });

    test('toggle flips value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(shareWithAllProvider.notifier).toggle();
      expect(container.read(shareWithAllProvider), false);
      container.read(shareWithAllProvider.notifier).toggle();
      expect(container.read(shareWithAllProvider), true);
    });

    test('setShareWithAll sets explicit value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(shareWithAllProvider.notifier).setShareWithAll(false);
      expect(container.read(shareWithAllProvider), false);
    });
  });

  group('PermissionNotifier', () {
    test('defaults to read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(sharePermissionProvider), SharePermission.read);
    });

    test('select changes permission', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(sharePermissionProvider.notifier)
          .select(SharePermission.admin);
      expect(container.read(sharePermissionProvider), SharePermission.admin);
    });
  });
}
