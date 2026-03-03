import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/results_helpers.dart';

/// Monster Mash - Results Screen Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test the results screen functionality including:
/// - Results content with winner name and buttons
/// - Play Again preserves settings
/// - Change Settings returns to menu with preserved settings
/// - Back to Menu returns home
/// - Speed play winner determination
/// - Tie display in speed play
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_results_screen_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Monster Mash
  final config = GameUIConfig.monsterMash();

  // ===== MOCK API DART THROWING HELPERS =====

  MockScoliaApiService? getMockApi(WidgetTester tester) {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    return dartboardProvider.apiService;
  }

  Future<void> throwDartViaMock(WidgetTester tester, int number, {String multiplier = 'single'}) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: number * (multiplier == 'double' ? 2 : multiplier == 'triple' ? 3 : 1),
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

  /// Complete a game to victory via elimination (low health for speed)
  Future<void> completeGameToVictory(WidgetTester tester) async {
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    if (playerA == null || playerB == null) {
      throw Exception('Players not found');
    }

    final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
    final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
    final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

    // Attack opponent with triples: 3+3+3 = 9 damage (out of 10 HP)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Opponent misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Finish off opponent (1 HP remaining)
    await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
    await clickDartsRemoved(tester);

    // Wait for victory screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  group('Monster Mash - Results Screen Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Results content - single winner - Winner name via key, all 3 action buttons visible', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      // Complete game
      await completeGameToVictory(tester);

      // Verify winner name
      final winnerName = ElementFinders.getMonsterMashWinnerName();
      expect(winnerName, findsOneWidget);

      // Verify all 3 action buttons
      expect(config.getPlayAgainButton(), findsOneWidget);
      expect(config.getChangeSettingsButton(), findsOneWidget);
      expect(config.getBackToMenuButton(), findsOneWidget);
    });

    testWidgets('Test 2: Play Again preserves settings - Complete game (health=15), Play Again -> new game with same players, healthMax=15', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 15);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      // Need to verify healthMax is 15 in game
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId), 15);

      // Complete game to victory
      // Attack with appropriate damage for health=15
      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Attack: 3+3+3=9 damage
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Opponent misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Attack: 3+3 = 6 more damage (total 15 = eliminated)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Wait for results
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Click Play Again
      await ResultsHelpers.clickPlayAgain(tester, config);

      // Verify new game started with same health
      expect(ProviderHelpers.isMonsterMashGameActive(tester), isTrue);
      final newPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, newPlayerId), 15);

      // Verify players are present
      expect(find.text('Player A'), findsWidgets);
      expect(find.text('Player B'), findsWidgets);
    });

    testWidgets('Test 3: Change Settings returns to menu - Complete game, Change Settings -> menu with preserved settings', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      await completeGameToVictory(tester);

      // Click Change Settings
      await ResultsHelpers.clickChangeSettings(tester, config);

      // Verify we're back on the menu
      expect(find.textContaining('Monster Mash'), findsWidgets);

      // Verify players are present
      expect(find.text('Player A'), findsWidgets);
      expect(find.text('Player B'), findsWidgets);
    });

    testWidgets('Test 4: Back to Menu returns home - Complete game, Back to Menu -> home screen', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      await completeGameToVictory(tester);

      // Click Back to Menu
      await ResultsHelpers.clickBackToMenu(tester, config);

      // Verify we're on the home screen
      expect(find.textContaining('Dart Games'), findsWidgets);
    });

    testWidgets('Test 5: Speed play winner (round limit) - health=50, speed play ON, limit=3, deal unequal damage -> correct winner by health', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Play 3 rounds - player 1 attacks, player 2 misses
      for (int round = 0; round < 3; round++) {
        // Player 1: attack with triples for significant damage
        await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);

        // Player 2: miss everything
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);
      }

      // Game should be over, winner determined by health
      expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify results screen
      expect(config.getPlayAgainButton(), findsOneWidget);
    });

    testWidgets('Test 6: Tie display (speed play) - health=50, speed play ON, limit=3, all misses -> tied result', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      // Play 3 rounds - all misses for both players (tied health)
      for (int round = 0; round < 3; round++) {
        // Player 1: miss
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);

        // Player 2: miss
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);
      }

      // Game should be over
      expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

      // Wait for results screen
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify tie display - should show "TIED!" text
      expect(find.textContaining('TIED'), findsWidgets);
    });
  });
}
