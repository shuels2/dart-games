import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/lunar_lander_provider.dart';
import 'package:dart_games/models/lunar_lander_game.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import '../shared/mock_api_helpers.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Creates a provider with a started 2-player game at 200 altitude, Hard Landing OFF.
LunarLanderProvider _makeProvider({
  List<String> playerIds = const ['p1', 'p2'],
  int startingAltitude = 200,
  bool hardLandingEnabled = false,
}) {
  final server = MockApiServer();
  final p = LunarLanderProvider(apiClient: server.apiClient);
  p.startGame(
    playerIds: playerIds,
    startingAltitude: startingAltitude,
    hardLandingEnabled: hardLandingEnabled,
  );
  return p;
}

/// Creates a provider WITHOUT starting a game.
LunarLanderProvider _makeIdleProvider() {
  final server = MockApiServer();
  return LunarLanderProvider(apiClient: server.apiClient);
}

/// Throws a miss dart (score 0).
void miss(LunarLanderProvider p) =>
    p.processDartThrow(score: 0, multiplier: 1, sector: 'Miss');

/// Throws a small-value dart that will never win for normal altitudes.
void smallDart(LunarLanderProvider p) =>
    p.processDartThrow(score: 1, multiplier: 1, sector: 'S1');

/// Throws 3 small darts to fill a turn without winning.
void fillTurn(LunarLanderProvider p) {
  for (int i = 0; i < 3; i++) {
    if (p.shouldPromptTakeout) break;
    smallDart(p);
  }
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Initial state
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — initial state', () {
    test('isGameActive is false before startGame', () {
      final p = _makeIdleProvider();
      expect(p.isGameActive, isFalse);
    });

    test('currentGame is null before startGame', () {
      final p = _makeIdleProvider();
      expect(p.currentGame, isNull);
    });

    test('getCurrentPlayerId returns null before startGame', () {
      final p = _makeIdleProvider();
      expect(p.getCurrentPlayerId(), isNull);
    });

    test('getCurrentPlayerDartsThrown returns 0 before startGame', () {
      final p = _makeIdleProvider();
      expect(p.getCurrentPlayerDartsThrown(), 0);
    });

    test('shouldPromptTakeout is false before startGame', () {
      final p = _makeIdleProvider();
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('hasWinner is false before startGame', () {
      final p = _makeIdleProvider();
      expect(p.hasWinner, isFalse);
    });

    test('startGame with fewer than 2 players is rejected', () {
      final p = _makeIdleProvider();
      p.startGame(
        playerIds: ['p1'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      expect(p.isGameActive, isFalse);
      expect(p.currentGame, isNull);
    });

    test('startGame with more than 8 players is rejected', () {
      final p = _makeIdleProvider();
      p.startGame(
        playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      expect(p.isGameActive, isFalse);
      expect(p.currentGame, isNull);
    });

    test('startGame with 2 players sets isGameActive true', () {
      final p = _makeProvider();
      expect(p.isGameActive, isTrue);
      expect(p.currentGame, isNotNull);
    });

    test('startGame sets all player altitudes to startingAltitude', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2', 'p3'], startingAltitude: 300);
      for (final id in ['p1', 'p2', 'p3']) {
        expect(p.getCurrentAltitude(id), 300);
      }
    });

    test('startGame sets dartsThrown to 0 for each player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      expect(p.currentGame!.dartsThrown['p1'], 0);
      expect(p.currentGame!.dartsThrown['p2'], 0);
    });

    test('startGame sets totalDartsThrown to 0 for each player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      expect(p.currentGame!.totalDartsThrown['p1'], 0);
      expect(p.currentGame!.totalDartsThrown['p2'], 0);
    });

    test('startGame sets totalTurns to 0 for each player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      expect(p.currentGame!.totalTurns['p1'], 0);
      expect(p.currentGame!.totalTurns['p2'], 0);
    });

    test('startGame sets first player as current player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      expect(p.getCurrentPlayerId(), 'p1');
    });

    test('startGame sets state to playing', () {
      final p = _makeProvider();
      expect(p.currentGame!.state, LunarLanderGameState.playing);
    });

    test('startGame stores hardLandingEnabled option on the game', () {
      final p = _makeProvider(hardLandingEnabled: true);
      expect(p.currentGame!.hardLandingEnabled, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. processDartThrow — single multipliers and miss
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — processDartThrow multipliers', () {
    test('single (×1) hit subtracts face value from altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.getCurrentAltitude('p1'), 180);
    });

    test('double (×2) hit subtracts 2× face value from altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 20, multiplier: 2, sector: 'D20');
      expect(p.getCurrentAltitude('p1'), 160); // 200 - 40
    });

    test('triple (×3) hit subtracts 3× face value from altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20');
      expect(p.getCurrentAltitude('p1'), 140); // 200 - 60
    });

    test('Bullseye (score=50, ×1) subtracts 50 from altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 50, multiplier: 1, sector: 'Bull');
      expect(p.getCurrentAltitude('p1'), 150);
    });

    test('Outer Bull (score=25, ×1) subtracts 25 from altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 25, multiplier: 1, sector: '25');
      expect(p.getCurrentAltitude('p1'), 175);
    });

    test('miss (score=0) does not change altitude', () {
      final p = _makeProvider(startingAltitude: 200);
      miss(p);
      expect(p.getCurrentAltitude('p1'), 200);
    });

    test('currentTurnDartSegments records sector string for each dart', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      p.processDartThrow(score: 20, multiplier: 2, sector: 'D20');
      expect(p.getCurrentTurnDartSegments('p1'), ['S20', 'D20']);
    });

    test('currentTurnDartScores records dart value (score×mult) for each dart', () {
      final p = _makeProvider(startingAltitude: 200);
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.processDartThrow(score: 10, multiplier: 2, sector: 'D10');
      // dartValues: 10 and 20
      expect(p.currentGame!.currentTurnDartScores['p1'], [10, 20]);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Turn advancement
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — turn advancement', () {
    test('shouldPromptTakeout is false after 2 darts', () {
      final p = _makeProvider();
      smallDart(p);
      smallDart(p);
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('shouldPromptTakeout is true after 3 darts', () {
      final p = _makeProvider();
      smallDart(p);
      smallDart(p);
      smallDart(p);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('processDartThrow is no-op when game is not active (endGame called)', () {
      final p = _makeProvider();
      p.endGame();
      smallDart(p);
      // totalDartsThrown should remain 0 (no dart was processed)
      expect(p.currentGame!.totalDartsThrown['p1'], 0);
    });

    test('processDartThrow is no-op when waitingForTakeout', () {
      final p = _makeProvider();
      fillTurn(p); // 3 darts → waitingForTakeout
      expect(p.shouldPromptTakeout, isTrue);
      // 4th dart must be ignored
      smallDart(p);
      expect(p.getCurrentPlayerDartsThrown(), 3);
    });

    test('advanceTurn resets dartsThrown for the player that just moved', () {
      final p = _makeProvider();
      fillTurn(p);
      p.advanceTurn();
      // p1 advanced; their dartsThrown is reset
      expect(p.currentGame!.dartsThrown['p1'], 0);
    });

    test('advanceTurn resets currentTurnDartSegments for the player that just moved', () {
      final p = _makeProvider();
      smallDart(p);
      smallDart(p);
      smallDart(p);
      p.advanceTurn();
      expect(p.currentGame!.currentTurnDartSegments['p1'], isEmpty);
    });

    test('advanceTurn switches from p1 to p2', () {
      final p = _makeProvider();
      fillTurn(p);
      p.advanceTurn();
      expect(p.getCurrentPlayerId(), 'p2');
    });

    test('advanceTurn switches from p2 back to p1', () {
      final p = _makeProvider();
      fillTurn(p);
      p.advanceTurn(); // → p2
      fillTurn(p);
      p.advanceTurn(); // → p1
      expect(p.getCurrentPlayerId(), 'p1');
    });

    test('advanceTurn is no-op when not waitingForTakeout', () {
      final p = _makeProvider();
      p.advanceTurn(); // no darts thrown yet, not waiting
      expect(p.getCurrentPlayerId(), 'p1'); // still p1
    });

    test('totalTurns increments on first dart only, not second or third', () {
      final p = _makeProvider();
      expect(p.currentGame!.totalTurns['p1'], 0);
      smallDart(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
      smallDart(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
      smallDart(p);
      expect(p.currentGame!.totalTurns['p1'], 1);
    });

    test('totalDartsThrown accumulates across multiple turns for each player', () {
      final p = _makeProvider(startingAltitude: 200);
      fillTurn(p); // p1: 3 darts
      p.advanceTurn();
      fillTurn(p); // p2: 3 darts
      p.advanceTurn();
      fillTurn(p); // p1: 3 more darts
      expect(p.currentGame!.totalDartsThrown['p1'], 6);
      expect(p.currentGame!.totalDartsThrown['p2'], 3);
    });

    test('skipTurn sets shouldPromptTakeout after 0 darts', () {
      final p = _makeProvider();
      p.skipTurn();
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('skipTurn from 0 darts adds 3 Miss markers to currentTurnDartSegments', () {
      final p = _makeProvider();
      p.skipTurn();
      final segs = p.getCurrentTurnDartSegments('p1');
      expect(segs, ['Miss', 'Miss', 'Miss']);
    });

    test('skipTurn after 1 dart adds 2 Miss markers for remaining slots', () {
      final p = _makeProvider();
      smallDart(p);
      p.skipTurn();
      final segs = p.getCurrentTurnDartSegments('p1');
      expect(segs.length, 3);
      expect(segs[1], 'Miss');
      expect(segs[2], 'Miss');
    });

    test('skipTurn is no-op when already waitingForTakeout', () {
      final p = _makeProvider();
      fillTurn(p);
      final segsBefore = List<String>.from(p.getCurrentTurnDartSegments('p1'));
      p.skipTurn();
      expect(p.getCurrentTurnDartSegments('p1'), segsBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Win detection
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — win detection', () {
    test('altitude exactly 0 triggers win with correct winnerId', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, 'p1');
    });

    test('win sets state to finished', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.currentGame!.state, LunarLanderGameState.finished);
    });

    test('win sets isGameActive to false', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.isGameActive, isFalse);
    });

    test('win sets shouldPromptTakeout true (takeout prompt required after win)', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('with Hard Landing OFF: negative altitude (overshoot) triggers win', () {
      final p = _makeProvider(
          startingAltitude: 30, hardLandingEnabled: false);
      p.processDartThrow(score: 20, multiplier: 2, sector: 'D20'); // 40 > 30 → -10
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, 'p1');
    });

    test('advanceTurn after win clears takeout but does not advance player', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1 wins
      expect(p.shouldPromptTakeout, isTrue);
      p.advanceTurn();
      // winnerId must still be p1 (game does not advance after win)
      expect(p.currentGame!.winnerId, 'p1');
      expect(p.currentGame!.state, LunarLanderGameState.finished);
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('checkWinCondition returns true after win', () {
      final p = _makeProvider(startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      expect(p.checkWinCondition(), isTrue);
    });

    test('checkWinCondition returns false before any win', () {
      final p = _makeProvider(startingAltitude: 200);
      expect(p.checkWinCondition(), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Hard Landing bust path
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — Hard Landing bust path', () {
    test('bust reverts altitude to turn-start value', () {
      // Reduce p1's altitude over turn 1, advance, then bust on turn 2
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 50→40
      p.processDartThrow(score: 5, multiplier: 1, sector: 'S5');   // 40→35
      p.processDartThrow(score: 5, multiplier: 1, sector: 'S5');   // 35→30
      p.advanceTurn(); // p2 turn
      fillTurn(p);
      p.advanceTurn(); // back to p1, turnStartAltitude snapped at 30
      // Now bust: value 60 > 30
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20');
      expect(p.getCurrentAltitude('p1'), 30); // reverted to turn-start
    });

    test('bust marks the dart in getDartThrowWasBust as true', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // 60 > 50 → bust
      expect(p.getDartThrowWasBust('p1').last, isTrue);
    });

    test('bust forfeits remaining darts (dartsThrown set to maxDartsPerTurn)', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // bust on first dart
      expect(p.currentGame!.dartsThrown['p1'],
          p.currentGame!.maxDartsPerTurn);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('bust does NOT set winnerId', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // bust
      expect(p.currentGame!.winnerId, isNull);
      expect(p.hasWinner, isFalse);
    });

    test('bust dart sector string is recorded in currentTurnDartSegments', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20');
      expect(p.getCurrentTurnDartSegments('p1'), contains('T20'));
    });

    test('after bust, advanceTurn advances to next player', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: true);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // bust → waitingForTakeout
      p.advanceTurn();
      expect(p.getCurrentPlayerId(), 'p2');
    });

    test('Hard Landing OFF: overshoot wins instead of busting', () {
      final p = _makeProvider(
          startingAltitude: 50, hardLandingEnabled: false);
      p.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // 60 > 50 → win
      expect(p.hasWinner, isTrue);
      expect(p.getDartThrowWasBust('p1').last, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. editPlayerScore replay / turn undo
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — editPlayerScore turn undo', () {
    test('editPlayerScore replays from turn-start altitude and updates result', () {
      final p = _makeProvider(startingAltitude: 100);
      // Throw 3 darts: 10+10+10=30 → altitude 70
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(p.getCurrentAltitude('p1'), 70);

      // Edit dart 0: change 10→20; new total: 20+10+10=40 → altitude 60
      p.editPlayerScore(
          playerId: 'p1', dartIndex: 0, newScore: 20, newMultiplier: 1);
      expect(p.getCurrentAltitude('p1'), 60);
    });

    test('editPlayerScore for non-current player is ignored', () {
      final p = _makeProvider(startingAltitude: 100);
      // p1 is active; attempt to edit p2 (not current player)
      p.editPlayerScore(
          playerId: 'p2', dartIndex: 0, newScore: 99, newMultiplier: 1);
      // p2's altitude must remain unchanged at startingAltitude
      expect(p.getCurrentAltitude('p2'), 100);
    });

    test('editPlayerScore undoes win if new dart sequence does not win', () {
      final p = _makeProvider(
          startingAltitude: 20, hardLandingEnabled: false);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1 wins
      expect(p.hasWinner, isTrue);

      // Edit dart 0 to a small value — no longer wins
      p.editPlayerScore(
          playerId: 'p1', dartIndex: 0, newScore: 5, newMultiplier: 1);
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.winnerId, isNull);
      expect(p.currentGame!.state, LunarLanderGameState.playing);
      expect(p.isGameActive, isTrue);
    });

    test('editPlayerScore preserves other player\'s altitude', () {
      final p = _makeProvider(startingAltitude: 100);
      // p1 fills their turn without scoring (miss × 3)
      miss(p);
      miss(p);
      miss(p);
      p.advanceTurn(); // → p2

      // p2 throws 1 dart (score=1 → altitude 99), then skips remaining
      smallDart(p);
      p.skipTurn(); // forfeit remaining 2 darts
      p.advanceTurn(); // → p1

      // p2's altitude should be 99 after exactly 1 smallDart
      expect(p.getCurrentAltitude('p2'), 99);

      // p1 now throws a dart and edits it; p2 altitude must stay 99
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.editPlayerScore(
          playerId: 'p1', dartIndex: 0, newScore: 5, newMultiplier: 1);
      expect(p.getCurrentAltitude('p2'), 99);
    });

    test('editPlayerScore with dartIndex beyond thrown darts is a no-op', () {
      final p = _makeProvider(startingAltitude: 100);
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 1 dart thrown
      // dartIndex=5 is out of range (only 1 dart recorded)
      p.editPlayerScore(
          playerId: 'p1', dartIndex: 5, newScore: 20, newMultiplier: 1);
      // Altitude should remain at what it was after the 1 dart (90)
      expect(p.getCurrentAltitude('p1'), 90);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. Multi-player turn cycle
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — multi-player turn cycle', () {
    test('4-player cycle P1→P2→P3→P4→P1', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2', 'p3', 'p4'], startingAltitude: 200);
      final order = ['p1', 'p2', 'p3', 'p4', 'p1'];
      for (int i = 0; i < 4; i++) {
        expect(p.getCurrentPlayerId(), order[i]);
        fillTurn(p);
        p.advanceTurn();
      }
      expect(p.getCurrentPlayerId(), order[4]);
    });

    test('each player\'s altitude is tracked independently', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 200);
      // p1 throws 20+20+20 → altitude 140
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20');
      p.advanceTurn();
      // p2 throws 10+10+10 → altitude 170
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      p.advanceTurn();
      expect(p.getCurrentAltitude('p1'), 140);
      expect(p.getCurrentAltitude('p2'), 170);
    });

    test('getCurrentAltitude for non-active player returns their own altitude', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 100);
      // It's p1's turn; p2 altitude should still be at startingAltitude
      expect(p.getCurrentAltitude('p2'), 100);
    });

    test('winning player does not affect other players\' altitudes', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 20);
      p.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1 wins
      // p2 was never touched; altitude unchanged
      expect(p.getCurrentAltitude('p2'), 20);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. Character assignment
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — character assignment', () {
    test('getCharacter returns a non-null LunarLanderCharacter for each player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2', 'p3']);
      for (final id in ['p1', 'p2', 'p3']) {
        expect(p.getCharacter(id), isNotNull);
        expect(p.getCharacter(id), isA<LunarLanderCharacter>());
      }
    });

    test('characters are unique across all 8 players (no duplicates)', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          startingAltitude: 200);
      final chars = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8']
          .map((id) => p.getCharacter(id))
          .toSet();
      expect(chars.length, 8);
    });

    test('getCharacter returns null before startGame', () {
      final p = _makeIdleProvider();
      expect(p.getCharacter('p1'), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. endGame and clearGame
  // ─────────────────────────────────────────────────────────────────────────────

  group('LunarLanderProvider — endGame and clearGame', () {
    test('endGame sets isGameActive to false', () {
      final p = _makeProvider();
      p.endGame();
      expect(p.isGameActive, isFalse);
    });

    test('endGame sets state to finished', () {
      final p = _makeProvider();
      p.endGame();
      expect(p.currentGame!.state, LunarLanderGameState.finished);
    });

    test('endGame does not clear currentGame (currentGame remains non-null)', () {
      final p = _makeProvider();
      p.endGame();
      expect(p.currentGame, isNotNull);
    });

    test('clearGame removes currentGame entirely', () {
      final p = _makeProvider();
      p.clearGame();
      expect(p.currentGame, isNull);
    });

    test('clearGame sets isGameActive to false', () {
      final p = _makeProvider();
      p.clearGame();
      expect(p.isGameActive, isFalse);
    });

    test('clearGame resets shouldPromptTakeout to false', () {
      final p = _makeProvider();
      fillTurn(p);
      expect(p.shouldPromptTakeout, isTrue);
      p.clearGame();
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('resumedSavedGameId is null by default', () {
      final p = _makeIdleProvider();
      expect(p.resumedSavedGameId, isNull);
    });

    test('clearResumedSavedGameId resets resumedSavedGameId to null after restoreGame', () {
      final server = MockApiServer();
      final p = LunarLanderProvider(apiClient: server.apiClient);
      p.startGame(
        playerIds: ['p1', 'p2'],
        startingAltitude: 200,
        hardLandingEnabled: false,
      );
      final gameJson = p.currentGame!.toJson();
      final metadata = SavedGameMetadata(
        id: 'test-save-id',
        gameType: 'lunar_lander',
        savedAt: DateTime.now(),
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Altitude: 200 / 200',
        gameModeName: 'Alt: 200',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: 'Alt: 200',
        gameState: gameJson,
        waitingForTakeout: false,
      );
      p.restoreGame(metadata);
      expect(p.resumedSavedGameId, 'test-save-id');
      p.clearResumedSavedGameId();
      expect(p.resumedSavedGameId, isNull);
    });
  });
}
