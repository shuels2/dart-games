import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/providers/gladiator_arena_provider.dart';
import 'package:dart_games/models/gladiator_arena_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';
import '../shared/mock_api_helpers.dart';

void main() {
  late MockApiServer mockServer;
  late GladiatorArenaProvider provider;
  late List<Player> players;

  setUp(() async {
    mockServer = MockApiServer();
    provider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  // Use a seeded Random that always returns 0 so currentPlayerIndex starts at p1.
  void startDefault() {
    provider.startGame(
      playerIds: ['p1', 'p2', 'p3'],
      targetScore: 200,
      doubleFinishEnabled: true,
      shieldRoundEnabled: false,
      speedPlayEnabled: false,
      random: Random(0),
    );
  }

  Future<List<dynamic>> savedGames() =>
      SaveGameService(mockServer.apiClient).loadSavedGames('gladiator_arena');

  // ─── Tests ───────────────────────────────────────────────────────────────────

  group('GladiatorArenaProvider save/restore', () {
    // ─── 1. saveGame creates correct gameType ──────────────────────────────────

    test('saveGame creates metadata with gameType "gladiator_arena"', () async {
      startDefault();
      provider.processDartThrow(score: 20, multiplier: 'single', sector: 'S20');

      await provider.saveGame(players);

      final saved = await savedGames();
      expect(saved, hasLength(1));
      expect(saved[0].gameType, equals('gladiator_arena'));
    });

    // ─── 2. saveGame serializes gameState matching currentGame.toJson() ────────

    test('saveGame stores gameState matching currentGame.toJson()', () async {
      startDefault();
      provider.processDartThrow(score: 15, multiplier: 'single', sector: 'S15');
      provider.processDartThrow(score: 10, multiplier: 'double', sector: 'D10');

      final expectedJson = provider.currentGame!.toJson();

      await provider.saveGame(players);

      final saved = await savedGames();
      expect(saved, hasLength(1));

      // Core game identity must match
      expect(saved[0].gameState['id'], equals(expectedJson['id']));
      expect(saved[0].gameState['targetScore'], equals(200));
      expect(saved[0].gameState['doubleFinishEnabled'], isTrue);
      expect(saved[0].gameState['playerIds'], equals(['p1', 'p2', 'p3']));
    });

    // ─── 3. saveGame includes player-name preview ──────────────────────────────

    test('saveGame includes all player names in playerNames', () async {
      startDefault();
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      await provider.saveGame(players);

      final saved = await savedGames();
      expect(saved[0].playerNames, containsAll(['Alice', 'Bob', 'Charlie']));
      expect(saved[0].playerNames, hasLength(3));
    });

    // ─── 4. restoreGame reconstructs the game state ────────────────────────────

    test('restoreGame reconstructs full game state', () async {
      startDefault();
      provider.processDartThrow(score: 20, multiplier: 'single', sector: 'S20');
      provider.processDartThrow(score: 20, multiplier: 'single', sector: 'S20');

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.targetScore, equals(200));
      expect(newProvider.currentGame!.doubleFinishEnabled, isTrue);
      expect(newProvider.currentGame!.playerIds, equals(['p1', 'p2', 'p3']));
      // p1 should have at least some darts thrown
      expect(newProvider.currentGame!.totalDartsThrown['p1']! > 0, isTrue);
    });

    // ─── 5. restoreGame sets resumedSavedGameId ────────────────────────────────

    test('restoreGame sets resumedSavedGameId to the saved game id', () async {
      startDefault();
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      await provider.saveGame(players);
      final saved = await savedGames();
      final savedId = saved[0].id;

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);

      expect(newProvider.resumedSavedGameId, equals(savedId));
    });

    // ─── 6. restoreGame triggers notifyListeners ───────────────────────────────

    test('restoreGame triggers notifyListeners', () async {
      startDefault();
      provider.processDartThrow(score: 10, multiplier: 'single', sector: 'S10');

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      int notifyCount = 0;
      newProvider.addListener(() => notifyCount++);

      await newProvider.restoreGame(saved[0]);
      expect(notifyCount, greaterThan(0));
    });

    // ─── 7. clearResumedSavedGameId zeroes the field ──────────────────────────

    test('clearResumedSavedGameId clears the resumed id', () async {
      startDefault();
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      await provider.saveGame(players);
      final saved = await savedGames();

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    // ─── 8. resumedSavedGameId cleared after endGame ──────────────────────────

    test('resumedSavedGameId is cleared after endGame', () async {
      startDefault();
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      await provider.saveGame(players);
      final saved = await savedGames();

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, isNotNull);

      provider.endGame();
      expect(provider.resumedSavedGameId, isNull);
    });

    // ─── 9. Mid-game state survives save/restore ───────────────────────────────

    test('mid-game scores and totalDartsThrown survive save/restore', () async {
      // Use seeded random so p1 (index 0) is always the first player.
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 300,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
        random: Random(0),
      );

      // p1 throws 3 darts → score accumulates, turn advances
      provider.processDartThrow(score: 20, multiplier: 'single', sector: 'S20');
      provider.processDartThrow(score: 10, multiplier: 'single', sector: 'S10');
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');
      provider.advanceToNextPlayer();

      // p2 throws 1 dart mid-turn
      provider.processDartThrow(score: 15, multiplier: 'single', sector: 'S15');

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);

      // p1 completed a turn: totalDartsThrown=3, totalTurns=1
      expect(newProvider.currentGame!.totalDartsThrown['p1'], equals(3));
      expect(newProvider.currentGame!.totalTurns['p1'], equals(1));

      // p2 mid-turn: totalDartsThrown=1, totalTurns=1
      expect(newProvider.currentGame!.totalDartsThrown['p2'], equals(1));
      expect(newProvider.currentGame!.totalTurns['p2'], equals(1));
    });

    // ─── 10. Knockoff history survives save/restore ────────────────────────────

    test('knockoff history preserves knockoffsDealt, knockoffsReceived, lastKnockoff fields',
        () async {
      provider.startGame(
        playerIds: ['p1', 'p2', 'p3'],
        targetScore: 500,
        doubleFinishEnabled: false,
        shieldRoundEnabled: false,
        speedPlayEnabled: false,
      );

      // Manually set knockoff stats on the current game to simulate history
      final game = provider.currentGame!;
      game.knockoffsDealt['p1'] = 2;
      game.knockoffsDealt['p2'] = 1;
      game.knockoffsReceived['p2'] = 1;
      game.knockoffsReceived['p3'] = 2;
      game.lastKnockoffVictimId = 'p3';
      game.lastKnockoffAttackerId = 'p1';
      game.lastKnockoffAt = DateTime(2026, 5, 9, 10, 0, 0);

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.knockoffsDealt['p1'], equals(2));
      expect(restored.knockoffsDealt['p2'], equals(1));
      expect(restored.knockoffsReceived['p2'], equals(1));
      expect(restored.knockoffsReceived['p3'], equals(2));
      expect(restored.lastKnockoffVictimId, equals('p3'));
      expect(restored.lastKnockoffAttackerId, equals('p1'));
      expect(restored.lastKnockoffAt, equals(DateTime(2026, 5, 9, 10, 0, 0)));
    });

    // ─── 11. All options survive save/restore ─────────────────────────────────

    test('all 4 option booleans and targetScore survive save/restore', () async {
      provider.startGame(
        playerIds: ['p1', 'p2'],
        targetScore: 350,
        doubleFinishEnabled: true,
        shieldRoundEnabled: true,
        speedPlayEnabled: true,
      );
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);

      final restored = newProvider.currentGame!;
      expect(restored.targetScore, equals(350));
      expect(restored.doubleFinishEnabled, isTrue);
      expect(restored.shieldRoundEnabled, isTrue);
      expect(restored.speedPlayEnabled, isTrue);
    });

    // ─── 12. Two saves of the same game create two separate records ───────────

    test('saving the same game twice without restore creates two save records',
        () async {
      startDefault();
      provider.processDartThrow(score: 10, multiplier: 'single', sector: 'S10');

      // First save — no resumed id, so a new id is generated
      await provider.saveGame(players);

      // Clear the internal resumed id to force a fresh save (simulate new save)
      provider.clearResumedSavedGameId();

      // Second save — again no resumed id, creates another record
      await provider.saveGame(players);

      final saved = await savedGames();
      expect(saved.length, greaterThanOrEqualTo(2));
      // The two saves should have different IDs
      final ids = saved.map((s) => s.id).toSet();
      expect(ids.length, greaterThanOrEqualTo(2));
    });

    // ─── 13. Overwrite semantics: same id reused when restoring and re-saving ─

    test('saving a resumed game overwrites the existing save (same id)', () async {
      startDefault();
      provider.processDartThrow(score: 5, multiplier: 'single', sector: 'S5');

      // First save
      await provider.saveGame(players);
      final saved1 = await savedGames();
      expect(saved1, hasLength(1));
      final originalId = saved1[0].id;

      // Restore into a new provider, throw another dart, save again
      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved1[0]);
      newProvider.processDartThrow(score: 10, multiplier: 'single', sector: 'S10');
      await newProvider.saveGame(players);

      // Should still be 1 saved game (overwrite), same id
      final saved2 = await savedGames();
      expect(saved2, hasLength(1));
      expect(saved2[0].id, equals(originalId));
    });

    // ─── 14. gameDuration is non-null after restore, null after clearGame ─────

    test('gameDuration is non-null after restoreGame and null after clearGame',
        () async {
      startDefault();
      provider.processDartThrow(score: 3, multiplier: 'single', sector: 'S3');

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      expect(newProvider.gameDuration, isNull);

      await newProvider.restoreGame(saved[0]);
      expect(newProvider.gameDuration, isNotNull);
      expect(newProvider.gameDuration!.inSeconds, greaterThanOrEqualTo(0));

      newProvider.clearGame();
      expect(newProvider.gameDuration, isNull);
    });

    // ─── 15. waitingForTakeout is preserved across save/restore ───────────────

    test('waitingForTakeout is preserved across save/restore', () async {
      startDefault();
      // Throw 3 darts → waitingForTakeout = true
      provider.processDartThrow(score: 1, multiplier: 'single', sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 'single', sector: 'S1');
      provider.processDartThrow(score: 1, multiplier: 'single', sector: 'S1');
      expect(provider.shouldPromptTakeout, isTrue);

      await provider.saveGame(players);
      final saved = await savedGames();

      final newProvider = GladiatorArenaProvider(apiClient: mockServer.apiClient);
      await newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, isTrue);
    });
  });
}
