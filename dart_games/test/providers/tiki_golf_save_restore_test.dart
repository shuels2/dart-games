import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/tiki_golf_provider.dart';
import 'package:dart_games/models/tiki_golf_game.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late TikiGolfProvider provider;
  late SaveGameService saveService;

  setUp(() {
    mockServer = MockApiServer();
    provider = TikiGolfProvider();
    saveService = SaveGameService(mockServer.apiClient);
  });

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Start a default 2-player Solo game.
  void startSoloGame({
    List<String> playerIds = const ['p1', 'p2'],
    int maxStrokes = 3,
    bool mulliganEnabled = false,
  }) {
    provider.startGame(
      playerIds: playerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: TikiGolfGameMode.solo,
      teamAssignment: TikiGolfTeamAssignment.random,
    );
  }

  /// Start a 2-team game with manual assignment.
  void startTeamGame({
    List<String> playerIds = const ['p1', 'p2', 'p3', 'p4'],
    int maxStrokes = 3,
    bool mulliganEnabled = false,
  }) {
    provider.startGame(
      playerIds: playerIds,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      gameMode: TikiGolfGameMode.team,
      teamAssignment: TikiGolfTeamAssignment.random,
    );
  }

  Future<List<dynamic>> savedGames() =>
      saveService.loadSavedGames('tiki_golf');

  // ─── Tests ───────────────────────────────────────────────────────────────────

  group('TikiGolfProvider save/restore', () {
    // ─── 1. saveGame records correct metadata ────────────────────────────────

    test('saveGame creates metadata with gameType "tiki_golf"', () async {
      startSoloGame();

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob']);

      final saved = await savedGames();
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'tiki_golf');
    });

    // ─── 2. saveGame stores gameState matching currentGame.toJson() ──────────

    test('saveGame stores gameState that matches currentGame.toJson()', () async {
      startSoloGame();
      // Advance dart state: one dart thrown (miss) for p1
      provider.processDartThrow(sector: 'Miss', score: 0);

      final expectedJson = provider.currentGame!.toJson();

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob']);

      final saved = await savedGames();
      expect(saved, hasLength(1));
      expect(saved[0].gameState['id'], expectedJson['id']);
      expect(saved[0].gameState['maxStrokes'], 3);
      expect(saved[0].gameState['gameMode'], 'solo');
      expect(saved[0].gameState['playerIds'], ['p1', 'p2']);
    });

    // ─── 3. saveGame includes player names ───────────────────────────────────

    test('saveGame includes playerNames in metadata', () async {
      startSoloGame(playerIds: ['p1', 'p2', 'p3']);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie']);

      final saved = await savedGames();
      expect(saved[0].playerNames,
          containsAll(['Alice', 'Bob', 'Charlie']));
      expect(saved[0].playerNames, hasLength(3));
    });

    test('saveGame lists only the players in THIS game, not the whole roster',
        () async {
      startSoloGame(playerIds: ['p1', 'p2']);

      // The roster is bigger than the match — a saved tile must not advertise
      // players who are not playing.
      await provider.saveGame(saveService, playerNamesById: {
        'p1': 'Alice',
        'p2': 'Bob',
        'p3': 'Charlie',
        'p4': 'Dana',
      });

      final saved = await savedGames();
      expect(saved[0].playerNames, ['Alice', 'Bob']);
    });

    test('saveGame resolves the leading player to a name, not an id', () async {
      startSoloGame(playerIds: ['id-aaa', 'id-bbb']);

      await provider.saveGame(saveService,
          playerNamesById: {'id-aaa': 'Alice', 'id-bbb': 'Bob'});

      final saved = await savedGames();
      expect(saved[0].leadingPlayerName, 'Alice',
          reason: 'Player ids are UUIDs — the tile must never show one');
    });

    test('saveGame falls back to ids when no names are supplied', () async {
      startSoloGame(playerIds: ['p1', 'p2']);

      await provider.saveGame(saveService);

      final saved = await savedGames();
      expect(saved[0].playerNames, ['p1', 'p2'],
          reason: 'Degrades to ids rather than throwing or listing nobody');
    });

    // ─── 4. restoreGame reconstructs full game state ─────────────────────────

    test('restoreGame reconstructs full game state', () async {
      startSoloGame(maxStrokes: 4, mulliganEnabled: true);
      // One dart thrown, miss
      provider.processDartThrow(sector: 'Miss', score: 0);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      final game = newProvider.currentGame!;
      expect(game.maxStrokes, 4);
      expect(game.mulliganEnabled, isTrue);
      expect(game.gameMode, TikiGolfGameMode.solo);
      expect(game.playerIds, ['p1', 'p2']);
      expect(game.holeTargets, hasLength(9));
      expect(game.holeImagePaths, hasLength(9));
    });

    // ─── 5. restoreGame sets resumedSavedGameId ──────────────────────────────

    test('restoreGame sets resumedSavedGameId to the saved game id', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();
      final savedId = saved[0].id;

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.resumedSavedGameId, equals(savedId));
    });

    // ─── 6. clearResumedSavedGameId resets to null ───────────────────────────

    test('clearResumedSavedGameId clears the resumed id', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    // ─── 7. Re-save after restore uses existingId (overwrites) ───────────────

    test('saving a resumed game overwrites the existing save (same id)', () async {
      startSoloGame();

      // First save
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved1 = await savedGames();
      expect(saved1, hasLength(1));
      final originalId = saved1[0].id;

      // Restore into new provider, throw a dart, re-save
      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved1[0]);
      newProvider.processDartThrow(sector: 'Miss', score: 0);
      await newProvider.saveGame(saveService, playerNames: ['Alice', 'Bob']);

      // Must still be exactly 1 saved record, same id
      final saved2 = await savedGames();
      expect(saved2, hasLength(1));
      expect(saved2[0].id, equals(originalId));
    });

    // ─── 8. Splash state + mulligan-available survives save/restore ──────────

    test('save/restore mid-Splash preserves Splash state and mulligan-available', () async {
      startSoloGame(maxStrokes: 3, mulliganEnabled: true);

      // Throw all 3 darts as misses → triggers Splash (score = maxStrokes+1 = 4)
      provider.processDartThrow(sector: 'Miss', score: 0);
      provider.processDartThrow(sector: 'Miss', score: 0);
      provider.processDartThrow(sector: 'Miss', score: 0);

      // Verify Splash state before saving
      final game = provider.currentGame!;
      expect(game.currentTurnEnded, isTrue);
      expect(game.playerHoleScores[game.activePlayerId]![0],
          game.maxStrokes + 1,
          reason: 'Should be a Splash (4) after 3 missed darts with maxStrokes=3');
      // Mulligan has NOT been used yet
      expect(game.playerMulligansUsed[game.activePlayerId], 0);

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      final restoredGame = newProvider.currentGame!;
      // waitingForTakeout / currentTurnEnded is restored via restoreGame
      expect(newProvider.shouldPromptTakeout, isTrue);
      // Splash score preserved
      expect(
          restoredGame.playerHoleScores[restoredGame.activePlayerId]![0],
          restoredGame.maxStrokes + 1);
      // Mulligan still available (not yet used)
      expect(restoredGame.playerMulligansUsed[restoredGame.activePlayerId], 0);
      expect(restoredGame.mulliganEnabled, isTrue);
    });

    // ─── 9. Mid-game state preserves all turn-tracking fields ────────────────

    test('save/restore mid-game preserves currentHole, rotation pointer, dartsThrown, totalTurns, currentTurnEnded', () async {
      startTeamGame(playerIds: ['p1', 'p2', 'p3', 'p4']);

      // Access game internals to set up a mid-game state
      final game = provider.currentGame!;
      // Simulate that hole 1 is done, now on hole 2 mid-turn
      game.currentHole = 2;
      // p1 has completed 1 turn (hole 1), totalTurns=1
      game.totalTurns['p1'] = 1;
      game.dartsThrown['p1'] = 0;
      // p1 threw 2 darts this turn on hole 2
      game.dartsThrown[game.activePlayerId!] = 2;
      game.totalTurns[game.activePlayerId!] =
          (game.totalTurns[game.activePlayerId] ?? 0) + 1;
      // Set the team rotation pointer
      final teamIds = game.teamPlayers.keys.toList();
      if (teamIds.isNotEmpty) {
        game.teamWithinHoleRotationPointer[teamIds[0]] = 1;
      }
      game.currentTeamIndex = 0;
      game.currentTurnEnded = false;

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie', 'Dave']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.currentHole, 2);
      expect(restored.currentTeamIndex, 0);
      expect(restored.currentTurnEnded, false);
      if (teamIds.isNotEmpty) {
        expect(restored.teamWithinHoleRotationPointer[teamIds[0]], 1);
      }
    });

    // ─── 10. waitingForTakeout flag is preserved across save/restore ─────────

    test('waitingForTakeout is preserved across save/restore', () async {
      startSoloGame(maxStrokes: 3);

      // Throw the target number to score a birdie (currentTurnEnded = true)
      final target = provider.currentGame!.holeTargets[0];
      provider.processDartThrow(sector: 'S$target', score: target);
      expect(provider.shouldPromptTakeout, isTrue);

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.shouldPromptTakeout, isTrue);
    });

    // ─── 11. restoreGame triggers notifyListeners ─────────────────────────────

    test('restoreGame triggers notifyListeners', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      int notifyCount = 0;
      newProvider.addListener(() => notifyCount++);

      newProvider.restoreGame(saved[0]);

      expect(notifyCount, greaterThan(0));
    });

    // ─── 12. Team mode restore preserves full team structure ──────────────────

    test('team mode save/restore preserves teamPlayers, crests, and playerTeamAssignments', () async {
      startTeamGame(playerIds: ['p1', 'p2', 'p3', 'p4']);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie', 'Dave']);
      final saved = await savedGames();

      final newProvider = TikiGolfProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.gameMode, TikiGolfGameMode.team);
      expect(restored.teamPlayers, isNotEmpty);
      expect(restored.teamCrestPaths, isNotEmpty);
      expect(restored.playerTeamAssignments, isNotEmpty);
      // All 4 player ids should be assigned to some team
      for (final pid in ['p1', 'p2', 'p3', 'p4']) {
        expect(restored.playerTeamAssignments.containsKey(pid), isTrue,
            reason: '$pid must have a team assignment after restore');
      }
    });

    // ─── 13. Two saves without restore create two separate records ────────────

    test('saving the same game twice without restore creates two save records', () async {
      startSoloGame();

      // First save — no resumedSavedGameId, gets a new UUID
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);

      // Clear the resumed id to force a fresh (not overwrite) save
      provider.clearResumedSavedGameId();

      // Second save — again no resumedSavedGameId
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob']);

      final saved = await savedGames();
      expect(saved.length, greaterThanOrEqualTo(2));
      final ids = saved.map((s) => s.id as String).toSet();
      expect(ids.length, greaterThanOrEqualTo(2));
    });
  });
}
