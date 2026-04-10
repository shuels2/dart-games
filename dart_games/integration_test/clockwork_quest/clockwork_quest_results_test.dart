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
    WidgetTester tester, GameUIConfig config) async {
  await UITestHelpers.navigateToGameMenu(tester, config);

  await UITestHelpers.addPlayer(tester, 'Player A', config);
  await UITestHelpers.addPlayer(tester, 'Player B', config);

  // Players are auto-selected when added
  await UITestHelpers.startGame(tester, config);
}

/// Complete a full turn: throw 3 misses and click darts removed
Future<void> completeTurnWithMisses(WidgetTester tester) async {
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);
}

/// Complete game: P1 advances through all 20 targets to win
/// P1 hits 3 targets per turn, P2 misses all turns
Future<void> completeGameToVictory(WidgetTester tester) async {
  // P1 hits targets 1-20 in groups of 3 per turn
  // After each P1 turn, P2 misses
  for (int startTarget = 1; startTarget <= 20; startTarget += 3) {
    // P1's turn: hit 3 sequential targets
    for (int t = startTarget; t < startTarget + 3 && t <= 20; t++) {
      await throwDartViaMock(tester, t);
    }
    // If P1 hit fewer than 3 targets (last group might be partial), fill with misses
    final targetsHit = (startTarget + 2 <= 20) ? 3 : (20 - startTarget + 1);
    for (int i = targetsHit; i < 3; i++) {
      await throwMissViaMock(tester);
    }
    await clickDartsRemoved(tester);

    // Check if game is over (P1 won after hitting target 20)
    if (ProviderHelpers.clockworkQuestHasWinner(tester)) break;

    // P2's turn: miss all
    await completeTurnWithMisses(tester);
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

    // ================================================================
    // RESULTS SCREEN DISPLAY
    // ================================================================

    testWidgets('Test 1: Results screen shows after game completion',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      // Results screen should have all 3 action buttons
      await UITestHelpers.verifyResultsScreen(tester, config);
    });

    testWidgets('Test 2: Winner name is displayed on results screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      final winnerName = ElementFinders.getClockworkQuestWinnerName();
      expect(winnerName, findsOneWidget);
    });

    testWidgets('Test 3: Winner title is displayed',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      expect(find.byKey(ClockworkQuestResultsKeys.winnerTitle), findsOneWidget);
    });

    testWidgets('Test 4: Rankings list shows all players',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      expect(find.byKey(ClockworkQuestResultsKeys.rankingsList), findsOneWidget);

      // Both players should appear in rankings
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      for (final playerId in provider.currentGame!.playerIds) {
        expect(
          find.byKey(ClockworkQuestResultsKeys.playerRankTile(playerId)),
          findsOneWidget,
          reason: 'Player $playerId should appear in rankings',
        );
      }
    });

    // ================================================================
    // PLAY AGAIN BUTTON
    // ================================================================

    testWidgets('Test 5: Play Again returns to game screen with same players',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickPlayAgain(tester, config);

      // Should be back on game screen with game active
      expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);

      // Should have same 2 players
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.playerIds.length, 2);
    });

    // ================================================================
    // CHANGE SETTINGS BUTTON
    // ================================================================

    testWidgets('Test 6: Change Settings returns to menu',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickChangeSettings(tester, config);

      // Should be back on menu with game settings visible
      expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
          findsOneWidget);
      expect(ElementFinders.getClockworkQuestSpeedModeCheckbox(),
          findsOneWidget);
      expect(ElementFinders.getClockworkQuestNumberOfLapsDropdown(),
          findsOneWidget);
    });

    testWidgets('Test 7: Change Settings preserves players from game',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickChangeSettings(tester, config);

      // Players should be pre-selected (2 players)
      final playerProvider = ProviderHelpers.getPlayerProvider(tester);
      expect(playerProvider.selectedPlayers.length, 2);
    });

    // ================================================================
    // LEAVE TOWER BUTTON
    // ================================================================

    testWidgets('Test 8: Leave Tower returns to home screen',
        (WidgetTester tester) async {
      await setupAndStartGame(tester, config);
      await completeGameToVictory(tester);

      await UITestHelpers.clickBackToMenu(tester, config);

      // Should be back on home screen with game card visible
      expect(ElementFinders.getClockworkQuestCard(), findsOneWidget);
    });
  });
}
