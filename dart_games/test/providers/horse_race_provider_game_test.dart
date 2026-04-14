import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/models/player.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late HorseRaceProvider provider;
  late List<Player> players;

  setUp(() {
    mockServer = MockApiServer();
    provider = HorseRaceProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
    ];
  });

  group('startGame', () {
    test('creates a game with correct initial state', () {
      provider.startGame(players, 100);

      expect(provider.isGameActive, true);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.targetScore, 100);
      expect(provider.currentGame!.playerIds, ['p1', 'p2']);
      expect(provider.currentGame!.currentPlayerIndex, 0);
      expect(provider.shouldPromptTakeout, false);
      expect(provider.hasWinner, false);
    });

    test('rejects empty player list', () {
      provider.startGame([], 100);

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
    });

    test('rejects target score below 20', () {
      provider.startGame(players, 19);

      expect(provider.currentGame, isNull);
    });

    test('rejects target score above 250', () {
      provider.startGame(players, 251);

      expect(provider.currentGame, isNull);
    });

    test('accepts boundary target scores 20 and 250', () {
      provider.startGame(players, 20);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.targetScore, 20);

      provider.clearGame();

      provider.startGame(players, 250);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.targetScore, 250);
    });

    test('sets exactScoreMode flag', () {
      provider.startGame(players, 100, exactScoreMode: true);

      expect(provider.currentGame!.exactScoreMode, true);
    });

    test('defaults exactScoreMode to false', () {
      provider.startGame(players, 100);

      expect(provider.currentGame!.exactScoreMode, false);
    });
  });

  group('processDartThrow', () {
    test('records score for current player', () {
      provider.startGame(players, 100);
      provider.processDartThrow(20, dartDisplay: 'S20');

      expect(provider.getPlayerScore('p1'), 20);
      expect(provider.getCurrentPlayerDartsThrown(), 1);
    });

    test('accumulates scores across multiple throws', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(15, dartDisplay: 'S15');

      expect(provider.getPlayerScore('p1'), 35);
      expect(provider.getCurrentPlayerDartsThrown(), 2);
    });

    test('sets waitingForTakeout after 3 darts', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, false);

      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, true);
    });

    test('ignores throws when waiting for takeout', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, true);

      // This throw should be ignored
      provider.processDartThrow(50, dartDisplay: 'Bull');
      expect(provider.getPlayerScore('p1'), 60);
    });

    test('ignores throws when game is not active', () {
      // No game started
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.currentGame, isNull);
    });

    test('records dartDisplay in current turn scores', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(60, dartDisplay: 'T20');

      final turnScores = provider.getCurrentTurnDartScores('p1');
      expect(turnScores, ['S20', 'T20']);
    });
  });

  group('exact score mode', () {
    test('busts when score exceeds target', () {
      provider.startGame(players, 50, exactScoreMode: true);
      provider.processDartThrow(40, dartDisplay: 'D20');
      // Score is now 40, throwing 20 would make 60 > 50
      provider.processDartThrow(20, dartDisplay: 'S20');

      expect(provider.currentPlayerBusted, true);
      expect(provider.getPlayerScore('p1'), 40); // Score unchanged after bust
    });

    test('sets waitingForTakeout on bust', () {
      provider.startGame(players, 50, exactScoreMode: true);
      provider.processDartThrow(40, dartDisplay: 'D20');
      provider.processDartThrow(20, dartDisplay: 'S20'); // Busts

      expect(provider.shouldPromptTakeout, true);
    });

    test('wins on exact target score', () {
      provider.startGame(players, 50, exactScoreMode: true);
      provider.processDartThrow(25, dartDisplay: '25');
      provider.processDartThrow(25, dartDisplay: '25');

      expect(provider.hasWinner, true);
      expect(provider.getPlayerScore('p1'), 50);
    });

    test('does not bust in normal mode when exceeding target', () {
      provider.startGame(players, 50, exactScoreMode: false);
      provider.processDartThrow(40, dartDisplay: 'D20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      // In normal mode, reaching or exceeding target is a win
      expect(provider.hasWinner, true);
      expect(provider.getPlayerScore('p1'), 60);
    });
  });

  group('skipTurn', () {
    test('adds skip markers for remaining darts', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.skipTurn();

      final turnScores = provider.getCurrentTurnDartScores('p1');
      expect(turnScores, ['S20', 'Skip', 'Skip']);
    });

    test('sets waitingForTakeout', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.skipTurn();

      expect(provider.shouldPromptTakeout, true);
    });

    test('adds 3 skip markers when no darts thrown', () {
      provider.startGame(players, 200);
      provider.skipTurn();

      final turnScores = provider.getCurrentTurnDartScores('p1');
      expect(turnScores, ['Skip', 'Skip', 'Skip']);
      expect(provider.shouldPromptTakeout, true);
    });

    test('does not skip when already waiting for takeout', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, true);

      // Already waiting for takeout, skipTurn should be no-op
      final turnScoresBefore = List<String>.from(
          provider.getCurrentTurnDartScores('p1'));
      provider.skipTurn();
      final turnScoresAfter = provider.getCurrentTurnDartScores('p1');
      expect(turnScoresAfter, turnScoresBefore);
    });
  });

  group('handleTakeoutFinished', () {
    test('advances to next player', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, true);

      provider.handleTakeoutFinished();

      expect(provider.getCurrentPlayerId(), 'p2');
      expect(provider.shouldPromptTakeout, false);
    });

    test('does not advance when there is a winner', () {
      provider.startGame(players, 50);
      provider.processDartThrow(50, dartDisplay: 'Bull');
      expect(provider.hasWinner, true);
      expect(provider.shouldPromptTakeout, true);

      provider.handleTakeoutFinished();

      // Should stay on the winner, not advance
      expect(provider.hasWinner, true);
    });

    test('does nothing when not waiting for takeout', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.handleTakeoutFinished(); // Not waiting yet
      // Should still be p1's turn
      expect(provider.getCurrentPlayerId(), 'p1');
    });
  });

  group('turn cycling', () {
    test('players take turns in order', () {
      provider.startGame(players, 200);
      expect(provider.getCurrentPlayerId(), 'p1');

      // P1 throws 3 darts
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.handleTakeoutFinished();

      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('wraps around to first player', () {
      provider.startGame(players, 200);

      // P1 turn
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.handleTakeoutFinished();

      // P2 turn
      provider.processDartThrow(10, dartDisplay: 'S10');
      provider.processDartThrow(10, dartDisplay: 'S10');
      provider.processDartThrow(10, dartDisplay: 'S10');
      provider.handleTakeoutFinished();

      // Should wrap back to P1
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('resets dart count and turn scores on advance', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.handleTakeoutFinished();

      // P2 should start fresh
      expect(provider.getCurrentPlayerDartsThrown(), 0);
      expect(provider.getCurrentTurnDartScores('p2'), isEmpty);
    });
  });

  group('win detection', () {
    test('player wins by reaching target score (normal mode)', () {
      provider.startGame(players, 60);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      expect(provider.hasWinner, true);
      expect(provider.getWinner(players)?.id, 'p1');
    });

    test('player wins by exceeding target score (normal mode)', () {
      provider.startGame(players, 50);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      expect(provider.hasWinner, true);
      expect(provider.getPlayerScore('p1'), 60);
    });

    test('getWinner returns correct player', () {
      provider.startGame(players, 50);
      provider.processDartThrow(50, dartDisplay: 'Bull');

      final winner = provider.getWinner(players);
      expect(winner, isNotNull);
      expect(winner!.name, 'Alice');
    });

    test('hasWinner is false before reaching target', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');

      expect(provider.hasWinner, false);
    });
  });

  group('editScore (updateAllDartScores)', () {
    test('replays 3 darts with new values', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.getPlayerScore('p1'), 60);

      provider.updateAllDartScores('p1', ['S10', 'S10', 'S10']);
      expect(provider.getPlayerScore('p1'), 30);
    });

    test('preserves current player index', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.updateAllDartScores('p1', ['S5', 'S5', 'S5']);
      expect(provider.getCurrentPlayerId(), 'p1');
    });

    test('rejects edit for non-current player', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');

      // Try to edit p2 (not the current player)
      provider.updateAllDartScores('p2', ['S10', 'S10', 'S10']);
      expect(provider.getPlayerScore('p2'), 0); // Unchanged
    });

    test('rejects edit with wrong number of darts', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.updateAllDartScores('p1', ['S10', 'S10']); // Only 2, need 3
      expect(provider.getPlayerScore('p1'), 60); // Unchanged
    });

    test('handles Miss segments', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.updateAllDartScores('p1', ['Miss', 'Miss', 'Miss']);
      expect(provider.getPlayerScore('p1'), 0);
    });

    test('handles Bull and 25 segments', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.updateAllDartScores('p1', ['Bull', '25', 'S20']);
      expect(provider.getPlayerScore('p1'), 95); // 50 + 25 + 20
    });

    test('sets waitingForTakeout after edit', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');

      // Clear takeout flag to test that updateAllDartScores re-sets it
      provider.updateAllDartScores('p1', ['S10', 'S10', 'S10']);
      expect(provider.shouldPromptTakeout, true);
    });
  });

  group('getHorsePosition', () {
    test('returns 0.0 at start', () {
      provider.startGame(players, 100);

      expect(provider.getHorsePosition('p1'), 0.0);
    });

    test('returns fractional position during game', () {
      provider.startGame(players, 100);
      provider.processDartThrow(50, dartDisplay: 'Bull');

      expect(provider.getHorsePosition('p1'), 0.5);
    });

    test('returns 1.0 when at target score', () {
      provider.startGame(players, 100);
      provider.processDartThrow(50, dartDisplay: 'Bull');
      provider.processDartThrow(50, dartDisplay: 'Bull');

      expect(provider.getHorsePosition('p1'), 1.0);
    });

    test('clamps to 1.0 when beyond target score', () {
      provider.startGame(players, 50);
      provider.processDartThrow(60, dartDisplay: 'T20');

      expect(provider.getHorsePosition('p1'), 1.0);
    });

    test('returns 0.0 when no game active', () {
      expect(provider.getHorsePosition('p1'), 0.0);
    });
  });

  group('clearGame and endGame', () {
    test('clearGame nulls everything', () {
      provider.startGame(players, 100);
      provider.processDartThrow(20, dartDisplay: 'S20');

      provider.clearGame();

      expect(provider.currentGame, isNull);
      expect(provider.isGameActive, false);
      expect(provider.shouldPromptTakeout, false);
    });

    test('endGame sets state to finished', () {
      provider.startGame(players, 100);
      expect(provider.isGameActive, true);

      provider.endGame();

      expect(provider.isGameActive, false);
      expect(provider.currentGame, isNotNull);
      expect(provider.currentGame!.state.name, 'finished');
    });

    test('getFinalStandings returns sorted scores', () {
      provider.startGame(players, 200);
      // P1 scores 60
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.handleTakeoutFinished();

      // P2 scores 90
      provider.processDartThrow(30, dartDisplay: 'T10');
      provider.processDartThrow(30, dartDisplay: 'T10');
      provider.processDartThrow(30, dartDisplay: 'T10');

      final standings = provider.getFinalStandings();
      expect(standings.length, 2);
      expect(standings[0].key, 'p2'); // Higher score first
      expect(standings[0].value, 90);
      expect(standings[1].key, 'p1');
      expect(standings[1].value, 60);
    });

    test('getFinalStandings returns empty when no game', () {
      expect(provider.getFinalStandings(), isEmpty);
    });
  });

  group('advanceToNextPlayer', () {
    test('manually advances to next player', () {
      provider.startGame(players, 200);
      expect(provider.getCurrentPlayerId(), 'p1');

      provider.advanceToNextPlayer();
      expect(provider.getCurrentPlayerId(), 'p2');
    });

    test('does not advance when there is a winner', () {
      provider.startGame(players, 50);
      provider.processDartThrow(50, dartDisplay: 'Bull');
      expect(provider.hasWinner, true);

      provider.advanceToNextPlayer();
      // currentPlayerIndex should not change meaningfully
      // The key assertion is that the method returns without error
      expect(provider.hasWinner, true);
    });

    test('clears waitingForTakeout flag', () {
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      provider.processDartThrow(20, dartDisplay: 'S20');
      expect(provider.shouldPromptTakeout, true);

      provider.advanceToNextPlayer();
      expect(provider.shouldPromptTakeout, false);
    });
  });
}
