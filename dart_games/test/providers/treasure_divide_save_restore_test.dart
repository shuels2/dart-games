import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/treasure_divide_provider.dart';
import 'package:dart_games/models/treasure_divide_game.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late TreasureDivideProvider provider;
  late SaveGameService saveService;

  setUp(() {
    mockServer = MockApiServer();
    provider = TreasureDivideProvider();
    saveService = SaveGameService(mockServer.apiClient);
  });

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Start a default 3-player Solo game.
  void startSoloGame({
    List<String> playerIds = const ['p1', 'p2', 'p3'],
    int numberOfRounds = 9,
    bool quarterItEnabled = false,
  }) {
    provider.startGame(
      playerIds: playerIds,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: false,
      gameMode: TreasureDivideGameMode.solo,
      teamAssignment: TreasureDivideTeamAssignment.random,
    );
  }

  /// Start a team game with 4 players and random team assignment.
  void startTeamGame({
    List<String> playerIds = const ['p1', 'p2', 'p3', 'p4'],
    int numberOfRounds = 9,
  }) {
    provider.startGame(
      playerIds: playerIds,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: false,
      customTargetsEnabled: false,
      gameMode: TreasureDivideGameMode.team,
      teamAssignment: TreasureDivideTeamAssignment.random,
    );
  }

  Future<List<dynamic>> savedGames() =>
      saveService.loadSavedGames('treasure_divide');

  // ─── Tests ───────────────────────────────────────────────────────────────────

  group('TreasureDivideProvider save/restore', () {
    // ─── 1. saveGame creates metadata with correct gameType ──────────────────

    test('saveGame creates metadata with gameType "treasure_divide"', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);

      final saved = await savedGames();
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'treasure_divide');
    });

    // ─── 2. saveGame stores gameState matching toJson ────────────────────────

    test('saveGame stores gameState that matches currentGame.toJson()', () async {
      startSoloGame(playerIds: ['p1', 'p2', 'p3']);

      final expectedJson = provider.currentGame!.toJson();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);

      final saved = await savedGames();
      expect(saved, hasLength(1));
      expect(saved[0].gameState['id'], expectedJson['id']);
      expect(saved[0].gameState['numberOfRounds'], 9);
      expect(saved[0].gameState['gameMode'], 'solo');
      expect(saved[0].gameState['playerIds'], ['p1', 'p2', 'p3']);
    });

    // ─── 3. saveGame includes player names ───────────────────────────────────

    test('saveGame includes playerNames in metadata', () async {
      startSoloGame(playerIds: ['p1', 'p2', 'p3']);

      await provider.saveGame(
        saveService,
        playerNames: ['Alice', 'Bob', 'Charlie'],
      );

      final saved = await savedGames();
      expect(saved[0].playerNames,
          containsAll(['Alice', 'Bob', 'Charlie']));
      expect(saved[0].playerNames, hasLength(3));
    });

    // ─── 4. restoreGame reconstructs full game state ─────────────────────────

    test('restoreGame reconstructs full game state including options', () async {
      startSoloGame(numberOfRounds: 12, quarterItEnabled: true);
      // Throw one dart to advance state
      provider.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      final game = newProvider.currentGame!;
      expect(game.numberOfRounds, 12);
      expect(game.quarterItEnabled, isTrue);
      expect(game.gameMode, TreasureDivideGameMode.solo);
      expect(game.playerIds, ['p1', 'p2', 'p3']);
      expect(game.targetSequence, hasLength(12));
    });

    // ─── 5. restoreGame sets resumedSavedGameId ──────────────────────────────

    test('restoreGame sets resumedSavedGameId to the saved game id', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();
      final savedId = saved[0].id;

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.resumedSavedGameId, equals(savedId));
    });

    // ─── 6. clearResumedSavedGameId clears to null ───────────────────────────

    test('clearResumedSavedGameId clears the resumed id without touching currentGame', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);
      expect(provider.currentGame, isNotNull);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
      // currentGame must still be intact
      expect(provider.currentGame, isNotNull);
    });

    // ─── 7. Re-save after restore overwrites the same record ─────────────────

    test('saving a resumed game overwrites the existing save (same id)', () async {
      startSoloGame();

      // First save
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved1 = await savedGames();
      expect(saved1, hasLength(1));
      final originalId = saved1[0].id;

      // Restore into new provider, advance state, re-save
      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved1[0]);
      newProvider.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      await newProvider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie']);

      // Must still be exactly 1 saved record, same id
      final saved2 = await savedGames();
      expect(saved2, hasLength(1));
      expect(saved2[0].id, equals(originalId));
    });

    // ─── 8. Mid-turn save round-trips current player + dart count ────────────

    test('mid-turn save/restore preserves currentPlayerId, dartsThrown, currentTurnDartSegments', () async {
      startSoloGame(playerIds: ['p1', 'p2', 'p3']);

      // Throw 2 darts mid-turn
      provider.processDartThrow(
          score: 20, multiplier: 'single', baseScore: 20, sector: 'S20');
      provider.processDartThrow(
          score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');

      // shouldPromptTakeout is false (3rd dart not thrown yet, no turn-end)
      final game = provider.currentGame!;
      final playerBefore = game.currentPlayerId;
      final dartsBeforeExpected = game.dartsThrown;

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.currentPlayerId, playerBefore);
      expect(restored.dartsThrown, dartsBeforeExpected);
      // currentTurnDartSegments for the current player must have 2 entries
      expect(restored.currentTurnDartSegments[playerBefore], hasLength(2));
    });

    // ─── 9. Save in team mode preserves team structure ────────────────────────

    test('team mode save/restore preserves teamPlayers, crests, and playerTeamAssignments', () async {
      startTeamGame(playerIds: ['p1', 'p2', 'p3', 'p4']);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie', 'Dave']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.gameMode, TreasureDivideGameMode.team);
      expect(restored.teamPlayers, isNotEmpty);
      expect(restored.teamCrestPaths, isNotEmpty);
      expect(restored.playerTeamAssignments, isNotEmpty);
      // All 4 player ids must be assigned to some team
      for (final pid in ['p1', 'p2', 'p3', 'p4']) {
        expect(restored.playerTeamAssignments.containsKey(pid), isTrue,
            reason: '$pid must have a team assignment after restore');
      }
    });

    // ─── 10. Save in solo crew turn (6-dart budget) ───────────────────────────

    test('solo crew (1-member team) save/restore preserves 6-dart turn state', () async {
      // Build a 3-player team game with odd players (p3 gets the solo crew)
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        numberOfRounds: 9,
        quarterItEnabled: false,
        customTargetsEnabled: false,
        gameMode: TreasureDivideGameMode.team,
        teamAssignment: TreasureDivideTeamAssignment.random,
      );

      // Identify the solo crew (team with 1 member)
      final game = provider.currentGame!;
      final soloCrew = game.teamPlayers.entries
          .firstWhere((e) => e.value.length == 1,
              orElse: () => throw TestFailure(
                  'Expected a solo crew in 3-player random team game'));
      final soloCrewId = soloCrew.key;

      // Check that the game correctly computes dartsThisTurn = 6 for that crew
      // We can verify by checking the model's dartsThisTurn getter after
      // setting activeTeamId to the solo crew
      game.activeTeamId = soloCrewId;
      game.currentPlayerId = soloCrew.value.first;
      expect(game.dartsThisTurn, 6,
          reason: 'Solo crew (1-member) must have dartsThisTurn = 6');

      // Throw 4 darts mid-turn
      final soloPlayerId = soloCrew.value.first;
      game.dartsThrown = 4;
      game.currentTurnDartSegments[soloPlayerId] = [
        'S20', 'D10', 'Miss', 'T5'
      ];
      game.totalDartsThrown[soloPlayerId] = 4;

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.activeTeamId, soloCrewId);
      expect(restored.currentPlayerId, soloPlayerId);
      expect(restored.dartsThrown, 4);
      expect(restored.currentTurnDartSegments[soloPlayerId],
          ['S20', 'D10', 'Miss', 'T5']);
      // dartsThisTurn must still compute to 6 after restore
      expect(restored.dartsThisTurn, 6);
    });

    // ─── 11. clearGame clears resumedSavedGameId ────────────────────────────
    // NOTE: endGame() transitions the game to finished state but does NOT
    // clear _resumedSavedGameId — that is clearGame()'s responsibility.
    // Reference: provider line 876 (_resumedSavedGameId = null is in clearGame).

    test('clearGame clears resumedSavedGameId', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.clearGame();
      expect(provider.resumedSavedGameId, isNull);
    });

    // ─── 12. restoreGame triggers notifyListeners ────────────────────────────

    test('restoreGame triggers notifyListeners', () async {
      startSoloGame();

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      int notifyCount = 0;
      newProvider.addListener(() => notifyCount++);

      newProvider.restoreGame(saved[0]);

      expect(notifyCount, greaterThan(0));
    });

    // ─── 13. Two saves without restore create two separate records ────────────

    test('saving the same game twice without restore creates two save records', () async {
      startSoloGame();

      // First save — no resumedSavedGameId, gets a new UUID
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);

      // Clear the resumed id to force a fresh (not overwrite) save
      provider.clearResumedSavedGameId();

      // Second save — again no resumedSavedGameId
      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);

      final saved = await savedGames();
      expect(saved.length, greaterThanOrEqualTo(2));
      final ids = saved.map((s) => s.id as String).toSet();
      expect(ids.length, greaterThanOrEqualTo(2));
    });

    // ─── 14. waitingForTakeout flag is preserved across save/restore ─────────

    test('waitingForTakeout is preserved across save/restore', () async {
      startSoloGame();

      // Throw all 3 darts to trigger shouldPromptTakeout
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(
            score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      }
      expect(provider.shouldPromptTakeout, isTrue);

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.shouldPromptTakeout, isTrue);
    });

    // ─── 15. Sentinel targets survive through provider save/restore ───────────

    test('kTargetAnyDouble and kTargetAnyTriple in targetSequence survive provider save/restore', () async {
      startSoloGame(numberOfRounds: 9);

      await provider.saveGame(saveService, playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.targetSequence[3], kTargetAnyDouble,
          reason: 'Index 3 must be kTargetAnyDouble (-1) after provider restore');
      expect(restored.targetSequence[7], kTargetAnyTriple,
          reason: 'Index 7 must be kTargetAnyTriple (-2) after provider restore');
      expect(restored.targetSequence[8], kTargetBull,
          reason: 'Index 8 must be kTargetBull (25) after provider restore');
    });

    // ─── 15b. Saved metadata shows names, not raw ids ─────────────────────────

    test('saveGame records display names and the actual leader', () async {
      startSoloGame(playerIds: ['id-aaa', 'id-bbb']);
      final target = provider.currentGame!.targetSequence[0];

      // First player scores, then finishes the turn — the lead is now theirs
      // even though the active player has moved on.
      for (int i = 0; i < 3; i++) {
        provider.processDartThrow(
            score: target,
            multiplier: 'single',
            baseScore: target,
            sector: 'S$target');
      }
      provider.handleTakeoutFinished();

      await provider.saveGame(saveService,
          playerNamesById: {'id-aaa': 'Alice', 'id-bbb': 'Bob'});
      final saved = await savedGames();
      final meta = saved[0];

      expect(meta.playerNames, ['Alice', 'Bob'],
          reason: 'Saved-game tiles must show names, never raw UUIDs');
      expect(meta.leadingPlayerName, 'Alice',
          reason: 'The leader is whoever holds the most gold, not whoever '
              'happens to be the active player');
      expect(meta.leadingPlayerScore, '${target * 3} gold');
    });

    // ─── 16. In-flight turn haul survives save/restore ────────────────────────

    test('mid-turn haul is restored, so the pending takeout commits the real score',
        () async {
      startSoloGame();
      final target = provider.currentGame!.targetSequence[0];
      final playerId = provider.currentGame!.currentPlayerId;
      expect(target, greaterThan(0),
          reason: 'Round 1 must be a plain number round for this scenario');

      // Two scoring darts; the turn is still open (third dart unthrown).
      for (int i = 0; i < 2; i++) {
        provider.processDartThrow(
            score: target,
            multiplier: 'single',
            baseScore: target,
            sector: 'S$target');
      }
      expect(provider.currentTurnHaul, target * 2);
      expect(provider.shouldPromptTakeout, isFalse);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentTurnHaul, target * 2,
          reason: 'Darts already thrown this turn must still count after resume');

      // Finish the turn on the restored provider.
      newProvider.processDartThrow(
          score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      newProvider.handleTakeoutFinished();

      expect(newProvider.currentGame!.playerRoundScores[playerId]![0],
          target * 2,
          reason: 'Round score must include the gold earned before the save');
      expect(newProvider.currentGame!.timesHalvedPerPlayer[playerId] ?? 0, 0,
          reason: 'A scoring turn must never be recorded as a halving event');
    });

    // ─── 17. Saved while awaiting takeout: haul is not lost ───────────────────

    test('haul survives a save taken while the takeout prompt is pending',
        () async {
      startSoloGame();
      final target = provider.currentGame!.targetSequence[0];
      final playerId = provider.currentGame!.currentPlayerId;

      // One hit then two misses — turn complete, takeout pending.
      provider.processDartThrow(
          score: target,
          multiplier: 'single',
          baseScore: target,
          sector: 'S$target');
      for (int i = 0; i < 2; i++) {
        provider.processDartThrow(
            score: 0, multiplier: 'miss', baseScore: 0, sector: 'Miss');
      }
      expect(provider.shouldPromptTakeout, isTrue);
      expect(provider.currentTurnHaul, target);

      await provider.saveGame(saveService,
          playerNames: ['Alice', 'Bob', 'Charlie']);
      final saved = await savedGames();

      final newProvider = TreasureDivideProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, isTrue);
      expect(newProvider.currentTurnHaul, target);

      newProvider.handleTakeoutFinished();

      expect(newProvider.currentGame!.playerRoundScores[playerId]![0], target,
          reason: 'Resuming into the takeout must commit the gold, not zero');
      expect(newProvider.currentGame!.timesHalvedPerPlayer[playerId] ?? 0, 0,
          reason: 'Treasure must not be halved after a scoring turn');
    });
  });
}
