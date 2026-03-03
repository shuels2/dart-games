import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';
import '../shared/edit_score_helpers.dart';

/// Monster Mash - Edit Score Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test edit score dialog functionality including:
/// - Opening the edit score dialog after 3 darts
/// - Changing individual darts and saving
/// - Changing all three darts
/// - Cancel preserves original scores
/// - Healing dart corrections
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_edit_score_test.dart \
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

  group('Monster Mash - Edit Score Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Edit score dialog opens - 3 darts -> takeout modal -> tap Edit Player Score -> dialog opens with dart dropdowns', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify we're in takeout state
      final provider = ProviderHelpers.getMonsterMashProvider(tester);
      expect(provider.shouldPromptTakeout, isTrue);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Verify dialog is open with dart dropdowns
      EditScoreHelpers.verifyDialogElements();
    });

    testWidgets('Test 2: Change single dart and save - 3 misses -> edit dart 1 to opponent target -> save -> opponent health -1', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Opponent health before
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthBefore, 20);

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Change dart 1 to opponent's target (single)
      await EditScoreHelpers.setDart1(tester, 'S$opponentTarget');

      // Save
      await EditScoreHelpers.updateScore(tester);

      // Verify opponent health decreased by 1
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthAfter, 19); // 20 - 1 = 19
    });

    testWidgets('Test 3: Change all three darts - 3 misses -> edit all darts to opponent S/D/T -> save -> opponent health -6', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Change all 3 darts to opponent's target: S, D, T
      await EditScoreHelpers.setAllDarts(
        tester,
        'S$opponentTarget',
        'D$opponentTarget',
        'T$opponentTarget',
      );

      // Save
      await EditScoreHelpers.updateScore(tester);

      // Verify opponent health decreased by 6 (1+2+3)
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthAfter, 14); // 20 - 6 = 14
    });

    testWidgets('Test 4: Cancel preserves original - 3 darts at opponent -> edit dart 1 to Miss -> cancel -> original scores preserved', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Throw 3 singles at opponent's target (3 damage total)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Opponent health should be 17
      final healthAfterThrows = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthAfterThrows, 17);

      // Open edit score dialog
      await EditScoreHelpers.openEditScore(tester, config);

      // Change dart 1 to Miss
      await EditScoreHelpers.setDart1(tester, 'Miss');

      // Cancel instead of saving
      await EditScoreHelpers.cancelEditScore(tester);

      // Verify original scores preserved (opponent still at 17)
      final healthAfterCancel = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthAfterCancel, 17);
    });

    testWidgets('Test 5: Healing dart correction - Miss -> edit to own target -> save -> health restored by heal amount', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final playerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

      // First, reduce health: skip turn, let opponent attack
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent attacks to reduce health
      await throwDartViaMock(tester, playerTarget, multiplier: 'triple'); // -3 HP
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Back to our turn, health should be 17
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthBefore, 17);

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Open edit score and change dart 1 to own target (heal)
      await EditScoreHelpers.openEditScore(tester, config);
      await EditScoreHelpers.setDart1(tester, 'S$playerTarget');
      await EditScoreHelpers.updateScore(tester);

      // Verify health increased by 1
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthAfter, 18); // 17 + 1 = 18
    });
  });
}
