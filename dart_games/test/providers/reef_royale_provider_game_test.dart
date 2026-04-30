import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/models/player.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late ReefRoyaleProvider provider;
  late List<Player> players;

  setUp(() {
    mockServer = MockApiServer();
    provider = ReefRoyaleProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
    ];
  });

  /// Helper: start a standard 2-player game with common defaults.
  void startStandardGame({
    bool easyClaim = false,
    bool neighborNumbers = false,
    bool randomReefs = false,
    bool bonusBuffs = false,
    bool showHints = false,
    bool speedPlay = false,
    int roundLimit = 10,
    ReefRoyaleGameMode gameMode = ReefRoyaleGameMode.standard,
    List<Player>? customPlayers,
  }) {
    provider.startGame(
      customPlayers ?? players,
      gameMode,
      easyClaim,
      neighborNumbers,
      randomReefs,
      bonusBuffs,
      showHints,
      speedPlay,
      roundLimit,
    );
  }

  // -------------------------------------------------------
  // 1. startGame
  // -------------------------------------------------------
  group('startGame', () {
    test('creates a game with valid 2-player input', () {
      startStandardGame();

      expect(provider.currentGame, isNotNull);
      expect(provider.isGameActive, true);
      expect(provider.currentGame!.playerIds, ['p1', 'p2']);
      expect(provider.currentGame!.state, ReefRoyaleGameState.playing);
    });

    test('rejects fewer than 2 players', () {
      provider.startGame(
        [Player(id: 'p1', name: 'Solo', createdAt: DateTime.now())],
        ReefRoyaleGameMode.standard,
        false, false, false, false, false, false, 10,
      );

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('initialises marks to zero for all players and targets', () {
      startStandardGame();

      final game = provider.currentGame!;
      for (final pid in game.playerIds) {
        for (final target in game.activeTargets) {
          expect(provider.getPlayerMarks(pid, target), 0);
        }
      }
    });

    test('sets correct game mode', () {
      startStandardGame(gameMode: ReefRoyaleGameMode.cursedTide);

      expect(provider.getGameMode(), ReefRoyaleGameMode.cursedTide);
    });

    test('uses standard targets when randomReefs is false', () {
      startStandardGame(randomReefs: false);

      expect(provider.currentGame!.activeTargets,
          ReefRoyaleGame.standardTargets);
    });

    test('first player is at index 0', () {
      startStandardGame();

      expect(provider.getCurrentPlayerId(), 'p1');
      expect(provider.getCurrentPlayerDartsThrown(), 0);
    });
  });

  // -------------------------------------------------------
  // 2. processDartThrow — miss handling and sector parsing
  // -------------------------------------------------------
  group('processDartThrow', () {
    test('miss with None string records a miss', () {
      startStandardGame();

      provider.processDartThrow('None');

      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getCurrentTurnDarts('p1'), ['Miss']);
    });

    test('miss with empty string records a miss', () {
      startStandardGame();

      provider.processDartThrow('');

      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getCurrentTurnDarts('p1'), ['Miss']);
    });

    test('non-target number records the sector text', () {
      startStandardGame(); // standard targets: 20,19,18,17,16,15,25

      // 1 is not a target
      provider.processDartThrow('S1');

      expect(provider.getCurrentPlayerDartsThrown(), 1);
      expect(provider.getCurrentTurnDarts('p1'), ['S1']);
    });

    test('3 darts sets waitingForTakeout', () {
      startStandardGame();

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');

      expect(provider.shouldPromptTakeout, true);
    });

    test('4th dart is rejected when waitingForTakeout', () {
      startStandardGame();

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.processDartThrow('S17'); // should be ignored

      expect(provider.getCurrentPlayerDartsThrown(), 3);
      expect(provider.getCurrentTurnDarts('p1').length, 3);
    });

    test('parses Bull sector correctly', () {
      startStandardGame();

      provider.processDartThrow('Bull');

      // Bull maps to target 25 (inner bull = 2 marks)
      expect(provider.getPlayerMarks('p1', 25), 2);
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('parses outer bull (25) sector correctly', () {
      startStandardGame();

      provider.processDartThrow('25');

      // 25 = outer bull = 1 mark on target 25
      expect(provider.getPlayerMarks('p1', 25), 1);
    });

    test('parses double sector correctly', () {
      startStandardGame();

      provider.processDartThrow('D20');

      expect(provider.getPlayerMarks('p1', 20), 2);
    });

    test('parses triple sector correctly', () {
      startStandardGame();

      provider.processDartThrow('T20');

      expect(provider.getPlayerMarks('p1', 20), 3);
    });
  });

  // -------------------------------------------------------
  // 3. Marks system
  // -------------------------------------------------------
  group('marks system', () {
    test('single hit adds 1 mark (standard threshold=3)', () {
      startStandardGame(easyClaim: false);

      provider.processDartThrow('S20');

      expect(provider.getPlayerMarks('p1', 20), 1);
      expect(provider.hasPlayerClaimed('p1', 20), false);
    });

    test('easyClaim uses threshold of 2', () {
      startStandardGame(easyClaim: true);

      expect(provider.currentGame!.markThreshold, 2);
    });

    test('standard uses threshold of 3', () {
      startStandardGame(easyClaim: false);

      expect(provider.currentGame!.markThreshold, 3);
    });

    test('riptideRush buff doubles marks', () {
      startStandardGame();

      provider.setActiveBuff(ReefBuff.riptideRush);
      provider.processDartThrow('S20');

      // single = 1 mark, doubled by riptide = 2
      expect(provider.getPlayerMarks('p1', 20), 2);
    });
  });

  // -------------------------------------------------------
  // 4. Claiming
  // -------------------------------------------------------
  group('claiming', () {
    test('reaching mark threshold claims the coral', () {
      startStandardGame(easyClaim: false); // threshold = 3

      provider.processDartThrow('T20'); // triple = 3 marks

      expect(provider.hasPlayerClaimed('p1', 20), true);
      expect(provider.getPlayerClaimedCount('p1'), 1);
    });

    test('easyClaim claims with 2 marks', () {
      startStandardGame(easyClaim: true); // threshold = 2

      provider.processDartThrow('D20'); // double = 2 marks

      expect(provider.hasPlayerClaimed('p1', 20), true);
    });

    test('target locks when all players claim it', () {
      startStandardGame(easyClaim: false); // threshold = 3

      // Player 1 claims target 20
      provider.processDartThrow('T20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.handleTakeoutFinished();

      // Player 2 claims target 20
      provider.processDartThrow('T20');

      expect(provider.isTargetLocked(20), true);
    });

    test('target not locked until all players claim', () {
      startStandardGame(easyClaim: false);

      // Only player 1 claims target 20
      provider.processDartThrow('T20');

      expect(provider.isTargetLocked(20), false);
    });
  });

  // -------------------------------------------------------
  // 5. handleTakeoutFinished
  // -------------------------------------------------------
  group('handleTakeoutFinished', () {
    test('advances to next player after takeout', () {
      startStandardGame();

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      expect(provider.shouldPromptTakeout, true);

      provider.handleTakeoutFinished();

      expect(provider.getCurrentPlayerId(), 'p2');
      expect(provider.shouldPromptTakeout, false);
      expect(provider.getCurrentPlayerDartsThrown(), 0);
    });

    test('does nothing when not waiting for takeout', () {
      startStandardGame();

      provider.processDartThrow('S20');
      // Only 1 dart thrown, not waiting for takeout
      expect(provider.shouldPromptTakeout, false);

      provider.handleTakeoutFinished();

      // Still player 1
      expect(provider.getCurrentPlayerId(), 'p1');
    });
  });

  // -------------------------------------------------------
  // 6. Turn cycling
  // -------------------------------------------------------
  group('turn cycling', () {
    test('cycles through players in order', () {
      startStandardGame();

      expect(provider.getCurrentPlayerId(), 'p1');

      // Player 1 full turn
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.handleTakeoutFinished();

      expect(provider.getCurrentPlayerId(), 'p2');

      // Player 2 full turn
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.handleTakeoutFinished();

      // Back to player 1, round 2
      expect(provider.getCurrentPlayerId(), 'p1');
      expect(provider.getCurrentRound(), 2);
    });

    test('round increments after all players complete a turn', () {
      startStandardGame();

      expect(provider.getCurrentRound(), 1);

      // Complete round 1
      for (int i = 0; i < 2; i++) {
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.handleTakeoutFinished();
      }

      expect(provider.getCurrentRound(), 2);
    });
  });

  // -------------------------------------------------------
  // 7. skipTurn
  // -------------------------------------------------------
  group('skipTurn', () {
    test('adds skip markers for remaining darts', () {
      startStandardGame();

      provider.processDartThrow('S20'); // 1 dart thrown
      provider.skipTurn();

      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts[1], 'Skip');
      expect(darts[2], 'Skip');
      expect(provider.shouldPromptTakeout, true);
    });

    test('skip with zero darts thrown adds 3 skip markers', () {
      startStandardGame();

      provider.skipTurn();

      final darts = provider.getCurrentTurnDarts('p1');
      expect(darts.length, 3);
      expect(darts.every((d) => d == 'Skip'), true);
      expect(provider.shouldPromptTakeout, true);
    });

    test('cannot skip when already waiting for takeout', () {
      startStandardGame();

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      // Already at 3 darts, waitingForTakeout
      expect(provider.shouldPromptTakeout, true);

      provider.skipTurn(); // should be no-op

      expect(provider.getCurrentTurnDarts('p1').length, 3);
    });
  });

  // -------------------------------------------------------
  // 8. editScore (updateDartScore / updateAllDartScores)
  // -------------------------------------------------------
  group('editScore', () {
    test('updateDartScore replays turn with corrected dart', () {
      startStandardGame(easyClaim: false);

      provider.processDartThrow('S20'); // 1 mark on 20
      provider.processDartThrow('S19'); // 1 mark on 19
      provider.processDartThrow('S18'); // 1 mark on 18

      // Correct dart 0 from S20 to T20 (3 marks on 20 = claim)
      provider.updateDartScore('p1', 0, 'T20');

      expect(provider.getPlayerMarks('p1', 20), 3);
      expect(provider.hasPlayerClaimed('p1', 20), true);
      // Other darts should still be applied
      expect(provider.getPlayerMarks('p1', 19), 1);
      expect(provider.getPlayerMarks('p1', 18), 1);
    });

    test('updateAllDartScores replays all three darts', () {
      startStandardGame(easyClaim: false);

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');

      // Replace all three with misses
      provider.updateAllDartScores('p1', ['Miss', 'Miss', 'Miss']);

      expect(provider.getPlayerMarks('p1', 20), 0);
      expect(provider.getPlayerMarks('p1', 19), 0);
      expect(provider.getPlayerMarks('p1', 18), 0);
    });

    test('updateDartScore ignores wrong player', () {
      startStandardGame();

      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');

      // Try to edit for p2 (not the current player)
      provider.updateDartScore('p2', 0, 'T20');

      // p1's marks should be unchanged
      expect(provider.getPlayerMarks('p1', 20), 1);
    });
  });

  // -------------------------------------------------------
  // 9. clearGame / endGame
  // -------------------------------------------------------
  group('clearGame and endGame', () {
    test('endGame sets state to finished', () {
      startStandardGame();

      provider.endGame();

      expect(provider.currentGame!.state, ReefRoyaleGameState.finished);
      expect(provider.isGameActive, false);
    });

    test('clearGame nullifies the game', () {
      startStandardGame();

      provider.clearGame();

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
      expect(provider.shouldPromptTakeout, false);
    });

    test('processDartThrow does nothing after endGame', () {
      startStandardGame();
      provider.endGame();

      provider.processDartThrow('S20');

      expect(provider.getCurrentPlayerDartsThrown(), 0);
    });

    test('processDartThrow does nothing after clearGame', () {
      startStandardGame();
      provider.clearGame();

      // Should not throw
      provider.processDartThrow('S20');

      expect(provider.currentGame, isNull);
    });
  });

  // -------------------------------------------------------
  // 10. Getters
  // -------------------------------------------------------
  group('getters', () {
    test('getPlayerPearls returns 0 initially', () {
      startStandardGame();

      expect(provider.getPlayerPearls('p1'), 0);
      expect(provider.getPlayerPearls('p2'), 0);
    });

    test('getPlayerClaimedCount returns correct count', () {
      startStandardGame(easyClaim: false);

      provider.processDartThrow('T20'); // claim target 20
      expect(provider.getPlayerClaimedCount('p1'), 1);
    });

    test('getRankedPlayerIds ranks by claimed count then pearls', () {
      startStandardGame(easyClaim: false);

      // Player 1 claims target 20
      provider.processDartThrow('T20');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      // Player 2 throws misses
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.processDartThrow('None');
      provider.handleTakeoutFinished();

      final ranked = provider.getRankedPlayerIds();
      expect(ranked.first, 'p1');
    });

    test('getActiveBuff returns null by default', () {
      startStandardGame();

      expect(provider.getActiveBuff(), isNull);
    });

    test('setActiveBuff updates the buff', () {
      startStandardGame();

      provider.setActiveBuff(ReefBuff.pearlFever);

      expect(provider.getActiveBuff(), ReefBuff.pearlFever);
    });

    test('getCurrentRound starts at 1', () {
      startStandardGame();

      expect(provider.getCurrentRound(), 1);
    });

    test('getters return defaults when no game is active', () {
      // No game started
      expect(provider.getPlayerPearls('p1'), 0);
      expect(provider.getPlayerClaimedCount('p1'), 0);
      expect(provider.getPlayerMarks('p1', 20), 0);
      expect(provider.hasPlayerClaimed('p1', 20), false);
      expect(provider.isTargetLocked(20), false);
      expect(provider.getActiveBuff(), isNull);
      expect(provider.getCurrentRound(), 1);
      expect(provider.getRankedPlayerIds(), isEmpty);
      expect(provider.getGameMode(), isNull);
      expect(provider.getCurrentPlayerId(), isNull);
    });

    test('pearls scored after claiming in standard mode', () {
      startStandardGame(easyClaim: false);

      // p1 claims target 20 with triple
      provider.processDartThrow('T20');
      expect(provider.hasPlayerClaimed('p1', 20), true);

      // p1 hits claimed target 20 again — scores pearls (opponent p2 has not claimed it)
      provider.processDartThrow('S20');

      expect(provider.getPlayerPearls('p1'), 20); // 20 * 1 = 20 pearls
    });
  });
}
