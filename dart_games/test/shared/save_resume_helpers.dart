import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';

import 'ui_test_helpers.dart';
import 'game_ui_config.dart';

class GameSaveConfig {
  final String gameType;
  final List<String> playerNames;
  final String progressInfo;
  final String gameModeName;
  final String leadingPlayerName;
  final String leadingPlayerScore;
  final Map<String, dynamic> gameState;

  const GameSaveConfig({
    required this.gameType,
    required this.playerNames,
    required this.progressInfo,
    required this.gameModeName,
    required this.leadingPlayerName,
    required this.leadingPlayerScore,
    this.gameState = const {'_marker': 'test'},
  });

  factory GameSaveConfig.targetTag() => const GameSaveConfig(
        gameType: 'target_tag',
        playerNames: ['Alice', 'Bob'],
        progressInfo: '2 of 2 players remaining',
        gameModeName: 'Solo',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '5 shields',
      );

  factory GameSaveConfig.targetTagSecond() => const GameSaveConfig(
        gameType: 'target_tag',
        playerNames: ['Charlie', 'Diana', 'Eve'],
        progressInfo: '3 of 3 players remaining',
        gameModeName: 'Solo + Hero Bonus',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '5 shields',
        gameState: {'_marker': 'test2'},
      );

  factory GameSaveConfig.carnivalDerby() => const GameSaveConfig(
        gameType: 'carnival_derby',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Leading: 20 pts',
        gameModeName: 'Target: 200',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '20 pts',
      );

  factory GameSaveConfig.carnivalDerbySecond() => const GameSaveConfig(
        gameType: 'carnival_derby',
        playerNames: ['Charlie', 'Diana'],
        progressInfo: 'Leading: 40 pts',
        gameModeName: 'Target: 300',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '40 pts',
        gameState: {'_marker': 'test2'},
      );

  factory GameSaveConfig.monsterMash() => const GameSaveConfig(
        gameType: 'monster_mash',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 1',
        gameModeName: 'HP: 20',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '20 HP',
      );

  factory GameSaveConfig.monsterMashSecond() => const GameSaveConfig(
        gameType: 'monster_mash',
        playerNames: ['Charlie', 'Diana'],
        progressInfo: 'Round 3',
        gameModeName: 'HP: 30 + Bonus Buffs',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '30 HP',
        gameState: {'_marker': 'test2'},
      );

  factory GameSaveConfig.reefRoyale() => const GameSaveConfig(
        gameType: 'reef_royale',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Round 1',
        gameModeName: 'Standard',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: '0/7 corals',
      );

  factory GameSaveConfig.reefRoyaleSecond() => const GameSaveConfig(
        gameType: 'reef_royale',
        playerNames: ['Charlie', 'Diana'],
        progressInfo: 'Round 3',
        gameModeName: 'Cursed Tide + Bonus Buffs',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: '2/7 corals',
        gameState: {'_marker': 'test2'},
      );

  factory GameSaveConfig.lunarLander() => const GameSaveConfig(
        gameType: 'lunar_lander',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Altitude: 120 / 200',
        gameModeName: 'Alt: 200',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: 'Alt: 120',
      );

  factory GameSaveConfig.lunarLanderSecond() => const GameSaveConfig(
        gameType: 'lunar_lander',
        playerNames: ['Charlie', 'Diana'],
        progressInfo: 'Altitude: 80 / 300',
        gameModeName: 'Alt: 300, Hard Landing',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: 'Alt: 80',
        gameState: {'_marker': 'test2'},
      );

  factory GameSaveConfig.clockworkQuest() => const GameSaveConfig(
        gameType: 'clockwork_quest',
        playerNames: ['Alice', 'Bob'],
        progressInfo: 'Gear 1',
        gameModeName: 'Standard',
        leadingPlayerName: 'Alice',
        leadingPlayerScore: 'Gear 1',
      );

  factory GameSaveConfig.clockworkQuestSecond() => const GameSaveConfig(
        gameType: 'clockwork_quest',
        playerNames: ['Charlie', 'Diana'],
        progressInfo: 'Gear 5',
        gameModeName: 'Bullseye + Speed Mode',
        leadingPlayerName: 'Charlie',
        leadingPlayerScore: 'Gear 5',
        gameState: {'_marker': 'test2'},
      );
}

class SaveResumeHelpers {
  static Future<void> navigateToGameScreen(
    WidgetTester tester,
    GameUIConfig config, {
    List<String> playerNames = const ['Alice', 'Bob'],
  }) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    for (final name in playerNames) {
      await UITestHelpers.addPlayer(tester, name, config);
    }
    await UITestHelpers.startGame(tester, config);
  }

  static Future<String> preSaveGame(GameSaveConfig saveConfig) async {
    final metadata = SavedGameMetadata.create(
      gameType: saveConfig.gameType,
      playerNames: saveConfig.playerNames,
      progressInfo: saveConfig.progressInfo,
      gameModeName: saveConfig.gameModeName,
      leadingPlayerName: saveConfig.leadingPlayerName,
      leadingPlayerScore: saveConfig.leadingPlayerScore,
      gameState: saveConfig.gameState,
    );
    await SaveGameService().saveGame(metadata);
    return metadata.id;
  }

  static Future<List<String>> preSaveTwoGames(
    GameSaveConfig config1,
    GameSaveConfig config2,
  ) async {
    final id1 = await preSaveGame(config1);
    final id2 = await preSaveGame(config2);
    return [id1, id2];
  }
}
