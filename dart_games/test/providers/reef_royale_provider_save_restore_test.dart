import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReefRoyaleProvider provider;
  late List<Player> players;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = ReefRoyaleProvider();
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  group('ReefRoyaleProvider save/restore', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, // easyClaim
        true,  // neighborNumbers
        false, // randomReefs
        true,  // bonusBuffs
        true,  // showHints
        true,  // speedPlay
        8,     // roundLimit
      );

      // Hit target 20
      provider.processDartThrow('S20');

      await provider.saveGame(players);

      final saved = await SaveGameService().loadSavedGames('reef_royale');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'reef_royale');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].progressInfo, 'Round 1');
      expect(saved[0].gameModeName, contains('Standard'));
      expect(saved[0].gameModeName, contains('Neighbors'));
      expect(saved[0].gameModeName, contains('Buffs'));
      expect(saved[0].gameModeName, contains('Speed (8)'));
      expect(saved[0].leadingPlayerScore, contains('corals'));
    });

    test('restoreGame restores full game state', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.cursedTide,
        true,  // easyClaim
        false, // neighborNumbers
        false, // randomReefs
        false, // bonusBuffs
        false, // showHints
        false, // speedPlay
        10,    // roundLimit
      );

      provider.processDartThrow('S20');
      provider.processDartThrow('D20');

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.gameMode,
          ReefRoyaleGameMode.cursedTide);
      expect(newProvider.currentGame!.easyClaim, true);
      expect(newProvider.currentGame!.marks['p1']![20]! > 0, true);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, false, false, false, false, false, 10,
      );
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      provider.processDartThrow('S20');
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('resumedSavedGameId is set and clearable', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, false, false, false, false, false, 10,
      );
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, saved[0].id);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, false, false, false, false, false, 10,
      );
      provider.processDartThrow('S20');
      provider.processDartThrow('S19');
      provider.processDartThrow('S18');
      provider.handleTakeoutFinished();

      provider.processDartThrow('S20');

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });

    test('gameplay continues correctly after restore', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, false, false, false, false, false, 10,
      );
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);

      newProvider.processDartThrow('S19');
      expect(newProvider.currentGame!.totalDartsThrown['p1'], 2);
    });

    test('claimed sets and marks survive save/restore', () async {
      provider.startGame(
        players,
        ReefRoyaleGameMode.standard,
        false, // easyClaim (need 3 marks)
        false, false, false, false, false, 10,
      );
      // 3 marks on target 20 to claim
      provider.processDartThrow('T20');

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('reef_royale');

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.claimed['p1']!.contains(20), true);
      expect(newProvider.currentGame!.marks['p1']![20], 3);
    });
  });
}
