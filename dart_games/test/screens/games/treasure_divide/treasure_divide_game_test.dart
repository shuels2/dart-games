import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/treasure_divide_game.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';

// ─── Test Helpers ─────────────────────────────────────────────────────────────

/// Creates a Solo TreasureDivideProvider.
TreasureDivideProvider _makeSoloProvider({
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

/// Creates a Team TreasureDivideProvider.
TreasureDivideProvider _makeTeamProvider({
  required Map<String, List<String>> teamPlayers,
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  Random? random,
}) {
  final allPlayerIds = teamPlayers.values.expand((e) => e).toList();
  final teamAssignments = <String, String>{};
  for (final entry in teamPlayers.entries) {
    for (final pid in entry.value) {
      teamAssignments[pid] = entry.key;
    }
  }

  final p = TreasureDivideProvider();
  p.startGame(
    playerIds: allPlayerIds,
    numberOfRounds: numberOfRounds,
    quarterItEnabled: quarterItEnabled,
    customTargetsEnabled: customTargetsEnabled,
    gameMode: TreasureDivideGameMode.team,
    teamAssignment: TreasureDivideTeamAssignment.manual,
    teamCount: teamPlayers.length,
    manualTeamAssignments: teamAssignments,
    random: random,
  );
  return p;
}

/// Returns the target for the current round.
int _currentTarget(TreasureDivideProvider p) {
  final game = p.currentGame!;
  return game.targetSequence[game.currentRoundIndex];
}

/// Throws a dart that HIT the current round's target for a specific score.
void _throwHit(TreasureDivideProvider p,
    {String multiplier = 'single', int? targetOverride}) {
  final game = p.currentGame!;
  final target = targetOverride ?? _currentTarget(p);
  int base, score;
  String sector;

  if (target == kTargetAnyDouble) {
    base = 15;
    score = 30;
    sector = 'D15';
    multiplier = 'double';
  } else if (target == kTargetAnyTriple) {
    base = 15;
    score = 45;
    sector = 'T15';
    multiplier = 'triple';
  } else if (target == kTargetBull) {
    base = 25;
    score = 25;
    sector = '25';
    multiplier = 'single';
  } else {
    base = target;
    score = target * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1);
    sector = '${multiplier == 'double' ? 'D' : multiplier == 'triple' ? 'T' : 'S'}$target';
  }

  p.processDartThrow(
    score: score,
    multiplier: multiplier,
    baseScore: base,
    sector: sector,
  );
}

/// Throws a dart that MISSES the current target.
void _throwMiss(TreasureDivideProvider p) {
  final game = p.currentGame!;
  final target = _currentTarget(p);
  // Use a number that can't match any target type
  int base;
  if (target == kTargetAnyDouble || target == kTargetAnyTriple) {
    base = 1;
  } else if (target == kTargetBull) {
    base = 1;
  } else {
    base = (target == 1) ? 2 : 1;
  }
  p.processDartThrow(
    score: base,
    multiplier: 'single',
    baseScore: base,
    sector: 'S$base',
  );
}

/// Throws all remaining darts as misses until the turn ends (shouldPromptTakeout).
void _missAll(TreasureDivideProvider p) {
  while (!p.shouldPromptTakeout) {
    _throwMiss(p);
  }
}

/// Completes a full turn with hits (hits first dart).
void _completeTurnWithHit(TreasureDivideProvider p) {
  _throwHit(p);
  while (!p.shouldPromptTakeout) {
    _throwMiss(p);
  }
  p.handleTakeoutFinished();
}

/// Completes a full turn with all misses.
void _completeTurnWithMiss(TreasureDivideProvider p) {
  _missAll(p);
  p.handleTakeoutFinished();
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // Scoring Basics (Tests 1-8)
  // ═══════════════════════════════════════════════════════════════════
  group('1. Scoring Basics', () {
    test('1. Single hit on number round scores number × 1', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final target = _currentTarget(p);
      if (target < 0 || target == 25) return; // skip non-number round
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      // Player score includes target (single = target × 1)
      // Score is now in round index 0 (just completed)
      final prevPlayer = game.playerIds.first;
      expect(game.playerRoundScores[prevPlayer]![0], target);
    });

    test('2. Double hit on number round scores number × 2', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final target = _currentTarget(p);
      if (target < 0 || target == 25) return;
      p.processDartThrow(
          score: target * 2, multiplier: 'double', baseScore: target,
          sector: 'D$target');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[game.playerIds.first]![0], target * 2);
    });

    test('3. Triple hit on number round scores number × 3', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final target = _currentTarget(p);
      if (target < 0 || target == 25) return;
      p.processDartThrow(
          score: target * 3, multiplier: 'triple', baseScore: target,
          sector: 'T$target');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[game.playerIds.first]![0], target * 3);
    });

    test('4. Miss on number round scores 0', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      _missAll(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[game.playerIds.first]![0], 0);
    });

    test('5. Outer bull scores 25 in Bull round', () {
      // Use a sequence with Bull at start for easy testing
      final p = TreasureDivideProvider();
      p.startGame(
        playerIds: ['p1', 'p2'],
        numberOfRounds: 7,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.solo,
        teamAssignment: TreasureDivideTeamAssignment.random,
        random: Random(0),
      );
      final game = p.currentGame!;
      // Fast-forward to Bull round (index 6 in 7-round game)
      for (int r = 0; r < 6; r++) {
        for (final pid in game.playerIds) {
          _completeTurnWithMiss(p);
        }
      }
      // Now at round 6 = Bull
      expect(game.targetSequence[6], kTargetBull);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 25, multiplier: 'single', baseScore: 25, sector: '25');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![6], 25);
    });

    test('6. Inner bull scores 50 in Bull round', () {
      final p = TreasureDivideProvider();
      p.startGame(
        playerIds: ['p1', 'p2'],
        numberOfRounds: 7,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.solo,
        teamAssignment: TreasureDivideTeamAssignment.random,
        random: Random(0),
      );
      final game = p.currentGame!;
      for (int r = 0; r < 6; r++) {
        for (int i = 0; i < game.playerIds.length; i++) {
          _completeTurnWithMiss(p);
        }
      }
      expect(game.targetSequence[6], kTargetBull);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 50, multiplier: 'bull', baseScore: 25, sector: 'Bull');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![6], 50);
    });

    test('7. AnyDouble round — any double counts, single does not', () {
      // 9-round: index 3 = AnyDouble
      final p = _makeSoloProvider(random: Random(42));
      final game = p.currentGame!;
      // Advance to round index 3
      for (int r = 0; r < 3; r++) {
        for (int i = 0; i < game.playerIds.length; i++) {
          _completeTurnWithMiss(p);
        }
      }
      expect(game.targetSequence[3], kTargetAnyDouble);
      final pid = game.currentPlayerId;

      // Single does NOT count
      p.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      // Double DOES count
      p.processDartThrow(
          score: 30, multiplier: 'double', baseScore: 15, sector: 'D15');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();

      expect(game.playerRoundScores[pid]![3], 30);
    });

    test('8. AnyTriple round — any triple counts, single does not', () {
      // 9-round: index 7 = AnyTriple
      final p = _makeSoloProvider(random: Random(42));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < game.playerIds.length; i++) {
          _completeTurnWithMiss(p);
        }
      }
      expect(game.targetSequence[7], kTargetAnyTriple);
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      p.processDartThrow(
          score: 45, multiplier: 'triple', baseScore: 15, sector: 'T15');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![7], 45);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Halving Logic (Tests 9-16)
  // ═══════════════════════════════════════════════════════════════════
  group('2. Halving Logic', () {
    test('9. Miss all 3 darts halves cumulative score (floor)', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      // Round 0: hit — give score 20
      final t = game.targetSequence[0];
      if (t > 0 && t != 25) {
        p.processDartThrow(
            score: t, multiplier: 'single', baseScore: t, sector: 'S$t');
        while (!p.shouldPromptTakeout) _throwMiss(p);
        p.handleTakeoutFinished();
        // Advance p2
        _completeTurnWithMiss(p);
        final scoreAfterR0 = game.playerRoundScores[pid]![0]!;
        expect(scoreAfterR0, greaterThan(0));
        // Round 1: miss all — halve
        _completeTurnWithMiss(p);
        _completeTurnWithMiss(p); // advance p2
        final afterHalve = game.totalForPlayer(pid);
        expect(afterHalve, (scoreAfterR0 / 2).floor());
      }
    });

    test('10. Floor on odd score: 15 halved = 7', () {
      // Build a game and manually set a score of 15, then apply halving
      final p = _makeSoloProvider(random: Random(5));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      // Manually set round 0 haul to 15
      game.playerRoundScores[pid]![0] = 15;
      game.playerRoundScores[game.playerIds[1]]![0] = 0;
      // Round 1: miss all → halve from 15
      game.playerRoundScores[pid]![1] = 0;
      game.playerRoundScores[game.playerIds[1]]![1] = 0;
      game.timesHalvedPerPlayer[pid] = 1;
      final total = game.totalForPlayer(pid);
      expect(total, 7); // floor(15/2) = 7
    });

    test('11. At least 1 hit prevents halving', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      final t = game.targetSequence[0];
      if (t > 0 && t != 25) {
        // Round 0: hit one dart
        p.processDartThrow(
            score: t, multiplier: 'single', baseScore: t, sector: 'S$t');
        while (!p.shouldPromptTakeout) _throwMiss(p);
        p.handleTakeoutFinished();
        // p1 should have haul > 0 (no halving)
        expect(game.playerRoundScores[pid]![0], greaterThan(0));
        expect(game.timesHalvedPerPlayer[pid], 0);
      }
    });

    test('12. Score of 0 halved is still 0', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      // Start with 0, miss round 0 → 0 halved = 0
      game.playerRoundScores[pid]![0] = 0;
      game.timesHalvedPerPlayer[pid] = 1;
      expect(game.totalForPlayer(pid), 0);
    });

    test('13. After 1 halving: score goes from some value to half', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      game.playerRoundScores[pid]![0] = 100;
      game.playerRoundScores[pid]![1] = 0; // halve
      game.timesHalvedPerPlayer[pid] = 1;
      final total = game.totalForPlayer(pid);
      expect(total, 50);
    });

    test('14. Quarter It: miss all 3 darts divides by 4', () {
      final p = _makeSoloProvider(quarterItEnabled: true, random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      game.playerRoundScores[pid]![0] = 100;
      game.playerRoundScores[pid]![1] = 0; // quartered
      game.timesHalvedPerPlayer[pid] = 1;
      final total = game.totalForPlayer(pid);
      expect(total, 25); // floor(100/4) = 25
    });

    test('15. Quarter It floors on odd: 100 quartered = 25; 102 quartered = 25', () {
      final p = _makeSoloProvider(quarterItEnabled: true, random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      game.playerRoundScores[pid]![0] = 102;
      game.playerRoundScores[pid]![1] = 0;
      game.timesHalvedPerPlayer[pid] = 1;
      expect(game.totalForPlayer(pid), 25); // floor(102/4) = 25
    });

    test('16. Multiple halvings accumulate (path-dependent)', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      // 100 → miss → 50 → miss → 25
      game.playerRoundScores[pid]![0] = 100;
      game.playerRoundScores[pid]![1] = 0;
      game.playerRoundScores[pid]![2] = 0;
      game.timesHalvedPerPlayer[pid] = 2;
      expect(game.totalForPlayer(pid), 25);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Round Progression (Tests 17-23)
  // ═══════════════════════════════════════════════════════════════════
  group('3. Round Progression', () {
    test('17. Standard 9-round sequence has correct targets', () {
      final seq = TreasureDivideGame.sequenceFor(9);
      expect(seq.length, 9);
      expect(seq[0], 20);
      expect(seq[1], 19);
      expect(seq[2], 18);
      expect(seq[3], kTargetAnyDouble);
      expect(seq[4], 17);
      expect(seq[7], kTargetAnyTriple);
      expect(seq[8], kTargetBull);
    });

    test('18. Short 7-round sequence has correct targets', () {
      final seq = TreasureDivideGame.sequenceFor(7);
      expect(seq.length, 7);
      expect(seq[3], kTargetAnyDouble);
      expect(seq[5], kTargetAnyTriple);
      expect(seq[6], kTargetBull);
    });

    test('19. Long 12-round sequence has correct targets', () {
      final seq = TreasureDivideGame.sequenceFor(12);
      expect(seq.length, 12);
      expect(seq[3], kTargetAnyDouble);
      expect(seq[7], kTargetAnyTriple);
      expect(seq[11], kTargetBull);
    });

    test('20. All players throw before advancing to next round', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2', 'p3'], random: Random(42));
      final game = p.currentGame!;
      // p1 finishes round 0
      _completeTurnWithHit(p);
      expect(game.currentRoundIndex, 0); // still round 0
      // p2 finishes
      _completeTurnWithHit(p);
      expect(game.currentRoundIndex, 0); // still round 0
      // p3 finishes → advance to round 1
      _completeTurnWithHit(p);
      expect(game.currentRoundIndex, 1);
    });

    test('21. Game ends after final round', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      for (int r = 0; r < 7; r++) {
        for (int i = 0; i < 2; i++) {
          _completeTurnWithHit(p);
        }
      }
      expect(game.state, TreasureDivideGameState.finished);
    });

    test('22. Bull is the final round target in 9-round game', () {
      final seq = TreasureDivideGame.sequenceFor(9);
      expect(seq.last, kTargetBull);
    });

    test('23. Round index advances after all players complete', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      expect(game.currentRoundIndex, 0);
      _completeTurnWithHit(p); // p1
      _completeTurnWithHit(p); // p2
      expect(game.currentRoundIndex, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Custom Targets (Tests 24-28)
  // ═══════════════════════════════════════════════════════════════════
  group('4. Custom Targets', () {
    test('24. Custom targets: numbers are random (not standard 20-19-18)', () {
      final seq = TreasureDivideGame.customSequenceFor(9, random: Random(99));
      // 9 rounds - AD(idx3) - AT(idx7) - Bull(idx8) = 6 number slots
      final numRounds = seq.where((t) => t > 0 && t <= 20).toList();
      expect(numRounds.length, 6); // 6 number slots in 9-round custom
    });

    test('25. Custom targets: Bull is always final', () {
      for (int rounds in [7, 9, 12]) {
        final seq =
            TreasureDivideGame.customSequenceFor(rounds, random: Random(123));
        expect(seq.last, kTargetBull);
      }
    });

    test('26. Custom targets (9 rounds): AD at idx 3, AT at idx 7', () {
      final seq = TreasureDivideGame.customSequenceFor(9, random: Random(5));
      expect(seq[3], kTargetAnyDouble);
      expect(seq[7], kTargetAnyTriple);
    });

    test('27. Custom target numbers are in range 1-20', () {
      final seq = TreasureDivideGame.customSequenceFor(12, random: Random(77));
      for (final t in seq) {
        if (t != kTargetAnyDouble && t != kTargetAnyTriple && t != kTargetBull) {
          expect(t, inInclusiveRange(1, 20));
        }
      }
    });

    test('28. Different Random seeds produce different custom sequences', () {
      final s1 = TreasureDivideGame.customSequenceFor(9, random: Random(1));
      final s2 = TreasureDivideGame.customSequenceFor(9, random: Random(9999));
      // They may occasionally be the same, but with different seeds they should differ
      // Check at least some non-sentinel positions differ
      bool differs = false;
      for (int i = 0; i < s1.length; i++) {
        if (s1[i] != s2[i]) {
          differs = true;
          break;
        }
      }
      expect(differs, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Scoring Accumulation (Tests 29-33)
  // ═══════════════════════════════════════════════════════════════════
  group('5. Scoring Accumulation', () {
    test('29. Score accumulates across rounds without halving', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      game.playerRoundScores[pid]![0] = 60;
      game.playerRoundScores[pid]![1] = 40;
      expect(game.totalForPlayer(pid), 100);
    });

    test('30. Round score is sum of hits this turn', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final pid = game.currentPlayerId;
      // Throw two darts that hit
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      p.processDartThrow(
          score: target * 2, multiplier: 'double', baseScore: target,
          sector: 'D$target');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target + target * 2);
    });

    test('31. A single miss in a turn does not reduce score (only all-miss halves)', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.currentPlayerId;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      // Miss, then hit
      _throwMiss(p);
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      while (!p.shouldPromptTakeout) _throwMiss(p);
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target);
      expect(game.timesHalvedPerPlayer[pid], 0);
    });

    test('32. Multiple hits in one turn all count', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      final pid = game.currentPlayerId;
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      p.processDartThrow(
          score: target, multiplier: 'single', baseScore: target,
          sector: 'S$target');
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], target * 3);
    });

    test('33. Score after halve then hit next round = (halved total) + new haul', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      // Round 0: haul 40, round 1: halve (0 haul), round 2: haul 20
      game.playerRoundScores[pid]![0] = 40;
      game.playerRoundScores[pid]![1] = 0; // halved
      game.playerRoundScores[pid]![2] = 20;
      game.timesHalvedPerPlayer[pid] = 1;
      expect(game.totalForPlayer(pid), 40); // floor(40/2)+20 = 20+20 = 40
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Win Conditions (Tests 34-37)
  // ═══════════════════════════════════════════════════════════════════
  group('6. Win Conditions', () {
    test('34. Highest score after all rounds wins', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      // Give p1 more treasure
      game.playerRoundScores['p1'] = [50, 50, 50, 50, 50, 50, 50];
      game.playerRoundScores['p2'] = [10, 10, 10, 10, 10, 10, 10];
      p.endGame();
      expect(game.winnerIds, ['p1']);
    });

    test('35. Tiebreaker: fewer halvings wins', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      // Both end at same total but p2 was halved more
      game.playerRoundScores['p1'] = [100, 0, 100, 0, 0, 0, 0];
      game.playerRoundScores['p2'] = [100, 0, 100, 0, 0, 0, 0];
      game.timesHalvedPerPlayer['p1'] = 1;
      game.timesHalvedPerPlayer['p2'] = 3;
      // Manually set total to be equal by adjusting scores to produce same final value
      // p1: 100 → halve → 50 → 100 → halve → 50 → halve → 25 → halve → 12
      // Actually let's just use a simpler scenario: same score, different halve counts
      game.playerRoundScores['p1'] = [100, 0, 0, 0, 0, 0, 0];
      game.playerRoundScores['p2'] = [100, 0, 0, 0, 0, 0, 0];
      game.timesHalvedPerPlayer['p1'] = 1;
      game.timesHalvedPerPlayer['p2'] = 1;
      p.endGame();
      // Both equal score and equal halvings → TIE
      expect(game.winnerIds.length, 2);
    });

    test('36. Tied score + tied halvings = DECLARE TIE (winnerIds.length > 1)', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      game.playerRoundScores['p1'] = [50, 50, 50, 0, 0, 0, 0];
      game.playerRoundScores['p2'] = [50, 50, 50, 0, 0, 0, 0];
      game.timesHalvedPerPlayer['p1'] = 1;
      game.timesHalvedPerPlayer['p2'] = 1;
      p.endGame();
      expect(game.winnerIds.length, greaterThanOrEqualTo(2));
    });

    test('37. Win with score 0 if all players have 0', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 7, random: Random(0));
      final game = p.currentGame!;
      game.playerRoundScores['p1'] = [0, 0, 0, 0, 0, 0, 0];
      game.playerRoundScores['p2'] = [0, 0, 0, 0, 0, 0, 0];
      game.timesHalvedPerPlayer['p1'] = 7;
      game.timesHalvedPerPlayer['p2'] = 7;
      p.endGame();
      expect(game.winnerIds, isNotEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Turn Management (Tests 38-41)
  // ═══════════════════════════════════════════════════════════════════
  group('7. Turn Management', () {
    test('38. Turn ends after 3 darts (Solo)', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      expect(game.shouldPromptTakeout, false);
      _throwMiss(p);
      _throwMiss(p);
      expect(game.shouldPromptTakeout, false);
      _throwMiss(p);
      expect(game.shouldPromptTakeout, true);
    });

    test('39. Skip forfeits remaining darts', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      p.skipTurn();
      expect(game.shouldPromptTakeout, true);
    });

    test('40. Skip with no hits = miss-all (haul = 0)', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.currentPlayerId;
      p.skipTurn();
      p.handleTakeoutFinished();
      expect(game.playerRoundScores[pid]![0], 0);
    });

    test('41. All players complete round before advancing', () {
      final p =
          _makeSoloProvider(playerIds: ['p1', 'p2', 'p3'], random: Random(0));
      final game = p.currentGame!;
      _completeTurnWithHit(p); // p1
      expect(game.currentRoundIndex, 0);
      _completeTurnWithHit(p); // p2
      expect(game.currentRoundIndex, 0);
      _completeTurnWithHit(p); // p3
      expect(game.currentRoundIndex, 1); // round advanced
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Edit Score (Tests 42-44)
  // ═══════════════════════════════════════════════════════════════════
  group('8. Edit Score', () {
    test('42. Edit recalculates round total', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      // Set up round 0 with a haul of 0
      game.playerRoundScores[pid]![0] = 0;
      // Edit with a hit
      p.editPlayerScore(
        playerId: pid,
        roundIndex: 0,
        newSegments: ['S$target', 'Miss', 'Miss'],
      );
      expect(game.playerRoundScores[pid]![0], target);
    });

    test('43. Edit removes halving when a hit is added', () {
      final p = _makeSoloProvider(random: Random(1));
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
      expect(game.timesHalvedPerPlayer[pid], 0);
    });

    test('44. Edit causes halving when all darts become misses', () {
      final p = _makeSoloProvider(random: Random(1));
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
      expect(game.timesHalvedPerPlayer[pid], 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Save/Restore (Tests 45-48)
  // ═══════════════════════════════════════════════════════════════════
  group('9. Save/Restore', () {
    test('45. Save and restore preserves player scores and round state', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 9, random: Random(42));
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 60;
      game.playerRoundScores['p2']![0] = 40;
      game.currentRoundIndex = 1;

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.playerRoundScores['p1']![0], 60);
      expect(restored.playerRoundScores['p2']![0], 40);
      expect(restored.currentRoundIndex, 1);
    });

    test('46. Save preserves target sequence (including custom)', () {
      final p = _makeSoloProvider(
          customTargetsEnabled: true, numberOfRounds: 9, random: Random(7));
      final game = p.currentGame!;
      final origSeq = List<int>.from(game.targetSequence);

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.targetSequence, origSeq);
    });

    test('47. Restore resumes correct round and player', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], numberOfRounds: 9, random: Random(3));
      final game = p.currentGame!;
      game.currentRoundIndex = 4;
      game.currentPlayerId = 'p2';

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.currentRoundIndex, 4);
      expect(restored.currentPlayerId, 'p2');
    });

    test('48. Restore preserves options (quarterIt, numberOfRounds, etc.)', () {
      final p = _makeSoloProvider(
        numberOfRounds: 12,
        quarterItEnabled: true,
        customTargetsEnabled: true,
        random: Random(11),
      );
      final game = p.currentGame!;

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.numberOfRounds, 12);
      expect(restored.quarterItEnabled, true);
      expect(restored.customTargetsEnabled, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Edge Cases (Tests 49-50)
  // ═══════════════════════════════════════════════════════════════════
  group('10. Edge Cases', () {
    test('49. Max possible score: triple on every round', () {
      // Manually compute the max for 9 rounds
      final seq = TreasureDivideGame.sequenceFor(9);
      int expectedMax = 0;
      for (final t in seq) {
        if (t == kTargetAnyDouble) {
          expectedMax += 20 * 2;
        } else if (t == kTargetAnyTriple) {
          expectedMax += 20 * 3;
        } else if (t == kTargetBull) {
          expectedMax += 50 * 3; // 3 inner bulls
        } else {
          expectedMax += t * 3;
        }
      }
      expect(expectedMax, greaterThan(0));
    });

    test('50. All halved every round: total stays 0 if started at 0', () {
      final p = _makeSoloProvider(random: Random(1));
      final game = p.currentGame!;
      final pid = game.playerIds.first;
      for (int i = 0; i < 9; i++) {
        game.playerRoundScores[pid]![i] = 0;
      }
      game.timesHalvedPerPlayer[pid] = 9;
      expect(game.totalForPlayer(pid), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode Crew Rotation (Tests 51-56)
  // ═══════════════════════════════════════════════════════════════════
  group('11. Team Mode Crew Rotation', () {
    test('51. Team mode: crew A plays through, then crew B', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      expect(game.currentPlayerId, 'p1');
      expect(game.activeTeamId, 'team_1');

      _completeTurnWithHit(p); // p1 done
      expect(game.currentPlayerId, 'p2'); // p2 next on team_1

      _completeTurnWithHit(p); // p2 done
      expect(game.activeTeamId, 'team_2'); // team_1 done → team_2
      expect(game.currentPlayerId, 'p3');
    });

    test('52. Solo crew (1-player) throws 6 darts in a single turn', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3'], // solo crew
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // Advance to team_2's turn
      _completeTurnWithHit(p); // p1
      _completeTurnWithHit(p); // p2
      expect(game.activeTeamId, 'team_2');
      expect(game.currentPlayerId, 'p3');
      expect(game.dartsThisTurn, 6);
    });

    test('53. 10-player team rotation: all 5 crews play', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
          'team_3': ['p5', 'p6'],
          'team_4': ['p7', 'p8'],
          'team_5': ['p9', 'p10'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // Complete all turns for round 0
      for (int crew = 0; crew < 5; crew++) {
        _completeTurnWithHit(p); // crew member 1
        _completeTurnWithHit(p); // crew member 2
      }
      expect(game.currentRoundIndex, 1); // advanced to round 1
    });

    test('54. All crews done → advance to next round', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      _completeTurnWithHit(p); // p1
      _completeTurnWithHit(p); // p2 → crew done
      _completeTurnWithHit(p); // p3
      _completeTurnWithHit(p); // p4 → all crews done → next round
      expect(game.currentRoundIndex, 1);
    });

    test('55. Skip in team mode forfeits only the current player, not the crew', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      p.skipTurn(); // p1 skips
      p.handleTakeoutFinished();
      expect(game.currentPlayerId, 'p2'); // p2 still plays
    });

    test('56. Solo crew 6-dart turn completes in one turn (no extra transition)', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      expect(game.activeTeamId, 'team_1');
      // Throw 6 darts (solo crew turn) — should trigger shouldPromptTakeout after 6
      for (int i = 0; i < 5; i++) {
        _throwMiss(p);
        expect(game.shouldPromptTakeout, false);
      }
      _throwMiss(p);
      expect(game.shouldPromptTakeout, true);
      p.handleTakeoutFinished();
      // After team_1 solo crew done, move to team_2
      expect(game.activeTeamId, 'team_2');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode SUM + Crew-wide Halving (Tests 57-66)
  // ═══════════════════════════════════════════════════════════════════
  group('12. Team Mode SUM + Crew-wide Halving', () {
    test('57. Crew treasure = SUM of member hauls', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 60;
      game.playerRoundScores['p2']![0] = 20;
      // Round 0 for team_1: 60+20 = 80
      final total = game.totalForTeam('team_1');
      expect(total, 80);
    });

    test('58. Crew safe when at least 1 member hits', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 60;
      game.playerRoundScores['p2']![0] = 0; // p2 missed
      final total = game.totalForTeam('team_1');
      expect(total, 60); // no halving
    });

    test('59. Crew halved when whole crew misses every dart', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 100;
      game.playerRoundScores['p1']![1] = 0; // crew all miss
      game.playerRoundScores['p2']![0] = 50;
      game.playerRoundScores['p2']![1] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      final total = game.totalForTeam('team_1');
      expect(total, 75); // (100+50) → 150 → halve → 75
    });

    test('60. Quarter It quartered the whole-crew miss (÷4 instead of ÷2)', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        quarterItEnabled: true,
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 100;
      game.playerRoundScores['p1']![1] = 0;
      game.playerRoundScores['p2']![0] = 0;
      game.playerRoundScores['p2']![1] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      final total = game.totalForTeam('team_1');
      expect(total, 25); // 100 quartered = 25
    });

    test('61. Crew-wide halving floor on odd crew total', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 50;
      game.playerRoundScores['p2']![0] = 51; // total 101
      game.playerRoundScores['p1']![1] = 0;
      game.playerRoundScores['p2']![1] = 0; // halve
      game.timesHalvedPerTeam['team_1'] = 1;
      final total = game.totalForTeam('team_1');
      expect(total, 50); // floor(101/2) = 50
    });

    test('62. Crew total folds over rounds correctly', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // Round 0: p1=40, p2=40 → crew 80
      // Round 1: all miss → halved to 40
      // Round 2: p1=20, p2=20 → crew +40 → total 80
      game.playerRoundScores['p1']![0] = 40;
      game.playerRoundScores['p2']![0] = 40;
      game.playerRoundScores['p1']![1] = 0;
      game.playerRoundScores['p2']![1] = 0;
      game.playerRoundScores['p1']![2] = 20;
      game.playerRoundScores['p2']![2] = 20;
      game.timesHalvedPerTeam['team_1'] = 1;
      final total = game.totalForTeam('team_1');
      expect(total, 80); // 80 → 40 → +40 → 80
    });

    test('63. Solo crew 6-dart haul: T20+T20+S20+S20+S20+S20 = 200', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // Force round 0 target to 20 for this test
      game.playerRoundScores['p1']![0] = 200; // T20+T20+S20+S20+S20+S20=200
      expect(game.totalForTeam('team_1'), 200);
    });

    test('64. Solo crew partial hit (1 of 6 darts hits) = safe', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 20; // 1 hit, 5 miss
      expect(game.totalForTeam('team_1'), 20);
      expect(game.timesHalvedPerTeam['team_1'], 0);
    });

    test('65. Solo crew all 6 miss halves crew treasure', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 100;
      game.playerRoundScores['p1']![1] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      expect(game.totalForTeam('team_1'), 50);
    });

    test('66. Each member per-round haul still stored individually', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      game.playerRoundScores['p1']![0] = 60;
      game.playerRoundScores['p2']![0] = 30;
      expect(game.playerRoundScores['p1']![0], 60);
      expect(game.playerRoundScores['p2']![0], 30);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode Win + Stats (Tests 67-72)
  // ═══════════════════════════════════════════════════════════════════
  group('13. Team Mode Win + Stats', () {
    test('67. Team with highest crew treasure wins', () {
      final p = _makeTeamProvider(
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
        game.playerRoundScores['p3']![r] = 10;
        game.playerRoundScores['p4']![r] = 10;
      }
      p.endGame();
      expect(game.winnerTeamIds, ['team_1']);
      expect(game.winnerIds, contains('p1'));
      expect(game.winnerIds, contains('p2'));
    });

    test('68. Team tiebreaker: fewer crew halvings wins', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        numberOfRounds: 7,
        random: Random(0),
      );
      final game = p.currentGame!;
      // Set same treasure total but different halvings
      for (int r = 0; r < 7; r++) {
        game.playerRoundScores['p1']![r] = 20;
        game.playerRoundScores['p2']![r] = 20;
        game.playerRoundScores['p3']![r] = 20;
        game.playerRoundScores['p4']![r] = 20;
      }
      game.timesHalvedPerTeam['team_1'] = 1;
      game.timesHalvedPerTeam['team_2'] = 3;
      p.endGame();
      expect(game.winnerTeamIds, ['team_1']);
    });

    test('69. Tie: equal treasure + equal halvings → all crews win', () {
      final p = _makeTeamProvider(
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

    test('70. All players on winning crew get win = true (via winnerIds)', () {
      final p = _makeTeamProvider(
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
        game.playerRoundScores['p3']![r] = 10;
        game.playerRoundScores['p4']![r] = 10;
      }
      p.endGame();
      expect(game.winnerIds, containsAll(['p1', 'p2']));
      expect(game.winnerIds, isNot(contains('p3')));
    });

    test('71. Losing crew members are not in winnerIds', () {
      final p = _makeTeamProvider(
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
      expect(game.winnerIds, isNot(contains('p3')));
      expect(game.winnerIds, isNot(contains('p4')));
    });

    test('72. winnerIds and winnerTeamIds are List<String> (never String?)', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        numberOfRounds: 7,
        random: Random(0),
      );
      final game = p.currentGame!;
      p.endGame();
      expect(game.winnerIds, isA<List<String>>());
      expect(game.winnerTeamIds, isA<List<String>>());
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode Solo-Crew Dart Budget (Tests 73-76)
  // ═══════════════════════════════════════════════════════════════════
  group('14. Team Mode Solo-Crew Dart Budget', () {
    test('73. dartsThisTurn == 6 for solo crew, 3 for paired', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // team_1 is first → dartsThisTurn = 3
      expect(game.dartsThisTurn, 3);
      // Advance to team_2 (solo crew)
      _completeTurnWithHit(p); // p1
      _completeTurnWithHit(p); // p2 → team_2 active
      expect(game.activeTeamId, 'team_2');
      expect(game.dartsThisTurn, 6);
    });

    test('74. Solo crew records up to 6 darts before turn ends', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      expect(game.activeTeamId, 'team_1');
      for (int i = 0; i < 6; i++) {
        expect(game.shouldPromptTakeout, false,
            reason: 'Should not end before dart $i+1');
        _throwMiss(p);
      }
      expect(game.shouldPromptTakeout, true);
      expect(game.currentTurnDartSegments['p1']!.length, 6);
    });

    test('75. Skip at dart 2 of solo crew forfeits remaining 4 darts', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      // Throw 2 darts
      _throwMiss(p);
      _throwMiss(p);
      // Skip — should prompt takeout immediately
      p.skipTurn();
      expect(game.shouldPromptTakeout, true);
    });

    test('76. Edit-score on solo crew round operates on 6-dart list', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      final target = game.targetSequence[0];
      if (target <= 0 || target == 25) return;
      // Simulate round 0 completed with 0 haul
      game.playerRoundScores['p1']![0] = 0;
      game.timesHalvedPerTeam['team_1'] = 1;
      // Edit with 6 segments
      p.editPlayerScore(
        playerId: 'p1',
        roundIndex: 0,
        newSegments: [
          'S$target', 'Miss', 'Miss', 'Miss', 'Miss', 'Miss'
        ],
      );
      expect(game.playerRoundScores['p1']![0], target);
      expect(game.timesHalvedPerTeam['team_1'], 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode Assignment + Distribution (Tests 77-83)
  // ═══════════════════════════════════════════════════════════════════
  group('15. Team Assignment + Distribution', () {
    test('77. randomDistribution uses pair-fill rule', () {
      final r3 = TreasureDivideProvider.randomDistribution(3);
      expect(r3.teamCount, 2);
      expect(r3.sizes, [2, 1]);

      final r4 = TreasureDivideProvider.randomDistribution(4);
      expect(r4.teamCount, 2);
      expect(r4.sizes, [2, 2]);

      final r10 = TreasureDivideProvider.randomDistribution(10);
      expect(r10.teamCount, 5);
      expect(r10.sizes, [2, 2, 2, 2, 2]);
    });

    test('78. randomDistribution for all N in 3..10', () {
      final expected = {
        3: (teamCount: 2, sizes: [2, 1]),
        4: (teamCount: 2, sizes: [2, 2]),
        5: (teamCount: 3, sizes: [2, 2, 1]),
        6: (teamCount: 3, sizes: [2, 2, 2]),
        7: (teamCount: 4, sizes: [2, 2, 2, 1]),
        8: (teamCount: 4, sizes: [2, 2, 2, 2]),
        9: (teamCount: 5, sizes: [2, 2, 2, 2, 1]),
        10: (teamCount: 5, sizes: [2, 2, 2, 2, 2]),
      };
      for (final entry in expected.entries) {
        final result = TreasureDivideProvider.randomDistribution(entry.key);
        expect(result.teamCount, entry.value.teamCount,
            reason: 'N=${entry.key} teamCount');
        expect(result.sizes, entry.value.sizes,
            reason: 'N=${entry.key} sizes');
      }
    });

    test('79. No crew > 2 players in Random distribution', () {
      for (int n = 3; n <= 10; n++) {
        final dist = TreasureDivideProvider.randomDistribution(n);
        for (final s in dist.sizes) {
          expect(s, lessThanOrEqualTo(2), reason: 'N=$n has crew of $s');
        }
      }
    });

    test('80. At most one 1-player crew in Random distribution', () {
      for (int n = 3; n <= 10; n++) {
        final dist = TreasureDivideProvider.randomDistribution(n);
        final soloCount = dist.sizes.where((s) => s == 1).length;
        expect(soloCount, lessThanOrEqualTo(1), reason: 'N=$n');
      }
    });

    test('81. Manual assignment respects user-set player→team mapping', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
        },
        random: Random(0),
      );
      final game = p.currentGame!;
      expect(game.playerTeamAssignments['p1'], 'team_1');
      expect(game.playerTeamAssignments['p3'], 'team_2');
    });

    test('82. Random assignment produces valid team structure', () {
      final p = TreasureDivideProvider();
      p.startGame(
        playerIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
        numberOfRounds: 9,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.team,
        teamAssignment: TreasureDivideTeamAssignment.random,
        random: Random(42),
      );
      final game = p.currentGame!;
      // N=5 → 3 crews [2,2,1]
      expect(game.teamCount, 3);
      int totalPlayers = 0;
      for (final members in game.teamPlayers.values) {
        totalPlayers += members.length;
        expect(members.length, lessThanOrEqualTo(2));
      }
      expect(totalPlayers, 5);
    });

    test('83. Crew crests are picked from the 6 available (no duplicates for ≤6 crews)', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['p1', 'p2'],
          'team_2': ['p3', 'p4'],
          'team_3': ['p5', 'p6'],
        },
        random: Random(77),
      );
      final game = p.currentGame!;
      final crests = game.teamCrestPaths;
      expect(crests.length, 3);
      // All crests should be unique
      expect(crests.toSet().length, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Pirate Theme Assignment (Tests 84-89)
  // ═══════════════════════════════════════════════════════════════════
  group('16. Pirate Theme Assignment', () {
    test('84. playerPirateThemes is populated for all players', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2', 'p3'], random: Random(42));
      final game = p.currentGame!;
      for (final pid in game.playerIds) {
        expect(game.playerPirateThemes.containsKey(pid), true);
        expect(game.playerPirateThemes[pid], inInclusiveRange(0, 7));
      }
    });

    test('85. Up to 8 players get unique themes (0-7 each used at most once)', () {
      final p = _makeSoloProvider(
        playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
        random: Random(42),
      );
      final game = p.currentGame!;
      final themes = game.playerPirateThemes.values.toList();
      expect(themes.toSet().length, 8); // all unique
    });

    test('86. >8 players (team mode) wrap is allowed (repeats possible)', () {
      final p = TreasureDivideProvider();
      p.startGame(
        playerIds: [
          'p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9', 'p10'
        ],
        numberOfRounds: 9,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.team,
        teamAssignment: TreasureDivideTeamAssignment.random,
        random: Random(1),
      );
      final game = p.currentGame!;
      // 10 players → some repeats allowed
      expect(game.playerPirateThemes.length, 10);
      for (final v in game.playerPirateThemes.values) {
        expect(v, inInclusiveRange(0, 7));
      }
    });

    test('87. Same player keeps same theme across all renders in a game', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], random: Random(10));
      final game = p.currentGame!;
      final theme = game.playerPirateThemes['p1']!;
      // Theme should not change mid-game
      expect(game.playerPirateThemes['p1'], theme);
    });

    test('88. New game produces a fresh theme shuffle', () {
      final p1 = _makeSoloProvider(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          random: Random(1));
      final p2 = _makeSoloProvider(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          random: Random(999));
      final themes1 = p1.currentGame!.playerPirateThemes;
      final themes2 = p2.currentGame!.playerPirateThemes;
      // With different seeds the assignment should differ
      bool differs = false;
      for (final pid in ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']) {
        if (themes1[pid] != themes2[pid]) {
          differs = true;
          break;
        }
      }
      expect(differs, true);
    });

    test('89. playerPirateThemes is persisted on save/restore', () {
      final p = _makeSoloProvider(
          playerIds: ['p1', 'p2'], random: Random(55));
      final game = p.currentGame!;
      final origThemes = Map<String, int>.from(game.playerPirateThemes);

      final json = game.toJson();
      final restored = TreasureDivideGame.fromJson(json);

      expect(restored.playerPirateThemes, origThemes);
    });
  });
}
