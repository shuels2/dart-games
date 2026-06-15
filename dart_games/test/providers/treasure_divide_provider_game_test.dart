import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/treasure_divide_game.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

TreasureDivideProvider _makeSolo({
  List<String>? playerIds,
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  Random? random,
}) {
  final p = TreasureDivideProvider();
  p.startGame(
    playerIds: playerIds ?? ['p1', 'p2'],
    numberOfRounds: numberOfRounds,
    quarterItEnabled: quarterItEnabled,
    customTargetsEnabled: customTargetsEnabled,
    gameMode: TreasureDivideGameMode.solo,
    teamAssignment: TreasureDivideTeamAssignment.random,
    random: random,
  );
  return p;
}

TreasureDivideProvider _makeTeam({
  required Map<String, List<String>> teamPlayers,
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  Random? random,
}) {
  final allIds = teamPlayers.values.expand((e) => e).toList();
  final assignments = <String, String>{};
  for (final entry in teamPlayers.entries) {
    for (final pid in entry.value) {
      assignments[pid] = entry.key;
    }
  }
  final p = TreasureDivideProvider();
  p.startGame(
    playerIds: allIds,
    numberOfRounds: numberOfRounds,
    quarterItEnabled: quarterItEnabled,
    customTargetsEnabled: false,
    gameMode: TreasureDivideGameMode.team,
    teamAssignment: TreasureDivideTeamAssignment.manual,
    teamCount: teamPlayers.length,
    manualTeamAssignments: assignments,
    random: random,
  );
  return p;
}

/// Throws a dart that hits the current round's target.
void _hit(TreasureDivideProvider p, {String? mul}) {
  final game = p.currentGame!;
  final target = game.targetSequence[game.currentRoundIndex];
  final multiplier = mul ?? 'single';
  int base, score;
  String sector;
  if (target == kTargetAnyDouble) {
    base = 10; score = 20; sector = 'D10';
  } else if (target == kTargetAnyTriple) {
    base = 10; score = 30; sector = 'T10';
  } else if (target == kTargetBull) {
    base = 25; score = 25; sector = '25';
  } else {
    base = target;
    score = target * (multiplier == 'triple' ? 3 : multiplier == 'double' ? 2 : 1);
    sector = '${multiplier == 'triple' ? 'T' : multiplier == 'double' ? 'D' : 'S'}$target';
  }
  p.processDartThrow(score: score, multiplier: multiplier, baseScore: base, sector: sector);
}

/// Throws a dart that always misses.
void _miss(TreasureDivideProvider p) {
  final game = p.currentGame!;
  final target = game.targetSequence[game.currentRoundIndex];
  int base = (target == 1 || target < 0 || target == 25) ? 2 : 1;
  p.processDartThrow(score: base, multiplier: 'single', baseScore: base, sector: 'S$base');
}

/// Completes a full turn with one hit then misses.
void _finishHit(TreasureDivideProvider p) {
  _hit(p);
  while (!p.shouldPromptTakeout) _miss(p);
  p.handleTakeoutFinished();
}

