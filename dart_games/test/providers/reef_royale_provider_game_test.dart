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
    bool includeBull = false,
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
      includeBull: includeBull,
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
  // 8. editScore (updateAllDartScores)
  // -------------------------------------------------------
  group('editScore', () {

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

  // -------------------------------------------------------
  // Win condition regression — claim-all-then-overtake
  // -------------------------------------------------------
  group('win condition', () {
    test('declares winner when a player who already claimed all corals '
        'later takes the pearl lead', () {
      // Regression for the bug where ReefRoyaleGame._checkWinCondition was
      // only called from _processMarkingForTarget (the path that runs while
      // a player is still claiming corals). Once Alice has claimed all 7
      // corals, EVERY subsequent dart she throws routes through
      // _processScoringForTarget, which updates pearls but used to NEVER
      // re-check the win condition. The bug: Alice could overtake Bob on
      // pearls and the engine would silently stay in `playing` state.
      //
      // Fix: call _checkWinCondition at the end of processDart.
      //
      // Scenario:
      //   * 3 players (P3 stays idle so no coral ever gets fully locked).
      //   * Alice claims all 7 corals via triples with 0 excess marks ->
      //     0 pearls accumulated.
      //   * Bob claims target 20 (also 0 excess) then over-hits it twice
      //     with singles -> 40 pearls.
      //   * Alice finishes claiming all 7 corals while still on 0 pearls;
      //     game must continue (no pearl lead).
      //   * Alice throws T20 next turn -> already claimed by Alice -> Path
      //     B scoring -> 60 pearls -> Alice now leads.
      //   * With the fix in place, the end-of-processDart _checkWinCondition
      //     call sees claimed-all + pearl-lead and declares Alice the winner.
      final threePlayers = [
        Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
        Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
        Player(id: 'p3', name: 'Carol', createdAt: DateTime.now()),
      ];
      startStandardGame(customPlayers: threePlayers);

      void missTurn() {
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.processDartThrow('None');
        provider.handleTakeoutFinished();
      }

      // Turn 1 — Alice claims 20, 19, 18 (0 pearls).
      expect(provider.getCurrentPlayerId(), 'p1');
      provider.processDartThrow('T20');
      provider.processDartThrow('T19');
      provider.processDartThrow('T18');
      provider.handleTakeoutFinished();
      expect(provider.getPlayerPearls('p1'), 0);
      expect(provider.getPlayerClaimedCount('p1'), 3);

      // Turn 2 — Bob claims target 20 with 0 excess, then over-hits twice
      // (singles on his own claimed target while Carol still hasn't
      // claimed it -> Path B scoring fires).
      expect(provider.getCurrentPlayerId(), 'p2');
      provider.processDartThrow('T20'); // mark to threshold, 0 excess
      provider.processDartThrow('S20'); // Path B: 20 * 1 = 20 pearls
      provider.processDartThrow('S20'); // Path B: 20 more pearls
      provider.handleTakeoutFinished();
      expect(provider.hasPlayerClaimed('p2', 20), isTrue);
      expect(provider.getPlayerPearls('p2'), 40);

      // Turn 3 — Carol misses.
      expect(provider.getCurrentPlayerId(), 'p3');
      missTurn();
      expect(provider.getPlayerPearls('p3'), 0);

      // Turn 4 — Alice claims 17, 16, 15 (still 0 pearls).
      expect(provider.getCurrentPlayerId(), 'p1');
      provider.processDartThrow('T17');
      provider.processDartThrow('T16');
      provider.processDartThrow('T15');
      provider.handleTakeoutFinished();
      expect(provider.getPlayerClaimedCount('p1'), 6);

      // Turns 5 & 6 — Bob and Carol both miss.
      missTurn();
      missTurn();

      // Turn 7 — Alice claims target 25 (the Bull coral) with three
      // '25' outer-bull darts (1 mark each, 3 = threshold, 0 excess).
      // Inner '50' Bull would be 2 marks/dart and would push excess
      // marks onto the threshold-cross dart, leaking pearls; '25'
      // keeps Alice's pearls at exactly 0 here.
      expect(provider.getCurrentPlayerId(), 'p1');
      provider.processDartThrow('25');
      provider.processDartThrow('25');
      provider.processDartThrow('25');
      expect(provider.hasPlayerClaimed('p1', 25), isTrue);

      // Alice has all 7 corals but no pearl lead — game must continue.
      // This is the moment the OLD code would also-correctly stay in
      // `playing` state; the bug surfaces on subsequent darts.
      expect(provider.getPlayerClaimedCount('p1'), 7);
      expect(provider.getPlayerPearls('p1'), 0);
      expect(provider.getPlayerPearls('p2'), 40);
      expect(provider.hasWinner, isFalse,
          reason: 'Alice has all corals but no pearl lead — game must '
              'continue');
      provider.handleTakeoutFinished();

      // Turns 8 & 9 — Bob and Carol miss.
      missTurn();
      missTurn();

      // Turn 10 — Alice throws T20. She has already claimed 20, so this
      // routes through _processScoringForTarget. Bob has also claimed
      // 20, but Carol still hasn't, so `anyOpponentUnclaimed` is true
      // and pearls flow to Alice: target 20 * triple = 60.
      //
      // WITHOUT the fix: hasWinner stays false here — _checkWinCondition
      //   was only wired into the marking path, never the scoring path,
      //   and Alice has already finished marking everything she can.
      // WITH the fix: _checkWinCondition runs at the end of processDart,
      //   sees Alice has all 7 corals and 60 > Bob's 40 pearls, and
      //   declares her the winner immediately.
      expect(provider.getCurrentPlayerId(), 'p1');
      provider.processDartThrow('T20');

      expect(provider.getPlayerPearls('p1'), 60);
      expect(provider.hasWinner, isTrue,
          reason: 'Alice took the pearl lead after claiming all corals — '
              'the game should end the moment this dart resolves');
      expect(provider.currentGame!.winnerId, 'p1');
      expect(provider.currentGame!.winnerIds, ['p1']);
    });
  });

  // -------------------------------------------------------
  // Include Bull option
  // -------------------------------------------------------
  group('Include Bull option', () {
    test('randomReefs ON + includeBull ON: 7 corals, Bull is the 7th', () {
      startStandardGame(randomReefs: true, includeBull: true);
      final targets = provider.currentGame!.activeTargets;
      expect(targets.length, 7);
      expect(targets.last, 25, reason: 'Bull occupies slot 7');
      // First 6 are unique 1-20.
      final numberTargets = targets.sublist(0, 6);
      expect(numberTargets.toSet().length, 6);
      for (final t in numberTargets) {
        expect(t, inInclusiveRange(1, 20));
      }
    });

    test('randomReefs ON + includeBull OFF: 7 number corals, Bull excluded',
        () {
      startStandardGame(randomReefs: true, includeBull: false);
      final targets = provider.currentGame!.activeTargets;
      expect(targets.length, 7);
      expect(targets.contains(25), isFalse,
          reason: 'Bull (25) must not appear when includeBull is off');
      // All 7 are unique 1-20.
      expect(targets.toSet().length, 7);
      for (final t in targets) {
        expect(t, inInclusiveRange(1, 20));
      }
    });

    test('randomReefs OFF: includeBull is inert; Bull is always present', () {
      // Both toggle values must produce the canonical standard list.
      // The Include Bull setting only affects the random-reefs path.
      for (final includeBull in [true, false]) {
        startStandardGame(randomReefs: false, includeBull: includeBull);
        expect(provider.currentGame!.activeTargets,
            [20, 19, 18, 17, 16, 15, 25],
            reason: 'standard target list is unaffected by includeBull '
                '(includeBull=$includeBull)');
      }
    });
  });
}
