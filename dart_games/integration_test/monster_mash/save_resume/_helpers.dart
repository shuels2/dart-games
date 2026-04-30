import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

final config = GameUIConfig.monsterMash();
const gameType = 'monster_mash';

/// Navigate to game screen with 2 players ready to play
Future<void> navigateToGameScreen(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);
  // Players are auto-selected when added, no need to call selectPlayers
  await UITestHelpers.startGame(tester, config);
}

/// Throw one dart on the game screen via mock API
Future<void> throwOneDart(WidgetTester tester) async {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  final mockApi = dartboardProvider.apiService;
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 20,
      multiplier: 'single',
      playerName: 'Player',
      baseScore: 20,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Throw a dart at a specific number via mock API
Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  final mockApi = dartboardProvider.apiService;
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: number *
          (multiplier == 'double'
              ? 2
              : multiplier == 'triple'
                  ? 3
                  : 1),
      multiplier: multiplier,
      playerName: 'Player',
      baseScore: number,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Throw a miss via mock API
Future<void> throwMissViaMock(WidgetTester tester) async {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  final mockApi = dartboardProvider.apiService;
  if (mockApi != null) {
    mockApi.simulateDartThrow(
      score: 0,
      multiplier: 'single',
      playerName: 'Player',
      baseScore: 0,
      widgetX: 125.0,
      widgetY: 125.0,
      widgetSize: 250.0,
    );
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Click DARTS REMOVED button on emulator
Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

/// Navigate to game screen with low health for quick completion
Future<void> navigateToGameScreenLowHealth(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);
  await UITestHelpers.startGame(tester, config);
}

/// Pre-populate a saved game via server API
Future<String> preSaveGame() async {
  final metadata = SavedGameMetadata.create(
    gameType: gameType,
    playerNames: ['Alice', 'Bob'],
    progressInfo: 'Round 1',
    gameModeName: 'HP: 20',
    leadingPlayerName: 'Alice',
    leadingPlayerScore: '20 HP',
    gameState: {'_marker': 'test'},
  );
  await SaveGameService().saveGame(metadata);
  return metadata.id;
}

/// Pre-populate two saved games
Future<List<String>> preSaveTwoGames() async {
  final id1 = await preSaveGame();
  final metadata2 = SavedGameMetadata.create(
    gameType: gameType,
    playerNames: ['Charlie', 'Diana'],
    progressInfo: 'Round 3',
    gameModeName: 'HP: 30 + Bonus Buffs',
    leadingPlayerName: 'Charlie',
    leadingPlayerScore: '30 HP',
    gameState: {'_marker': 'test2'},
  );
  await SaveGameService().saveGame(metadata2);
  return [id1, metadata2.id];
}
