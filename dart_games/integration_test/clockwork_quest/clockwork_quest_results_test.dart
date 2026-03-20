import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

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

Future<void> clickDartsRemoved(WidgetTester tester) async {
  final dartsRemovedButton = find.text('DARTS REMOVED');
  if (dartsRemovedButton.evaluate().isNotEmpty) {
    await tester.tap(dartsRemovedButton.first);
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

/// Complete game: P1 advances through all 20 targets to win
Future<void> completeGameToVictory(WidgetTester tester) async {
  final playerId = ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;

  // P1 advances from 1 to 20 (hitting each target)
  for (int target = 1; target <= 20; target++) {
    await throwDartViaMock(tester, target);

    // Wait for takeout prompt after every 3rd dart
    if (target % 3 == 0) {
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await clickDartsRemoved(tester);
    }
  }

  // If not at 21st dart yet (didn't trigger takeout on 20th), click it now
  final currentDarts = ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester);
  if (currentDarts > 0) {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await clickDartsRemoved(tester);
  }

  // Wait for results screen navigation
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(); // Process navigation
  await tester.pump(); // Build results screen
  await tester.pump(); // Layout
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Results Screen Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Results screen shows after game completion',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      // Results screen should have 3 buttons
      await UITestHelpers.verifyResultsScreen(tester, config);
    });

    testWidgets('Test 2: Winner name is displayed on results screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      final winnerName = ElementFinders.getClockworkQuestWinnerName();
      expect(winnerName, findsOneWidget);
    });

    testWidgets('Test 3: Play Again returns to game screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickPlayAgain(tester, config);

      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
    });

    testWidgets('Test 4: Change Settings returns to menu',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickChangeSettings(tester, config);

      // Should be back on menu with game options visible
      expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(), findsOneWidget);
    });

    testWidgets('Test 5: Back to Menu returns to home screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickBackToMenu(tester, config);

      // Should be back on home screen
      expect(ElementFinders.getClockworkQuestCard(), findsOneWidget);
    });
  });
}
