import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/tiki_golf_game.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

TikiGolfProvider _makeSoloProvider({
  List<String> playerIds = const ['p1', 'p2'],
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  Random? random,
}) {
  final p = TikiGolfProvider();
  p.startGame(
    playerIds: playerIds,
    maxStrokes: maxStrokes,
    mulliganEnabled: mulliganEnabled,
    gameMode: TikiGolfGameMode.solo,
    teamAssignment: TikiGolfTeamAssignment.random,
    random: random,
  );
  return p;
}

TikiGolfProvider _makeTeamProviderManual({
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

/// Idle provider (no game started)
TikiGolfProvider _makeIdleProvider() => TikiGolfProvider();

/// Hit the current hole's target.
void _hit(TikiGolfProvider p) {
  final game = p.currentGame!;
  final target = game.holeTargets[game.currentHole - 1];
  p.processDartThrow(sector: 'S$target', score: target);
}

/// Miss the current hole's target.
void _miss(TikiGolfProvider p) {
  final game = p.currentGame!;
  final target = game.holeTargets[game.currentHole - 1];
  final missNum = target == 1 ? 2 : 1;
  p.processDartThrow(sector: 'S$missNum', score: missNum);
}

/// Fill with misses until Splash (currentTurnEnded = true).
void _fillMisses(TikiGolfProvider p) {
  while (!(p.currentGame!.currentTurnEnded)) {
    _miss(p);
  }
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────────
  // Group 1 — Initial state
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — initial state', () {
    test('1.1 isGameActive is false before startGame', () {
      final p = _makeIdleProvider();
      expect(p.isGameActive, isFalse);
    });

    test('1.2 currentGame is null before startGame', () {
      final p = _makeIdleProvider();
      expect(p.currentGame, isNull);
    });

    test('1.3 currentPlayerId is null before startGame', () {
      final p = _makeIdleProvider();
      expect(p.currentPlayerId, isNull);
    });

    test('1.4 isGameActive is true after startGame', () {
      final p = _makeSoloProvider();
      expect(p.isGameActive, isTrue);
    });

    test('1.5 holeTargets has length 9 and all values in 1..20', () {
      for (int run = 0; run < 5; run++) {
        final p = _makeSoloProvider();
        final targets = p.currentGame!.holeTargets;
        expect(targets.length, 9);
        for (final t in targets) {
          expect(t, greaterThanOrEqualTo(1));
          expect(t, lessThanOrEqualTo(20));
        }
      }
    });

    test('1.6 holeTargets are distinct (no duplicates)', () {
      final p = _makeSoloProvider();
      final targets = p.currentGame!.holeTargets;
      expect(targets.toSet().length, 9);
    });

    test('1.7 holeImagePaths is a permutation of the 9 hole-theme paths', () {
      const allPaths = {
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
      final paths = p.currentGame!.holeImagePaths.toSet();
      expect(paths, equals(allPaths));
      expect(p.currentGame!.holeImagePaths.length, 9);
    });

    test('1.8 mulliganEnabled defaults to false', () {
      final p = _makeSoloProvider();
      expect(p.currentGame!.mulliganEnabled, isFalse);
    });

    test('1.9 all playerMulligansUsed initialized to 0', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2', 'p3']);
      final game = p.currentGame!;
      for (final pid in game.playerIds) {
        expect(game.playerMulligansUsed[pid], 0);
      }
    });

    test('1.10 all dartsThrown initialized to 0', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      for (final pid in game.playerIds) {
        expect(game.dartsThrown[pid], 0);
      }
    });

    test('1.11 all totalTurns initialized to 0', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      for (final pid in game.playerIds) {
        expect(game.totalTurns[pid], 0);
      }
    });

    test('1.12 currentHole starts at 1', () {
      final p = _makeSoloProvider();
      expect(p.currentGame!.currentHole, 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 2 — processDartThrow
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — processDartThrow', () {
    // ── Sector hit detection ──
    test('2.1 S<N> hits target N', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      p.processDartThrow(sector: 'S$target', score: target);

      expect(game.playerHoleScores[pid]![0], 1);
      expect(game.currentTurnEnded, isTrue);
    });

    test('2.2 D<N> hits target N (double of target counts)', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      p.processDartThrow(sector: 'D$target', score: target);

      expect(game.playerHoleScores[pid]![0], 1);
      expect(game.currentTurnEnded, isTrue);
    });

    test('2.3 T<N> hits target N (triple of target counts)', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      p.processDartThrow(sector: 'T$target', score: target);

      expect(game.playerHoleScores[pid]![0], 1);
      expect(game.currentTurnEnded, isTrue);
    });

    test('2.4 S<N> misses when N != target', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];
      final notTarget = target == 20 ? 19 : 20;

      p.processDartThrow(sector: 'S$notTarget', score: notTarget);

      expect(game.currentTurnEnded, isFalse);
      expect(game.playerHoleScores[pid]![0], isNull);
    });

    test('2.5 Bull misses target when target is not 25', () {
      // All targets are 1-20, so Bull never matches
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      p.processDartThrow(sector: 'Bull', score: 50);

      expect(game.currentTurnEnded, isFalse);
      expect(game.playerHoleScores[pid]![0], isNull);
    });

    test('2.6 Miss sector never hits target', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      p.processDartThrow(sector: 'Miss', score: 0);

      expect(game.currentTurnEnded, isFalse);
      expect(game.playerHoleScores[pid]![0], isNull);
    });

    // ── Per-maxStrokes hit timing ──
    test('2.7 maxStrokes=3: hit on dart 1 → score 1', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _hit(p);
      expect(game.playerHoleScores[pid]![0], 1);
    });

    test('2.8 maxStrokes=3: hit on dart 2 → score 2', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _miss(p);
      _hit(p);
      expect(game.playerHoleScores[pid]![0], 2);
    });

    test('2.9 maxStrokes=3: hit on dart 3 → score 3', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _miss(p);
      _miss(p);
      _hit(p);
      expect(game.playerHoleScores[pid]![0], 3);
    });

    test('2.10 maxStrokes=3: all 3 miss → score 4 (splash)', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      expect(game.playerHoleScores[pid]![0], 4);
    });

    test('2.11 maxStrokes=4: hit on dart 4 → score 4', () {
      final p = _makeSoloProvider(maxStrokes: 4);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _miss(p); _miss(p); _miss(p);
      _hit(p);
      expect(game.playerHoleScores[pid]![0], 4);
    });

    test('2.12 maxStrokes=4: all 4 miss → score 5 (splash)', () {
      final p = _makeSoloProvider(maxStrokes: 4);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      expect(game.playerHoleScores[pid]![0], 5);
    });

    test('2.13 maxStrokes=5: hit on dart 5 → score 5', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _miss(p); _miss(p); _miss(p); _miss(p);
      _hit(p);
      expect(game.playerHoleScores[pid]![0], 5);
    });

    test('2.14 maxStrokes=5: all 5 miss → score 6 (splash)', () {
      final p = _makeSoloProvider(maxStrokes: 5);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      expect(game.playerHoleScores[pid]![0], 6);
    });

    test('2.15 maxStrokes=6: hit on dart 6 → score 6', () {
      final p = _makeSoloProvider(maxStrokes: 6);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _miss(p); _miss(p); _miss(p); _miss(p); _miss(p);
      _hit(p);
      expect(game.playerHoleScores[pid]![0], 6);
    });

    test('2.16 maxStrokes=6: all 6 miss → score 7 (splash)', () {
      final p = _makeSoloProvider(maxStrokes: 6);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      expect(game.playerHoleScores[pid]![0], 7);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 3 — Turn end conditions
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — turn end conditions', () {
    test('3.1 Early end on target hit: currentTurnEnded = true after hit', () {
      final p = _makeSoloProvider(maxStrokes: 6);
      final game = p.currentGame!;

      _hit(p); // dart 1 hits

      expect(game.currentTurnEnded, isTrue);
    });

    test('3.2 No early end after a miss with darts remaining', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;

      _miss(p); // dart 1 misses

      expect(game.currentTurnEnded, isFalse);
    });

    test('3.3 Full-darts Splash: currentTurnEnded after last dart missed', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;

      _fillMisses(p);

      expect(game.currentTurnEnded, isTrue);
    });

    test('3.4 Skip Turn: currentTurnEnded = true immediately', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;

      p.skipTurn();

      expect(game.currentTurnEnded, isTrue);
    });

    test('3.5 dartsThrown resets after confirmTurnEnd', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      _hit(p); // p1's turn ends
      p.confirmTurnEnd(); // advance to p2

      expect(game.dartsThrown[game.activePlayerId!], 0);
    });

    test('3.6 currentTurnEnded resets to false after confirmTurnEnd', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      _hit(p);
      expect(game.currentTurnEnded, isTrue);
      p.confirmTurnEnd();
      expect(game.currentTurnEnded, isFalse);
    });

    test('3.7 Dart throws after currentTurnEnded = true are ignored', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _hit(p); // turn ends
      final dartsBefore = game.dartsThrown[pid]!;
      _hit(p); // should be ignored
      expect(game.dartsThrown[pid], dartsBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 4 — totalTurns increment
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — totalTurns increment', () {
    test('4.1 totalTurns increments exactly once on first dart of a turn', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      expect(game.totalTurns[pid], 0);

      _miss(p); // first dart
      expect(game.totalTurns[pid], 1);

      _miss(p); // second dart
      expect(game.totalTurns[pid], 1); // still 1

      _miss(p); // third dart → splash
      expect(game.totalTurns[pid], 1); // still 1
    });

    test('4.2 totalTurns = 1 after a hit on dart 1', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _hit(p);
      expect(game.totalTurns[pid], 1);
    });

    test('4.3 totalTurns increments again on mulligan re-throw first dart', () {
      final p = _makeSoloProvider(mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p); // splash → totalTurns = 1
      expect(game.totalTurns[pid], 1);

      p.useMulligan();
      // dartsThrown reset to 0; first dart of mulligan re-throw will increment again

      _miss(p); // first mulligan dart
      expect(game.totalTurns[pid], 2); // incremented again
    });

    test('4.4 totalTurns never increments in confirmTurnEnd', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      final p1 = 'p1';

      _hit(p);
      expect(game.totalTurns[p1], 1);

      p.confirmTurnEnd();
      // After advancing to p2, p1's totalTurns should still be 1
      expect(game.totalTurns[p1], 1);
    });

    test('4.5 totalTurns accumulates across holes', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;
      final pid = 'p1';

      // Hole 1: p1 hits
      _hit(p);
      p.confirmTurnEnd();
      // p2 hits
      _hit(p);
      p.confirmTurnEnd();

      // Hole 2: p1 hits again
      expect(game.activePlayerId, 'p1');
      _hit(p);

      expect(game.totalTurns[pid], 2);
    });

    test('4.6 Skip turn on a 0-dart state increments totalTurns', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      expect(game.dartsThrown[pid], 0);
      p.skipTurn();
      expect(game.totalTurns[pid], 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 5 — Win detection
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — win detection', () {
    test('5.1 Solo: lowest total wins', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1]; // 9
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2]; // 18

      p.endGame();
      expect(game.winnerId, 'p1');
      expect(game.state, TikiGolfGameState.finished);
    });

    test('5.2 Solo tiebreaker: more birdies wins', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // Same total = 19, p1 has 4 birdies, p2 has 1 birdie
      game.playerHoleScores['p1'] = [1, 1, 1, 1, 3, 3, 3, 3, 3]; // 4+15=19
      game.playerHoleScores['p2'] = [2, 2, 2, 3, 2, 2, 3, 2, 1]; // 14+4+1=... let's recalculate
      // p2: 2+2+2+3+2+2+3+2+1 = 19 ✓ birdies=1

      expect(game.totalForPlayer('p1'), 19);
      expect(game.totalForPlayer('p2'), 19);
      expect(game.birdiesForPlayer('p1'), 4);
      expect(game.birdiesForPlayer('p2'), 1);

      p.endGame();
      expect(game.winnerId, 'p1');
    });

    test('5.3 Solo tiebreaker: fewer bogeys wins', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      // Same total = 20, 0 birdies, p1 fewer bogeys
      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 4]; // 1 bogey (4)
      game.playerHoleScores['p2'] = [3, 3, 2, 2, 2, 2, 2, 2, 2]; // 2 bogeys (3s)

      expect(game.totalForPlayer('p1'), 20);
      expect(game.totalForPlayer('p2'), 20);

      p.endGame();
      expect(game.winnerId, 'p1');
    });

    test('5.4 Solo tiebreaker: first in turn order wins when all else equal', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      game.playerHoleScores['p1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['p2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerId, 'p1');
    });

    test('5.5 Team: lowest team total wins', () {
      // 3 players minimum: team_1 has 2, team_2 has 1
      final p = _makeTeamProviderManual(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // team_1 best-ball: min(1,1)=1 × 9 = 9; team_2: 2 × 9 = 18
      game.playerHoleScores['a1'] = [1, 1, 1, 1, 1, 1, 1, 1, 1];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
    });

    test('5.6 Team tiebreaker: more team-birdies wins', () {
      final p = _makeTeamProviderManual(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // team_1 best-ball: [1,1,2,2,2,2,2,2,4]=18, 2 birdies
      // team_2 best-ball: [2,2,2,2,2,2,2,2,2]=18, 0 birdies
      game.playerHoleScores['a1'] = [1, 1, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
    });

    test('5.7 Team tiebreaker: fewer team-bogeys wins', () {
      final p = _makeTeamProviderManual(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // team_1 best-ball: [2,2,2,2,2,2,2,2,4]=20, 0 birdies, 1 bogey (4)
      // team_2 best-ball: [2,2,2,2,2,2,2,3,3]=20, 0 birdies, 2 bogeys
      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 4];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 3, 3];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
    });

    test('5.8 Team tiebreaker: team that finished first (lower index) wins', () {
      final p = _makeTeamProviderManual(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Identical best-ball scores; team_1 index=0 → wins
      game.playerHoleScores['a1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['a2'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];
      game.playerHoleScores['b1'] = [2, 2, 2, 2, 2, 2, 2, 2, 2];

      p.endGame();
      expect(game.winnerTeamId, 'team_1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 6 — Per-option side-effects
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — per-option side-effects', () {
    test('6.1 mulliganEnabled ON: useMulligan succeeds after splash', () {
      final p = _makeSoloProvider(mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      p.useMulligan();

      expect(game.playerMulligansUsed[pid], 1);
      expect(game.currentTurnEnded, isFalse);
    });

    test('6.2 mulliganEnabled OFF: useMulligan does nothing', () {
      final p = _makeSoloProvider(mulliganEnabled: false);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;

      _fillMisses(p);
      p.useMulligan();

      expect(game.playerMulligansUsed[pid], 0);
      expect(game.currentTurnEnded, isTrue); // still ended
    });

    test('6.3 maxStrokes value determines Splash threshold', () {
      for (final ms in [3, 4, 5, 6]) {
        final p = _makeSoloProvider(maxStrokes: ms);
        final game = p.currentGame!;
        final pid = game.activePlayerId!;

        _fillMisses(p);
        expect(game.playerHoleScores[pid]![0], ms + 1,
            reason: 'maxStrokes=$ms → splash should be ${ms + 1}');
      }
    });

    test('6.4 maxStrokes persists through serialization', () {
      for (final ms in [3, 4, 5, 6]) {
        final p = _makeSoloProvider(maxStrokes: ms);
        final json = p.currentGame!.toJson();
        final restored = TikiGolfGame.fromJson(json);
        expect(restored.maxStrokes, ms);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 7 — Round/match transitions
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — round/match transitions', () {
    test('7.1 _advanceToNextHole resets within-hole rotation for teams', () {
      final p = _makeTeamProviderManual(teamPlayers: {
        'team_1': ['a1', 'a2'],
        'team_2': ['b1'],
      });
      final game = p.currentGame!;

      // Complete hole 1
      _hit(p); p.confirmTurnEnd(); // a1
      _hit(p); p.confirmTurnEnd(); // a2
      _hit(p); p.confirmTurnEnd(); // b1 → advance to hole 2

      expect(game.currentHole, 2);
      expect(game.activePlayerId, 'a1'); // rotation reset
      expect(game.currentTeamIndex, 0);
      expect(game.teamWithinHoleRotationPointer['team_1'], 0);
    });

    test('7.2 Game ends (state=finished) after hole 9', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);
      final game = p.currentGame!;

      for (int h = 0; h < 9; h++) {
        _hit(p); p.confirmTurnEnd();
        _hit(p); p.confirmTurnEnd();
      }

      expect(game.state, TikiGolfGameState.finished);
    });

    test('7.3 Winner is set when game ends after hole 9', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);

      for (int h = 0; h < 9; h++) {
        _hit(p); p.confirmTurnEnd();
        _hit(p); p.confirmTurnEnd();
      }

      expect(p.currentGame!.winnerId, isNotNull);
    });

    test('7.4 isGameActive becomes false after game ends', () {
      final p = _makeSoloProvider(playerIds: ['p1', 'p2']);

      for (int h = 0; h < 9; h++) {
        _hit(p); p.confirmTurnEnd();
        _hit(p); p.confirmTurnEnd();
      }

      expect(p.isGameActive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 8 — editPlayerScore replay
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — editPlayerScore', () {
    test('8.1 Editing a Splash to a birdie updates the score', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      // Set a splash manually
      game.playerHoleScores[pid]![0] = game.maxStrokes + 1;

      // Edit to birdie
      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: ['S$target'],
      );

      expect(game.playerHoleScores[pid]![0], 1);
    });

    test('8.2 Undoing a Splash gives the mulligan back', () {
      final p = _makeSoloProvider(mulliganEnabled: true);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];

      // Record a splash and mark mulligan as used
      _fillMisses(p);
      expect(game.playerHoleScores[pid]![0], game.maxStrokes + 1);
      game.playerMulligansUsed[pid] = 1; // simulating mulligan was used

      // Edit to remove the splash
      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: ['S$target'], // birdie
      );

      expect(game.playerHoleScores[pid]![0], 1);
      expect(game.playerMulligansUsed[pid], 0); // mulligan restored
    });

    test('8.3 Changing a birdie to a par updates totalForPlayer', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];
      final missNum = target == 1 ? 2 : 1;

      // Set birdie
      game.playerHoleScores[pid]![0] = 1;

      // Edit to par (2 darts)
      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: ['S$missNum', 'S$target'],
      );

      expect(game.playerHoleScores[pid]![0], 2);
    });

    test('8.4 editPlayerScore handles all-miss input as Splash', () {
      final p = _makeSoloProvider(maxStrokes: 3);
      final game = p.currentGame!;
      final pid = game.activePlayerId!;
      final target = game.holeTargets[0];
      final missNum = target == 1 ? 2 : 1;

      game.playerHoleScores[pid]![0] = 1; // was birdie

      p.editPlayerScore(
        playerId: pid,
        holeIndex: 0,
        newDartSegments: ['S$missNum', 'S$missNum', 'S$missNum'], // 3 misses → splash
      );

      expect(game.playerHoleScores[pid]![0], 4); // maxStrokes + 1
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 9 — endGame and resumedSavedGameId
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider — endGame and save-id tracking', () {
    test('9.1 endGame sets state to finished', () {
      final p = _makeSoloProvider();
      p.endGame();
      expect(p.currentGame!.state, TikiGolfGameState.finished);
    });

    test('9.2 endGame sets isGameActive to false', () {
      final p = _makeSoloProvider();
      p.endGame();
      expect(p.isGameActive, isFalse);
    });

    test('9.3 resumedSavedGameId is null initially', () {
      final p = _makeSoloProvider();
      expect(p.resumedSavedGameId, isNull);
    });

    test('9.4 clearResumedSavedGameId sets it to null', () {
      final p = _makeSoloProvider();
      // Simulate having a resumed ID
      p.restoreGame(_makeFakeSavedGame());
      expect(p.resumedSavedGameId, isNotNull);

      p.clearResumedSavedGameId();
      expect(p.resumedSavedGameId, isNull);
    });

    test('9.5 restoreGame restores game state from saved metadata', () {
      final p = _makeSoloProvider();
      final game = p.currentGame!;

      // Advance to hole 3
      game.currentHole = 3;
      final json = game.toJson();

      // Create a new provider and restore
      final p2 = TikiGolfProvider();
      p2.restoreGame(_makeFakeSavedGameFromJson(json, 'test-id-123'));

      expect(p2.currentGame!.currentHole, 3);
      expect(p2.resumedSavedGameId, 'test-id-123');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 10 — Random distribution full table
  // ─────────────────────────────────────────────────────────────────────────────
  group('TikiGolfProvider.randomDistribution — full table', () {
    // Authoritative distribution table from spec Section 5.
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
      test('10.N${row.n}: N=${row.n} → T=${row.t}, sizes=${row.sizes}', () {
        final result = TikiGolfProvider.randomDistribution(row.n);

        expect(result.teamCount, row.t,
            reason: 'N=${row.n}: expected teamCount=${row.t}');

        final sortedActual = List<int>.from(result.sizes)
          ..sort((a, b) => b.compareTo(a));
        final sortedExpected = List<int>.from(row.sizes)
          ..sort((a, b) => b.compareTo(a));

        expect(sortedActual, sortedExpected,
            reason: 'N=${row.n}: expected sizes (sorted)=$sortedExpected, got $sortedActual');

        // Also verify the sum equals N
        expect(result.sizes.fold<int>(0, (s, v) => s + v), row.n,
            reason: 'N=${row.n}: sum of sizes should equal N');
      });
    }
  });
}

// ─── Fake SavedGameMetadata helper ───────────────────────────────────────────

SavedGameMetadata _makeFakeSavedGame() {
  final p = TikiGolfProvider();
  p.startGame(
    playerIds: ['p1', 'p2'],
    maxStrokes: 3,
    mulliganEnabled: false,
    gameMode: TikiGolfGameMode.solo,
    teamAssignment: TikiGolfTeamAssignment.random,
  );
  return SavedGameMetadata.create(
    gameType: 'tiki_golf',
    playerNames: ['Player 1', 'Player 2'],
    progressInfo: 'Hole 1 of 9',
    gameModeName: 'Solo, Max Darts: 3',
    leadingPlayerName: 'Player 1',
    leadingPlayerScore: '0 holes completed',
    gameState: p.currentGame!.toJson(),
    waitingForTakeout: false,
  );
}

SavedGameMetadata _makeFakeSavedGameFromJson(
    Map<String, dynamic> gameJson, String id) {
  return SavedGameMetadata(
    id: id,
    gameType: 'tiki_golf',
    savedAt: DateTime.now(),
    playerNames: ['Player 1', 'Player 2'],
    progressInfo: 'Hole 1 of 9',
    gameModeName: 'Solo, Max Darts: 3',
    leadingPlayerName: 'Player 1',
    leadingPlayerScore: '0 holes completed',
    gameState: gameJson,
    waitingForTakeout: false,
  );
}
