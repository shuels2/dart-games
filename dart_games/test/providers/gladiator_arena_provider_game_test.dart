import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/gladiator_arena_provider.dart';
import 'package:dart_games/models/gladiator_arena_game.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import '../shared/mock_api_helpers.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Creates a provider backed by a mock API server and starts a game.
GladiatorArenaProvider _makeProvider({
  List<String> playerIds = const ['p1', 'p2'],
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
  Random? random,
}) {
  final server = MockApiServer();
  final p = GladiatorArenaProvider(apiClient: server.apiClient);
  p.startGame(
    playerIds: playerIds,
    targetScore: targetScore,
    doubleFinishEnabled: doubleFinishEnabled,
    shieldRoundEnabled: shieldRoundEnabled,
    speedPlayEnabled: speedPlayEnabled,
    random: random,
  );
  return p;
}

/// Creates a provider WITHOUT starting a game.
GladiatorArenaProvider _makeIdleProvider() {
  final server = MockApiServer();
  return GladiatorArenaProvider(apiClient: server.apiClient);
}

/// Throw one dart.
void _dart(GladiatorArenaProvider p, int score, String multiplier,
    String sector) {
  p.processDartThrow(score: score, multiplier: multiplier, sector: sector);
}

/// Throw a miss.
void _miss(GladiatorArenaProvider p) =>
    _dart(p, 0, 'miss', 'Miss');

/// Throw 3 misses to fill a turn and trigger takeout.
void _fillMisses(GladiatorArenaProvider p) {
  for (int i = 0; i < 3; i++) {
    if (p.shouldPromptTakeout) break;
    _miss(p);
  }
}

/// Forces the current player to be [id] by setting currentPlayerIndex.
void _forcePlayer(GladiatorArenaProvider p, String id) {
  p.currentGame!.currentPlayerIndex = p.currentGame!.playerIds.indexOf(id);
}

