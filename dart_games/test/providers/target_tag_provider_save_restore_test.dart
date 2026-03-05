import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/services/save_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TargetTagProvider provider;
  late List<Player> players;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = TargetTagProvider();
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  // Helper to create sector string from target number
  String singleSector(int number) => 'S$number';
  String doubleSector(int number) => 'D$number';

  group('TargetTagProvider save/restore - solo', () {
    test('saveGame creates metadata with correct fields', () async {
      provider.startSoloGame(players, 5, false);

      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));

      await provider.saveGame(players);

      final saved = await SaveGameService().loadSavedGames('target_tag');
      expect(saved, hasLength(1));
      expect(saved[0].gameType, 'target_tag');
      expect(saved[0].playerNames, ['Alice', 'Bob', 'Charlie']);
      expect(saved[0].progressInfo, contains('of 3 players remaining'));
      expect(saved[0].gameModeName, contains('Solo'));
      expect(saved[0].gameModeName, contains('Shields: 5'));
      expect(saved[0].leadingPlayerScore, contains('shields'));
    });

    test('restoreGame restores full game state', () async {
      provider.startSoloGame(players, 5, true);

      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(doubleSector(p1Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame, isNotNull);
      expect(newProvider.currentGame!.shields['p1'], 3);
      expect(newProvider.currentGame!.soloHeroBonus, true);
      expect(newProvider.currentGame!.shieldMax, 5);
    });

    test('restoreGame restores waitingForTakeout', () async {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      expect(provider.shouldPromptTakeout, true);

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.shouldPromptTakeout, true);
    });

    test('resumedSavedGameId is set and clearable', () async {
      provider.startSoloGame(players, 5, false);
      provider.processDartThrow(singleSector(
          provider.currentGame!.targetNumbers['p1']!));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      provider.restoreGame(saved[0]);
      expect(provider.resumedSavedGameId, saved[0].id);

      provider.clearResumedSavedGameId();
      expect(provider.resumedSavedGameId, isNull);
    });

    test('totalDartsThrown and totalTurns survive save/restore', () async {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      provider.processDartThrow(singleSector(p1Target));
      provider.handleTakeoutFinished();

      final p2Target = provider.currentGame!.targetNumbers['p2']!;
      provider.processDartThrow(singleSector(p2Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.totalDartsThrown['p1'], 3);
      expect(newProvider.currentGame!.totalDartsThrown['p2'], 1);
      expect(newProvider.currentGame!.totalTurns['p1'], 1);
      expect(newProvider.currentGame!.totalTurns['p2'], 1);
    });

    test('gameplay continues correctly after restore', () async {
      provider.startSoloGame(players, 5, false);
      final p1Target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow(singleSector(p1Target));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);

      final restoredTarget = newProvider.currentGame!.targetNumbers['p1']!;
      newProvider.processDartThrow(doubleSector(restoredTarget));
      expect(newProvider.currentGame!.shields['p1'], 3);
    });
  });

  group('TargetTagProvider save/restore - team', () {
    test('team mode save/restore preserves team mappings', () async {
      final teams = {
        'team1': ['p1', 'p2'],
        'team2': ['p3'],
      };
      provider.startTeamGame(teams, 5, false);

      final firstPlayer = provider.currentGame!.getCurrentPlayerId();
      final firstTarget = provider.currentGame!.targetNumbers[firstPlayer]!;
      provider.processDartThrow(singleSector(firstTarget));

      await provider.saveGame(players);
      final saved = await SaveGameService().loadSavedGames('target_tag');

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);

      expect(newProvider.currentGame!.playerToTeam, isNotNull);
      expect(newProvider.currentGame!.teamPlayers, isNotNull);
      expect(newProvider.currentGame!.teamIcons, isNotNull);
    });
  });
}
