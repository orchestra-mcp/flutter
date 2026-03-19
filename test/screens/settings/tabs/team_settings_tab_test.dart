import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/team/team_provider.dart';

void main() {
  // ── Team model ────────────────────────────────────────────────────────────

  group('Team model', () {
    group('isOwner', () {
      test('returns true when role is owner', () {
        const team = Team(id: '1', name: 'Acme', role: 'owner');
        expect(team.isOwner, isTrue);
      });

      test('returns false when role is admin', () {
        const team = Team(id: '2', name: 'Beta', role: 'admin');
        expect(team.isOwner, isFalse);
      });

      test('returns false when role is member', () {
        const team = Team(id: '3', name: 'Gamma', role: 'member');
        expect(team.isOwner, isFalse);
      });

      test('returns false when role is null', () {
        const team = Team(id: '4', name: 'Delta');
        expect(team.isOwner, isFalse);
      });
    });

    group('isAdmin', () {
      test('returns true when role is admin', () {
        const team = Team(id: '1', name: 'A', role: 'admin');
        expect(team.isAdmin, isTrue);
      });

      test('returns true when role is owner (owner implies admin)', () {
        const team = Team(id: '2', name: 'B', role: 'owner');
        expect(team.isAdmin, isTrue);
      });

      test('returns false when role is member', () {
        const team = Team(id: '3', name: 'C', role: 'member');
        expect(team.isAdmin, isFalse);
      });

      test('returns false when role is null', () {
        const team = Team(id: '4', name: 'D');
        expect(team.isAdmin, isFalse);
      });

      test('returns false for unrecognised role string', () {
        const team = Team(id: '5', name: 'E', role: 'viewer');
        expect(team.isAdmin, isFalse);
      });
    });

    group('Team.fromJson', () {
      test('parses a flat team object', () {
        final team = Team.fromJson({
          'id': 42,
          'name': 'Flat Team',
          'slug': 'flat-team',
          'avatar_url': '/uploads/avatar.png',
          'plan': 'pro',
          'member_count': 5,
          'role': 'owner',
        });
        expect(team.id, '42');
        expect(team.name, 'Flat Team');
        expect(team.slug, 'flat-team');
        expect(team.avatarUrl, '/uploads/avatar.png');
        expect(team.plan, 'pro');
        expect(team.memberCount, 5);
        expect(team.role, 'owner');
      });

      test('parses a nested wrapper (team + role at top level)', () {
        final team = Team.fromJson({
          'team': {
            'id': 7,
            'name': 'Nested Team',
            'slug': 'nested-team',
            'avatar_url': null,
            'plan': 'free',
            'member_count': 2,
          },
          'role': 'admin',
        });
        expect(team.id, '7');
        expect(team.name, 'Nested Team');
        expect(team.slug, 'nested-team');
        expect(team.avatarUrl, isNull);
        expect(team.plan, 'free');
        expect(team.memberCount, 2);
        expect(team.role, 'admin');
      });

      test('handles minimal fields', () {
        final team = Team.fromJson({'id': 1});
        expect(team.id, '1');
        expect(team.name, '');
        expect(team.slug, isNull);
        expect(team.avatarUrl, isNull);
        expect(team.plan, isNull);
        expect(team.memberCount, isNull);
        expect(team.role, isNull);
      });

      test('converts integer id to string', () {
        final team = Team.fromJson({'id': 999, 'name': 'Num'});
        expect(team.id, '999');
      });

      test('converts string id to string', () {
        final team = Team.fromJson({'id': 'abc-123', 'name': 'Str'});
        expect(team.id, 'abc-123');
      });
    });

    group('Team.personal', () {
      test('has id "personal"', () {
        expect(Team.personal.id, 'personal');
      });

      test('has name "Personal"', () {
        expect(Team.personal.name, 'Personal');
      });

      test('has null optional fields', () {
        expect(Team.personal.slug, isNull);
        expect(Team.personal.avatarUrl, isNull);
        expect(Team.personal.plan, isNull);
        expect(Team.personal.memberCount, isNull);
        expect(Team.personal.role, isNull);
      });

      test('is not owner and not admin', () {
        expect(Team.personal.isOwner, isFalse);
        expect(Team.personal.isAdmin, isFalse);
      });
    });
  });

  // ── TeamMember model ──────────────────────────────────────────────────────

  group('TeamMember model', () {
    group('fromJson', () {
      test('parses complete member JSON', () {
        final member = TeamMember.fromJson({
          'id': 10,
          'name': 'Alice',
          'email': 'alice@example.com',
          'role': 'admin',
          'avatar_url': '/uploads/alice.jpg',
          'status': 'active',
          'joined_at': '2026-01-15T10:30:00Z',
        });
        expect(member.id, '10');
        expect(member.name, 'Alice');
        expect(member.email, 'alice@example.com');
        expect(member.role, 'admin');
        expect(member.avatarUrl, '/uploads/alice.jpg');
        expect(member.status, 'active');
        expect(member.joinedAt, isA<DateTime>());
        expect(member.joinedAt!.year, 2026);
      });

      test('handles missing optional fields', () {
        final member = TeamMember.fromJson({
          'id': 20,
          'name': 'Bob',
          'email': 'bob@example.com',
          'role': 'member',
        });
        expect(member.avatarUrl, isNull);
        expect(member.status, isNull);
        expect(member.joinedAt, isNull);
      });

      test('defaults name to empty string when null', () {
        final member = TeamMember.fromJson({
          'id': 30,
          'name': null,
          'email': 'anon@example.com',
          'role': 'member',
        });
        expect(member.name, '');
      });

      test('defaults role to member when null', () {
        final member = TeamMember.fromJson({
          'id': 32,
          'name': 'DefaultRole',
          'email': 'dr@example.com',
        });
        expect(member.role, 'member');
      });

      test('handles invalid joined_at gracefully', () {
        final member = TeamMember.fromJson({
          'id': 40,
          'name': 'BadDate',
          'email': 'bd@example.com',
          'role': 'member',
          'joined_at': 'not-a-date',
        });
        expect(member.joinedAt, isNull);
      });
    });

    group('constructor', () {
      test('is constructible with required fields', () {
        const member = TeamMember(
          id: '1',
          name: 'Test',
          email: 'test@test.com',
          role: 'member',
        );
        expect(member.id, '1');
        expect(member.avatarUrl, isNull);
      });
    });
  });
}
