import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MonsterMashProvider provider;
  late List<Player> players;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = MonsterMashProvider();
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  // Helper to create sector strings
  String singleSector(int number) => 'S$number';
  String doubleSector(int number) => 'D$number';

  group('MonsterMashProvider save/restore', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startGame(players, 20, true, true, 5);

      final p2Target = provider.currentGame!.targetNumbers['p2']!;
      provider.processDartThrow(singleSector(p2Target));

      await provider.saveGame(players);

      final saved = await SaveGameService().loadSavedGames('monster_mash');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'monster_mash');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].progressInfo, 'Round 1');
      expect(saved[0].gameModeName, contains('HP: 20'));
      expect(saved[0].gameModeName, contains('Buffs'));
      expect(saved[0].gameModeName, contains('Speed (5)'));
      expect(saved[0].leadingPlayerScore, contains('HP'));
    });

    test('restoreGame restores full game state', () async {
      provider.startGame(players, 20, true, false, 10);

      final p2Target = provider.currentGame!.targetNumbers['p2']!;
      provider.processDartThrow(doubleSector(p2Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.healthMax, 20);
      expect(newProvider.currentGame!.bonusBuffsEnabled, true);
      expect(newProvider.currentGame!.health['p2']! < 20, true);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startGame(players, 20, false, false, 10);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('resumedSavedGameId is set and clearable', () async {
      provider.startGame(players, 20, false, false, 10);
      provider.processDartThrow(singleSector(
          provider.currentGame!.targetNumbers['p2']!));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, saved[0].id);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startGame(players, 20, false, false, 10);
      final p2Target = provider.currentGame!.targetNumbers['p2']!;
      provider.processDartThrow(singleSector(p2Target));
      provider.processDartThrow(singleSector(p2Target));
      provider.processDartThrow(singleSector(p2Target));
      provider.handleTakeoutFinished();

      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });

    test('gameplay continues correctly after restore', () async {
      provider.startGame(players, 20, false, false, 10);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);

      newProvider.processDartThrow(singleSector(p1Target));
      expect(newProvider.currentGame!.totalDartsThrown['p1'], 2);
    });

    test('monster assignments survive save/restore', () async {
      provider.startGame(players, 20, false, false, 10);

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('monster_mash');

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.monsterAssignments,
          provider.currentGame!.monsterAssignments);
    });
  });
}
