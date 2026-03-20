import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/edit_score_helpers.dart';

// ==========================================================================
// HELPER METHODS
// ==========================================================================

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

Future<void> setupAndStartGame(
    WidgetTester tester, GameUIConfig config) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Edit Score Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Edit score button appears after 3 darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      // Throw 3 darts
      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      // Wait for takeout prompt
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Edit score button should be visible
      final editButton = config.getEditScoreButton();
      expect(editButton, findsOneWidget);
    });

    testWidgets('Test 2: Edit score dialog opens with current darts',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      await throwDartViaMock(tester, 1);
      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Tap edit score
      final editButton = config.getEditScoreButton();
      await tester.tap(editButton);
      await PumpSequences.dialogOpen(tester);

      // Dialog should be visible
      expect(ElementFinders.getEditScoreDialog(), findsOneWidget);
    });

    testWidgets('Test 3: Cancel edit score preserves original target',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      await throwDartViaMock(tester, 1);
      final targetBefore =
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId);

      await throwDartViaMock(tester, 2);
      await throwDartViaMock(tester, 3);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Open and cancel edit score
      final editButton = config.getEditScoreButton();
      await tester.tap(editButton);
      await PumpSequences.dialogOpen(tester);

      await tester.tap(ElementFinders.getEditScoreCancelButton());
      await PumpSequences.dialogClose(tester);

      // Target should be unchanged (advanced from 1 to 2)
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId),
          targetBefore);
    });

    testWidgets('Test 4: Edit score recalculates target progression correctly',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);

      final playerId =
          ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

      // Throw 3 misses - no advancement
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump();

      // Should still be at target 1
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 1);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Change dart 1 from Miss to S1 (should advance to target 2)
      await EditScoreHelpers.setDart1(tester, 'S1');

      // Save
      await EditScoreHelpers.updateScore(tester);

      // Target should now be 2
      expect(
          ProviderHelpers.getClockworkQuestPlayerCurrentTarget(tester, playerId), 2);
    });
  });
}