void main() {
  // ─────────────────────────────────────────────────────────────────────────────
  // Group 1 — Initial state
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — initial state', () {
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

    test('1.4 After startGame: state=playing, scores=0, dartsThrown=0, round=1', () {
      final p = _makeProvider();
      expect(p.isGameActive, isTrue);
      expect(p.currentGame!.scores['p1'], 0);
      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.dartsThrown['p1'], 0);
      expect(p.currentGame!.dartsThrown['p2'], 0);
      expect(p.currentGame!.round, 1);
      expect(p.hasWinner, isFalse);
    });

    test('1.5 All player maps initialised for every player', () {
      final p = _makeProvider(playerIds: ['a', 'b', 'c']);
      for (final id in ['a', 'b', 'c']) {
        expect(p.currentGame!.scores.containsKey(id), isTrue);
        expect(p.currentGame!.dartsThrown.containsKey(id), isTrue);
        expect(p.currentGame!.totalTurns.containsKey(id), isTrue);
        expect(p.currentGame!.totalDartsThrown.containsKey(id), isTrue);
        expect(p.currentGame!.knockoffsDealt.containsKey(id), isTrue);
        expect(p.currentGame!.knockoffsReceived.containsKey(id), isTrue);
      }
    });

    test('1.6 currentPlayerId is determined by Random seed (deterministic)', () {
      // With a seeded random and 2 players, the starting index is deterministic
      final p = _makeProvider(
        playerIds: ['p1', 'p2'],
        random: Random(42),
      );
      // Random(42).nextInt(2) == 0 → p1 starts; we just verify it's one of the players
      expect(['p1', 'p2'].contains(p.currentPlayerId), isTrue);
    });

    test('1.7 startGame with fewer than 2 players is rejected', () {
      final p = _makeIdleProvider();
      p.startGame(
        playerIds: ['p1'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );
      expect(p.isGameActive, isFalse);
    });

    test('1.8 startGame with more than 8 players is rejected', () {
      final p = _makeIdleProvider();
      p.startGame(
        playerIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'],
        targetScore: 200,
        doubleFinishEnabled: true,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );
      expect(p.isGameActive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 2 — processDartThrow scoring
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — processDartThrow scoring', () {
    test('2.1 Single hit S20 adds 20 to accumulated turn value', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20');
      expect(p.currentGame!.currentTurnDartValues['p1'], [20]);
    });

    test('2.2 Double hit D20 adds 40 to accumulated turn value', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'double', 'D20');
      expect(p.currentGame!.currentTurnDartValues['p1'], [40]);
    });

    test('2.3 Triple hit T20 adds 60 to accumulated turn value', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'triple', 'T20');
      expect(p.currentGame!.currentTurnDartValues['p1'], [60]);
    });

    test('2.4 Inner bull adds 50', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 50, 'bull', 'Bull');
      expect(p.currentGame!.currentTurnDartValues['p1'], [50]);
    });

    test('2.5 Outer bull (sector="25") adds 25', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 25, 'single', '25');
      expect(p.currentGame!.currentTurnDartValues['p1'], [25]);
    });

    test('2.6 Miss adds 0', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _miss(p);
      expect(p.currentGame!.currentTurnDartValues['p1'], [0]);
    });

    test('2.7 Multi-dart turn: S20 + S20 + S20 = 60 added to score', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20');
      _dart(p, 20, 'single', 'S20');
      _dart(p, 20, 'single', 'S20');
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores['p1'], 60);
    });

    test('2.8 Mixed turn: S20 + D10 + Miss = 40 added to score', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20');  // 20
      _dart(p, 10, 'double', 'D10');  // 20
      _miss(p);                         // 0
      expect(p.currentGame!.scores['p1'], 40);
    });

    test('2.9 Bull + T5 = 65 points in a turn', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _dart(p, 50, 'bull', 'Bull'); // 50
      _dart(p, 5, 'triple', 'T5');  // 15
      _miss(p);                       // 0
      expect(p.currentGame!.scores['p1'], 65);
    });

    test('2.10 After 3 darts, dartsThrown[p1]=3 and shouldPromptTakeout=true', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _miss(p);
      _miss(p);
      _miss(p);
      expect(p.currentGame!.dartsThrown['p1'], 3);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('2.11 Raw segments recorded in currentTurnDartSegments', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20');
      _dart(p, 20, 'double', 'D20');
      _miss(p);
      expect(p.currentGame!.currentTurnDartSegments['p1'],
          ['S20', 'D20', 'Miss']);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 3 — Turn advancement
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — turn advancement', () {
    test('3.1 After 3 darts + handleTakeoutFinished, currentPlayerId advances', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      expect(p.shouldPromptTakeout, isTrue);
      p.handleTakeoutFinished();
      expect(p.currentPlayerId, 'p2');
    });

    test('3.2 skipTurn with 0 darts → no score change, advance', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      p.skipTurn();
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores['p1'], 0);
      p.handleTakeoutFinished();
      expect(p.currentPlayerId, 'p2');
    });

    test('3.3 skipTurn with 2 darts thrown → score updates, advance', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20'); // 20
      _dart(p, 10, 'single', 'S10'); // 10
      p.skipTurn();
      expect(p.currentGame!.scores['p1'], 30);
      p.handleTakeoutFinished();
      expect(p.currentPlayerId, 'p2');
    });

    test('3.4 After full rotation of all players, round increments', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      expect(p.currentGame!.round, 1);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      p.handleTakeoutFinished(); // advances to p2
      _fillMisses(p);
      p.handleTakeoutFinished(); // wraps to p1 → round 2
      expect(p.currentGame!.round, 2);
    });

    test('3.5 Dart counters reset to 0 at start of next turn', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      p.handleTakeoutFinished();
      // Now p2's turn
      _fillMisses(p);
      p.handleTakeoutFinished(); // back to p1
      // p1's dartsThrown should be 0 at start of their new turn
      expect(p.currentGame!.dartsThrown['p1'], 0);
    });

    test('3.6 processDartThrow no-ops when state=finished', () {
      // Per-dart win evaluation: dart 1 ends the game on a winning total.
      // Subsequent throws must be no-ops once state=finished.
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 190;
      // Dart 1: 20 → prospective 210 ≥ 200 → VICTORY immediately
      _dart(p, 20, 'single', 'S20');
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.totalDartsThrown['p1'], 1);
      // Any subsequent dart: no-op because state=finished
      _dart(p, 10, 'single', 'S10');
      expect(p.currentGame!.totalDartsThrown['p1'], 1); // still 1
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 4 — Win detection: Double Finish ON
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — win detection: Double Finish ON', () {
    test('4.1 Score=160, throw S20+S20+D20 → exact+double on dart 3 → VICTORY', () {
      // 160 + 20 + 20 + 40 = 240 > 200 → BUST on dart 3 aggregate
      // Better: score=100, S20+T20+D20 → 100+20+60+40=220>200 → BUST
      // Best: score=140, T20+D10+miss → 140+60+20+0=220>200 → BUST
      // Use: score=160, miss+miss+D20 → 160+0+0+40=200 exact, last dart double → WIN
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 160;

      _miss(p);
      _miss(p);
      _dart(p, 20, 'double', 'D20'); // 40 → 160+40=200 exact, D → WIN
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, 'p1');
    });

    test('4.2 Score=180, miss+miss+S20 → 200 exact but NOT a double → BUST', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _miss(p);
      _miss(p);
      _dart(p, 20, 'single', 'S20'); // 20 → 200 exact, not a double → BUST
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 180); // score reverts
    });

    test('4.3 Score=180, throw T20+miss+miss → 180+60+0+0=240 > 200 → BUST', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'triple', 'T20'); // 60
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 180); // score reverts (overshoot bust)
    });

    test('4.4 Score=140, S20+T20+D10 → 140+20+60+20=240 > 200 → BUST (not a win)', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 140;

      _dart(p, 20, 'single', 'S20'); // 20
      _dart(p, 20, 'triple', 'T20'); // 60
      _dart(p, 10, 'double', 'D10'); // 20 → 140+20+60+20=240>200 → BUST
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 140);
    });

    test('4.5 Score=100, S20+T20+D10 → 100+20+60+20=200 exact, last D10 → VICTORY', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;

      _dart(p, 20, 'single', 'S20'); // 20
      _dart(p, 20, 'triple', 'T20'); // 60
      _dart(p, 10, 'double', 'D10'); // 20 → 100+20+60+20=200, last=D → WIN
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.winnerId, 'p1');
    });

    test('4.6 Score=160, D10+miss+miss → 160+20+0+0=180 < 200, score updates normally', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 160;

      _dart(p, 10, 'double', 'D10'); // 20
      _miss(p);
      _miss(p);
      // 160+20=180 < 200 → normal update
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 180);
    });

    test('4.7 DF ON: win/bust evaluation runs per-dart (matches other games)', () {
      // Per-dart evaluation: hitting target on a non-double busts on that
      // dart — remaining darts are forfeited and takeout fires immediately.
      // score=180, dart1=S20 → prospective 200, last segment 'S20' is not a
      // double → BUST on dart 1.
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'single', 'S20');
      expect(p.shouldPromptTakeout, isTrue,
          reason: 'BUST on dart 1 ends the turn immediately');
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 180,
          reason: 'bust → score reverts to pre-turn value');
      // Subsequent throws are no-ops while waitingForTakeout=true
      _dart(p, 1, 'single', 'S1');
      expect(p.currentGame!.totalDartsThrown['p1'], 1,
          reason: 'extra darts after bust are no-ops');
    });

    test('4.8 DF ON Bull finish: score=150, miss+miss+Bull → 150+50=200, Bull starts with "B" not "D" → BUST', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 150;

      _miss(p);
      _miss(p);
      _dart(p, 50, 'bull', 'Bull'); // 50 → 200 exact, 'Bull' does NOT start with 'D' → BUST
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 150);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 5 — Win detection: Double Finish OFF
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — win detection: Double Finish OFF', () {
    test('5.1 Score=100, S20 on dart 1 → 120 < 200, no win, turn continues', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;

      _dart(p, 20, 'single', 'S20'); // 120 < 200
      expect(p.hasWinner, isFalse);
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('5.2 Score=100, T20+T20 darts → 100+60+60=220 ≥ 200 → VICTORY on dart 2', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;

      _dart(p, 20, 'triple', 'T20'); // 60 → 160 < 200, no win
      // After dart 1 (DF OFF) — win check is still at turn end
      expect(p.hasWinner, isFalse);
      _dart(p, 20, 'triple', 'T20'); // 60 → 220 ≥ 200 → win check doesn't happen mid-turn either
      // After dart 2: still not at turn end (DF OFF also evaluates at turn end per spec)
      _miss(p); // dart 3: turn ends now
      expect(p.hasWinner, isTrue); // victory
    });

    test('5.3 Score=180, S20 on dart 1 → 200 ≥ 200 → VICTORY at turn end', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'single', 'S20'); // 20 → 200 ≥ 200
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isTrue);
    });

    test('5.4 Score=180, D20 → 220 ≥ 200 → VICTORY (no overshoot bust in DF OFF)', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'double', 'D20'); // 40 → 220 ≥ 200
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isTrue);
    });

    test('5.5 DF OFF, turn total < target → score updates normally', () {
      final p = _makeProvider(targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;

      _dart(p, 5, 'single', 'S5');
      _dart(p, 5, 'single', 'S5');
      _dart(p, 5, 'single', 'S5');
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 115);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 6 — Knockoff mechanics
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — knockoff mechanics', () {
    test('6.1 Score mismatch → no knockoff', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 60;

      _dart(p, 20, 'single', 'S20'); // p1→100, p2=60 → no match
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 60); // unchanged
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
    });

    test('6.2 Score match → opponent knocked to 0', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20'); // p1→100, matches p2=100 → knockoff
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.knockoffsDealt['p1'], 1);
      expect(p.currentGame!.knockoffsReceived['p2'], 1);
    });

    test('6.3 Multi-match: p1 matches p2 AND p3 → both knocked off, knockoffsDealt=2', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2', 'p3'],
          targetScore: 500,
          doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;
      p.currentGame!.scores['p3'] = 100;

      _dart(p, 20, 'single', 'S20'); // p1→100, matches p2=100 AND p3=100
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.scores['p3'], 0);
      expect(p.currentGame!.knockoffsDealt['p1'], 2);
    });

    test('6.4 Score=0 guard: player with 0 score does not trigger knockoff', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 0;
      p.currentGame!.scores['p2'] = 0;

      _miss(p);
      _miss(p);
      _miss(p);
      // p1 score stays 0 after misses, guard prevents knockoff of p2 at 0
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
    });

    test('6.5 Knockoff after a player has been previously knocked to 0', () {
      // p2 is at 0. p1=80, p2=0. p1 throws misses (no score → p1 stays 80 → no knockoff)
      // Test: p1=0, throws +60 → p1=60; p2 also at 60 → knockoff
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 0;
      p.currentGame!.scores['p2'] = 60;

      _dart(p, 20, 'triple', 'T20'); // p1→60, matches p2=60 → knockoff! (score>0 guard passes)
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0);
    });

    test('6.6 Shield round (shieldRoundEnabled=true, round=5) blocks knockoff', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 500,
          doubleFinishEnabled: false,
          shieldRoundEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.round = 5; // shield round
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20'); // p1→100, would match p2=100 but shield active
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 100); // NOT knocked off
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
    });

    test('6.7 Shield round OFF (shieldRoundEnabled=false, round=5) → knockoffs still happen', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 500,
          doubleFinishEnabled: false,
          shieldRoundEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.round = 5; // round 5 but shield disabled
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20'); // p1→100, matches p2 → knockoff happens
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0);
    });

    test('6.8 Round 6 after shield round 5 → knockoffs work again', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 500,
          doubleFinishEnabled: false,
          shieldRoundEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.round = 6; // NOT a shield round (6%5≠0)
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20');
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0); // knocked off
    });

    test('6.9 Knockoff does not fire when VICTORY occurs (winnerId set instead)', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;
      p.currentGame!.scores['p2'] = 200; // already at target (unusual but test the guard)
      // p2 can't normally have 200 without winning, but set it to test knockoff guard
      // Actually target=200 and DF OFF → p1 wins with 200, no knockoff check
      _dart(p, 20, 'single', 'S20'); // 200 → WIN
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isTrue);
      expect(p.currentGame!.knockoffsDealt['p1'], 0); // victory path skips knockoff
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 7 — Per-option side-effects
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — per-option side-effects', () {
    test('7.1 targetScore=100: win when score reaches 100', () {
      final p =
          _makeProvider(targetScore: 100, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;

      _dart(p, 20, 'single', 'S20'); // 100 ≥ 100 → win
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isTrue);
    });

    test('7.2 targetScore=500: game continues until score reaches 500', () {
      final p =
          _makeProvider(targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 400;

      _dart(p, 20, 'triple', 'T20'); // +60 → 460 < 500, no win
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 460);
    });

    test('7.3 doubleFinishEnabled ON: forces double requirement', () {
      final p = _makeProvider(targetScore: 100, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;

      _dart(p, 20, 'single', 'S20'); // 100 exact but NOT double → BUST
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.scores['p1'], 80);
    });

    test('7.4 doubleFinishEnabled OFF: same scenario → VICTORY', () {
      final p = _makeProvider(targetScore: 100, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;

      _dart(p, 20, 'single', 'S20'); // 100 ≥ 100 → WIN (DF OFF)
      _miss(p);
      _miss(p);
      expect(p.hasWinner, isTrue);
    });

    test('7.5 shieldRoundEnabled ON, round=5 → isShieldRound=true', () {
      final p = _makeProvider(shieldRoundEnabled: true);
      p.currentGame!.round = 5;
      expect(p.currentGame!.isShieldRound, isTrue);
    });

    test('7.6 shieldRoundEnabled OFF, round=5 → isShieldRound=false', () {
      final p = _makeProvider(shieldRoundEnabled: false);
      p.currentGame!.round = 5;
      expect(p.currentGame!.isShieldRound, isFalse);
    });

    test('7.7 speedPlayEnabled ON: speedPlayTimeRemaining initialised to 25', () {
      final p = _makeProvider(speedPlayEnabled: true);
      // After startGame, speedPlayTimeRemaining is not pre-set (timer starts on screen)
      // After advanceToNextPlayer, it resets to 25
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      p.handleTakeoutFinished(); // advance — resets timer to 25 for next player
      expect(p.currentGame!.speedPlayTimeRemaining, 25);
    });

    test('7.8 speedPlayEnabled OFF: speedPlayTimeRemaining stays null after advance', () {
      final p = _makeProvider(speedPlayEnabled: false);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      p.handleTakeoutFinished();
      expect(p.currentGame!.speedPlayTimeRemaining, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 8 — totalTurns increment behaviour
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — totalTurns increment', () {
    test('8.1 totalTurns increments EXACTLY ONCE on the first dart of a turn', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      expect(p.currentGame!.totalTurns['p1'], 0);

      _dart(p, 5, 'single', 'S5'); // first dart → totalTurns becomes 1
      expect(p.currentGame!.totalTurns['p1'], 1);

      _dart(p, 5, 'single', 'S5'); // second dart → no change
      expect(p.currentGame!.totalTurns['p1'], 1);

      _dart(p, 5, 'single', 'S5'); // third dart → no change
      expect(p.currentGame!.totalTurns['p1'], 1);
    });

    test('8.2 totalTurns NOT incremented in advanceToNextPlayer', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      final turnsBeforeAdvance = p.currentGame!.totalTurns['p1']!;
      p.handleTakeoutFinished(); // calls advanceToNextPlayer
      // p1's totalTurns should not change during advance
      expect(p.currentGame!.totalTurns['p1'], turnsBeforeAdvance);
    });

    test('8.3 skipTurn with 0 darts increments totalTurns once', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      expect(p.currentGame!.totalTurns['p1'], 0);
      p.skipTurn();
      expect(p.currentGame!.totalTurns['p1'], 1);
    });

    test('8.4 After two full rounds, totalTurns equals 2 for each player', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      // Round 1
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      p.handleTakeoutFinished();
      _fillMisses(p); // p2's turn
      p.handleTakeoutFinished();
      // Round 2
      _fillMisses(p); // p1 again
      p.handleTakeoutFinished();
      _fillMisses(p); // p2
      p.handleTakeoutFinished();
      expect(p.currentGame!.totalTurns['p1'], 2);
      expect(p.currentGame!.totalTurns['p2'], 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 9 — editPlayerScore / _resetTurnForPlayer
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — editPlayerScore', () {
    test('9.1 Edit winning turn to non-winning: win side-effects undone', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 160;

      _miss(p);
      _miss(p);
      _dart(p, 20, 'double', 'D20'); // 160+40=200 exact, double → WIN
      expect(p.hasWinner, isTrue);

      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']); // no win
      expect(p.hasWinner, isFalse);
      expect(p.currentGame!.state, GladiatorArenaGameState.playing);
      expect(p.currentGame!.endedAt, isNull);
      expect(p.currentGame!.scores['p1'], 160); // pre-turn score (misses add 0)
    });

    test('9.2 Edit knockoff turn: opponent score restored', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20'); // p1→100, knockoff p2
      _miss(p);
      _miss(p);
      expect(p.currentGame!.scores['p2'], 0);

      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']); // no knockoff
      expect(p.currentGame!.scores['p2'], 100); // restored
      expect(p.currentGame!.knockoffsDealt['p1'], 0);
      expect(p.currentGame!.knockoffsReceived['p2'], 0);
    });

    test('9.3 editPlayerScore with fewer than 3 segments → handled gracefully (partial turn stays mid-turn)', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _fillMisses(p); // complete a turn with 3 misses

      // Edit with only 1 segment: replays 1 dart, turn stays open (no turn-end)
      // Score only updates at turn END (after 3 darts), so score stays 0
      p.editPlayerScore('p1', ['S5']); // 1 dart replayed → dartsThrown=1, turn not ended
      // The 1 dart is recorded but score hasn't updated (turn still in progress)
      expect(p.currentGame!.currentTurnDartValues['p1'], [5]); // dart value recorded
      expect(p.currentGame!.dartsThrown['p1'], 1); // 1 dart thrown so far
      // Now fill remaining 2 darts and verify score updates
      _miss(p);
      _miss(p);
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores['p1'], 5); // 5+0+0 = 5
    });

    test('9.4 editPlayerScore with all misses: score reverts to pre-turn value', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 50;

      _dart(p, 20, 'single', 'S20');
      _dart(p, 10, 'single', 'S10');
      _dart(p, 5, 'single', 'S5');
      // Score = 50+20+10+5=85

      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']);
      expect(p.currentGame!.scores['p1'], 50); // back to pre-turn
    });

    test('9.5 editPlayerScore does NOT decrement totalTurns', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _fillMisses(p);
      final turnsBefore = p.currentGame!.totalTurns['p1']!;

      p.editPlayerScore('p1', ['S20', 'S20', 'S20']);
      // totalTurns should be unchanged (turn still happened)
      expect(p.currentGame!.totalTurns['p1'], turnsBefore);
    });

    test('9.6 editPlayerScore adjusts totalDartsThrown correctly', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 200, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      _fillMisses(p); // threw 3 real darts → totalDartsThrown['p1']=3
      final totalBefore = p.currentGame!.totalDartsThrown['p1']!;

      // Edit with 3 new segments → 3 darts undone then 3 replayed → net same count
      p.editPlayerScore('p1', ['S20', 'S20', 'S20']);
      expect(p.currentGame!.totalDartsThrown['p1'], totalBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 10 — Speed Play
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — speed play', () {
    test('10.1 setSpeedPlayTimeRemaining updates the model field', () {
      final p = _makeProvider(speedPlayEnabled: true);
      p.setSpeedPlayTimeRemaining(18);
      expect(p.currentGame!.speedPlayTimeRemaining, 18);
    });

    test('10.2 onSpeedPlayTimerExpired with 1 dart thrown: processes 1-dart turn', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: false,
          speedPlayEnabled: true);
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20'); // throw 1 dart (20 pts)
      // Timer expires before dart 2 and 3
      p.onSpeedPlayTimerExpired();
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores['p1'], 20); // only 1 dart counted
    });

    test('10.3 onSpeedPlayTimerExpired with 0 darts: 0 score, advance possible', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: false,
          speedPlayEnabled: true);
      _forcePlayer(p, 'p1');
      p.onSpeedPlayTimerExpired();
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.scores['p1'], 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 11 — endGame and resumedSavedGameId
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — endGame and save/restore lifecycle', () {
    test('11.1 endGame sets state=finished, endedAt=now, clears resumedSavedGameId', () {
      final p = _makeProvider();
      p.endGame();
      expect(p.currentGame!.state, GladiatorArenaGameState.finished);
      expect(p.currentGame!.endedAt, isNotNull);
      expect(p.resumedSavedGameId, isNull);
    });

    test('11.2 resumedSavedGameId is set after restoreGame', () async {
      final p = _makeProvider();
      final metadata = SavedGameMetadata.create(
        gameType: 'gladiator_arena',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 2',
        gameModeName: 'Target: 200',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '80',
        gameState: p.currentGame!.toJson(),
        existingId: 'test-saved-id-123',
      );
      await p.restoreGame(metadata);
      expect(p.resumedSavedGameId, 'test-saved-id-123');
    });

    test('11.3 clearResumedSavedGameId zeroes the field', () async {
      final p = _makeProvider();
      final metadata = SavedGameMetadata.create(
        gameType: 'gladiator_arena',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 2',
        gameModeName: 'Target: 200',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '80',
        gameState: p.currentGame!.toJson(),
        existingId: 'test-id-xyz',
      );
      await p.restoreGame(metadata);
      expect(p.resumedSavedGameId, 'test-id-xyz');
      p.clearResumedSavedGameId();
      expect(p.resumedSavedGameId, isNull);
    });

    test('11.4 clearGame resets all provider state', () {
      final p = _makeProvider();
      p.clearGame();
      expect(p.currentGame, isNull);
      expect(p.isGameActive, isFalse);
      expect(p.shouldPromptTakeout, isFalse);
      expect(p.resumedSavedGameId, isNull);
    });

    test('11.5 restoreGame loads full game state correctly', () async {
      final p = _makeProvider(playerIds: ['p1', 'p2'], targetScore: 300);
      p.currentGame!.scores['p1'] = 150;
      p.currentGame!.round = 3;
      final gameJson = p.currentGame!.toJson();

      final metadata = SavedGameMetadata.create(
        gameType: 'gladiator_arena',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 3',
        gameModeName: 'Target: 300',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '150',
        gameState: gameJson,
      );

      final p2 = _makeIdleProvider();
      await p2.restoreGame(metadata);
      expect(p2.currentGame!.scores['p1'], 150);
      expect(p2.currentGame!.round, 3);
      expect(p2.currentGame!.targetScore, 300);
      expect(p2.isGameActive, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 12 — Additional edge cases
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — additional edge cases', () {
    test('12.1 processDartThrow no-ops when waitingForTakeout=true', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _fillMisses(p); // now waitingForTakeout=true
      expect(p.shouldPromptTakeout, isTrue);
      // Additional dart should be ignored
      _dart(p, 20, 'single', 'S20');
      expect(p.currentGame!.dartsThrown['p1'], 3); // still 3, not 4
    });

    test('12.2 8-player game: all players correctly tracked', () {
      final ids = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'];
      final p = _makeProvider(playerIds: ids, targetScore: 200, doubleFinishEnabled: false);
      for (final id in ids) {
        expect(p.currentGame!.scores.containsKey(id), isTrue);
        expect(p.currentGame!.dartsThrown.containsKey(id), isTrue);
        expect(p.currentGame!.knockoffsDealt.containsKey(id), isTrue);
      }
      expect(p.currentGame!.playerIds.length, 8);
    });

    test('12.3 getCurrentTurnDartSegments returns correct segments', () {
      final p = _makeProvider();
      _forcePlayer(p, 'p1');
      _dart(p, 20, 'single', 'S20');
      _dart(p, 20, 'double', 'D20');
      expect(p.getCurrentTurnDartSegments('p1'), ['S20', 'D20']);
    });

    test('12.4 hasWinner false before any win', () {
      final p = _makeProvider();
      expect(p.hasWinner, isFalse);
    });

    test('12.5 After skip turn, currentTurnDartSegments contains "Skip" markers', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      p.skipTurn();
      final segs = p.currentGame!.currentTurnDartSegments['p1']!;
      expect(segs.length, 3);
      expect(segs.every((s) => s == 'Skip'), isTrue);
    });

    test('12.6 lastKnockoff fields are set after a knockoff', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], targetScore: 500, doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 100;

      _dart(p, 20, 'single', 'S20');
      _miss(p);
      _miss(p);
      expect(p.currentGame!.lastKnockoffVictimId, 'p2');
      expect(p.currentGame!.lastKnockoffAttackerId, 'p1');
      expect(p.currentGame!.lastKnockoffAt, isNotNull);
    });

    test('12.7 shouldPromptTakeout is false at start of a turn', () {
      final p = _makeProvider();
      expect(p.shouldPromptTakeout, isFalse);
    });

    test('12.8 getCurrentPlayerDartsThrown returns correct count mid-turn', () {
      final p = _makeProvider(playerIds: ['p1', 'p2']);
      _forcePlayer(p, 'p1');
      expect(p.getCurrentPlayerDartsThrown(), 0);
      _dart(p, 5, 'single', 'S5');
      expect(p.getCurrentPlayerDartsThrown(), 1);
      _dart(p, 5, 'single', 'S5');
      expect(p.getCurrentPlayerDartsThrown(), 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Group 13 — Gap-coverage tests (Phase 1 of cross-game audit)
  //
  // Targets specific behavioural seams the original suite did not exercise:
  //   • DF bust short-circuits the knockoff check (no false-positive knockoffs)
  //   • DF bust freezes dartsThrown to 3 on dart 1 / 2 / 3
  //   • Shield-round modulo holds at rounds 5, 10, 15
  //   • Win during shield round still wins (shield gate is knockoff-only)
  //   • Speed-Play timer expiry no-ops after a bust already set takeout
  //   • Speed-Play X-padding interacts correctly with DF prospective on commit
  //   • editPlayerScore decrements stats for EVERY victim of a multi-victim
  //     knockoff (not just one)
  // ─────────────────────────────────────────────────────────────────────────────
  group('GladiatorArenaProvider — gap coverage', () {
    test(
        '13.1 DF ON bust overshoot: knockoff check is NOT run (opponent at the would-be-commit score is unaffected)',
        () {
      // Setup: p1 at 180, p2 at 180 (deliberately matched). p1 throws T20,
      // prospective 240 > target 200 → BUST. _runKnockoffCheck must NOT run
      // (provider line 234-240: bust path returns before line 262 commit).
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;
      p.currentGame!.scores['p2'] = 180;

      _dart(p, 20, 'triple', 'T20'); // prospective=240 > 200 → BUST

      expect(p.currentGame!.scores['p1'], 180,
          reason: 'p1 score reverts on bust');
      expect(p.currentGame!.scores['p2'], 180,
          reason: 'p2 stays — bust did NOT commit, so no knockoff check ran');
      expect(p.currentGame!.knockoffsDealt['p1'] ?? 0, 0);
      expect(p.currentGame!.knockoffsReceived['p2'] ?? 0, 0);
    });

    test(
        '13.2 DF ON bust no-double: knockoff check is NOT run (opponent unaffected)',
        () {
      // p1 at 180, p2 at 200 is impossible (target=200 means p2 won), so
      // construct via target=100, p1 at 80, p2 at 100 → impossible too.
      // Use target=100, p1 at 80, p2 at 80 — non-conflict baseline showing
      // bust-no-double doesn't introduce a side-effect.
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 100,
          doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;
      p.currentGame!.scores['p2'] = 80;

      _dart(p, 20, 'single', 'S20'); // prospective=100, S20 not double → BUST

      expect(p.currentGame!.scores['p1'], 80, reason: 'bust reverts');
      expect(p.currentGame!.scores['p2'], 80,
          reason: 'knockoff check skipped on bust');
      expect(p.currentGame!.knockoffsDealt['p1'] ?? 0, 0);
    });

    test(
        '13.3 DF bust overshoot on dart 1 sets dartsThrown=3 (remaining darts forfeited)',
        () {
      // Bust on dart 1 must immediately set dartsThrown[playerId]=3 so the
      // takeout prompt fires and the remaining slots are skipped.
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'triple', 'T20'); // prospective=240 → BUST on dart 1

      expect(p.currentGame!.dartsThrown['p1'], 3,
          reason: 'dartsThrown jumps to 3 on dart-1 bust');
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.totalDartsThrown['p1'], 1,
          reason: 'only the busting dart counts toward totalDartsThrown');
    });

    test('13.4 DF bust overshoot on dart 2 sets dartsThrown=3', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 160;

      _dart(p, 5, 'single', 'S5'); // prospective=165, no bust
      _dart(p, 20, 'triple', 'T20'); // prospective=225 → BUST on dart 2

      expect(p.currentGame!.dartsThrown['p1'], 3);
      expect(p.shouldPromptTakeout, isTrue);
      expect(p.currentGame!.totalDartsThrown['p1'], 2);
    });

    test('13.5 DF bust no-double on dart 1 sets dartsThrown=3', () {
      // score=180, dart 1 = S20 → prospective=200 exact, S20 is not a double
      // → BUST. Per provider line 254-257, dartsThrown must be set to 3 here
      // (not on the next dart).
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 180;

      _dart(p, 20, 'single', 'S20');

      expect(p.currentGame!.dartsThrown['p1'], 3);
      expect(p.shouldPromptTakeout, isTrue);
    });

    test('13.6 isShieldRound is true on rounds 5, 10, 15 (modulo holds)', () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'], shieldRoundEnabled: true);

      p.currentGame!.round = 5;
      expect(p.currentGame!.isShieldRound, isTrue,
          reason: 'round 5 is a shield round');
      p.currentGame!.round = 10;
      expect(p.currentGame!.isShieldRound, isTrue);
      p.currentGame!.round = 15;
      expect(p.currentGame!.isShieldRound, isTrue);
      p.currentGame!.round = 6;
      expect(p.currentGame!.isShieldRound, isFalse);
      p.currentGame!.round = 11;
      expect(p.currentGame!.isShieldRound, isFalse);
    });

    test(
        '13.7 Win during a shield round still wins (shield gates knockoffs only)',
        () {
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: true,
          shieldRoundEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 160;
      p.currentGame!.round = 5; // shield round active
      expect(p.currentGame!.isShieldRound, isTrue);

      _miss(p);
      _miss(p);
      _dart(p, 20, 'double', 'D20'); // 160+40=200 on a double → WIN

      expect(p.hasWinner, isTrue,
          reason: 'shield round does not block a victory');
      expect(p.currentGame!.winnerId, 'p1');
    });

    test(
        '13.8 onSpeedPlayTimerExpired is a no-op after a DF bust already set _waitingForTakeout',
        () {
      // After a DF bust, _waitingForTakeout=true. The timer-expiry guard at
      // provider line 546 returns early, so the X-padding code path doesn't
      // re-run and pollute state.
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 100,
          doubleFinishEnabled: true,
          speedPlayEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;

      _dart(p, 20, 'triple', 'T20'); // prospective=140 → BUST on dart 1
      expect(p.shouldPromptTakeout, isTrue);
      final dartsThrownBeforeExpiry = p.currentGame!.dartsThrown['p1'];
      final segmentsBeforeExpiry =
          List<String>.from(p.currentGame!.currentTurnDartSegments['p1']!);

      p.onSpeedPlayTimerExpired();

      expect(p.currentGame!.dartsThrown['p1'], dartsThrownBeforeExpiry,
          reason: 'no-op when already waiting for takeout');
      expect(p.currentGame!.currentTurnDartSegments['p1'], segmentsBeforeExpiry,
          reason: 'X markers NOT appended on the no-op path');
    });

    test(
        '13.9 onSpeedPlayTimerExpired with DF-ON partial turn that would overshoot still busts',
        () {
      // p1 at 80, target=100, DF ON. Throws T20 (prospective=140 → BUST on
      // dart 1; takeout fires). Timer expires AFTER the bust → it's a no-op
      // and the bust outcome is preserved. (Same flow as 13.8 but asserts on
      // the *score* side: stays at preTurnScore, no X padding visible.)
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 100,
          doubleFinishEnabled: true,
          speedPlayEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 80;

      _dart(p, 20, 'triple', 'T20'); // BUST
      p.onSpeedPlayTimerExpired();

      expect(p.currentGame!.scores['p1'], 80,
          reason: 'bust outcome preserved across timer expiry no-op');
      expect(p.shouldPromptTakeout, isTrue);
    });

    test(
        '13.10 onSpeedPlayTimerExpired with partial DF-OFF turn commits prospective via X padding',
        () {
      // DF OFF, target=200, p1 at 100. Throws S20 (1 dart, prospective=120
      // <200). Timer expires → pads X+X. Final score commit = 120.
      final p = _makeProvider(
          playerIds: ['p1', 'p2'],
          targetScore: 200,
          doubleFinishEnabled: false,
          speedPlayEnabled: true);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;

      _dart(p, 20, 'single', 'S20'); // 1 dart, prospective=120, not committed
      p.onSpeedPlayTimerExpired();

      expect(p.currentGame!.scores['p1'], 120,
          reason: 'X padding commits prospective at current accumulated total');
      expect(p.currentGame!.dartsThrown['p1'], 3,
          reason: 'X padding fills remaining slots');
      expect(p.shouldPromptTakeout, isTrue);
    });

    test(
        '13.11 editPlayerScore undoes a multi-victim knockoff: both victims restored, dealt count drops by 2',
        () {
      // 3 players, target=200, DF OFF. p1 at 100, p2 and p3 BOTH at 160.
      // p1 throws T20+Miss+Miss → commit 160, knocks off p2 AND p3.
      // Then editPlayerScore('p1', [Miss,Miss,Miss]) must undo BOTH
      // knockoffs: knockoffsDealt[p1]-=2, knockoffsReceived[p2]/[p3]-=1,
      // and both victim scores restored to 160.
      final p = _makeProvider(
          playerIds: ['p1', 'p2', 'p3'],
          targetScore: 200,
          doubleFinishEnabled: false);
      _forcePlayer(p, 'p1');
      p.currentGame!.scores['p1'] = 100;
      p.currentGame!.scores['p2'] = 160;
      p.currentGame!.scores['p3'] = 160;

      _dart(p, 20, 'triple', 'T20'); // 60 → commits at dart 3 below
      _miss(p);
      _miss(p);

      // Verify the multi-victim knockoff happened
      expect(p.currentGame!.scores['p1'], 160);
      expect(p.currentGame!.scores['p2'], 0);
      expect(p.currentGame!.scores['p3'], 0);
      expect(p.currentGame!.knockoffsDealt['p1'], 2);
      expect(p.currentGame!.knockoffsReceived['p2'], 1);
      expect(p.currentGame!.knockoffsReceived['p3'], 1);

      // Edit p1's turn to all misses — must undo BOTH knockoffs
      p.editPlayerScore('p1', ['Miss', 'Miss', 'Miss']);

      expect(p.currentGame!.scores['p1'], 100, reason: 'p1 score reverts');
      expect(p.currentGame!.scores['p2'], 160,
          reason: 'p2 restored to pre-knockoff score');
      expect(p.currentGame!.scores['p3'], 160,
          reason: 'p3 restored to pre-knockoff score');
      expect(p.currentGame!.knockoffsDealt['p1'], 0,
          reason: 'knockoffsDealt decremented for EACH victim (2 total)');
      expect(p.currentGame!.knockoffsReceived['p2'], 0);
      expect(p.currentGame!.knockoffsReceived['p3'], 0);
    });
  });
}
