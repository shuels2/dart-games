// WS03 §3.7. Tiki Golf and Treasure Divide ran the same within-team-then-
// across-teams pointer arithmetic in two ~40-line copies. These tests cover
// the extracted arithmetic directly — neither provider had a test aimed at
// the rotation itself, only at its downstream effects.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/round_robin_team_rotation.dart';

void main() {
  const teamPlayers = <String, List<String>>{
    'A': ['a1', 'a2'],
    'B': ['b1', 'b2'],
    'C': ['c1'],
  };
  const teamIds = ['A', 'B', 'C'];

  TeamRotationStep step({
    required String team,
    required int index,
    required Map<String, int> pointers,
  }) =>
      RoundRobinTeamRotation.advance(
        teamIds: teamIds,
        currentTeamId: team,
        currentTeamIndex: index,
        withinPeriodPointer: pointers,
        teamPlayers: teamPlayers,
      );

  group('within a team', () {
    test('moves to the next member', () {
      final s = step(team: 'A', index: 0, pointers: {'A': 0});
      expect(s.outcome, TeamRotationOutcome.nextPlayerSameTeam);
      expect(s.nextPlayerId, 'a2');
      expect(s.pointerForCurrentTeam, 1);
    });
  });

  group('across teams', () {
    test('hands over to the next team at its FIRST member', () {
      final s = step(team: 'A', index: 0, pointers: {'A': 1});
      expect(s.outcome, TeamRotationOutcome.nextTeam);
      expect(s.nextTeamId, 'B');
      expect(s.nextTeamIndex, 1);
      expect(s.nextPlayerId, 'b1');
    });

    test('still reports the finished team pointer past its last member', () {
      // Both providers write this back. Dropping it lets the finished team
      // replay its final player at the start of the next period.
      final s = step(team: 'A', index: 0, pointers: {'A': 1});
      expect(s.pointerForCurrentTeam, 2,
          reason: 'must move past the last member, not stay on it');
    });

    test('a one-member team hands over immediately', () {
      final s = step(team: 'C', index: 2, pointers: {'C': 0});
      expect(s.outcome, TeamRotationOutcome.periodComplete,
          reason: 'C is the last team, so finishing it ends the period');
    });
  });

  group('period completion', () {
    test('the last team finishing completes the period', () {
      final s = step(team: 'C', index: 2, pointers: {'C': 0});
      expect(s.outcome, TeamRotationOutcome.periodComplete);
      expect(s.nextPlayerId, isNull,
          reason: 'nobody is up — the caller advances the hole/round');
      expect(s.nextTeamId, isNull);
    });
  });

  group('robustness', () {
    test('a missing pointer entry is treated as 0', () {
      final s = step(team: 'A', index: 0, pointers: {});
      expect(s.outcome, TeamRotationOutcome.nextPlayerSameTeam);
      expect(s.nextPlayerId, 'a2');
    });

    test('an empty next team yields a null player instead of throwing', () {
      // `.first` on an empty list throws deep inside a rotation, which is a
      // miserable place to debug. Both games guarantee non-empty crews; this
      // fails visibly if that ever stops being true.
      final s = RoundRobinTeamRotation.advance(
        teamIds: const ['A', 'EMPTY'],
        currentTeamId: 'A',
        currentTeamIndex: 0,
        withinPeriodPointer: const {'A': 1},
        teamPlayers: const {
          'A': ['a1', 'a2'],
          'EMPTY': <String>[],
        },
      );
      expect(s.outcome, TeamRotationOutcome.nextTeam);
      expect(s.nextPlayerId, isNull);
    });

    test('does not mutate the pointer map it is given', () {
      // The caller writes the pointer back, so the mutation stays visible at
      // the call site rather than happening invisibly in a helper.
      final pointers = {'A': 0};
      step(team: 'A', index: 0, pointers: pointers);
      expect(pointers, {'A': 0});
    });
  });

  group('a full period', () {
    test('visits every player exactly once, in order', () {
      final pointers = <String, int>{'A': 0, 'B': 0, 'C': 0};
      final visited = <String>['a1'];
      var team = 'A';
      var index = 0;

      for (var guard = 0; guard < 20; guard++) {
        final s = step(team: team, index: index, pointers: pointers);
        pointers[team] = s.pointerForCurrentTeam;
        if (s.outcome == TeamRotationOutcome.periodComplete) break;
        if (s.outcome == TeamRotationOutcome.nextTeam) {
          team = s.nextTeamId!;
          index = s.nextTeamIndex!;
          pointers[team] = 0;
        }
        visited.add(s.nextPlayerId!);
      }

      expect(visited, ['a1', 'a2', 'b1', 'b2', 'c1']);
    });
  });
}
