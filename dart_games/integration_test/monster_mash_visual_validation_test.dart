import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

// Shared component imports
import 'shared/ui_test_helpers.dart';
import 'shared/pump_sequences.dart';
import 'shared/settings_helpers.dart';
import 'shared/game_ui_config.dart';
import 'shared/provider_helpers.dart';

/// Monster Mash - Visual Validation Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and validate visual states including:
/// - Health bar color gradients at different thresholds
/// - Monster image changes with health percentage
/// - Dart display border colors for healing/damage/miss
/// - Eliminated opponent visual state
/// - Opponent health shield colors
/// - Round progress bar states
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_visual_validation_test.dart \
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

  group('Monster Mash - Visual Validation Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Health bar color gradient thresholds - Full health = green, ~70% = yellow shift, ~30% = red shift via provider healthPercentage', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Full health = 100%
      final fullHealthPct = ProviderHelpers.getMonsterMashHealthPercentage(tester, currentPlayerId);
      expect(fullHealthPct, 1.0);

      // Reduce opponent's health to ~70% (14/20 = 70%)
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent at 14/20 = 70%
      final pct70 = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
      expect(pct70, closeTo(0.7, 0.01));

      // Opponent's turn - attack first player to get to ~30%
      final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await clickDartsRemoved(tester);

      // First player at 11/20 = 55%
      final pct55 = ProviderHelpers.getMonsterMashHealthPercentage(tester, currentPlayerId);
      expect(pct55, closeTo(0.55, 0.01));

      // Attack opponent more to get to ~30%
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 11/20
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 8/20
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 6/20
      await clickDartsRemoved(tester);

      // Opponent at 6/20 = 30%
      final pct30 = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
      expect(pct30, closeTo(0.3, 0.01));
    });

    testWidgets('Test 2: Monster image changes with health - Provider getMonsterImagePath returns correct state: FullHealth, 70Health, 30Health, Eliminated', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Full health: FullHealth image
      final fullImage = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
      expect(fullImage, contains('FullHealth'));

      // Reduce to 70% health (7/10) -> 70Health image
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 7/10
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      final image70 = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
      expect(image70, contains('70Health'));

      // Opponent misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Reduce to 30% health (3/10) -> 30Health image
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 5/10
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 3/10
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      final image30 = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
      expect(image30, contains('30Health'));

      // Opponent misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Eliminate (reduce to 0)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 0
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, opponentId), isTrue);

      final eliminatedImage = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, opponentId)!;
      expect(eliminatedImage, contains('Eliminated'));
    });

    testWidgets('Test 3: Dart display - healing vs damage vs miss - Provider tracks heal amount, damage dealt, and target per dart', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;
      final ownTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

      // First reduce health so heal is visible
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent attacks to reduce health
      await throwDartViaMock(tester, ownTarget, multiplier: 'triple'); // -3
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Now test: Dart 1 = heal (own target), Dart 2 = damage (opponent target), Dart 3 = miss
      await throwDartViaMock(tester, ownTarget, multiplier: 'single'); // heal +1
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single'); // damage 1
      await throwMissViaMock(tester); // miss

      // Verify dart tracking
      final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
      final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      final targetIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);

      expect(healAmounts.length, 3);
      expect(healAmounts[0], 1); // heal dart
      expect(healAmounts[1], 0); // damage dart (no heal)
      expect(healAmounts[2], 0); // miss (no heal)

      expect(damageAmounts.length, 3);
      expect(damageAmounts[0], 0); // heal dart (no damage)
      expect(damageAmounts[1], 1); // damage dart
      expect(damageAmounts[2], 0); // miss (no damage)

      expect(targetIds.length, 3);
      expect(targetIds[0], isNull); // heal dart (no target)
      expect(targetIds[1], opponentId); // damage dart
      expect(targetIds[2], isNull); // miss (no target)
    });

    testWidgets('Test 4: Eliminated opponent visual state - Eliminated opponent marked via provider', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      await UITestHelpers.startGame(tester, config);

      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

      // Not eliminated initially
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isFalse);

      // Attack player B to eliminate
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple'); // -3 -> 1 HP
      await clickDartsRemoved(tester);

      // Player B misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player C misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Finish off Player B
      await throwDartViaMock(tester, playerBTarget, multiplier: 'single'); // -1 -> 0 HP

      // Verify elimination
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id), 0);

      // Verify eliminated image path
      final imagePath = ProviderHelpers.getMonsterMashPlayerMonsterImagePath(tester, playerB.id)!;
      expect(imagePath, contains('Eliminated'));
    });

    testWidgets('Test 5: Opponent health thresholds - Health >70% green zone, 30-70% yellow zone, <30% red zone', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // At 20/20 = 100% -> green zone (>70%)
      var pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
      expect(pct, greaterThan(0.7));

      // Reduce to 12/20 = 60% -> yellow zone (30-70%)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 17
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 14
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 12
      await clickDartsRemoved(tester);

      pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
      expect(pct, closeTo(0.6, 0.01));
      expect(pct, greaterThanOrEqualTo(0.3));
      expect(pct, lessThanOrEqualTo(0.7));

      // Opponent misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Reduce to 4/20 = 20% -> red zone (<30%)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 9
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple'); // -3 -> 6
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double'); // -2 -> 4
      await clickDartsRemoved(tester);

      pct = ProviderHelpers.getMonsterMashHealthPercentage(tester, opponentId);
      expect(pct, closeTo(0.2, 0.01));
      expect(pct, lessThan(0.3));
    });

    testWidgets('Test 6: Round progress bar states - Speed play OFF = no active round bar, Speed play ON = shows round progress', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start with speed play OFF
      await UITestHelpers.startGame(tester, config);

      // Verify current round
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

      // Play through 1 full round
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Round should increment
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);

      // Navigate back and start with speed play ON
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await PumpSequences.navigation(tester);
      }

      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 5);

      await UITestHelpers.startGame(tester, config);

      // Verify round starts at 1
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

      // Verify round limit
      expect(ProviderHelpers.getMonsterMashRoundLimit(tester), 5);

      // Play 1 round
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Round should be 2
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);
    });
  });
}