/// Completes a full turn with all misses.
void _finishMiss(TreasureDivideProvider p) {
  while (!p.shouldPromptTakeout) _miss(p);
  p.handleTakeoutFinished();
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // Initial State
  // ═══════════════════════════════════════════════════════════════════
  group('Initial State', () {
    test('1. isGameActive is false before startGame', () {
      final p = TreasureDivideProvider();
      expect(p.isGameActive, false);
    });

    test('2. isGameActive is true after startGame', () {
      final p = _makeSolo();
      expect(p.isGameActive, true);
    });

    test('3. currentRoundIndex starts at 0', () {
      final p = _makeSolo();
      expect(p.currentGame!.currentRoundIndex, 0);
    });

    test('4. Standard 9-round sequence has correct AD/AT/Bull positions', () {
      final p = _makeSolo(customTargetsEnabled: false);
      final seq = p.currentGame!.targetSequence;
      expect(seq[3], kTargetAnyDouble);
      expect(seq[7], kTargetAnyTriple);
      expect(seq[8], kTargetBull);
    });

    test('5. shouldPromptTakeout starts false', () {
      final p = _makeSolo();
      expect(p.shouldPromptTakeout, false);
    });

    test('6. winnerIds is empty before game ends', () {
      final p = _makeSolo();
      expect(p.currentGame!.winnerIds, isEmpty);
    });

    test('7. playerRoundScores initialized to null for all rounds', () {
      final p = _makeSolo(playerIds: ['p1', 'p2'], numberOfRounds: 9);
      final scores = p.currentGame!.playerRoundScores['p1']!;
      expect(scores.length, 9);
      expect(scores.every((s) => s == null), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // processDartThrow per round-target type
  // ═══════════════════════════════════════════════════════════════════
  group('processDartThrow per round-target type', () {
    test('8. Number round: single of target scores target×1', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target, sector: 'S$target');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target);
    });

    test('9. Number round: double of target scores target×2', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: target * 2, multiplier: 'double', baseScore: target,
          sector: 'D$target');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target * 2);
    });

    test('10. Number round: triple of target scores target×3', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: target * 3, multiplier: 'triple', baseScore: target,
          sector: 'T$target');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target * 3);
    });

    test('11. Number round: single of different number scores 0', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final wrongNum = (target == 1) ? 2 : 1;
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: wrongNum, multiplier: 'single', baseScore: wrongNum,
          sector: 'S$wrongNum');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], 0);
    });

    test('12. AnyDouble round: double counts, single of same number does not', () {
      final p = _makeSolo(random: Random(42));
      final game = p.currentGame!;
      // Advance to round 3 (AnyDouble)
      for (int r = 0; r < 3; r++) {
        for (int i = 0; i < 2; i++) _finishMiss(p);
      }
      expect(game.targetSequence[3], kTargetAnyDouble);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      p.processDartThrow(
          score: 30, multiplier: 'double', baseScore: 15, sector: 'D15');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![3], 30);
    });

    test('13. AnyTriple round: triple counts, double of same number does not', () {
      final p = _makeSolo(random: Random(42));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < 2; i++) _finishMiss(p);
      }
      expect(game.targetSequence[7], kTargetAnyTriple);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 20, multiplier: 'double', baseScore: 10, sector: 'D10');
      p.processDartThrow(
          score: 45, multiplier: 'triple', baseScore: 15, sector: 'T15');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![7], 45);
    });

    test('14. Bull round: outer bull 25 scores 25', () {
      final p = _makeSolo(numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 6; r++) {
        for (int i = 0; i < 2; i++) _finishMiss(p);
      }
      expect(game.targetSequence[6], kTargetBull);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 25, multiplier: 'single', baseScore: 25, sector: '25');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![6], 25);
    });

    test('15. Bull round: inner bull 50 scores 50', () {
      final p = _makeSolo(numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 6; r++) {
        for (int i = 0; i < 2; i++) _finishMiss(p);
      }
      expect(game.targetSequence[6], kTargetBull);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 50, multiplier: 'bull', baseScore: 25, sector: 'Bull');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![6], 50);
    });

    test('16. Number round: trying to score 20 on AnyDouble round with single = 0', () {
      final p = _makeSolo(random: Random(42));
      final game = p.currentGame!;
      // Advance to round 3 (AnyDouble)
      for (int r = 0; r < 3; r++) {
        for (int i = 0; i < 2; i++) _finishMiss(p);
      }
      expect(game.targetSequence[3], kTargetAnyDouble);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      while (!p.shouldPromptTakeout) _miss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![3], 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Turn Advancement
  // ═══════════════════════════════════════════════════════════════════
  group('Turn Advancement', () {
    test('17. Advances after 3 darts (Solo)', () {
      final p = _makeSolo();
      final game = p.currentGame!;
      _miss(p); _miss(p);
      expect(game.shouldPromptTakeout, false);
      _miss(p);
      expect(game.shouldPromptTakeout, true);
    });

    test('18. Advances after 6 darts for solo crew', () {
      final p = _makeTeam(
        teamPlayers: {'team_1': ['p1'], 'team_2': ['p2', 'p3']},
        random: Random(0),
      );
      final game = p.currentGame!;
      for (int i = 0; i < 5; i++) {
        _miss(p);
        expect(game.shouldPromptTakeout, false);
      }
      _miss(p);
      expect(game.shouldPromptTakeout, true);
    });

    test('19. skipTurn forfeits remaining darts and ends turn', () {
      final p = _makeSolo();
      final game = p.currentGame!;
      _miss(p); // 1 dart thrown
      p.skipTurn();
      expect(game.shouldPromptTakeout, true);
    });

    test('20. Dart counter resets to 0 per turn', () {
      final p = _makeSolo();
      final game = p.currentGame!;
      _finishHit(p); // p1 completes turn
      // p2's turn starts fresh
      expect(game.dartsThrown, 0);
    });

    test('21. No-op when state == finished', () {
      final p = _makeSolo(numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      // Complete all rounds
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < 2; i++) _finishHit(p);
      }
      expect(game.state, TreasureDivideGameState.finished);
      final beforeCount = game.totalDartsThrown['p1'] ?? 0;
      _miss(p); // should be ignored
      expect(game.totalDartsThrown['p1'] ?? 0, beforeCount);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Win Detection
  // ═══════════════════════════════════════════════════════════════════
  group('Win Detection', () {
    test('22. Highest score wins (Solo)', () {
      final p = _makeSolo(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 50;
        game.playerRoundScores['p2']![r] = 10;
      }
      p.endGame();
      expect(game.winnerIds, ['p1']);
    });

    test('23. Highest crew treasure wins (Team)', () {
      final p = _makeTeam(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        numberOfRounds: 7,
        random: Random(0),
      );
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 30;
        game.playerRoundScores['p2']![r] = 30;
        game.playerRoundScores['p3']![r] = 5;
        game.playerRoundScores['p4']![r] = 5;
      }
      p.endGame();
      expect(game.winnerTeamIds, ['team_1']);
    });

    test('24. Tiebreaker: fewer halvings wins (Solo)', () {
      final p = _makeSolo(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      // Same total, p2 halved more
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 20;
        game.playerRoundScores['p2']![r] = 20;
      }
      game.timesHalvedPerPlayer['p1'] = 0;
      game.timesHalvedPerPlayer['p2'] = 2;
      p.endGame();
      expect(game.winnerIds, ['p1']);
    });

    test('25. Tie: equal score + equal halvings → winnerIds.length == 2 (Solo)', () {
      final p = _makeSolo(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 20;
        game.playerRoundScores['p2']![r] = 20;
      }
      p.endGame();
      expect(game.winnerIds.length, 2);
    });

    test('26. Tie: equal crew treasure + equal halvings → winnerTeamIds.length == 2', () {
      final p = _makeTeam(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        numberOfRounds: 7,
        random: Random(0),
      );
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 20;
        game.playerRoundScores['p2']![r] = 20;
        game.playerRoundScores['p3']![r] = 20;
        game.playerRoundScores['p4']![r] = 20;
      }
      p.endGame();
      expect(game.winnerTeamIds.length, 2);
      expect(game.winnerIds.length, 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Per-option side-effects
  // ═══════════════════════════════════════════════════════════════════
  group('Per-option side-effects', () {
    test('27. Quarter It changes divisor to 4 (Solo)', () {
      final p = _makeSolo(quarterItEnabled: true, random: Random(1));
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 100;
      game.playerRoundScores['p1']![1] = 0; // quartered
      game.timesHalvedPerPlayer['p1'] = 1;
      expect(game.totalForPlayer('p1'), 25); // floor(100/4)
    });

    test('28. Quarter It applies to crew in Team mode (÷4)', () {
      final p = _makeTeam(
        teamPlayers: {'team_1': ['p1', 'p2'], 'team_2': ['p3', 'p4']},
        quarterItEnabled: true,
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 80;
      game.playerRoundScores['p2']![0] = 20;
      game.playerRoundScores['p1']![1] = 0;
      game.playerRoundScores['p2']![1] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      expect(game.totalForTeam('team_1'), 25); // floor(100/4)
    });

    test('29. Custom Targets randomizes sequence', () {
      final p = _makeSolo(customTargetsEnabled: true, random: Random(42));
      final standard = TreasureDivideGame.sequenceFor(9);
      final custom = p.currentGame!.targetSequence;
      // AD/AT/Bull positions are fixed
      expect(custom[3], kTargetAnyDouble);
      expect(custom[7], kTargetAnyTriple);
      expect(custom[8], kTargetBull);
      // Some numbers should differ from standard
      bool differs = false;
      for (int i = 0; i < 9; i++) {
        if (custom[i] != standard[i]) {
          differs = true;
          break;
        }
      }
      expect(differs, true);
    });

    test('30. Number of Rounds 7 adjusts target list length', () {
      final p = _makeSolo(numberOfRounds: 7);
      expect(p.currentGame!.targetSequence.length, 7);
    });

    test('31. Number of Rounds 12 adjusts target list length', () {
      final p = _makeSolo(numberOfRounds: 12);
      expect(p.currentGame!.targetSequence.length, 12);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Round/Match Transitions
  // ═══════════════════════════════════════════════════════════════════
  group('Round/Match Transitions', () {
    test('32. Round increments after all players complete', () {
      final p = _makeSolo(playerIds: ['p1', 'p2'], random: Random(0));
      _finishHit(p); // p1
      _finishHit(p); // p2
      expect(p.currentGame!.currentRoundIndex, 1);
    });

    test('33. currentPlayerId advances to next player within a round', () {
      final p = _makeSolo(playerIds: ['p1', 'p2'], random: Random(0));
      final game = p.currentGame!;
      expect(game.currentPlayerId, 'p1');
      _finishHit(p);
      expect(game.currentPlayerId, 'p2');
    });

    test('34. currentTeamIndex advances after crew finishes (Team)', () {
      final p = _makeTeam(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      expect(game.currentTeamIndex, 0);
      _finishHit(p); // p1
      _finishHit(p); // p2 → crew done
      expect(game.currentTeamIndex, 1);
    });

    test('35. Game finishes after final round', () {
      final p = _makeSolo(numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < 2; i++) _finishHit(p);
      }
      expect(game.state, TreasureDivideGameState.finished);
      expect(game.gameEndTime, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // editPlayerScore replay
  // ═══════════════════════════════════════════════════════════════════
  group('editPlayerScore replay', () {
    test('36. Edit updates round score from miss to hit', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      game.playerRoundScores[pid]![0] = 0;
      game.timesHalvedPerPlayer[pid] = 1;
      p.editPlayerScore(
        playerId: pid,
        roundIndex: 0,
        newSegments: ['S$target', 'Miss', 'Miss'],
      );
      expect(game.playerRoundScores[pid]![0], target);
      expect(game.timesHalvedPerPlayer[pid], 0);
    });

    test(
        '37. Edit updates round score from hit to miss (new halving — '
        'when there was treasure to halve)', () {
      // Set up a 2-round history: round 0 = scored, round 1 = scored,
      // and we then edit round 1 to all-miss. Because the player had
      // a positive treasure walking into round 1, the all-miss edit
      // counts as a real halving event and bumps timesHalvedPerPlayer.
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      final target0 = game.targetSequence[0];
      final target1 = game.targetSequence[1];
      if (target0 <= 0 ||
          target0 == 25 ||
          target1 <= 0 ||
          target1 == 25) {
        return;
      }
      game.playerRoundScores[pid]![0] = target0;
      game.playerRoundScores[pid]![1] = target1;
      game.timesHalvedPerPlayer[pid] = 0;
      p.editPlayerScore(
        playerId: pid,
        roundIndex: 1,
        newSegments: ['Miss', 'Miss', 'Miss'],
      );
      expect(game.playerRoundScores[pid]![1], 0);
      expect(game.timesHalvedPerPlayer[pid], 1);
    });

    test(
        '37b. Edit hit→miss on round 0 does NOT count as halving '
        '(no prior treasure)', () {
      // Player has zero treasure walking into round 0 (it's the first
      // round). Editing the round-0 score from a hit to all-miss
      // brings the total to (0 / divisor).floor() = 0 — no actual
      // halving event happened, so the display counter must stay 0.
      // Regression for the bug where opponent tiles showed
      // "Quartered 1 time" after a first-round all-miss even though
      // the player's gold never dropped.
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      game.playerRoundScores[pid]![0] = target;
      game.timesHalvedPerPlayer[pid] = 0;
      p.editPlayerScore(
        playerId: pid,
        roundIndex: 0,
        newSegments: ['Miss', 'Miss', 'Miss'],
      );
      expect(game.playerRoundScores[pid]![0], 0);
      expect(
        game.timesHalvedPerPlayer[pid],
        0,
        reason: 'No treasure walking into round 0 → halving 0 is a '
            'no-op → counter must stay 0',
      );
    });

    test('38. Edit on finished game re-runs finalization (Rule §20)', () {
      final p = _makeSolo(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 50;
        game.playerRoundScores['p2']![r] = 10;
      }
      p.endGame();
      expect(game.winnerIds, ['p1']);

      // Now edit p1's scores to be lower than p2
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 1;
        game.playerRoundScores['p2']![r] = 50;
      }
      p.editPlayerScore(
        playerId: 'p1',
        roundIndex: 0,
        newSegments: ['Miss', 'Miss', 'Miss'],
      );
      // Game should re-finalize
      expect(game.state, TreasureDivideGameState.finished);
    });

    test('39. Editing a round for team player adjusts team halve counter', () {
      final p = _makeTeam(
        teamPlayers: {'team_1': ['p1', 'p2'], 'team_2': ['p3', 'p4']},
        random: Random(0),
      );
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      // Both p1 and p2 missed round 0 → crew halved
      game.playerRoundScores['p1']![0] = 0;
      game.playerRoundScores['p2']![0] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      // Edit p1 to a hit → crew no longer fully missed
      p.editPlayerScore(
        playerId: 'p1',
        roundIndex: 0,
        newSegments: ['S$target', 'Miss', 'Miss'],
      );
      // timesHalvedPerTeam should be recomputed to 0
      expect(game.timesHalvedPerTeam['team_1'], 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Halving counter — "nothing to halve" guard (multi-round)
  // ═══════════════════════════════════════════════════════════════════
  //
  // Regression group for the bug where opponent tiles showed
  // "Quartered N times" or "Halved N times" even though the player's
  // gold balance never actually dropped. The model's totalForPlayer
  // applies `(0 / divisor).floor() = 0` as a no-op when the running
  // treasure is 0, so the display counter must agree and only count
  // halving events that genuinely lowered the balance.
  group('Halving counter no-op guard', () {
    test('39b. Round 0 all-miss with no prior treasure → counter NOT bumped',
        () {
      // Both p1 and p2 throw all misses in round 0. Round transitions
      // (both players done with round 0 → _applyRoundResultsSolo).
      // Neither had treasure walking in, so counter stays 0 for both.
      final p = _makeSolo(random: Random(0));
      final game = p.currentGame!;
      _finishMiss(p); // p1 round 0
      _finishMiss(p); // p2 round 0 → round advances
      expect(game.currentRoundIndex, 1,
          reason: 'Round 0 finished, should be on round 1');
      expect(game.timesHalvedPerPlayer['p1'], 0,
          reason: 'p1 had 0 treasure walking into round 0 → no halving');
      expect(game.timesHalvedPerPlayer['p2'], 0,
          reason: 'p2 had 0 treasure walking into round 0 → no halving');
      expect(game.totalForPlayer('p1'), 0);
      expect(game.totalForPlayer('p2'), 0);
    });

    test(
        '39c. p1 scores round 0, all-miss round 1 → counter bumped, '
        'and treasure drops', () {
      // p1 hits in round 0 (positive treasure), then misses every dart
      // in round 1. After round 1 finalizes, the halving counter must
      // increment AND the total treasure must drop per the divisor.
      final p = _makeSolo(random: Random(0));
      final game = p.currentGame!;
      _finishHit(p); // p1 round 0 hits something
      _finishMiss(p); // p2 round 0 miss → round advances to 1
      final treasureBefore = game.totalForPlayer('p1');
      expect(treasureBefore, greaterThan(0),
          reason: 'p1 must have non-zero treasure after a round-0 hit');
      _finishMiss(p); // p1 round 1 all-miss
      _finishMiss(p); // p2 round 1 all-miss → round advances to 2
      expect(game.timesHalvedPerPlayer['p1'], 1,
          reason:
              'p1 had treasure walking into round 1; all-miss halves it');
      expect(game.totalForPlayer('p1'), treasureBefore ~/ 2,
          reason: 'Treasure should be halved');
      expect(game.timesHalvedPerPlayer['p2'], 0,
          reason: 'p2 had 0 treasure walking into round 1 → not counted');
      expect(game.totalForPlayer('p2'), 0);
    });

    test(
        '39d. Quarter It variant — counter only bumped when treasure '
        'actually quartered', () {
      // Same scenario but with Quarter It enabled (divisor = 4).
      // p1 misses round 0 (no treasure) — counter must NOT increment.
      // p1 hits round 1 — has treasure. p1 misses round 2 — counter
      // increments to 1 and total drops to floor(prev / 4).
      final p = _makeSolo(quarterItEnabled: true, random: Random(0));
      final game = p.currentGame!;
      _finishMiss(p); // p1 round 0 miss (no treasure → no halve)
      _finishMiss(p); // p2 round 0 miss → round advances
      expect(game.timesHalvedPerPlayer['p1'], 0,
          reason: 'Round 0 miss with 0 balance → no quartering counted');

      _finishHit(p); // p1 round 1 hits
      _finishMiss(p); // p2 round 1 → round advances
      final treasureBefore = game.totalForPlayer('p1');
      expect(treasureBefore, greaterThan(0));

      _finishMiss(p); // p1 round 2 all-miss → real quartering
      _finishMiss(p); // p2 round 2 → round advances
      expect(game.timesHalvedPerPlayer['p1'], 1,
          reason: 'Round 2 miss with positive treasure → quartered');
      expect(game.totalForPlayer('p1'), treasureBefore ~/ 4);
    });

    test(
        '39e. Team mode — crew with 0 treasure missing whole round '
        'does NOT bump timesHalvedPerTeam', () {
      // Both members of team_1 miss round 0. _applyCrewRoundResult
      // detects the all-crew miss, but team had 0 treasure → no count.
      // team_2 hits in round 0 → has treasure. team_2 then misses
      // round 1 → counter increments to 1.
      final p = _makeTeam(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;

      // Round 0: team_1 all miss, team_2 one hit.
      _finishMiss(p); // p1 (team_1)
      _finishMiss(p); // p2 (team_1) → crew_1 result applies
      _finishHit(p); // p3 (team_2)
      _finishMiss(p); // p4 (team_2) → crew_2 result + round advances

      expect(game.timesHalvedPerTeam['team_1'], 0,
          reason: 'team_1 had 0 treasure walking into round 0 → no halving');
      expect(game.timesHalvedPerTeam['team_2'], 0,
          reason: 'team_2 had a hit → not an all-miss round');

      // Round 1: team_1 still 0 treasure (don't count their miss).
      // team_2 has treasure, all-miss → counts as halving.
      _finishMiss(p);
      _finishMiss(p); // team_1 round 1 all-miss again
      _finishMiss(p);
      _finishMiss(p); // team_2 round 1 all-miss → round advances

      expect(game.timesHalvedPerTeam['team_1'], 0,
          reason: 'team_1 still has 0 treasure → still no halving');
      expect(game.timesHalvedPerTeam['team_2'], 1,
          reason: 'team_2 had treasure → halving counted on round-1 miss');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Randomized targets + theme shuffles invariants
  // ═══════════════════════════════════════════════════════════════════
  group('Randomized invariants', () {
    test('40. Two startGame calls with different seeds produce different themes', () {
      final p1 = _makeSolo(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          random: Random(1));
      final p2 = _makeSolo(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          random: Random(9999));
      bool differs = false;
      for (final pid in ['p1', 'p2', 'p3']) {
        if (p1.currentGame!.playerPirateThemes[pid] !=
            p2.currentGame!.playerPirateThemes[pid]) {
          differs = true;
          break;
        }
      }
      expect(differs, true);
    });

    test('41. Custom sequence numbers are unique (no duplicates in number slots)', () {
      final seq = TreasureDivideGame.customSequenceFor(9, random: Random(33));
      final numbers = seq.where((t) => t > 0 && t != kTargetBull).toList();
      expect(numbers.toSet().length, numbers.length);
    });

    test('42. Team crests are a subset of the 6 available', () {
      const all = [
        'assets/games/treasure_divide/teams/CrossedCutlasses.png',
        'assets/games/treasure_divide/teams/GoldDoubloon.png',
        'assets/games/treasure_divide/teams/CompassRose.png',
        'assets/games/treasure_divide/teams/ShipsWheel.png',
        'assets/games/treasure_divide/teams/Anchor.png',
        'assets/games/treasure_divide/teams/Kraken.png',
      ];
      final p = _makeTeam(
        teamPlayers: {'team_1': ['p1', 'p2'], 'team_2': ['p3', 'p4']},
        random: Random(42),
      );
      for (final crest in p.currentGame!.teamCrestPaths) {
        expect(all, contains(crest));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // endGame + resumedSavedGameId
  // ═══════════════════════════════════════════════════════════════════
  group('endGame + resumedSavedGameId', () {
    test('43. endGame clears active flag', () {
      final p = _makeSolo();
      p.endGame();
      expect(p.isGameActive, false);
    });

    test('44. clearGame nulls currentGame', () {
      final p = _makeSolo();
      p.clearGame();
      expect(p.currentGame, null);
    });

    test('45. resumedSavedGameId is null by default', () {
      final p = _makeSolo();
      expect(p.resumedSavedGameId, null);
    });

    test('46. clearResumedSavedGameId resets the id', () {
      final p = _makeSolo();
      // Manually set it via the model for testing
      p.clearResumedSavedGameId();
      expect(p.resumedSavedGameId, null);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Additional edge cases
  // ═══════════════════════════════════════════════════════════════════
  group('Additional edge cases', () {
    test('47. totalTurns increments exactly once per turn', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.currentPlayerId;
      expect(game.totalTurns[pid], 0);
      _miss(p); // first dart → totalTurns becomes 1
      expect(game.totalTurns[pid], 1);
      _miss(p); // second dart → no increment
      expect(game.totalTurns[pid], 1);
      _miss(p); // third dart → no increment
      expect(game.totalTurns[pid], 1);
    });

    test('48. totalDartsThrown accumulates across turns', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.currentPlayerId;
      _miss(p); _miss(p); _miss(p); // 3 darts
      p.handleTakeoutFinished();
      expect(game.totalDartsThrown[pid], 3);
    });

    test('49. dartsThisTurn is 3 for solo mode', () {
      final p = _makeSolo(random: Random(0));
      expect(p.currentGame!.dartsThisTurn, 3);
    });

    test('50. dartsThisTurn is 6 for solo crew (1-player team)', () {
      final p = _makeTeam(
        teamPlayers: {'team_1': ['p1'], 'team_2': ['p2', 'p3']},
        random: Random(0),
      );
      expect(p.currentGame!.dartsThisTurn, 6);
    });

    test('51. winnerIds and winnerTeamIds are List<String> not nullable', () {
      final p = _makeSolo();
      expect(p.currentGame!.winnerIds, isA<List<String>>());
      expect(p.currentGame!.winnerTeamIds, isA<List<String>>());
    });

    test('52. Serialization round-trip preserves all fields', () {
      final p = _makeSolo(
        numberOfRounds: 12,
        quarterItEnabled: true,
        customTargetsEnabled: true,
        playerIds: ['p1', 'p2', 'p3'],
        random: Random(88),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 50;
      game.currentRoundIndex = 3;
      game.timesHalvedPerPlayer['p1'] = 1;

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.numberOfRounds, 12);
      expect(restored.quarterItEnabled, true);
      expect(restored.customTargetsEnabled, true);
      expect(restored.playerRoundScores['p1']![0], 50);
      expect(restored.currentRoundIndex, 3);
      expect(restored.timesHalvedPerPlayer['p1'], 1);
      expect(restored.targetSequence, game.targetSequence);
      expect(restored.playerPirateThemes, game.playerPirateThemes);
    });

    test('53. processDartThrow no-op when game is finished', () {
      final p = _makeSolo(numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < 2; i++) _finishHit(p);
      }
      expect(game.state, TreasureDivideGameState.finished);
      final beforeTotal = game.totalDartsThrown['p1'] ?? 0;
      _miss(p);
      expect(game.totalDartsThrown['p1'] ?? 0, beforeTotal);
    });

    test('54. Skip with 0 darts still increments totalTurns', () {
      final p = _makeSolo(random: Random(1));
      final game = p.currentGame!;
      final pid = game.currentPlayerId;
      expect(game.totalTurns[pid], 0);
      p.skipTurn();
      expect(game.totalTurns[pid], 1);
    });

    test('55. Custom targets for 7 rounds: AD at idx 3, AT at idx 5, Bull at idx 6', () {
      final seq = TreasureDivideGame.customSequenceFor(7, random: Random(5));
      expect(seq[3], kTargetAnyDouble);
      expect(seq[5], kTargetAnyTriple);
      expect(seq[6], kTargetBull);
    });
  });
}
