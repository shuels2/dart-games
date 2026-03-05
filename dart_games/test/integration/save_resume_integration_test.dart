import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/models/reef_royale_game.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/monster_mash_provider.dart';
import 'package:dart_games/providers/reef_royale_provider.dart';
import 'package:dart_games/services/save_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Player> players;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    players = [
      Player(id: 'p1', name: 'Alice', createdAt: DateTime.now()),
      Player(id: 'p2', name: 'Bob', createdAt: DateTime.now()),
      Player(id: 'p3', name: 'Charlie', createdAt: DateTime.now()),
    ];
  });

  group('Save trigger condition - totalDartsThrown', () {
    test('Carnival Derby: no darts thrown means no save needed', () {
      final provider = HorseRaceProvider();
      provider.startGame(players, 200);
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, false);
    });

    test('Carnival Derby: darts thrown means save needed', () {
      final provider = HorseRaceProvider();
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, true);
    });

    test('Target Tag: no darts thrown means no save needed', () {
      final provider = TargetTagProvider();
      provider.startSoloGame(players, 5, false);
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, false);
    });

    test('Target Tag: darts thrown means save needed', () {
      final provider = TargetTagProvider();
      provider.startSoloGame(players, 5, false);
      final target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow('S$target');
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, true);
    });

    test('Monster Mash: no darts thrown means no save needed', () {
      final provider = MonsterMashProvider();
      provider.startGame(players, 20, false, false, 10);
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, false);
    });

    test('Monster Mash: darts thrown means save needed', () {
      final provider = MonsterMashProvider();
      provider.startGame(players, 20, false, false, 10);
      provider.processDartThrow('S20');
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, true);
    });

    test('Reef Royale: no darts thrown means no save needed', () {
      final provider = ReefRoyaleProvider();
      provider.startGame(players, ReefRoyaleGameMode.standard, false, false, false, false, false, false, 8);
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, false);
    });

    test('Reef Royale: darts thrown means save needed', () {
      final provider = ReefRoyaleProvider();
      provider.startGame(players, ReefRoyaleGameMode.standard, false, false, false, false, false, false, 8);
      provider.processDartThrow('S20');
      final game = provider.currentGame!;
      final hasDarts = game.totalDartsThrown.values.any((c) => c > 0);
      expect(hasDarts, true);
    });
  });

  group('Full save-resume-complete cycle', () {
    test('Carnival Derby: save → resume → complete → auto-delete', () async {
      final provider = HorseRaceProvider();
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');
      provider.processDartThrow(20, dartDisplay: '20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(1));

      final newProvider = HorseRaceProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, saved[0].id);
      expect(newProvider.currentGame!.scores['p1'], 40);

      // Simulate auto-delete on game completion
      final savedGameId = newProvider.resumedSavedGameId!;
      await SaveGameService().deleteSavedGame('carnival_derby', savedGameId);
      newProvider.clearResumedSavedGameId();

      saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, isEmpty);
      expect(newProvider.resumedSavedGameId, isNull);
    });

    test('Target Tag: save → resume → complete → auto-delete', () async {
      final provider = TargetTagProvider();
      provider.startSoloGame(players, 5, false);
      final target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow('S$target');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('target_tag');
      expect(saved, hasLength(1));

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, saved[0].id);

      await SaveGameService().deleteSavedGame('target_tag', newProvider.resumedSavedGameId!);
      newProvider.clearResumedSavedGameId();

      saved = await SaveGameService().loadSavedGames('target_tag');
      expect(saved, isEmpty);
    });

    test('Monster Mash: save → resume → complete → auto-delete', () async {
      final provider = MonsterMashProvider();
      provider.startGame(players, 20, false, false, 10);
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('monster_mash');
      expect(saved, hasLength(1));

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, saved[0].id);

      await SaveGameService().deleteSavedGame('monster_mash', newProvider.resumedSavedGameId!);
      newProvider.clearResumedSavedGameId();

      saved = await SaveGameService().loadSavedGames('monster_mash');
      expect(saved, isEmpty);
    });

    test('Reef Royale: save → resume → complete → auto-delete', () async {
      final provider = ReefRoyaleProvider();
      provider.startGame(players, ReefRoyaleGameMode.standard, false, false, false, false, false, false, 8);
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('reef_royale');
      expect(saved, hasLength(1));

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, saved[0].id);

      await SaveGameService().deleteSavedGame('reef_royale', newProvider.resumedSavedGameId!);
      newProvider.clearResumedSavedGameId();

      saved = await SaveGameService().loadSavedGames('reef_royale');
      expect(saved, isEmpty);
    });
  });

  group('Resumed game save overwrites instead of duplicating', () {
    test('Carnival Derby: resume → save overwrites original entry', () async {
      final provider = HorseRaceProvider();
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      // Resume game in new provider
      final newProvider = HorseRaceProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, originalId);

      // Throw more darts and save again
      newProvider.processDartThrow(19, dartDisplay: '19');
      await newProvider.saveGame(players);

      // Should still be 1 saved game, not 2
      saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(1));
      expect(saved[0].id, originalId);
      // Verify updated state
      expect(saved[0].gameState['scores']['p1'], 39);
    });

    test('Target Tag: resume → save overwrites original entry', () async {
      final provider = TargetTagProvider();
      provider.startSoloGame(players, 5, false);
      final target = provider.currentGame!.targetNumbers['p1']!;
      provider.processDartThrow('S$target');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('target_tag');
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      final newProvider = TargetTagProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, originalId);

      // Throw another dart and save again
      final newTarget = newProvider.currentGame!.targetNumbers['p1']!;
      newProvider.processDartThrow('S$newTarget');
      await newProvider.saveGame(players);

      saved = await SaveGameService().loadSavedGames('target_tag');
      expect(saved, hasLength(1));
      expect(saved[0].id, originalId);
    });

    test('Monster Mash: resume → save overwrites original entry', () async {
      final provider = MonsterMashProvider();
      provider.startGame(players, 20, false, false, 10);
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('monster_mash');
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      final newProvider = MonsterMashProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, originalId);

      newProvider.processDartThrow('S19');
      await newProvider.saveGame(players);

      saved = await SaveGameService().loadSavedGames('monster_mash');
      expect(saved, hasLength(1));
      expect(saved[0].id, originalId);
    });

    test('Reef Royale: resume → save overwrites original entry', () async {
      final provider = ReefRoyaleProvider();
      provider.startGame(players, ReefRoyaleGameMode.standard, false, false, false, false, false, false, 8);
      provider.processDartThrow('S20');

      await provider.saveGame(players);
      var saved = await SaveGameService().loadSavedGames('reef_royale');
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      final newProvider = ReefRoyaleProvider();
      newProvider.restoreGame(saved[0]);
      expect(newProvider.resumedSavedGameId, originalId);

      newProvider.processDartThrow('S19');
      await newProvider.saveGame(players);

      saved = await SaveGameService().loadSavedGames('reef_royale');
      expect(saved, hasLength(1));
      expect(saved[0].id, originalId);
    });

    test('new game save still creates separate entry alongside resumed save', () async {
      // Save game 1
      final provider1 = HorseRaceProvider();
      provider1.startGame(players, 200);
      provider1.processDartThrow(20, dartDisplay: '20');
      await provider1.saveGame(players);

      var saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(1));
      final originalId = saved[0].id;

      // Resume and re-save game 1
      final resumedProvider = HorseRaceProvider();
      resumedProvider.restoreGame(saved[0]);
      resumedProvider.processDartThrow(19, dartDisplay: '19');
      await resumedProvider.saveGame(players);

      // Save a brand new game 2 (no resumedSavedGameId)
      final provider2 = HorseRaceProvider();
      provider2.startGame(players, 100);
      provider2.processDartThrow(50, dartDisplay: 'Bull');
      await provider2.saveGame(players);

      // Should have 2 saves: overwritten game 1 + new game 2
      saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(2));
      expect(saved[0].id, originalId); // overwritten, same ID
      expect(saved[1].id, isNot(originalId)); // new game, different ID
    });
  });

  group('Multiple saves independence', () {
    test('saves for different game types are independent', () async {
      final hrProvider = HorseRaceProvider();
      hrProvider.startGame(players, 200);
      hrProvider.processDartThrow(20, dartDisplay: '20');
      await hrProvider.saveGame(players);

      final ttProvider = TargetTagProvider();
      ttProvider.startSoloGame(players, 5, false);
      final target = ttProvider.currentGame!.targetNumbers['p1']!;
      ttProvider.processDartThrow('S$target');
      await ttProvider.saveGame(players);

      final cdSaved = await SaveGameService().loadSavedGames('carnival_derby');
      final ttSaved = await SaveGameService().loadSavedGames('target_tag');
      expect(cdSaved, hasLength(1));
      expect(ttSaved, hasLength(1));

      await SaveGameService().deleteAllSavedGames('carnival_derby');
      final cdAfter = await SaveGameService().loadSavedGames('carnival_derby');
      final ttAfter = await SaveGameService().loadSavedGames('target_tag');
      expect(cdAfter, isEmpty);
      expect(ttAfter, hasLength(1));
    });

    test('multiple saves for same game type coexist', () async {
      final provider1 = HorseRaceProvider();
      provider1.startGame(players, 200);
      provider1.processDartThrow(20, dartDisplay: '20');
      await provider1.saveGame(players);

      final provider2 = HorseRaceProvider();
      provider2.startGame(players, 100);
      provider2.processDartThrow(50, dartDisplay: 'Bull');
      await provider2.saveGame(players);

      final saved = await SaveGameService().loadSavedGames('carnival_derby');
      expect(saved, hasLength(2));

      expect(saved[0].gameState['targetScore'] != saved[1].gameState['targetScore'] ||
             saved[0].leadingPlayerScore != saved[1].leadingPlayerScore, true);
    });

    test('hasSavedGames returns correct status', () async {
      expect(await SaveGameService().hasSavedGames('carnival_derby'), false);

      final provider = HorseRaceProvider();
      provider.startGame(players, 200);
      provider.processDartThrow(20, dartDisplay: '20');
      await provider.saveGame(players);

      expect(await SaveGameService().hasSavedGames('carnival_derby'), true);
      expect(await SaveGameService().hasSavedGames('target_tag'), false);
    });
  });
}
