import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/models/target_tag_game.dart';
import 'package:dart_games/models/player.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late TargetTagProvider provider;
  late List<Player> players;

  setUp(() {
    mockServer = MockApiServer();
    provider = TargetTagProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  // Helpers to build sector strings from a number
  String singleSector(int number) => 'S$number';
  String doubleSector(int number) => 'D$number';
  String tripleSector(int number) => 'T$number';

  // Helper: complete a player's turn (throw 3 misses then handle takeout)
  void completeTurnWithMisses(TargetTagProvider p) {
    p.processDartThrow('None');
    p.processDartThrow('None');
    p.processDartThrow('None');
    p.handleTakeoutFinished();
  }

  // =====================================================================
  // 1. startSoloGame
  // =====================================================================
  group('startSoloGame', () {
    test('creates a valid solo game with initial state', () {
      provider.startSoloGame(players, 5, false);

      expect(provider.currentGame, isNotNull);
      expect(provider.isGameActive, true);
      expect(provider.currentGame!.mode, GameMode.solo);
      expect(provider.currentGame!.shieldMax, 5);
      expect(provider.currentGame!.soloHeroBonus, false);
      expect(provider.currentGame!.state, GameState.playing);
      // All shields start at 0, nobody tagged in or eliminated
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(provider.getShields(pid), 0);
        expect(provider.isTaggedIn(pid), false);
        expect(provider.isEliminated(pid), false);
      }
    });

    test('rejects fewer than 2 players', () {
      provider.startSoloGame([players[0]], 5, false);
      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('rejects shieldMax below 1', () {
      provider.startSoloGame(players, 0, false);
      expect(provider.currentGame, isNull);
    });

    test('rejects shieldMax above 10', () {
      provider.startSoloGame(players, 11, false);
      expect(provider.currentGame, isNull);
    });

    test('assigns unique target numbers to each player', () {
      provider.startSoloGame(players, 5, false);
      final targets = provider.currentGame!.targetNumbers;
      expect(targets.keys.length, 3);
      // All values unique
      expect(targets.values.toSet().length, 3);
      // All in range 1-20
      for (final t in targets.values) {
        expect(t, inInclusiveRange(1, 20));
      }
    });

    test('first player is the current player', () {
      provider.startSoloGame(players, 5, false);
      expect(provider.getCurrentPlayerId(), 'p1');
      expect(provider.getCurrentPlayer(players)!.name, 'Alice');
    });
  });

  // =====================================================================
  // 2. startTeamGame
  // =====================================================================
  group('startTeamGame', () {
    test('creates a valid team game', () {
      final teams = {'team1': ['p1', 'p2'], 'team2': ['p3']};
      provider.startTeamGame(teams, 4, false);

      expect(provider.currentGame, isNotNull);
      expect(provider.isGameActive, true);
      expect(provider.currentGame!.mode, GameMode.team);
    });

    test('rejects fewer than 3 total players', () {
      final teams = {'team1': ['p1'], 'team2': ['p2']};
      provider.startTeamGame(teams, 4, false);
      expect(provider.currentGame, isNull);
    });

    test('rejects invalid shieldMax', () {
      final teams = {'team1': ['p1', 'p2'], 'team2': ['p3']};
      provider.startTeamGame(teams, 0, false);
      expect(provider.currentGame, isNull);

      provider.startTeamGame(teams, 11, false);
      expect(provider.currentGame, isNull);
    });
  });

  // =====================================================================
  // 3. processDartThrow
  // =====================================================================
  group('processDartThrow', () {
    test('treats "None" as a miss', () {
      provider.startSoloGame(players, 5, false);
      provider.processDartThrow('None');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
      // Shields unchanged for current player
      expect(provider.getShields('p1'), 0);
    });

    test('treats empty string as a miss', () {
      provider.startSoloGame(players, 5, false);
      provider.processDartThrow('');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('parses Bull as number 50', () {
      provider.startSoloGame(players, 5, false);
      // Bull won't match any target (1-20), so it should just count as a dart
      provider.processDartThrow('Bull');
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('sets waitingForTakeout after 3 darts', () {
      provider.startSoloGame(players, 5, false);
      expect(provider.shouldPromptTakeout, false);

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, false);

      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, true);
    });

    test('ignores darts when waitingForTakeout', () {
      provider.startSoloGame(players, 5, false);
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // 4th dart should be ignored
      provider.processDartThrow('None');
      expect(provider.getCurrentPlayerDartsThrown(), 3);
    });

    test('ignores darts when game is not active', () {
      // No game started
      provider.processDartThrow('S5');
      expect(provider.currentGame, isNull);
    });
  });

  // =====================================================================
  // 4. Shield mechanics
  // =====================================================================
  group('shield mechanics', () {
    test('hitting own target builds shields (single)', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      provider.processDartThrow(singleSector(p1Target));
      expect(provider.getShields('p1'), 1);
    });

    test('hitting own target builds shields (double adds 2)', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      provider.processDartThrow(doubleSector(p1Target));
      expect(provider.getShields('p1'), 2);
    });

    test('hitting own target builds shields (triple adds 3)', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      provider.processDartThrow(tripleSector(p1Target));
      expect(provider.getShields('p1'), 3);
    });

    test('shields cap at shieldMax', () {
      provider.startSoloGame(players, 3, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      // Triple should give 3, which is the max
      provider.processDartThrow(tripleSector(p1Target));
      expect(provider.getShields('p1'), 3);
      expect(provider.isTaggedIn('p1'), true);

      // Another hit should not exceed shieldMax
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.getShields('p1'), 3);
    });

    test('reaching shieldMax sets taggedIn to true', () {
      provider.startSoloGame(players, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      expect(provider.isTaggedIn('p1'), false);
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.isTaggedIn('p1'), true);
    });

    test('cannot attack opponent targets until tagged in', () {
      provider.startSoloGame(players, 5, false);
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1 is not tagged in, hitting p2's target does nothing to p2
      provider.processDartThrow(singleSector(p2Target));
      expect(provider.getShields('p2'), 0);
    });

    test('tagged in player can attack opponent shields', () {
      // shieldMax=1 so first self-hit tags in immediately
      provider.startSoloGame(players, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // Build p2 shields first: advance to p2 and self-hit
      completeTurnWithMisses(provider); // p1 turn done
      provider.processDartThrow(singleSector(p2Target)); // p2 builds 1 shield, tagged in
      expect(provider.isTaggedIn('p2'), true);
      expect(provider.getShields('p2'), 1);

      // Now finish p2 turn and p3 turn
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished(); // end p2 turn
      completeTurnWithMisses(provider); // p3 turn done

      // Now it's p1's turn again; tag in p1 first
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.isTaggedIn('p1'), true);

      // Now hit p2's target to subtract shields
      provider.processDartThrow(singleSector(p2Target));
      expect(provider.getShields('p2'), 0);
      expect(provider.isTaggedIn('p2'), false); // lost tagged in since < shieldMax
    });
  });

  // =====================================================================
  // 5. handleTakeoutFinished
  // =====================================================================
  group('handleTakeoutFinished', () {
    test('advances to next player and clears waitingForTakeout', () {
      provider.startSoloGame(players, 5, false);

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.shouldPromptTakeout, true);
      expect(provider.getCurrentPlayerId(), 'p1');

      provider.handleTakeoutFinished();
      expect(provider.shouldPromptTakeout, false);
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('does nothing if not waitingForTakeout', () {
      provider.startSoloGame(players, 5, false);
      provider.handleTakeoutFinished(); // should be a no-op
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('clears waitingForTakeout when game has winner without advancing', () {
      // shieldMax=1, 2 players. Tag in p1, then eliminate p2
      final twoPlayers = [players[0], players[1]];
      provider.startSoloGame(twoPlayers, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1: tag in by hitting own target
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.isTaggedIn('p1'), true);

      // p1: hit p2 target - p2 at 0 shields + hit = eliminated
      provider.processDartThrow(singleSector(p2Target));
      expect(provider.isEliminated('p2'), true);
      expect(provider.hasWinner, true);
      expect(provider.shouldPromptTakeout, true);

      provider.handleTakeoutFinished();
      expect(provider.shouldPromptTakeout, false);
    });
  });

  // =====================================================================
  // 6. Turn cycling
  // =====================================================================
  group('turn cycling', () {
    test('rotates through all players in order', () {
      provider.startSoloGame(players, 5, false);

      expect(provider.getCurrentPlayerId(), 'p1');
      completeTurnWithMisses(provider);

      expect(provider.getCurrentPlayerId(), 'p2');
      completeTurnWithMisses(provider);

      expect(provider.getCurrentPlayerId(), 'p3');
      completeTurnWithMisses(provider);

      // Wraps back to p1
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('skips eliminated players during rotation', () {
      // Setup: 3 players, shieldMax=1
      provider.startSoloGame(players, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1 tags in
      provider.processDartThrow(singleSector(p1Target));
      // p1 eliminates p2 (who has 0 shields)
      provider.processDartThrow(singleSector(p2Target));
      expect(provider.isEliminated('p2'), true);

      // Game should not be over (p3 still alive)
      // But p1 may have won depending on p3 state. p3 is still alive.
      // If there's a winner, the game ends. Let's check:
      // p1 and p3 are alive, so no winner yet.
      if (!provider.hasWinner) {
        provider.processDartThrow('None'); // 3rd dart
        provider.handleTakeoutFinished();

        // Should skip p2 and go to p3
        expect(provider.getCurrentPlayerId(), 'p3');
      }
    });
  });

  // =====================================================================
  // 7. skipTurn
  // =====================================================================
  group('skipTurn', () {
    test('adds Skip markers for remaining darts and sets waitingForTakeout', () {
      provider.startSoloGame(players, 5, false);

      // Throw 1 dart, then skip
      provider.processDartThrow('None');
      provider.skipTurn();

      expect(provider.shouldPromptTakeout, true);
      final darts = provider.getCurrentTurnDarts('p1');
      // 1 miss + 2 skips = 3 display entries
      expect(darts.length, 3);
      expect(darts[1], 'Skip');
      expect(darts[2], 'Skip');
    });

    test('skip with 0 darts thrown adds 3 Skip markers', () {
      provider.startSoloGame(players, 5, false);
      provider.skipTurn();

      expect(provider.shouldPromptTakeout, true);
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts.every((d) => d == 'Skip'), true);
    });

    test('skip is ignored when already waitingForTakeout', () {
      provider.startSoloGame(players, 5, false);
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      // Now waiting for takeout
      provider.skipTurn(); // should be no-op
      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3); // still 3, no extra skips
    });

    test('skip is ignored when game is not active', () {
      provider.skipTurn(); // no game started - should be no-op
      // just ensure no crash
    });
  });

  // =====================================================================
  // 8. Elimination
  // =====================================================================
  group('elimination', () {
    test('player at 0 shields is eliminated when hit by tagged-in opponent', () {
      final twoPlayers = [players[0], players[1]];
      provider.startSoloGame(twoPlayers, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1 tags in
      provider.processDartThrow(singleSector(p1Target));
      // p1 hits p2 (0 shields) -> eliminated
      provider.processDartThrow(singleSector(p2Target));

      expect(provider.isEliminated('p2'), true);
      expect(provider.hasWinner, true);
      expect(provider.getWinner(twoPlayers)!.id, 'p1');
    });

    test('last player standing wins', () {
      final twoPlayers = [players[0], players[1]];
      provider.startSoloGame(twoPlayers, 1, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1 tags in and eliminates p2
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p2Target));

      final winners = provider.getWinners(twoPlayers);
      expect(winners.length, 1);
      expect(winners[0].id, 'p1');
      expect(provider.currentGame!.state, GameState.finished);
    });
  });

  // =====================================================================
  // 9. editScore (updateAllDartScores)
  // =====================================================================
  group('editScore', () {
    test('updateAllDartScores replays turn with new values', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      // Throw 3 misses
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      expect(provider.getShields('p1'), 0);

      // Edit all 3 to be self-hits
      provider.updateAllDartScores('p1', [
        singleSector(p1Target),
        singleSector(p1Target),
        singleSector(p1Target),
      ]);
      expect(provider.getShields('p1'), 3);
    });

    test('updateAllDartScores ignores if not current player', () {
      provider.startSoloGame(players, 5, false);
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // Try to edit p2's darts (but it's p1's turn)
      provider.updateAllDartScores('p2', [
        singleSector(p2Target),
        singleSector(p2Target),
        singleSector(p2Target),
      ]);
      // p2 shields should remain 0
      expect(provider.getShields('p2'), 0);
    });

    test('updateAllDartScores rejects list not of length 3', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');

      // Only 2 darts - should be rejected
      provider.updateAllDartScores('p1', [
        singleSector(p1Target),
        singleSector(p1Target),
      ]);
      expect(provider.getShields('p1'), 0);
    });

    test('updateDartScore edits a single dart and replays', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      // Throw miss, self-hit, miss
      provider.processDartThrow('None');
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow('None');
      expect(provider.getShields('p1'), 1);

      // Edit dart index 0 from miss to self-hit
      provider.updateDartScore('p1', 0, singleSector(p1Target));
      expect(provider.getShields('p1'), 2);
    });
  });

  // =====================================================================
  // 10. clearGame / endGame
  // =====================================================================
  group('clearGame and endGame', () {
    test('clearGame nullifies the game', () {
      provider.startSoloGame(players, 5, false);
      expect(provider.currentGame, isNotNull);

      provider.clearGame();
      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
      expect(provider.shouldPromptTakeout, false);
    });

    test('endGame sets state to finished', () {
      provider.startSoloGame(players, 5, false);
      expect(provider.isGameActive, true);

      provider.endGame();
      expect(provider.currentGame!.state, GameState.finished);
      expect(provider.isGameActive, false);
    });
  });

  // =====================================================================
  // 11. Getters
  // =====================================================================
  group('getters', () {
    test('getActivePlayers returns non-eliminated players', () {
      final twoPlayers = [players[0], players[1]];
      provider.startSoloGame(twoPlayers, 1, false);

      expect(provider.getActivePlayers(), ['p1', 'p2']);

      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      final p2Target = provider.currentGame!.targetNumbers['p2']!;

      // p1 tags in and eliminates p2
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p2Target));

      expect(provider.getActivePlayers(), ['p1']);
    });

    test('getTargetNumber returns assigned target', () {
      provider.startSoloGame(players, 5, false);
      final target = provider.getTargetNumber('p1');
      expect(target, isNotNull);
      expect(target, inInclusiveRange(1, 20));
    });

    test('getters return defaults when no game is active', () {
      expect(provider.getShields('p1'), 0);
      expect(provider.isTaggedIn('p1'), false);
      expect(provider.isEliminated('p1'), false);
      expect(provider.getTargetNumber('p1'), isNull);
      expect(provider.getCurrentPlayerId(), isNull);
      expect(provider.getCurrentPlayer(players), isNull);
      expect(provider.getCurrentPlayerDartsThrown(), 0);
      expect(provider.getCurrentTurnDarts('p1'), isEmpty);
      expect(provider.hasWinner, false);
      expect(provider.getWinner(players), isNull);
      expect(provider.getWinners(players), isEmpty);
      expect(provider.getActivePlayers(), isEmpty);
      expect(provider.isSuddenDeath, false);
    });

    test('getDartThrow tracking lists return correct data', () {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;

      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow('None');

      final taggedInStatus = provider.getDartThrowTaggedInStatus('p1');
      expect(taggedInStatus.length, 2);

      final heroBonusHits = provider.getDartThrowHeroBonusHit('p1');
      expect(heroBonusHits.length, 2);
      expect(heroBonusHits[0], false); // no hero bonus in this game
      expect(heroBonusHits[1], false);

      final reachedMax = provider.getDartThrowReachedMax('p1');
      expect(reachedMax.length, 2);

      final causedElim = provider.getDartThrowCausedElimination('p1');
      expect(causedElim.length, 2);
      expect(causedElim[0], false);
      expect(causedElim[1], false);

      final hitOpponent = provider.getDartThrowHitOpponentTarget('p1');
      expect(hitOpponent.length, 2);
    });
  });

  // =====================================================================
  // Additional: hero bonus
  // =====================================================================
  group('hero bonus', () {
    test('solo hero bonus assigns buff numbers to all players', () {
      provider.startSoloGame(players, 5, true);

      expect(provider.currentGame!.soloHeroBonus, true);
      for (final pid in ['p1', 'p2', 'p3']) {
        expect(provider.isSoloHero(pid), true);
        expect(provider.getSoloHeroBuffNumber(pid), isNotNull);
        expect(provider.getSoloHeroBuffMultiplier(pid), isNotNull);
        expect(
          provider.getSoloHeroBuffMultiplier(pid),
          anyOf('double', 'triple'),
        );
      }
    });

    test('hero buff numbers are distinct from target numbers', () {
      provider.startSoloGame(players, 5, true);
      final targets = provider.currentGame!.targetNumbers.values.toSet();
      final buffs = provider.currentGame!.soloHeroBuffNumbers!.values.toSet();
      // No overlap between target numbers and hero buff numbers
      expect(targets.intersection(buffs), isEmpty);
    });
  });
}
