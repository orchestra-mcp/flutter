import 'package:flutter_test/flutter_test.dart';
import 'package:orchestra/core/team/team_provider.dart';

void main() {
  group('Team model used by TeamSwitcher', () {
    test('Team.personal is the synthetic personal team', () {
      expect(Team.personal.id, 'personal');
      expect(Team.personal.name, 'Personal');
      expect(Team.personal.role, isNull);
      expect(Team.personal.isOwner, isFalse);
      expect(Team.personal.isAdmin, isFalse);
    });

    test('Team with owner role reports correct isOwner and isAdmin', () {
      const team = Team(id: '1', name: 'Acme', role: 'owner');
      expect(team.isOwner, isTrue);
      expect(team.isAdmin, isTrue);
    });

    test('Team with admin role reports correct isOwner and isAdmin', () {
      const team = Team(id: '2', name: 'Beta', role: 'admin');
      expect(team.isOwner, isFalse);
      expect(team.isAdmin, isTrue);
    });

    test('Team with member role reports correct isOwner and isAdmin', () {
      const team = Team(id: '3', name: 'Gamma', role: 'member');
      expect(team.isOwner, isFalse);
      expect(team.isAdmin, isFalse);
    });
  });

  group('Team.fromJson used by TeamSwitcher', () {
    test('parses nested team wrapper', () {
      final team = Team.fromJson({
        'team': {'id': 7, 'name': 'Test Team', 'member_count': 3},
        'role': 'admin',
      });
      expect(team.id, '7');
      expect(team.name, 'Test Team');
      expect(team.memberCount, 3);
      expect(team.role, 'admin');
    });

    test('parses flat team object', () {
      final team = Team.fromJson({
        'id': 'abc',
        'name': 'Flat',
        'role': 'member',
      });
      expect(team.id, 'abc');
      expect(team.name, 'Flat');
      expect(team.role, 'member');
    });
  });
}
