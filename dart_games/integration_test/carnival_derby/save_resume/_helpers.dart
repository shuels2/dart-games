import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/saved_game_metadata.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

final config = GameUIConfig.carnivalDerby();
const gameType = 'carnival_derby';

Future<void> navigateToGameScreen(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);
  await UITestHelpers.startGame(tester, config);
}

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

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
    await PumpSequences.simpleUpdate(tester);
  }
}

Future<String> preSaveGame() async {
  final metadata = SavedGameMetadata.create(
    gameType: gameType,
    playerNames: ['Alice', 'Bob'],
    progressInfo: 'Leading: 20 pts',
    gameModeName: 'Target: 200',
    leadingPlayerName: 'Alice',
    leadingPlayerScore: '20 pts',
    gameState: {'_marker': 'test'},
  );
  await SaveGameService().saveGame(metadata);
  return metadata.id;
}

Future<List<String>> preSaveTwoGames() async {
  final id1 = await preSaveGame();
  final metadata2 = SavedGameMetadata.create(
    gameType: gameType,
    playerNames: ['Charlie', 'Diana'],
    progressInfo: 'Leading: 40 pts',
    gameModeName: 'Target: 300',
    leadingPlayerName: 'Charlie',
    leadingPlayerScore: '40 pts',
    gameState: {'_marker': 'test2'},
  );
  await SaveGameService().saveGame(metadata2);
  return [id1, metadata2.id];
}
