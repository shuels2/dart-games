import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/lunar_lander_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/lunar_lander_provider.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Creates a [LunarLanderGame] directly (bypasses provider) with predictable state.
LunarLanderGame createGame({
  List<String>? playerIds,
  int startingAltitude = 200,
  bool hardLandingEnabled = false,
}) {
  final ids = playerIds ?? ['p1', 'p2'];
  return LunarLanderGame.create(
    playerIds: ids,
    startingAltitude: startingAltitude,
    hardLandingEnabled: hardLandingEnabled,
  );
}

/// Creates a provider with a started game.
LunarLanderProvider createProvider({
  List<String>? playerIds,
  int startingAltitude = 200,
  bool hardLandingEnabled = false,
}) {
  final ids = playerIds ?? ['p1', 'p2'];
  final provider = LunarLanderProvider();
  provider.startGame(
    playerIds: ids,
    startingAltitude: startingAltitude,
    hardLandingEnabled: hardLandingEnabled,
  );
  return provider;
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // Group 1 — Basic Scoring & Descent
  // ═══════════════════════════════════════════════════════════════════
  group('Group 1 — Basic Scoring & Descent', () {
    test('1. Single hit subtracts face value from altitude', () {
      final provider = createProvider(startingAltitude: 200);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20');

      expect(provider.getCurrentAltitude(playerId), 180);
    });

    test('2. Double hit subtracts face value × 2 from altitude', () {
      final provider = createProvider(startingAltitude: 200);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 2, sector: 'D20');

      expect(provider.getCurrentAltitude(playerId), 160); // 200 - 40
    });

    test('3. Triple hit subtracts face value × 3 from altitude', () {
      final provider = createProvider(startingAltitude: 200);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20');

      expect(provider.getCurrentAltitude(playerId), 140); // 200 - 60
    });

    test('4. Outer bull (single 25) subtracts 25', () {
      final provider = createProvider(startingAltitude: 200);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 25, multiplier: 1, sector: '25');

      expect(provider.getCurrentAltitude(playerId), 175);
    });

    test('5. Inner bull (single 50) subtracts 50', () {
      final provider = createProvider(startingAltitude: 200);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 50, multiplier: 1, sector: 'Bull');

      expect(provider.getCurrentAltitude(playerId), 150);
    });

    test('6. Altitude decreases correctly across multiple darts in a turn', () {
      final provider = createProvider(startingAltitude: 300);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // -20 → 280
      provider.processDartThrow(score: 15, multiplier: 1, sector: 'S15'); // -15 → 265
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // -10 → 255

      expect(provider.getCurrentAltitude(playerId), 255);
    });

    test('7. Altitude decreases correctly across multiple turns', () {
      final provider =
          createProvider(playerIds: ['p1', 'p2'], startingAltitude: 200);
      final p1 = 'p1';
      final p2 = 'p2';

      // P1 throws 3 darts and triggers takeout
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1: 200-20=180
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1: 180-20=160
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1: 160-20=140
      expect(provider.getCurrentAltitude(p1), 140);
      expect(provider.shouldPromptTakeout, isTrue);

      // Advance to P2
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), p2);

      // P2 throws 2 darts
      provider.processDartThrow(score: 15, multiplier: 1, sector: 'S15'); // p2: 200-15=185
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // p2: 185-10=175
      expect(provider.getCurrentAltitude(p2), 175);

      // Finish P2's turn
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5'); // p2: 175-5=170
      provider.advanceTurn();

      // Back to P1
      expect(provider.getCurrentPlayerId(), p1);
      expect(provider.getCurrentAltitude(p1), 140); // unchanged since last turn
    });

    test('8. Three darts in a turn correctly tracked in dartsThrown counter',
        () {
      final provider = createProvider(startingAltitude: 200);
      final game = provider.currentGame!;
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(game.dartsThrown[playerId], 1);
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(game.dartsThrown[playerId], 2);
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(game.dartsThrown[playerId], 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 2 — Starting Altitude (CONSUMES OPTION: startingAltitude)
  // ═══════════════════════════════════════════════════════════════════
  group('Group 2 — Starting Altitude', () {
    test('9. Starting altitude 100 initializes correctly for all players', () {
      // EXERCISES OPTION: startingAltitude = 100
      final game = createGame(
          playerIds: ['p1', 'p2', 'p3'], startingAltitude: 100);
      for (final id in game.playerIds) {
        expect(game.currentAltitudes[id], 100);
      }
      expect(game.startingAltitude, 100);
    });

    test('10. Starting altitude 200 (default) initializes correctly', () {
      // EXERCISES OPTION: startingAltitude = 200 (default)
      final game = createGame(startingAltitude: 200);
      for (final id in game.playerIds) {
        expect(game.currentAltitudes[id], 200);
      }
      expect(game.startingAltitude, 200);
    });

    test('11. Starting altitude 500 initializes correctly', () {
      // EXERCISES OPTION: startingAltitude = 500
      final game = createGame(
          playerIds: ['p1', 'p2'], startingAltitude: 500);
      for (final id in game.playerIds) {
        expect(game.currentAltitudes[id], 500);
      }
      expect(game.startingAltitude, 500);
    });

    test('12. All players start at the same altitude', () {
      final game = createGame(
          playerIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
          startingAltitude: 350);
      final altitudes =
          game.playerIds.map((id) => game.currentAltitudes[id]).toSet();
      expect(altitudes.length, 1); // All same
      expect(altitudes.first, 350);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 3 — Hard Landing / Bust (CONSUMES OPTION: hardLandingEnabled)
  // ═══════════════════════════════════════════════════════════════════
  group('Group 3 — Hard Landing / Bust', () {
    test(
        '13. Hard Landing ON: dart that would bring alt below 0 reverts altitude to turn-start value',
        () {
      // EXERCISES OPTION: hardLandingEnabled = true
      // Use a starting altitude of 100 so we can reduce it over two turns to 30,
      // then attempt a bust on the third turn.
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 100,
          hardLandingEnabled: true);
      final p1 = 'p1';
      final p2 = 'p2';

      // Turn 1 — P1: throw 3 darts to reduce from 100 → 70
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 100-10=90
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 90-10=80
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 80-10=70
      expect(provider.getCurrentAltitude(p1), 70);
      provider.advanceTurn(); // advance to P2

      // Turn 1 — P2: quick 3-dart turn
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.advanceTurn(); // back to P1

      // Turn 2 — P1: reduce from 70 → 40
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 70-10=60
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 60-10=50
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 50-10=40
      expect(provider.getCurrentAltitude(p1), 40);
      provider.advanceTurn(); // advance to P2

      // Turn 2 — P2: quick 3-dart turn
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.advanceTurn(); // back to P1

      // Turn 3 — P1: altitude is 40. Dart that goes below zero: T20=60 > 40
      expect(provider.getCurrentAltitude(p1), 40); // starts this turn at 40
      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // would be -20 → bust
      // Must revert to turn-start altitude (40)
      expect(provider.getCurrentAltitude(p1), 40);
      expect(provider.currentGame!.dartThrowWasBust[p1]!.last, isTrue);
    });

    test(
        '14. Hard Landing ON: remaining darts forfeited after bust (turn ends immediately)',
        () {
      // EXERCISES OPTION: hardLandingEnabled = true
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 50,
          hardLandingEnabled: true);
      final playerId = provider.getCurrentPlayerId()!;

      // Throw a bust dart on first dart (single 60 > altitude 50)
      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // 60 > 50 → bust
      expect(provider.getCurrentAltitude(playerId), 50); // reverted
      expect(provider.currentGame!.dartsThrown[playerId],
          provider.currentGame!.maxDartsPerTurn); // forfeited
      expect(provider.shouldPromptTakeout, isTrue);
    });

    test('15. Hard Landing ON: exact 0 is valid (NOT a bust) — player wins',
        () {
      // EXERCISES OPTION: hardLandingEnabled = true
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 60,
          hardLandingEnabled: true);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // exactly 60 → 0
      expect(provider.getCurrentAltitude(playerId), 0);
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, playerId);
      expect(provider.currentGame!.dartThrowWasBust[playerId]!.last, isFalse);
    });

    test(
        '16. Hard Landing ON: multiple busts across turns each reverts to that turn’s start',
        () {
      // EXERCISES OPTION: hardLandingEnabled = true
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 100,
          hardLandingEnabled: true);
      final p1 = 'p1';
      final p2 = 'p2';

      // P1 turn 1: reduce to 80, then bust
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // 100-20=80
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // 80-20=60
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // 60-20=40
      provider.advanceTurn();

      // P2 turn 1
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.advanceTurn();

      // P1 turn 2 start altitude is 40; bust on the first dart
      expect(provider.getCurrentAltitude(p1), 40);
      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // 60 > 40 → bust
      expect(provider.getCurrentAltitude(p1), 40); // reverted to 40

      provider.advanceTurn(); // P2 turn 2
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1');
      provider.advanceTurn();

      // P1 turn 3: altitude still 40 (bust in turn 2 didn't change it)
      expect(provider.getCurrentAltitude(p1), 40);
    });

    test(
        '17. Hard Landing OFF: negative altitude allowed, player wins (overshoot = touchdown)',
        () {
      // EXERCISES OPTION: hardLandingEnabled = false
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 30,
          hardLandingEnabled: false);
      final playerId = provider.getCurrentPlayerId()!;

      // Dart that overshoots (score > altitude) — should WIN
      provider.processDartThrow(score: 20, multiplier: 2, sector: 'D20'); // 40 > 30 → -10
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, playerId);
    });

    test('18. Hard Landing OFF: dart that lands exactly at 0 wins', () {
      // EXERCISES OPTION: hardLandingEnabled = false
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 40,
          hardLandingEnabled: false);
      final playerId = provider.getCurrentPlayerId()!;

      provider.processDartThrow(score: 20, multiplier: 2, sector: 'D20'); // exactly 40 → 0
      expect(provider.getCurrentAltitude(playerId), 0);
      expect(provider.hasWinner, isTrue);
    });

    test(
        '19. Hard Landing ON: bust marks darts as bust in dartThrowWasBust',
        () {
      // EXERCISES OPTION: hardLandingEnabled = true
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 50,
          hardLandingEnabled: true);
      final playerId = provider.getCurrentPlayerId()!;

      // Throw a valid dart first
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 50-10=40
      expect(provider.currentGame!.dartThrowWasBust[playerId]!.last, isFalse);

      // Now bust (any value > 40)
      provider.processDartThrow(score: 20, multiplier: 3, sector: 'T20'); // 60 > 40 → bust
      final bustList =
          provider.currentGame!.dartThrowWasBust[playerId]!;
      expect(bustList.last, isTrue);
      expect(bustList.where((b) => b).length, 1); // exactly one bust
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 4 — Game Flow
  // ═══════════════════════════════════════════════════════════════════
  group('Group 4 — Game Flow', () {
    test('20. Turn advances after 3 darts thrown', () {
      final provider =
          createProvider(playerIds: ['p1', 'p2'], startingAltitude: 200);

      // P1 throws 3 darts
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(provider.shouldPromptTakeout, isTrue);

      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('21. Skip turn with darts already thrown advances to next player', () {
      final provider =
          createProvider(playerIds: ['p1', 'p2'], startingAltitude: 200);

      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10'); // 1 dart thrown
      provider.skipTurn(); // skip remaining 2
      expect(provider.shouldPromptTakeout, isTrue);

      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('22. Skip turn with no darts thrown advances to next player', () {
      final provider =
          createProvider(playerIds: ['p1', 'p2'], startingAltitude: 200);

      provider.skipTurn(); // skip all 3 without throwing any
      expect(provider.shouldPromptTakeout, isTrue);

      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('23. First player to altitude 0 wins', () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 20);
      final p1 = 'p1';

      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1: 20-20=0
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, p1);
    });

    test('24. Win condition triggers state=finished and sets winnerId', () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 20);

      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1 wins
      expect(provider.currentGame!.state, LunarLanderGameState.finished);
      expect(provider.currentGame!.winnerId, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 5 — Multi-Player
  // ═══════════════════════════════════════════════════════════════════
  group('Group 5 — Multi-Player', () {
    test('25. Game with 2 players cycles correctly', () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 200);

      expect(provider.getCurrentPlayerId(), 'p1');
      _throwFullTurn(provider, 10); // p1 done
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p2');
      _throwFullTurn(provider, 10); // p2 done
      provider.advanceTurn();
      expect(provider.getCurrentPlayerId(), 'p1'); // wrapped back
    });

    test('26. Game with 8 players cycles correctly', () {
      final ids =
          List.generate(8, (i) => 'p${i + 1}');
      final provider = createProvider(
          playerIds: ids, startingAltitude: 200);

      for (int i = 0; i < 8; i++) {
        expect(provider.getCurrentPlayerId(), ids[i]);
        _throwFullTurn(provider, 5);
        provider.advanceTurn();
      }
      // After 8 turns we should be back to p1
      expect(provider.getCurrentPlayerId(), ids[0]);
    });

    test('27. Win condition checked only for current player on each dart', () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 50);
      final p1 = 'p1';
      final p2 = 'p2';

      // Reduce p1 to near-zero
      provider.processDartThrow(score: 20, multiplier: 2, sector: 'D20'); // p1: 50-40=10
      expect(provider.getCurrentPlayerId(), p1);
      expect(provider.hasWinner, isFalse);

      // End p1's turn
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1'); // p1: 10-1=9
      provider.processDartThrow(score: 1, multiplier: 1, sector: 'S1'); // p1: 9-1=8
      provider.advanceTurn();

      // p2 is now active; p2 wins — p1 is NOT affected
      expect(provider.getCurrentPlayerId(), p2);
      provider.processDartThrow(score: 25, multiplier: 2, sector: 'D25'); // p2: 50-50=0
      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, p2);
      // p1 is still at 8, not at 0
      expect(provider.getCurrentAltitude(p1), 8);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 6 — Character Assignment
  // ═══════════════════════════════════════════════════════════════════
  group('Group 6 — Character Assignment', () {
    test(
        '28. Each player gets a unique character (no duplicates) when player count ≤ 8',
        () {
      for (final count in [2, 3, 4, 5, 6, 7, 8]) {
        final ids = List.generate(count, (i) => 'p$i');
        final game = createGame(playerIds: ids);
        final chars = game.characterAssignments.values.toList();
        final uniqueChars = chars.toSet();
        expect(uniqueChars.length, count,
            reason: 'Expected $count unique chars for $count players');
      }
    });

    test('29. Character assignments persist across the game (don\'t change mid-game)',
        () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 200);
      final game = provider.currentGame!;

      final charBefore =
          Map<String, LunarLanderCharacter>.from(game.characterAssignments);

      // Play a few turns
      _throwFullTurn(provider, 10);
      provider.advanceTurn();
      _throwFullTurn(provider, 10);
      provider.advanceTurn();

      // Characters must not have changed
      expect(game.characterAssignments, equals(charBefore));
    });

    test('30. characterAssignments populated for every playerId', () {
      final ids = ['p1', 'p2', 'p3', 'p4'];
      final game = createGame(playerIds: ids);

      for (final id in ids) {
        expect(game.characterAssignments.containsKey(id), isTrue,
            reason: 'Player $id should have a character');
        expect(game.characterAssignments[id], isNotNull);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 7 — Edit Score
  // ═══════════════════════════════════════════════════════════════════
  group('Group 7 — Edit Score', () {
    test('31. Edit dart score updates altitude correctly (replay from turnStartAltitude)',
        () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'], startingAltitude: 100);
      final playerId = provider.getCurrentPlayerId()!;

      // Throw 3 darts: 10+10+10 = 30 → altitude 70
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      provider.processDartThrow(score: 10, multiplier: 1, sector: 'S10');
      expect(provider.getCurrentAltitude(playerId), 70);

      // Edit dart 0: change from score=10 (value=10) to score=20 (value=20)
      // After edit: 20+10+10 = 40 → altitude 60
      provider.editPlayerScore(
          playerId: playerId,
          dartIndex: 0,
          newScore: 20,
          newMultiplier: 1);

      expect(provider.getCurrentAltitude(playerId), 60);
    });

    test(
        '32. Edit dart score can change game outcome (e.g., turn an overshoot into a win)',
        () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 20,
          hardLandingEnabled: false);
      final playerId = provider.getCurrentPlayerId()!;

      // Throw a small dart, no win yet
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5'); // 20-5=15
      provider.processDartThrow(score: 5, multiplier: 1, sector: 'S5'); // 15-5=10
      expect(provider.hasWinner, isFalse);

      // Edit dart 0 to score=20 (value 20): 20+5+5=30 → overshoot -10 → win (hard landing off)
      provider.editPlayerScore(
          playerId: playerId,
          dartIndex: 0,
          newScore: 20,
          newMultiplier: 1);

      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.winnerId, playerId);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Serialization Round-Trip
  // ═══════════════════════════════════════════════════════════════════
  group('Serialization — toJson / fromJson round-trip', () {
    test('All fields preserved through toJson/fromJson', () {
      final provider = createProvider(
          playerIds: ['p1', 'p2'],
          startingAltitude: 150,
          hardLandingEnabled: true);

      // Play some darts to create non-trivial state
      provider.processDartThrow(score: 20, multiplier: 1, sector: 'S20'); // p1: 150-20=130
      provider.processDartThrow(score: 10, multiplier: 2, sector: 'D10'); // p1: 130-20=110

      final game = provider.currentGame!;
      final json = game.toJson();
      final restored = LunarLanderGame.fromJson(json);

      expect(restored.id, game.id);
      expect(
          restored.startedAt.toIso8601String(), game.startedAt.toIso8601String());
      expect(restored.startingAltitude, 150);
      expect(restored.hardLandingEnabled, isTrue);
      expect(restored.playerIds, game.playerIds);
      expect(restored.characterAssignments, game.characterAssignments);
      expect(restored.currentAltitudes, game.currentAltitudes);
      expect(restored.state, game.state);
      expect(restored.currentPlayerIndex, game.currentPlayerIndex);
      expect(restored.winnerId, game.winnerId);
      expect(restored.dartsThrown, game.dartsThrown);
      expect(restored.totalDartsThrown, game.totalDartsThrown);
      expect(restored.totalTurns, game.totalTurns);
      expect(restored.currentTurnDartScores, game.currentTurnDartScores);
      expect(restored.dartThrowWasBust, game.dartThrowWasBust);
      expect(restored.turnStartAltitude, game.turnStartAltitude);
      expect(restored.turnStartState, game.turnStartState);
      expect(restored.turnStartWinnerId, game.turnStartWinnerId);
    });
  });
}

// ─── Private Helpers ─────────────────────────────────────────────────────────

/// Throws 3 low-value darts for the current player (non-winning scores).
void _throwFullTurn(LunarLanderProvider provider, int scorePerDart) {
  for (int i = 0; i < 3; i++) {
    if (!provider.isGameActive) break;
    if (provider.shouldPromptTakeout) break;
    provider.processDartThrow(score: scorePerDart, multiplier: 1, sector: 'S$scorePerDart');
  }
}
