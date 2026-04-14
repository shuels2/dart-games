import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/models/player.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late MonsterMashProvider provider;
  late List<Player> players;

  setUp(() {
    mockServer = MockApiServer();
    provider = MonsterMashProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  /// Helper: starts a game and returns target numbers so tests can
  /// craft sector strings that hit specific players.
  Map<String, int> startGameAndGetTargets({
    int healthMax = 20,
    bool bonusBuffs = false,
    bool speedPlay = false,
    int roundLimit = 10,
    List<Player>? customPlayers,
  }) {
    final p = customPlayers ?? players;
    provider.startGame(p, healthMax, bonusBuffs, speedPlay, roundLimit);
    final targets = <String, int>{};
    for (final player in p) {
      targets[player.id] = provider.getTargetNumber(player.id)!;
    }
    return targets;
  }

  /// Builds a single-hit sector string for a given number.
  String sectorFor(int number) => 'S$number';
  String doubleSectorFor(int number) => 'D$number';
  String tripleSectorFor(int number) => 'T$number';

  // ─────────────────────────────────────────────────────────────────
  // 1. startGame
  // ─────────────────────────────────────────────────────────────────
  group('startGame', () {
    test('creates a game with valid parameters', () {
      provider.startGame(players, 20, false, false, 10);

      expect(provider.isGameActive, isTrue);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.playerIds, ['p1', 'p2', 'p3']);
      expect(provider.currentGame!.healthMax, 20);
    });

    test('rejects fewer than 2 players', () {
      final solo = [players[0]];
      provider.startGame(solo, 20, false, false, 10);

      expect(provider.isGameActive, isFalse);
      expect(provider.currentGame, isNull);
    });

    test('rejects healthMax below 10', () {
      provider.startGame(players, 5, false, false, 10);

      expect(provider.currentGame, isNull);
    });

    test('rejects healthMax above 50', () {
      provider.startGame(players, 60, false, false, 10);

      expect(provider.currentGame, isNull);
    });

    test('initializes all players to max health', () {
      provider.startGame(players, 30, false, false, 10);

      for (final p in players) {
        expect(provider.getHealth(p.id), 30);
        expect(provider.getHealthPercentage(p.id), 1.0);
        expect(provider.isEliminated(p.id), isFalse);
      }
    });

    test('assigns unique target numbers 1-20 and unique monsters', () {
      provider.startGame(players, 20, false, false, 10);

      final targetNumbers = <int>{};
      final monsters = <MonsterType>{};
      for (final p in players) {
        final target = provider.getTargetNumber(p.id)!;
        expect(target, inInclusiveRange(1, 20));
        targetNumbers.add(target);
        monsters.add(provider.getMonsterType(p.id)!);
      }
      // All unique
      expect(targetNumbers.length, players.length);
      expect(monsters.length, players.length);
    });

    test('first player is current player', () {
      provider.startGame(players, 20, false, false, 10);

      expect(provider.getCurrentPlayerId(), 'p1');
      expect(provider.getCurrentPlayer(players)!.name, 'Alice');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 2. processDartThrow — basic
  // ─────────────────────────────────────────────────────────────────
  group('processDartThrow', () {
    test('records a miss on empty sector', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');

      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getCurrentTurnDarts('p1'), ['Miss']);
    });

    test('records a miss on empty string', () {
      startGameAndGetTargets();

      provider.processDartThrow('');

      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getCurrentTurnDarts('p1'), ['Miss']);
    });

    test('sets waitingForTakeout after 3 darts', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isFalse);

      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isTrue);
    });

    test('ignores throws when waitingForTakeout', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isTrue);

      // This should be ignored
      provider.processDartThrow('None');
      expect(provider.getCurrentPlayerDartsThrown(), 3);
    });

    test('ignores throws when game is not active', () {
      startGameAndGetTargets();

      provider.endGame();
      provider.processDartThrow('S5');

      expect(provider.getCurrentPlayerDartsThrown(), 0);
    });

    test('parses single, double, and triple sectors', () {
      final targets = startGameAndGetTargets();
      final opponentTarget = targets['p2']!;

      // Throw a single at the opponent's number — should deal 1 damage
      provider.processDartThrow('S$opponentTarget');
      expect(provider.getHealth('p2'), 19);

      provider.processDartThrow('D$opponentTarget');
      expect(provider.getHealth('p2'), 17); // 19 - 2

      provider.processDartThrow('T$opponentTarget');
      expect(provider.getHealth('p2'), 14); // 17 - 3
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 3. Health mechanics — heal and damage
  // ─────────────────────────────────────────────────────────────────
  group('health mechanics', () {
    test('hitting own target number heals self (single = +1)', () {
      final targets = startGameAndGetTargets();
      final ownTarget = targets['p1']!;

      // Damage p1 first so healing is observable
      // Manually set health lower
      provider.currentGame!.health['p1'] = 15;

      provider.processDartThrow('S$ownTarget');
      expect(provider.getHealth('p1'), 16);
    });

    test('hitting own target with double heals +2', () {
      final targets = startGameAndGetTargets();
      final ownTarget = targets['p1']!;
      provider.currentGame!.health['p1'] = 15;

      provider.processDartThrow('D$ownTarget');
      expect(provider.getHealth('p1'), 17);
    });

    test('hitting own target with triple heals +3', () {
      final targets = startGameAndGetTargets();
      final ownTarget = targets['p1']!;
      provider.currentGame!.health['p1'] = 15;

      provider.processDartThrow('T$ownTarget');
      expect(provider.getHealth('p1'), 18);
    });

    test('healing does not exceed healthMax', () {
      final targets = startGameAndGetTargets();
      final ownTarget = targets['p1']!;

      // p1 at full health (20); hitting own target should not go above 20
      provider.processDartThrow('T$ownTarget');
      expect(provider.getHealth('p1'), 20);
    });

    test('hitting opponent target damages them', () {
      final targets = startGameAndGetTargets();
      final opponentTarget = targets['p2']!;

      provider.processDartThrow('S$opponentTarget');
      expect(provider.getHealth('p2'), 19);
    });

    test('outer bull (25) heals +5', () {
      startGameAndGetTargets();
      provider.currentGame!.health['p1'] = 10;

      provider.processDartThrow('25');
      expect(provider.getHealth('p1'), 15);
    });

    test('bullseye (Bull / 50) heals to max', () {
      startGameAndGetTargets();
      provider.currentGame!.health['p1'] = 5;

      provider.processDartThrow('Bull');
      expect(provider.getHealth('p1'), 20);
    });

    test('hitting an unassigned number does nothing', () {
      final targets = startGameAndGetTargets();
      // Find a number that nobody owns
      final assignedNumbers = targets.values.toSet();
      int freeNumber = 1;
      while (assignedNumbers.contains(freeNumber)) {
        freeNumber++;
      }

      final healthBefore = provider.getHealth('p1');
      provider.processDartThrow('S$freeNumber');
      expect(provider.getHealth('p1'), healthBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 4. Elimination
  // ─────────────────────────────────────────────────────────────────
  group('elimination', () {
    test('player is eliminated when health reaches 0', () {
      final targets = startGameAndGetTargets();
      final opponentTarget = targets['p2']!;

      // Set p2 health to 1 so a single hit eliminates
      provider.currentGame!.health['p2'] = 1;

      provider.processDartThrow('S$opponentTarget');
      expect(provider.getHealth('p2'), 0);
      expect(provider.isEliminated('p2'), isTrue);
    });

    test('eliminated player is skipped during turn cycling', () {
      final targets = startGameAndGetTargets();
      final p2Target = targets['p2']!;

      // Eliminate p2
      provider.currentGame!.health['p2'] = 1;
      provider.processDartThrow('S$p2Target');
      // Fill remaining darts
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // Advance past p1
      provider.handleTakeoutFinished();

      // p2 is eliminated, so current player should be p3
      expect(provider.getCurrentPlayerId(), 'p3');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 5. handleTakeoutFinished
  // ─────────────────────────────────────────────────────────────────
  group('handleTakeoutFinished', () {
    test('advances to next player and clears waitingForTakeout', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isTrue);

      provider.handleTakeoutFinished();
      expect(provider.shouldPromptTakeout, isFalse);
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('does nothing if not waitingForTakeout', () {
      startGameAndGetTargets();

      provider.handleTakeoutFinished();
      // Should still be p1's turn
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('resets darts thrown for the previous player', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // p1's dart count should be reset
      expect(provider.currentGame!.dartsThrown['p1'], 0);
      expect(provider.currentGame!.currentTurnDarts['p1'], isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 6. Turn cycling
  // ─────────────────────────────────────────────────────────────────
  group('turn cycling', () {
    test('cycles through all players in order', () {
      startGameAndGetTargets();

      // p1 turn
      expect(provider.getCurrentPlayerId(), 'p1');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // p2 turn
      expect(provider.getCurrentPlayerId(), 'p2');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // p3 turn
      expect(provider.getCurrentPlayerId(), 'p3');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // Back to p1
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('round increments after all active players have played', () {
      startGameAndGetTargets();

      expect(provider.getCurrentRound(), 1);

      // Complete a full round
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.handleTakeoutFinished();
      }

      expect(provider.getCurrentRound(), 2);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 7. skipTurn
  // ─────────────────────────────────────────────────────────────────
  group('skipTurn', () {
    test('adds Skip markers for remaining darts', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.skipTurn();

      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts, ['Miss', 'Skip', 'Skip']);
      expect(provider.shouldPromptTakeout, isTrue);
    });

    test('skipping with 0 darts thrown adds 3 Skip markers', () {
      startGameAndGetTargets();

      provider.skipTurn();

      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts, ['Skip', 'Skip', 'Skip']);
      expect(provider.shouldPromptTakeout, isTrue);
    });

    test('cannot skip when already waitingForTakeout', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isTrue);

      // skipTurn should be a no-op
      final dartsBefore = List<String>.from(provider.getCurrentTurnDarts('p1'));
      provider.skipTurn();
      expect(provider.getCurrentTurnDarts('p1'), dartsBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 8. Win detection
  // ─────────────────────────────────────────────────────────────────
  group('win detection', () {
    test('last player standing wins', () {
      final twoPlayers = [players[0], players[1]];
      final targets = startGameAndGetTargets(customPlayers: twoPlayers);
      final p2Target = targets['p2']!;

      // Set p2 to 1 HP and eliminate with a hit
      provider.currentGame!.health['p2'] = 1;
      provider.processDartThrow('S$p2Target');

      expect(provider.hasWinner, isTrue);
      expect(provider.currentGame!.state, MonsterMashGameState.finished);
      expect(provider.getWinner(twoPlayers)!.id, 'p1');
    });

    test('game ends immediately on elimination (does not require 3 darts)', () {
      final twoPlayers = [players[0], players[1]];
      final targets = startGameAndGetTargets(customPlayers: twoPlayers);
      final p2Target = targets['p2']!;

      provider.currentGame!.health['p2'] = 1;

      // First dart eliminates p2
      provider.processDartThrow('S$p2Target');
      expect(provider.hasWinner, isTrue);
      expect(provider.shouldPromptTakeout, isTrue);
      // Only 1 dart was thrown
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('speed play: round limit reached determines winner by health', () {
      final twoPlayers = [players[0], players[1]];
      startGameAndGetTargets(
        customPlayers: twoPlayers,
        speedPlay: true,
        roundLimit: 1,
      );

      // Damage p2 so p1 has more health
      final targets = <String, int>{};
      for (final p in twoPlayers) {
        targets[p.id] = provider.getTargetNumber(p.id)!;
      }
      final p2Target = targets['p2']!;

      provider.processDartThrow('S$p2Target');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // p2's turn — complete round 1
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // Round should have advanced past the limit, finishing the game
      expect(provider.currentGame!.state, MonsterMashGameState.finished);
      expect(provider.hasWinner, isTrue);
      expect(provider.getWinner(twoPlayers)!.id, 'p1');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 9. editScore — updateDartScore / updateAllDartScores
  // ─────────────────────────────────────────────────────────────────
  group('editScore', () {
    test('updateDartScore replays turn with edited dart', () {
      final targets = startGameAndGetTargets();
      final p2Target = targets['p2']!;

      // Throw 3 misses
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // p2 should still be at full health
      expect(provider.getHealth('p2'), 20);

      // Edit dart 1 (index 1) to hit p2's target
      provider.updateDartScore('p1', 1, 'S$p2Target');

      // Now p2 should have taken 1 damage
      expect(provider.getHealth('p2'), 19);
    });

    test('updateDartScore ignores if playerId is not current player', () {
      final targets = startGameAndGetTargets();
      final p2Target = targets['p2']!;

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // Try to edit p2's darts — should be ignored since p1 is current
      provider.updateDartScore('p2', 0, 'S$p2Target');
      expect(provider.getHealth('p2'), 20); // No change
    });

    test('updateAllDartScores replays all 3 darts', () {
      final targets = startGameAndGetTargets();
      final p2Target = targets['p2']!;

      // Throw 3 misses
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      expect(provider.getHealth('p2'), 20);

      // Replace all 3 darts with hits on p2
      provider.updateAllDartScores('p1', [
        'S$p2Target',
        'S$p2Target',
        'S$p2Target',
      ]);

      // 3 single hits = 3 damage
      expect(provider.getHealth('p2'), 17);
    });

    test('updateAllDartScores rejects if not exactly 3 darts', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      final healthBefore = provider.getHealth('p2');
      provider.updateAllDartScores('p1', ['Miss', 'Miss']);
      expect(provider.getHealth('p2'), healthBefore);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // 10. clearGame / endGame
  // ─────────────────────────────────────────────────────────────────
  group('clearGame / endGame', () {
    test('endGame sets state to finished', () {
      startGameAndGetTargets();

      provider.endGame();
      expect(provider.currentGame!.state, MonsterMashGameState.finished);
      expect(provider.isGameActive, isFalse);
    });

    test('clearGame removes the game entirely', () {
      startGameAndGetTargets();

      provider.clearGame();
      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, isFalse);
      expect(provider.shouldPromptTakeout, isFalse);
    });

    test('clearGame resets waitingForTakeout', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, isTrue);

      provider.clearGame();
      expect(provider.shouldPromptTakeout, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Bonus: dart throw tracking arrays
  // ─────────────────────────────────────────────────────────────────
  group('dart throw tracking', () {
    test('records heal amount when hitting own target', () {
      final targets = startGameAndGetTargets();
      final ownTarget = targets['p1']!;
      provider.currentGame!.health['p1'] = 15;

      provider.processDartThrow('S$ownTarget');

      final heals = provider.getDartThrowHealAmount('p1');
      expect(heals, [1]);
      final damages = provider.getDartThrowDamageDealt('p1');
      expect(damages, [0]);
    });

    test('records damage dealt when hitting opponent target', () {
      final targets = startGameAndGetTargets();
      final p2Target = targets['p2']!;

      provider.processDartThrow('S$p2Target');

      final damages = provider.getDartThrowDamageDealt('p1');
      expect(damages, [1]);
      final targetIds = provider.getDartThrowTargetPlayerId('p1');
      expect(targetIds, ['p2']);
    });

    test('records zero heal and zero damage on miss', () {
      startGameAndGetTargets();

      provider.processDartThrow('None');

      final heals = provider.getDartThrowHealAmount('p1');
      expect(heals, [0]);
      final damages = provider.getDartThrowDamageDealt('p1');
      expect(damages, [0]);
    });
  });
}
