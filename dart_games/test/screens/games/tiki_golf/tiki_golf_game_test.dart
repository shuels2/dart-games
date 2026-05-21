import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/tiki_golf_game.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';

// ─── Test Helpers ─────────────────────────────────────────────────────────────

/// Creates a minimal solo TikiGolfProvider with two players.
TikiGolfProvider _makeSoloProvider({
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  List<String>? playerIds,
  Random? random,
}) {
  final p = TikiGolfProvider();
  p.startGame(
    playerIds: playerIds ?? ['p1', 'p2'],
    maxStrokes: maxStrokes,
    mulliganEnabled: mulliganEnabled,
    gameMode: TikiGolfGameMode.solo,
    teamAssignment: TikiGolfTeamAssignment.random,
    random: random,
  );
  return p;
}

/// Creates a team provider. teamPlayers is teamId → playerIds.
TikiGolfProvider _makeTeamProvider({
  required Map<String, List<String>> teamPlayers,
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  Random? random,
}) {
  final allPlayerIds = teamPlayers.values.expand((e) => e).toList();
  final teamAssignments = <String, String>{};
  for (final entry in teamPlayers.entries) {
    for (final pid in entry.value) {
      teamAssignments[pid] = entry.key;
    }
  }

  final p = TikiGolfProvider();
  p.startGame(
    playerIds: allPlayerIds,
    maxStrokes: maxStrokes,
    mulliganEnabled: mulliganEnabled,
    gameMode: TikiGolfGameMode.team,
    teamAssignment: TikiGolfTeamAssignment.manual,
    teamCount: teamPlayers.length,
    manualTeamAssignments: teamAssignments,
    random: random,
  );
  return p;
}

/// Throws a dart that hits the current hole's target.
void _throwHit(TikiGolfProvider p) {
  final game = p.currentGame!;
  final target = game.holeTargets[game.currentHole - 1];
  p.processDartThrow(sector: 'S$target', score: target);
}

/// Throws a dart that misses (always hits S1 when target != 1, else S2).
void _throwMiss(TikiGolfProvider p) {
  final game = p.currentGame!;
  final target = game.holeTargets[game.currentHole - 1];
  final missNum = target == 1 ? 2 : 1;
  p.processDartThrow(sector: 'S$missNum', score: missNum);
}

