import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/gladiator_arena_game.dart';
import 'package:dart_games/providers/gladiator_arena_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

GladiatorArenaGame createGame({
  List<String>? playerIds,
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
}) {
  final ids = playerIds ?? ['p1', 'p2'];
  return GladiatorArenaGame.create(
    playerIds: ids,
    targetScore: targetScore,
    doubleFinishEnabled: doubleFinishEnabled,
    shieldRoundEnabled: shieldRoundEnabled,
    speedPlayEnabled: speedPlayEnabled,
  );
}

GladiatorArenaProvider createProvider({
  List<String>? playerIds,
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
}) {
  final ids = playerIds ?? ['p1', 'p2'];
  final p = GladiatorArenaProvider();
  p.startGame(
    playerIds: ids,
    targetScore: targetScore,
    doubleFinishEnabled: doubleFinishEnabled,
    shieldRoundEnabled: shieldRoundEnabled,
    speedPlayEnabled: speedPlayEnabled,
  );
  return p;
}

/// Throw a dart to a specific player via provider.
void throwDart(GladiatorArenaProvider p, int score, String multiplier, String sector) {
  p.processDartThrow(score: score, multiplier: multiplier, sector: sector);
}

/// Throw 3 misses to fill a turn.
void fillTurnWithMisses(GladiatorArenaProvider p) {
  for (int i = 0; i < 3; i++) {
    if (p.shouldPromptTakeout) break;
    throwDart(p, 0, 'miss', 'Miss');
  }
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // Group 1 — GladiatorArenaGame model
  // ═══════════════════════════════════════════════════════════════════
  group('GladiatorArenaGame model', () {
    test('1. Default construction initialises all players at score 0', () {
      final game = createGame(playerIds: ['p1', 'p2', 'p3']);
      expect(game.scores['p1'], 0);
      expect(game.scores['p2'], 0);
      expect(game.scores['p3'], 0);
    });

    test('2. Default options: targetScore=200, DF=true, shield=false, speed=false', () {
      final game = createGame();
      expect(game.targetScore, 200);
      expect(game.doubleFinishEnabled, isTrue);
      expect(game.shieldRoundEnabled, isFalse);
      expect(game.speedPlayEnabled, isFalse);
    });

    test('3. round starts at 1, currentPlayerIndex starts at 0', () {
      final game = createGame();
      expect(game.round, 1);
      expect(game.currentPlayerIndex, 0);
    });

    test('4. isShieldRound is false when shieldRoundEnabled=false', () {
      final game = createGame(shieldRoundEnabled: false);
      game.round = 5;
      expect(game.isShieldRound, isFalse);
    });

    test('5. isShieldRound is true when shieldRoundEnabled=true and round%5==0', () {
      final game = createGame(shieldRoundEnabled: true);
      game.round = 5;
      expect(game.isShieldRound, isTrue);
    });

    test('6. isShieldRound is false when shieldRoundEnabled=true but round%5!=0', () {
      final game = createGame(shieldRoundEnabled: true);
      game.round = 6;
      expect(game.isShieldRound, isFalse);
    });

    test('7. toJson round-trip preserves all top-level fields', () {
      final game = createGame(
        playerIds: ['p1', 'p2'],
        targetScore: 300,
        doubleFinishEnabled: false,
        shieldRoundEnabled: true,
        speedPlayEnabled: true,
      );
      game.scores['p1'] = 80;
      game.scores['p2'] = 60;
      game.knockoffsDealt['p1'] = 2;
      game.knockoffsReceived['p2'] = 2;
      game.round = 3;

      final json = game.toJson();
      final restored = GladiatorArenaGame.fromJson(json);

      expect(restored.targetScore, 300);
      expect(restored.doubleFinishEnabled, isFalse);
      expect(restored.shieldRoundEnabled, isTrue);
      expect(restored.speedPlayEnabled, isTrue);
      expect(restored.scores['p1'], 80);
      expect(restored.scores['p2'], 60);
      expect(restored.knockoffsDealt['p1'], 2);
      expect(restored.knockoffsReceived['p2'], 2);
      expect(restored.round, 3);
    });

    test('8. toJson/fromJson with null endedAt, winnerId, lastKnockoff* fields', () {
      final game = createGame();
      final json = game.toJson();
      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.endedAt, isNull);
      expect(restored.winnerId, isNull);
      expect(restored.lastKnockoffVictimId, isNull);
      expect(restored.lastKnockoffAttackerId, isNull);
      expect(restored.lastKnockoffAt, isNull);
    });

    test('9. toJson/fromJson with speedPlayTimeRemaining set', () {
      final game = createGame(speedPlayEnabled: true);
      game.speedPlayTimeRemaining = 12;
      final json = game.toJson();
      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.speedPlayTimeRemaining, 12);
    });

    test('10. fromJson with null speedPlayTimeRemaining returns null', () {
      final game = createGame();
      // speedPlayTimeRemaining not set → should be null
      final json = game.toJson();
      expect(json['speedPlayTimeRemaining'], isNull);
      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.speedPlayTimeRemaining, isNull);
    });

    test('11. currentTurnDartValues and currentTurnDartSegments round-trip', () {
      final game = createGame();
      game.currentTurnDartValues['p1'] = [20, 40, 60];
      game.currentTurnDartSegments['p1'] = ['S20', 'D20', 'T20'];
      final json = game.toJson();
      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.currentTurnDartValues['p1'], [20, 40, 60]);
      expect(restored.currentTurnDartSegments['p1'], ['S20', 'D20', 'T20']);
    });

    test('12. GladiatorArenaGameState round-trips through toJson/fromJson', () {
      final game = createGame();
      game.state = GladiatorArenaGameState.finished;
      game.winnerId = 'p1';
      game.endedAt = DateTime.now();
      final json = game.toJson();
      final restored = GladiatorArenaGame.fromJson(json);
      expect(restored.state, GladiatorArenaGameState.finished);
      expect(restored.winnerId, 'p1');
      expect(restored.endedAt, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 2 — GladiatorArenaProvider via screen-level integration
  // ═══════════════════════════════════════════════════════════════════
  group('GladiatorArenaProvider via screen-level integration', () {
    test('13. startGame initialises all scores to 0', () {
      final p = createProvider();
      for (final id in ['p1', 'p2']) {
        expect(p.currentGame!.scores[id], 0);
      }
    });

    test('14. startGame sets state to playing', () {
      final p = createProvider();
      expect(p.isGameActive, isTrue);
    });

    test('15. Scoring via processDartThrow accumulates correctly', () {
      final p = createProvider(playerIds: ['p1', 'p2']);
      final playerId = p.currentPlayerId!;

      throwDart(p, 20, 'single', 'S20');
      throwDart(p, 20, 'double', 'D20');
      throwDart(p, 20, 'triple', 'T20');

      // After 3 darts (S20=20, D20=40, T20=60 = 120 total)
      // shouldPromptTakeout is now true
      expect(p.shouldPromptTakeout, isTrue);

      // Score updates after turn end (prospective < target → normal)
      expect(p.currentGame!.scores[playerId], 120);
    });

    test('16. Win detection: DF ON with double on exact target = VICTORY', () {
      // p1 at score 160, throw D20 (40) → 200 exact, last dart double
      final p = createProvider(playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: true);
      final playerId = p.currentPlayerId!;
      p.currentGame!.scores[playerId] = 160;

      throwDart(p, 0, 'miss', 'Miss');    // dart 1: 0
      throwDart(p, 0, 'miss', 'Miss');    // dart 2: 0
      throwDart(p, 20, 'double', 'D20'); // dart 3: 40 → 200 exact, double → WIN

      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, playerId);
    });

    test('17. Win detection: DF ON with non-double on exact target = BUST (no winner)', () {
      final p = createProvider(playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: true);
      final playerId = p.currentPlayerId!;
      p.currentGame!.scores[playerId] = 180;

      throwDart(p, 0, 'miss', 'Miss');    // dart 1: 0
      throwDart(p, 0, 'miss', 'Miss');    // dart 2: 0
      throwDart(p, 20, 'single', 'S20'); // dart 3: 20 → 200 exact, NOT a double → BUST

      expect(p.hasWinner, isFalse);
      // Score stays at pre-turn value (bust reverts)
      expect(p.currentGame!.scores[playerId], 180);
    });

    test('18. Win detection: DF ON with overshoot = BUST (score unchanged)', () {
      final p = createProvider(playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: true);
      final playerId = p.currentPlayerId!;
      p.currentGame!.scores[playerId] = 180;

      throwDart(p, 20, 'triple', 'T20'); // dart 1: 60
      throwDart(p, 0, 'miss', 'Miss');    // dart 2: 0
      throwDart(p, 0, 'miss', 'Miss');    // dart 3: 0 → prospective 240 > 200 → BUST

      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores[playerId], 180);
    });

    test('19. Win detection: DF OFF with overshoot = VICTORY (no bust)', () {
      final p = createProvider(playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      final playerId = p.currentPlayerId!;
      p.currentGame!.scores[playerId] = 180;

      throwDart(p, 20, 'triple', 'T20'); // dart 1: 60
      throwDart(p, 0, 'miss', 'Miss');    // dart 2: 0
      throwDart(p, 0, 'miss', 'Miss');    // dart 3: 0 → prospective 240 ≥ 200 → VICTORY

      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, playerId);
    });

    test('20. Knockoff: player A score matches player B → B resets to 0', () {
      // Use a seeded random so currentPlayerIndex=0 (p1) is deterministic
      final p = GladiatorArenaProvider();
      p.startGame(
        playerIds: ['p1', 'p2'],
        targetScore: 500,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        random: Random(0), // Random(0).nextInt(2) == some value
      );
      // Force p1 to be the current player regardless
      p.currentGame!.currentPlayerIndex = 0; // p1 is index 0
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      // p1 throws +20 → p1=100, matches p2=100 → p2 knocked to 0
      throwDart(p, 20, 'single', 'S20');
      throwDart(p, 0, 'miss', 'Miss');
      throwDart(p, 0, 'miss', 'Miss');

      expect(p.currentGame!.scores['p1'], 100);
      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.knockoffsDealt['p1'], 1);
      expect(p.currentGame!.knockoffsReceived['p2'], 1);
    });

    test('21. Skip turn with 0 darts → no score change, shouldPromptTakeout=true', () {
      final p = createProvider(playerIds: ['p1', 'p2']);
      final playerId = p.currentPlayerId!;
      final scoreBefore = p.currentGame!.scores[playerId]!;

      p.skipTurn();

      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores[playerId], scoreBefore);
    });

    test('22. Skip turn with partial darts → score updates with thrown darts only', () {
      final p = createProvider(playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      final playerId = p.currentPlayerId!;

      throwDart(p, 20, 'single', 'S20'); // dart 1: 20
      throwDart(p, 20, 'single', 'S20'); // dart 2: 20
      // 2 darts thrown, skip the 3rd
      p.skipTurn();

      expect(p.shouldPromptTakeout, isTrue);
      // Score = 0 + 20 + 20 = 40 (< 200, no victory, no bust)
      expect(p.currentGame!.scores[playerId], 40);
    });

    test('23. editPlayerScore undoes win side-effects (Rule 20)', () {
      final p = createProvider(
        playerIds: ['p1', 'p2'],
        targetScore: 200,
        doubleFinishEnabled: true,
      );
      // Force p1 as current player
      p.currentGame!.currentPlayerIndex = 0;
      p.currentGame!.scores['p1'] = 160;

      // Throw winning turn: S20 (0 pts) x2 + D20 (40) → exact on double → WIN
      throwDart(p, 0, 'miss', 'Miss');
      throwDart(p, 0, 'miss', 'Miss');
      throwDart(p, 20, 'double', 'D20');

      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, 'p1');

      // Edit score: replace with all misses (no win)
      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']);

      // Win should be undone
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.winnerId, isNull);
      expect(p.currentGame!.state, GladiatorArenaGameState.playing);
      // Score reverts to pre-turn value (160) then misses add 0 → 160
      expect(p.currentGame!.scores['p1'], 160);
    });

    test('24. editPlayerScore undoes knockoff side-effects', () {
      final p = createProvider(
        playerIds: ['p1', 'p2'],
        targetScore: 500,
        doubleFinishEnabled: false,
      );
      p.currentGame!.currentPlayerIndex = 0;
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      // p1 throws +20 → p1=100, matches p2=100 → knockoff
      throwDart(p, 20, 'single', 'S20');
      throwDart(p, 0, 'miss', 'Miss');
      throwDart(p, 0, 'miss', 'Miss');

      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.knockoffsDealt['p1'], 1);

      // Edit to all misses → no knockoff
      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']);

      // p2's score should be restored to pre-turn value
      expect(p.currentGame!.scores['p2'], 100);
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
      expect(p.currentGame!.knockoffsReceived['p2'], 0);
    });

    test('25. totalTurns increments exactly once per turn (on first dart)', () {
      final p = createProvider(playerIds: ['p1', 'p2']);
      p.currentGame!.currentPlayerIndex = 0;

      expect(p.currentGame!.totalTurns['p1'], 0);

      throwDart(p, 5, 'single', 'S5');   // dart 1: totalTurns incremented here
      expect(p.currentGame!.totalTurns['p1'], 1);

      throwDart(p, 5, 'single', 'S5');   // dart 2: no increment
      expect(p.currentGame!.totalTurns['p1'], 1);

      throwDart(p, 5, 'single', 'S5');   // dart 3: no increment
      expect(p.currentGame!.totalTurns['p1'], 1); // still 1

      // After advance, p2 takes a turn
      p.handleTakeoutFinished();

      expect(p.currentGame!.totalTurns['p1'], 1); // p1 unchanged
    });

    test('26. Shield round blocks knockoff (shieldRoundEnabled=true, round=5)', () {
      final p = createProvider(
        playerIds: ['p1', 'p2'],
        targetScore: 500,
        doubleFinishEnabled: false,
        shieldRoundEnabled: true,
      );
      p.currentGame!.round = 5; // shield round
      p.currentGame!.currentPlayerIndex = 0;
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      // p1 throws +20 → p1=100, would match p2=100 but shield blocks
      throwDart(p, 20, 'single', 'S20');
      throwDart(p, 0, 'miss', 'Miss');
      throwDart(p, 0, 'miss', 'Miss');

      expect(p.currentGame!.scores['p2'], 100); // NOT knocked off
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
    });
  });
}
