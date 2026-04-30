import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';

final config = GameUIConfig.clockworkQuest();

MockScoliaApiService? getMockApi(WidgetTester tester) {
  final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
  return dartboardProvider.apiService;
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
    {String multiplier = 'single'}) async {
  final mockApi = getMockApi(tester);
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
  final mockApi = getMockApi(tester);
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

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  bool speedMode = false,
}) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  if (includeBullseye) {
    await SettingsHelpers.toggleClockworkQuestIncludeBullseye(tester);
  }
  if (speedMode) {
    await SettingsHelpers.toggleClockworkQuestSpeedMode(tester);
  }

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

/// Throw 3 darts to trigger takeout prompt (where edit score button appears)
Future<void> throw3DartsAndWaitForTakeout(WidgetTester tester,
    {int target1 = 0, int target2 = 0, int target3 = 0}) async {
  if (target1 > 0) {
    await throwDartViaMock(tester, target1);
  } else {
    await throwMissViaMock(tester);
  }
  if (target2 > 0) {
    await throwDartViaMock(tester, target2);
  } else {
    await throwMissViaMock(tester);
  }
  if (target3 > 0) {
    await throwDartViaMock(tester, target3);
  } else {
    await throwMissViaMock(tester);
  }
}