/// Fills the turn with misses up to maxStrokes (producing a Splash).
void _fillMissesForSplash(TikiGolfProvider p) {
  while (!p.currentGame!.currentTurnEnded) {
    _throwMiss(p);
  }
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // Scoring (Tests 1-8)
  // ═══════════════════════════════════════════════════════════════════
  group('Scoring', () {
    test('1. Hit target on 1st dart = score 1 (birdie)', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _throwHit(p);

      expect(game.playerHoleScores[pid]![holeIndex], 1);
    });

    test('2. Hit target on 2nd dart = score 2 (par)', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _throwMiss(p);
      _throwHit(p);

      expect(game.playerHoleScores[pid]![holeIndex], 2);
    });

    test('3. Hit target on 3rd dart = score 3 (bogey)', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _throwMiss(p);
      _throwMiss(p);
      _throwHit(p);

      expect(game.playerHoleScores[pid]![holeIndex], 3);
    });

    test('4. Miss all 3 darts at Max Darts=3 = score 4 (splash)', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _fillMissesForSplash(p);

      expect(game.playerHoleScores[pid]![holeIndex], 4); // maxStrokes + 1 = 4
    });

    test('5. Hole ends immediately on hit', () {
      final p = _makeSoloProvider(maxStrokes: 6);
      final game = p.currentGame!;

      _throwHit(p);

      // Turn should have ended after 1 dart
      expect(game.currentTurnEnded, isTrue);
      expect(game.dartsThrown[game.activePlayerId!], 1);
    });

    test('6. Remaining darts not thrown after hit', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      // Hit on dart 1 — no more darts should be throwable
      _throwHit(p);
      expect(game.currentTurnEnded, isTrue);
      expect(game.playerHoleScores[pid]![holeIndex], 1);

      // Attempting to throw more darts should not change score
      _throwHit(p); // should be ignored (currentTurnEnded = true)
      expect(game.playerHoleScores[pid]![holeIndex], 1);
      expect(game.dartsThrown[pid], 1);
    });

    test('7. Non-target hit counts as miss', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;
      final target = game.holeTargets[holeIndex];

      // Find a number that is not the target
      final nonTarget = target == 20 ? 19 : 20;
      p.processDartThrow(sector: 'S$nonTarget', score: nonTarget);

      // Should not have ended the turn (still mid-turn miss)
      expect(game.currentTurnEnded, isFalse);
      expect(game.playerHoleScores[pid]![holeIndex], isNull);
    });

    test('8. Bull hit when target is not bull = miss', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      // Targets are always 1-20, so Bull never matches
      p.processDartThrow(sector: 'Bull', score: 50);

      expect(game.currentTurnEnded, isFalse);
      expect(game.playerHoleScores[pid]![holeIndex], isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Per-Game Randomization (Tests 9-16)
  // ═══════════════════════════════════════════════════════════════════
  group('Per-Game Randomization', () {
    test('9. New game produces a holeTargets list of length 9', () {
      final p = _makeSoloProvider();
      expect(p.currentGame!.holeTargets.length, 9);
    });

    test('10. holeTargets contains 9 distinct numbers (no duplicates)', () {
      final p = _makeSoloProvider();
      final targets = p.currentGame!.holeTargets;
      final unique = targets.toSet();
      expect(unique.length, 9);
    });

    test('11. holeTargets values are all in range 1..20', () {
      for (int run = 0; run < 20; run++) {
        final p = _makeSoloProvider();
        for (final t in p.currentGame!.holeTargets) {
          expect(t, greaterThanOrEqualTo(1));
          expect(t, lessThanOrEqualTo(20));
        }
      }
    });

    test('12. Two consecutive constructions produce different holeTargets (statistical)', () {
      // Run 20 pairs — at least one pair should differ
      bool foundDifferent = false;
      for (int i = 0; i < 20; i++) {
        final p1 = _makeSoloProvider();
        final p2 = _makeSoloProvider();
        if (!_listsEqual(p1.currentGame!.holeTargets, p2.currentGame!.holeTargets)) {
          foundDifferent = true;
          break;
        }
      }
      expect(foundDifferent, isTrue,
          reason: 'Expected at least one pair with different holeTargets across 20 runs');
    });

    test('13. New game produces a holeImagePaths list of length 9', () {
      final p = _makeSoloProvider();
      expect(p.currentGame!.holeImagePaths.length, 9);
    });

    test('14. holeImagePaths is a full permutation of the 9 hole-theme asset paths', () {
      const expected = {
        'assets/games/tiki_golf/pieces/Volcano.png',
        'assets/games/tiki_golf/pieces/Waterfall.png',
        'assets/games/tiki_golf/pieces/TikiStatue.png',
        'assets/games/tiki_golf/pieces/PalmTree.png',
        'assets/games/tiki_golf/pieces/Lagoon.png',
        'assets/games/tiki_golf/pieces/Shipwreck.png',
        'assets/games/tiki_golf/pieces/BambooTemple.png',
        'assets/games/tiki_golf/pieces/CoralReef.png',
        'assets/games/tiki_golf/pieces/SunsetPier.png',
      };

      final p = _makeSoloProvider();
      final actual = p.currentGame!.holeImagePaths.toSet();
      expect(actual, equals(expected));
    });

    test('15. Two consecutive constructions produce different holeImagePaths ordering (statistical)', () {
      bool foundDifferent = false;
      for (int i = 0; i < 20; i++) {
        final p1 = _makeSoloProvider();
        final p2 = _makeSoloProvider();
        if (!_listsEqual(
            p1.currentGame!.holeImagePaths, p2.currentGame!.holeImagePaths)) {
          foundDifferent = true;
          break;
        }
      }
      expect(foundDifferent, isTrue,
          reason:
              'Expected at least one pair with different holeImagePaths across 20 runs');
    });

    test('16. Active target for the current hole equals holeTargets[currentHole - 1]', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      // Hole 1 (index 0)
      expect(game.holeTargets[game.currentHole - 1], game.holeTargets[0]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Hole Progression (Tests 17-21)
  // ═══════════════════════════════════════════════════════════════════
  group('Hole Progression', () {
    test('17. Advance to next hole after all players complete current hole', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      expect(game.currentHole, 1);

      // p1 hits target
      _throwHit(p);
      p.confirmTurnEnd(); // advance to p2

      // p2 hits target
      _throwHit(p);
      p.confirmTurnEnd(); // all done with hole 1 → advance to hole 2

      expect(game.currentHole, 2);
    });

    test('18. Game ends after hole 9', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // Play through all 9 holes
      for (int h = 0; h < 9; h++) {
        // p1
        _throwHit(p);
        p.confirmTurnEnd();
        // p2
        _throwHit(p);
        p.confirmTurnEnd();
      }

      expect(game.state, TikiGolfGameState.finished);
      expect(game.winnerId, isNotNull);
    });

    test('19. All players complete hole before advancing', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2', 'p3']);
      final game = p.currentGame!;

      // p1 done
      _throwHit(p); // score on hole 1
      p.confirmTurnEnd();
      expect(game.currentHole, 1); // still hole 1

      // p2 done
      _throwHit(p);
      p.confirmTurnEnd();
      expect(game.currentHole, 1); // still hole 1

      // p3 done — now advance
      _throwHit(p);
      p.confirmTurnEnd();
      expect(game.currentHole, 2);
    });

    test('20. Running total updates after each hole', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // p1 birdie hole 1
      _throwHit(p);
      p.confirmTurnEnd();
      // p2 par hole 1
      _throwMiss(p);
      _throwHit(p);
      p.confirmTurnEnd(); // advance to hole 2

      expect(game.totalForPlayer('p1'), 1); // birdie
      expect(game.totalForPlayer('p2'), 2); // par
    });

    test('21. Hole image and target both update when currentHole advances', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      final hole1Target = game.holeTargets[0];
      final hole1Image = game.holeImagePaths[0];

      // Play through hole 1
      _throwHit(p);
      p.confirmTurnEnd();
      _throwHit(p);
      p.confirmTurnEnd();

      // Now on hole 2
      expect(game.currentHole, 2);
      expect(game.holeTargets[game.currentHole - 1], game.holeTargets[1]);
      expect(game.holeImagePaths[game.currentHole - 1], game.holeImagePaths[1]);

      // The key assertion is that the getter indexes by [currentHole - 1]
      // (values at index 1 may or may not differ from hole 1 — we just check indexing)
      expect(game.holeTargets[game.currentHole - 1], game.holeTargets[1]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Mulligan (Tests 22-26)
  // ═══════════════════════════════════════════════════════════════════
  group('Mulligan', () {
    test('22. Mulligan available after splash', () {
      final p = _makeSoloProvider(maxStrokes: 3, mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMissesForSplash(p);
      expect(game.playerMulligansUsed[pid], 0); // still available

      // useMulligan should succeed
      p.useMulligan();
      expect(game.playerMulligansUsed[pid], 1); // now used
      expect(game.currentTurnEnded, isFalse);
    });

    test('23. Mulligan not available after non-splash score', () {
      final p = _makeSoloProvider(maxStrokes: 3, mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      // Hit target (not a splash)
      _throwHit(p);

      // useMulligan should not work (not a splash)
      p.useMulligan();
      expect(game.playerMulligansUsed[pid], 0); // NOT used
      expect(game.currentTurnEnded, isTrue); // turn still ended (hit)
    });

    test('24. Mulligan: re-throw resets hole score for that player', () {
      final p = _makeSoloProvider(maxStrokes: 3, mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _fillMissesForSplash(p);
      expect(game.playerHoleScores[pid]![holeIndex], 4); // splash

      p.useMulligan();
      expect(game.playerHoleScores[pid]![holeIndex], isNull); // cleared
      expect(game.dartsThrown[pid], 0); // reset
    });

    test('25. Mulligan: can only be used once per game per player', () {
      final p = _makeSoloProvider(maxStrokes: 3, mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      // Use mulligan on hole 1
      _fillMissesForSplash(p);
      p.useMulligan();
      expect(game.playerMulligansUsed[pid], 1);

      // Splash again during mulligan re-throw
      _fillMissesForSplash(p);
      p.confirmTurnEnd(); // no mulligan this time — already used
      // p2's turn or advance to hole 2; player can't use mulligan again
      expect(game.playerMulligansUsed[pid], 1); // still 1 (not reset)
    });

    test('26. Mulligan OFF: no mulligan option available', () {
      final p = _makeSoloProvider(maxStrokes: 3, mulliganEnabled: false);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _fillMissesForSplash(p);
      expect(game.playerHoleScores[pid]![holeIndex], 4); // splash

      // useMulligan should do nothing (mulliganEnabled = false)
      p.useMulligan();
      expect(game.playerHoleScores[pid]![holeIndex], 4); // unchanged
      expect(game.currentTurnEnded, isTrue); // still ended
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Win Condition (Tests 27-30)
  // ═══════════════════════════════════════════════════════════════════
  group('Win Condition', () {
    test('27. Lowest total score wins', () {
      // p1 gets all birdies (9 × 1 = 9), p2 gets all pars (9 × 2 = 18)
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);

      for (int h = 0; h < 9; h++) {
        _throwHit(p); // p1 birdie
        p.confirmTurnEnd();
        _throwMiss(p);
        _throwHit(p); // p2 par
        p.confirmTurnEnd();
      }

      expect(p.currentGame!.winnerId, 'p1');
    });

    test('28. Equal totals (different birdie counts) → both are tied winners', () {
      // Per spec change: a tie on TOTAL means ALL players tied are winners.
      // Birdie/bogey counts no longer break the tie — they are display-only.
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // p1 has more birdies but same total as p2 — both are winners.
      game.playerHoleScores['p1'] = [1, 1, 1, 1, 3, 3, 3, 3, 3]; // total 19
      game.playerHoleScores['p2'] = [2, 2, 2, 3, 2, 2, 3, 2, 1]; // total 19

      expect(game.totalForPlayer('p1'), 19);
      expect(game.totalForPlayer('p2'), 19);

      p.endGame();
      // Both players tied → winnerIds contains both, in turn order.
      expect(game.winnerIds, ['p1', 'p2']);
      // Legacy single-winner reference points to the first tied player.
      expect(game.winnerId, 'p1');
    });

    test('29. Equal totals (different bogey counts) → both are tied winners', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // Same total (20) and birdies (0), but p2 has more bogeys. Still a tie.
      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 4]; // total 20
      game.playerHoleScores['p2'] = [3, 3, 2, 2, 2, 2, 2, 2, 2]; // total 20

      expect(game.totalForPlayer('p1'), 20);
      expect(game.totalForPlayer('p2'), 20);
      expect(game.bogeysForPlayer('p1'), 1);
      expect(game.bogeysForPlayer('p2'), 2);

      p.endGame();
      expect(game.winnerIds, ['p1', 'p2']);
      expect(game.winnerId, 'p1');
    });

    test('30. Identical totals (no other differences) → all players tied', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerIds, ['p1', 'p2']);
      expect(game.winnerId, 'p1');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Game Flow (Tests 31-33)
  // ═══════════════════════════════════════════════════════════════════
  group('Game Flow', () {
    test('31. Turn advancement after hit (hole ends on hit, advance to next player)', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      expect(game.activePlayerId, 'p1');
      _throwHit(p);
      p.confirmTurnEnd();
      expect(game.activePlayerId, 'p2');
    });

    test('32. Skip turn counts remaining darts as misses', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      p.skipTurn();

      // Should record Splash
      expect(game.playerHoleScores[pid]![holeIndex], game.maxStrokes + 1);
      expect(game.currentTurnEnded, isTrue);
    });

    test('33. Game state serialization (toJson/fromJson round-trip)', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2'], maxStrokes: 4);
      final game = p.currentGame!;

      // Throw one dart so there's some state
      _throwMiss(p);

      final json = game.toJson();
      final restored = TikiGolfGame.fromJson(json);

      expect(restored.id, game.id);
      expect(restored.playerIds, game.playerIds);
      expect(restored.maxStrokes, 4);
      expect(restored.holeTargets, game.holeTargets);
      expect(restored.holeImagePaths, game.holeImagePaths);
      expect(restored.currentHole, game.currentHole);
      expect(restored.dartsThrown[game.activePlayerId!],
          game.dartsThrown[game.activePlayerId!]);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Edge Cases (Tests 34-36)
  // ═══════════════════════════════════════════════════════════════════
  group('Edge Cases', () {
    test('34. Edit score recalculates hole score and total', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      final pid = 'p1';

      // Manually set a score for hole 0
      game.playerHoleScores[pid] = [3, null, null, null, null, null, null, null, null];
      expect(game.totalForPlayer(pid), 3);

      // Edit: player re-throws, hits on dart 1 → birdie
      final target = game.holeTargets[0];
      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: ['S$target'],
      );

      expect(game.playerHoleScores[pid]![0], 1);
      expect(game.totalForPlayer(pid), 1);
    });

    test('35. 4-player solo game flow (max solo count)', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2', 'p3', 'p4']);
      final game = p.currentGame!;

      // All 4 players complete hole 1
      for (int i = 0; i < 4; i++) {
        _throwHit(p);
        p.confirmTurnEnd();
      }

      expect(game.currentHole, 2);
    });

    test('36. All players splash on same hole', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2'], maxStrokes: 3);
      final game = p.currentGame!;

      // p1 splashes
      _fillMissesForSplash(p);
      p.confirmTurnEnd();
      // p2 splashes
      _fillMissesForSplash(p);
      p.confirmTurnEnd();

      // Both should have splash score (4) on hole 1
      expect(game.playerHoleScores['p1']![0], 4);
      expect(game.playerHoleScores['p2']![0], 4);
      // Should advance to hole 2
      expect(game.currentHole, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Max Darts (Tests 37-42)
  // ═══════════════════════════════════════════════════════════════════
  group('Max Darts (variable per-turn dart cap)', () {
    test('37. Max Darts = 3: splash threshold = 4', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      // Miss all 3 → score 4
      _fillMissesForSplash(p);
      expect(game.playerHoleScores[pid]![holeIndex], 4);
    });

    test('38. Max Darts = 4: hit on dart 4 = 4 strokes; splash threshold = 5', () {
      final p = _makeSoloProvider(maxStrokes: 4);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _throwMiss(p);
      _throwMiss(p);
      _throwMiss(p);
      _throwHit(p); // dart 4

      expect(game.playerHoleScores[pid]![holeIndex], 4);
      expect(game.currentTurnEnded, isTrue);

      // Reset and verify splash = 5
      final p2 = _makeSoloProvider(maxStrokes: 4);
      final game2 = p2.currentGame!;
      final pid2 = game2.activePlayerId!;
      final holeIndex2 = game2.currentHole - 1;
      _fillMissesForSplash(p2);
      expect(game2.playerHoleScores[pid2]![holeIndex2], 5);
    });

    test('39. Max Darts = 5: splash threshold is 6 strokes', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _fillMissesForSplash(p);
      expect(game.playerHoleScores[pid]![holeIndex], 6);
    });

    test('40. Max Darts = 6: splash threshold is 7 strokes; hit on dart 6 = 6 strokes', () {
      // Test splash = 7
      final p = _makeSoloProvider(maxStrokes: 6);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final holeIndex = game.currentHole - 1;

      _fillMissesForSplash(p);
      expect(game.playerHoleScores[pid]![holeIndex], 7);

      // Test hit on dart 6 = 6 strokes
      final p2 = _makeSoloProvider(maxStrokes: 6);
      final game2 = p2.currentGame!;
      final pid2 = game2.activePlayerId!;
      final holeIndex2 = game2.currentHole - 1;

      for (int i = 0; i < 5; i++) _throwMiss(p2);
      _throwHit(p2);
      expect(game2.playerHoleScores[pid2]![holeIndex2], 6);
    });

    test('41. Max Darts setting persists via toJson/fromJson', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final json = p.currentGame!.toJson();
      final restored = TikiGolfGame.fromJson(json);
      expect(restored.maxStrokes, 5);
    });

    test('42. Edit-Score replays with correct dart count for Max Darts setting', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      // Edit providing 4 misses then a hit on dart 5
      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: [
          'S${target == 1 ? 2 : 1}', // miss
          'S${target == 1 ? 2 : 1}', // miss
          'S${target == 1 ? 2 : 1}', // miss
          'S${target == 1 ? 2 : 1}', // miss
          'S$target', // hit on dart 5
        ],
      );

      expect(game.playerHoleScores[pid]![0], 5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode — every-player-plays-every-hole rotation (Tests 43-50)
  // ═══════════════════════════════════════════════════════════════════
  group('Team Mode — every-player-plays-every-hole rotation', () {
    test('43. Team config [A:2, B:1] — each team plays its players in roster order', () {
      // Total 3 players (minimum for team mode): A:2, B:1
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      expect(game.activeTeamId, 'team_1');
      expect(game.activePlayerId, 'a1');

      _throwHit(p);
      p.confirmTurnEnd();

      // a1 done → a2 up (still team_1)
      expect(game.activeTeamId, 'team_1');
      expect(game.activePlayerId, 'a2');

      _throwHit(p);
      p.confirmTurnEnd();

      // team_1 done → team_2 up
      expect(game.activeTeamId, 'team_2');
      expect(game.activePlayerId, 'b1');
    });

    test('44. Team config [A:2, B:2] — hole order: A_P1 → A_P2 → B_P1 → B_P2', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      // Verify turn order
      expect(game.activePlayerId, 'a1');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'a2');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'b1');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'b2');
      _throwHit(p);
      p.confirmTurnEnd();

      // All done — hole 2 starts
      expect(game.currentHole, 2);
    });

    test('45. Team config [A:3, B:1] — hole order: A_P1 → A_P2 → A_P3 → B_P1', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2', 'a3'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      expect(game.activePlayerId, 'a1');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'a2');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'a3');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.activePlayerId, 'b1');
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.currentHole, 2);
    });

    test('46. Team config [A:4, B:2, C:1, D:3] — full hole order verified', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2', 'a3', 'a4'],
        'team_2': ['b1', 'b2'],
        'team_3': ['c1'],
        'team_4': ['d1', 'd2', 'd3'],
      });
      final game = p.currentGame!;

      final expectedOrder = ['a1', 'a2', 'a3', 'a4', 'b1', 'b2', 'c1', 'd1', 'd2', 'd3'];
      for (final pid in expectedOrder) {
        expect(game.activePlayerId, pid,
            reason: 'Expected player $pid but got ${game.activePlayerId}');
        _throwHit(p);
        p.confirmTurnEnd();
      }

      expect(game.currentHole, 2);
    });

    test('47. After all players on all teams complete a hole, advance to next hole; rotation resets', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      // Complete hole 1
      for (int i = 0; i < 4; i++) {
        _throwHit(p);
        p.confirmTurnEnd();
      }

      expect(game.currentHole, 2);
      // Rotation should restart at a1
      expect(game.activePlayerId, 'a1');
      expect(game.currentTeamIndex, 0);
      expect(game.teamWithinHoleRotationPointer['team_1'], 0);
    });

    test('48. Skip turn in team mode skips only current player; rotation advances correctly', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      expect(game.activePlayerId, 'a1');
      p.skipTurn(); // Skip a1
      p.confirmTurnEnd();
      expect(game.activePlayerId, 'a2'); // a2 still plays
    });

    test('49. Resume from saved game preserves within-hole rotation pointer and team cursor', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      // a1 plays, advance to a2
      _throwHit(p);
      p.confirmTurnEnd();
      expect(game.activePlayerId, 'a2');

      // Save and restore
      final json = game.toJson();
      final restored = TikiGolfGame.fromJson(json);

      expect(restored.teamWithinHoleRotationPointer['team_1'], 1);
      expect(restored.activePlayerId, 'a2');
      expect(restored.currentTeamIndex, game.currentTeamIndex);
    });

    test('50. Edit score on team-mode hole re-attributes score; best-ball recomputes', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;
      final target = game.holeTargets[0];

      // a1 gets a par (dart 2 hit)
      _throwMiss(p);
      _throwHit(p);
      p.confirmTurnEnd();

      expect(game.playerHoleScores['a1']![0], 2); // par
      expect(game.bestBallForTeam('team_1', 0), 2);

      // Edit a1's score to birdie (hit on dart 1)
      p.editPlayerScore(
        playerId: 'a1',
        holeIndex: 0,
        newDartSegments: ['S$target'],
      );

      expect(game.playerHoleScores['a1']![0], 1); // birdie
      expect(game.bestBallForTeam('team_1', 0), 1); // recomputed
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode — best-ball aggregation (Tests 51-58)
  // ═══════════════════════════════════════════════════════════════════
  group('Team Mode — best-ball aggregation', () {
    test('51. Team [A:3] scores {P1:1, P2:3, P3:2} → team hole score = 1', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2', 'a3'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Manually set scores for hole 0
      game.playerHoleScores['a1']![0] = 1;
      game.playerHoleScores['a2']![0] = 3;
      game.playerHoleScores['a3']![0] = 2;

      expect(game.bestBallForTeam('team_1', 0), 1);
    });

    test('52. Team [A:1] with hole score 4 → team hole score = 4 (uses 3-player min setup)', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1']![0] = 4;
      expect(game.bestBallForTeam('team_1', 0), 4);
    });

    test('53. Team [A:4] all splashes (Max=6 → splash=7) → team hole score = 7', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2', 'a3', 'a4'],
          'team_2': ['b1'],
        },
        maxStrokes: 6,
      );
      final game = p.currentGame!;

      for (final pid in ['a1', 'a2', 'a3', 'a4']) {
        game.playerHoleScores[pid]![0] = 7; // max=6 → splash=7
      }
      expect(game.bestBallForTeam('team_1', 0), 7);
    });

    test('54. Mid-hole: after P1 birdies, team best-ball-so-far = 1', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // a1 throws birdie
      _throwHit(p);
      // Before confirmTurnEnd, a1's score is recorded
      expect(game.playerHoleScores['a1']![0], 1);
      expect(game.bestBallForTeam('team_1', 0), 1);
    });

    test('55. Mulligan on a1: splashes, mulligans, gets birdie → team score recomputes', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2'],
          'team_2': ['b1'],
        },
        maxStrokes: 3,
        mulliganEnabled: true,
      );
      final game = p.currentGame!;

      // a2 plays first and gets bogey (score 3) — wait, a1 goes first per roster
      // a1 goes first
      _fillMissesForSplash(p); // a1 splashes
      expect(game.playerHoleScores['a1']![0], 4); // splash

      p.useMulligan(); // mulligan
      _throwHit(p); // a1 now birdies
      p.confirmTurnEnd();

      // a2 gets a par
      _throwMiss(p);
      _throwHit(p);
      p.confirmTurnEnd();

      // team best-ball should be MIN(1,2) = 1
      expect(game.bestBallForTeam('team_1', 0), 1);
    });

    test('56. Mulligan: P1 already birdied; P2 splashes, mulligans → team score still 1', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2'],
          'team_2': ['b1'],
        },
        mulliganEnabled: true,
      );
      final game = p.currentGame!;

      // a1 birdies
      _throwHit(p);
      p.confirmTurnEnd();
      expect(game.playerHoleScores['a1']![0], 1);

      // a2 splashes
      _fillMissesForSplash(p);
      p.useMulligan(); // mulligan: re-throw — still splashes
      _fillMissesForSplash(p);
      p.confirmTurnEnd();

      // Team best-ball still = 1 (from a1)
      expect(game.bestBallForTeam('team_1', 0), 1);
    });

    test('57. Team running total = sum of per-hole best-ball scores', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Set best-ball scores for 3 holes manually
      game.playerHoleScores['a1'] = [1, 2, 3, null, null, null, null, null, null];
      game.playerHoleScores['a2'] = [2, 1, 2, null, null, null, null, null, null];

      // Best-ball per hole: 1, 1, 2 → total = 4
      expect(game.bestBallForTeam('team_1', 0), 1);
      expect(game.bestBallForTeam('team_1', 1), 1);
      expect(game.bestBallForTeam('team_1', 2), 2);
      // totalForTeam only counts holes with scores
      // holes 3-8 have null → bestBall returns null → not counted
      expect(game.totalForTeam('team_1'), 4);
    });

    test('58. Team birdie count = holes where best-ball == 1', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [1, 2, 1, 2, 3, 2, 2, 1, 2]; // 3 birdies
      game.playerHoleScores['a2'] = [2, 1, 2, 2, 2, 2, 2, 2, 2]; // 1 birdie hole 2

      // Best-ball: min(1,2)=1, min(2,1)=1, min(1,2)=1, 2, 2, 2, 2, 1, 2
      // Birdies (score==1): holes 0,1,2,7 → 4 team birdies
      expect(game.teamBirdies('team_1'), 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode — win condition + stats (Tests 59-64)
  // ═══════════════════════════════════════════════════════════════════
  group('Team Mode — win condition + stats', () {
    test('59. Lowest team total wins', () {
      // 3 players total (min for team mode): [2,1]
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1]; // best-ball min
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // worse
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // team_2 total=18

      // team_1 best-ball per hole = min(1,2) = 1 × 9 = 9
      // team_2 best-ball per hole = 2 × 9 = 18
      p.endGame();
      expect(game.winnerTeamId, 'team_1');
    });

    test('60. Equal team totals (different birdie counts) → both teams tied', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // team_1 best-ball: [1,1,2,2,2,2,2,2,4] = 18, 2 birdies
      // team_2 best-ball: [2,2,2,2,2,2,2,2,2] = 18, 0 birdies
      game.playerHoleScores['a1'] = [1, 1, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.totalForTeam('team_1'), 18);
      expect(game.totalForTeam('team_2'), 18);
      expect(game.winnerTeamIds, ['team_1', 'team_2']);
      expect(game.winnerTeamId, 'team_1');
    });

    test('61. Equal team totals (different bogey counts) → both teams tied', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Both teams total 20 best-ball; team_2 has more bogeys.
      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 3, 3];

      p.endGame();
      expect(game.winnerTeamIds, ['team_1', 'team_2']);
      expect(game.winnerTeamId, 'team_1');
    });

    test('62. Identical team totals → all teams tied', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Identical best-ball totals
      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamIds, ['team_1', 'team_2']);
      expect(game.winnerTeamId, 'team_1');
    });

    test('63. All players on winning team get win credit (winnerTeamId set)', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1]; // best-ball=9
      game.playerHoleScores['a2'] = [1, 1, 1, 1, 1, 1, 1, 1, 1];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // best-ball=18
      game.playerHoleScores['b2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
      // All team_1 players (a1, a2) are covered by winnerTeamId
      expect(game.teamPlayers['team_1'], contains('a1'));
      expect(game.teamPlayers['team_1'], contains('a2'));
    });

    test('64. Losing-team players are not in winning team; no team label persisted', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1];
      game.playerHoleScores['a2'] = [1, 1, 1, 1, 1, 1, 1, 1, 1];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
      expect(game.teamPlayers['team_2'], contains('b1'));
      // b1 is NOT in the winning team
      expect(game.teamPlayers[game.winnerTeamId!], isNot(contains('b1')));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode — mulligan per-player (Tests 65-67)
  // ═══════════════════════════════════════════════════════════════════
  group('Team Mode — mulligan per-player', () {
    test('65. Mulligan is per-player (each tracks own counter)', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2'],
          'team_2': ['b1'],
        },
        mulliganEnabled: true,
      );
      final game = p.currentGame!;

      // a1 splashes and uses mulligan
      _fillMissesForSplash(p);
      p.useMulligan();
      expect(game.playerMulligansUsed['a1'], 1);
      // a2's mulligan is unaffected
      expect(game.playerMulligansUsed['a2'], 0);
    });

    test('66. P1 using mulligan does not consume P2 mulligan on the same team', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2'],
          'team_2': ['b1'],
        },
        mulliganEnabled: true,
      );
      final game = p.currentGame!;

      // a1 uses mulligan
      _fillMissesForSplash(p);
      p.useMulligan();
      _fillMissesForSplash(p); // splash after mulligan
      p.confirmTurnEnd();

      // a2 still has mulligan
      expect(game.playerMulligansUsed['a2'], 0);
    });

    test('67. Mulligan available only on splash, regardless of teammates', () {
      final p = _makeTeamProvider(
        teamPlayers: {
          'team_1': ['a1', 'a2'],
          'team_2': ['b1'],
        },
        mulliganEnabled: true,
      );
      final game = p.currentGame!;

      // a1 gets a par (not splash)
      _throwMiss(p);
      _throwHit(p);
      p.confirmTurnEnd();

      // a2 should still have mulligan available (unrelated to a1's result)
      expect(game.playerMulligansUsed['a2'], 0);

      // a2 splashes and can use mulligan
      _fillMissesForSplash(p);
      p.useMulligan();
      expect(game.playerMulligansUsed['a2'], 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Team Mode — assignment & setup (Tests 68-72)
  // ═══════════════════════════════════════════════════════════════════
  group('Team Mode — assignment & setup', () {
    test('68. Random assignment uses randomDistribution algorithm', () {
      final p = TikiGolfProvider();
      p.startGame(
        playerIds: ['p1', 'p2', 'p3', 'p4'],
        maxStrokes: 3,
        mulliganEnabled: false,
        gameMode: TikiGolfGameMode.team,
        teamAssignment: TikiGolfTeamAssignment.random,
      );

      final game = p.currentGame!;
      // N=4 → 2 teams of [2,2]
      expect(game.teamCount, 2);
      final sizes = game.teamPlayers.values.map((v) => v.length).toList()..sort();
      expect(sizes, [2, 2]);
    });

    test('69. Random distribution full-table provider test (all N from 3..16)', () {
      // Spec table:
      const table = [
        (n: 3, t: 2, sizes: [2, 1]),
        (n: 4, t: 2, sizes: [2, 2]),
        (n: 5, t: 3, sizes: [2, 2, 1]),
        (n: 6, t: 3, sizes: [2, 2, 2]),
        (n: 7, t: 4, sizes: [2, 2, 2, 1]),
        (n: 8, t: 2, sizes: [4, 4]),
        (n: 9, t: 3, sizes: [3, 3, 3]),
        (n: 10, t: 3, sizes: [4, 3, 3]),
        (n: 11, t: 3, sizes: [4, 4, 3]),
        (n: 12, t: 4, sizes: [3, 3, 3, 3]),
        (n: 13, t: 4, sizes: [4, 3, 3, 3]),
        (n: 14, t: 4, sizes: [4, 4, 3, 3]),
        (n: 15, t: 4, sizes: [4, 4, 4, 3]),
        (n: 16, t: 4, sizes: [4, 4, 4, 4]),
      ];

      for (final row in table) {
        final result = TikiGolfProvider.randomDistribution(row.n);
        final sortedSizes = List<int>.from(result.sizes)..sort((a, b) => b.compareTo(a));
        final expectedSorted = List<int>.from(row.sizes)..sort((a, b) => b.compareTo(a));

        expect(result.teamCount, row.t,
            reason: 'N=${row.n}: expected teamCount=${row.t}, got=${result.teamCount}');
        expect(sortedSizes, expectedSorted,
            reason: 'N=${row.n}: expected sizes=${row.sizes} sorted=$expectedSorted, got=${result.sizes} sorted=$sortedSizes');
      }
    });

    test('70. Manual assignment respects user-set team membership', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_A': ['alice', 'bob'],
        'team_B': ['carol', 'dave'],
      });
      final game = p.currentGame!;

      expect(game.teamPlayers['team_A'], containsAll(['alice', 'bob']));
      expect(game.teamPlayers['team_B'], containsAll(['carol', 'dave']));
      expect(game.playerTeamAssignments['alice'], 'team_A');
      expect(game.playerTeamAssignments['carol'], 'team_B');
    });

    test('71. Empty team rejected — startGame validation', () {
      // Attempting team mode with only 2 players (below minimum of 3)
      final p = TikiGolfProvider();
      p.startGame(
        playerIds: ['p1', 'p2'],
        maxStrokes: 3,
        mulliganEnabled: false,
        gameMode: TikiGolfGameMode.team,
        teamAssignment: TikiGolfTeamAssignment.random,
      );
      // Should not start a game
      expect(p.currentGame, isNull);
    });

    test('72. Team logos: at game start 4 distinct crests from 6 available, locked in order', () {
      const allCrests = {
        'assets/games/tiki_golf/teams/Sharks.png',
        'assets/games/tiki_golf/teams/SeaTurtles.png',
        'assets/games/tiki_golf/teams/Hibiscus.png',
        'assets/games/tiki_golf/teams/Volcanoes.png',
        'assets/games/tiki_golf/teams/Coconuts.png',
        'assets/games/tiki_golf/teams/Parrots.png',
      };

      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1'],
        'team_2': ['b1'],
        'team_3': ['c1'],
        'team_4': ['d1'],
      });
      final game = p.currentGame!;

      // 4 crests assigned
      expect(game.teamCrestPaths.length, 4);
      // All crests are from the valid set
      for (final crest in game.teamCrestPaths) {
        expect(allCrests, contains(crest));
      }
      // All 4 crests are distinct
      expect(game.teamCrestPaths.toSet().length, 4);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Ties — explicit coverage for solo + team modes
  // ═══════════════════════════════════════════════════════════════════
  group('Ties', () {
    test('Solo outright winner populates winnerIds with one entry', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1]; // 9
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerIds, ['p1']);
      expect(game.winnerId, 'p1');
    });

    test('Solo 2-way tie: winnerIds contains both, in turn order', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerIds, ['p1', 'p2']);
      expect(game.winnerId, 'p1'); // legacy first-winner reference
    });

    test('Solo 3-way tie: all three players in winnerIds', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2', 'p3']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['p3'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerIds, ['p1', 'p2', 'p3']);
    });

    test('Solo partial tie: only players at the lowest total are winners', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2', 'p3']);
      final game = p.currentGame!;

      // p1 & p3 tied at 18; p2 has 20 (loser).
      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 4]; // 20
      game.playerHoleScores['p3'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerIds, ['p1', 'p3']);
      expect(game.winnerIds, isNot(contains('p2')));
    });

    test('Team outright winner populates winnerTeamIds with one entry', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1]; // best-ball 9
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerTeamIds, ['team_1']);
    });

    test('Team 2-way tie: winnerTeamIds contains both teams', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1', 'b2'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18 best-ball
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerTeamIds, ['team_1', 'team_2']);
      expect(game.winnerTeamId, 'team_1'); // legacy reference
    });

    test('Team 3-way tie: all three teams in winnerTeamIds', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1'],
        'team_2': ['b1'],
        'team_3': ['c1'],
      });
      final game = p.currentGame!;

      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['c1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamIds, ['team_1', 'team_2', 'team_3']);
    });

    test('Team partial tie: only teams at the lowest total are winners', () {
      final p = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1'],
        'team_2': ['b1'],
        'team_3': ['c1'],
      });
      final game = p.currentGame!;

      // team_1 & team_3 tied at 18; team_2 totals 20 (loser).
      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 4]; // 20
      game.playerHoleScores['c1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerTeamIds, ['team_1', 'team_3']);
      expect(game.winnerTeamIds, isNot(contains('team_2')));
    });

    test('winnerIds / winnerTeamIds survive JSON round-trip', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      p.endGame();

      final restored = TikiGolfGame.fromJson(game.toJson());
      expect(restored.winnerIds, ['p1', 'p2']);
      expect(restored.winnerId, 'p1');

      final teamP = _makeTeamProvider(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final tg = teamP.currentGame!;
      tg.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      tg.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      tg.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      teamP.endGame();
      final restoredTeam = TikiGolfGame.fromJson(tg.toJson());
      expect(restoredTeam.winnerTeamIds, ['team_1', 'team_2']);
      expect(restoredTeam.winnerTeamId, 'team_1');
    });
  });
}

// ─── Utility ──────────────────────────────────────────────────────────────────

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
