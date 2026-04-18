import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/models/monster_mash_game.dart';
import 'package:dart_games/constants/test_keys.dart';

// Shared component imports
import '../shared/ui_test_helpers.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

/// Monster Mash - Gameplay Integration Tests
///
/// These are full integration tests that run the complete app in Chrome
/// and test gameplay functionality including:
/// - Healing (hitting own number)
/// - Attacking (hitting opponent number)
/// - Multiplier effects
/// - Bullseye/Outer Bull special effects
/// - Miss handling
/// - Turn advancement and takeout
/// - Skip turn
/// - Player elimination
/// - Game win conditions
/// - Speed play round counting
/// - Bonus buff effects (Blood Moon, Ancient Bandages, Shadow Walk, Laboratory Spark)
///
/// Run with:
/// ```bash
/// # Terminal 1: Start chromedriver
/// cd dart_games/chromedriver/chromedriver-win64
/// ./chromedriver.exe --port=4444
///
/// # Terminal 2: Run tests
/// flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/monster_mash_gameplay_test.dart \
///   -d chrome
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Game configuration for Monster Mash
  final config = GameUIConfig.monsterMash();

  // ===== MOCK API DART THROWING HELPERS =====

  /// Get MockScoliaApiService from the widget tree
  MockScoliaApiService? getMockApi(WidgetTester tester) {
    final dartboardProvider = ProviderHelpers.getDartboardProvider(tester);
    return dartboardProvider.apiService;
  }

  /// Simulate hitting a specific dartboard number using mock API
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

  /// Simulate throwing a bullseye (50 points)
  Future<void> throwBullseyeViaMock(WidgetTester tester) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 50,
        multiplier: 'bullseye',
        playerName: 'Player',
        baseScore: 50,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Simulate throwing an outer bull (25 points)
  Future<void> throwOuterBullViaMock(WidgetTester tester) async {
    final mockApi = getMockApi(tester);
    if (mockApi != null) {
      mockApi.simulateDartThrow(
        score: 25,
        multiplier: 'outer_bull',
        playerName: 'Player',
        baseScore: 25,
        widgetX: 125.0,
        widgetY: 125.0,
        widgetSize: 250.0,
      );
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Simulate a miss
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

  /// Click DARTS REMOVED button on emulator
  Future<void> clickDartsRemoved(WidgetTester tester) async {
    final dartsRemovedButton = find.text('DARTS REMOVED');
    if (dartsRemovedButton.evaluate().isNotEmpty) {
      await tester.tap(dartsRemovedButton.first);
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Set the active buff programmatically on the provider's current game
  Future<void> setActiveBuff(WidgetTester tester, BonusBuff buff) async {
    final provider = ProviderHelpers.getMonsterMashProvider(tester);
    provider.currentGame!.activeBuff = buff;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    provider.notifyListeners();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  }

  group('Monster Mash - Core Gameplay Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Test 1: Healing - hit own number - Throw single at own target -> healAmount=1, health increases', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      // Start game with health=20
      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final playerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;

      // First reduce health via opponent attack
      // Find opponent's target to hit
      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Hit opponent's target to deal damage (just to verify attack works, but we're testing heal)
      // Instead, let's reduce health by hitting the opponent target first
      // Actually, let's test healing directly - throw misses to use darts, advance turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player B's turn - hit Player A's target to reduce health
      final newCurrentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final firstPlayerTarget = currentPlayerId == playerA.id
          ? ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA.id)!
          : ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

      // Attack first player
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'single');
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Back to first player - health should be 19
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthBefore, 19);

      // Hit own target to heal
      await throwDartViaMock(tester, playerTarget, multiplier: 'single');

      // Verify heal amount
      final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
      expect(healAmounts.isNotEmpty, isTrue);
      expect(healAmounts.last, 1);

      // Verify health increased
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthAfter, 20); // 19 + 1 = 20
    });

    testWidgets('Test 2: Attack - hit opponent number - Throw single at opponent target -> opponent health -1, damageDealt=1, targetPlayerId set', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Attacker', config);
      await UITestHelpers.addPlayer(tester, 'Defender', config);

      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final attacker = ProviderHelpers.findPlayerByName(tester, 'Attacker')!;
      final defender = ProviderHelpers.findPlayerByName(tester, 'Defender')!;
      final opponentId = currentPlayerId == attacker.id ? defender.id : attacker.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Record health before attack
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthBefore, 20);

      // Attack opponent
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Verify damage
      final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageDealt.isNotEmpty, isTrue);
      expect(damageDealt.last, 1);

      // Verify target player ID
      final targetPlayerIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);
      expect(targetPlayerIds.isNotEmpty, isTrue);
      expect(targetPlayerIds.last, opponentId);

      // Verify opponent health decreased
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(healthAfter, 19);
    });

    testWidgets('Test 3: Multiplier effects (S/D/T) - Three darts at opponent: single(1), double(2), triple(3) -> total 6 damage', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Throw single (1 dmg)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
      // Throw double (2 dmg)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double');
      // Throw triple (3 dmg)
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');

      // Verify total damage: 1 + 2 + 3 = 6
      final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(opponentHealth, 14); // 20 - 6 = 14

      // Verify individual dart damage
      final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageDealt.length, 3);
      expect(damageDealt[0], 1); // single
      expect(damageDealt[1], 2); // double
      expect(damageDealt[2], 3); // triple
    });

    testWidgets('Test 4: Bullseye heals to full - Reduce health first, throw Bullseye -> heals to healthMax', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Healer', config);
      await UITestHelpers.addPlayer(tester, 'Opponent', config);

      await UITestHelpers.startGame(tester, config);

      final healer = ProviderHelpers.findPlayerByName(tester, 'Healer')!;
      final opponent = ProviderHelpers.findPlayerByName(tester, 'Opponent')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final firstPlayerId = currentPlayerId;

      // Miss 3 darts, advance turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent attacks first player to reduce health
      final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, firstPlayerId)!;
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
      await clickDartsRemoved(tester);

      // First player's turn again - health should be 11 (20 - 9)
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
      expect(healthBefore, 11);

      // Throw bullseye to heal to full
      await throwBullseyeViaMock(tester);

      // Verify healed to max
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
      expect(healthAfter, 20); // healed to healthMax
    });

    testWidgets('Test 5: Outer bull heals +5 - Reduce health, throw Outer Bull -> +5 health (capped at max)', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final firstPlayerId = currentPlayerId;

      // Miss 3 darts, advance turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent attacks to reduce health
      final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, firstPlayerId)!;
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3 HP
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // First player's health should be 14 (20 - 6)
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
      expect(healthBefore, 14);

      // Throw outer bull to heal +5
      await throwOuterBullViaMock(tester);

      // Verify +5 heal
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, firstPlayerId);
      expect(healthAfter, 19); // 14 + 5 = 19
    });

    testWidgets('Test 6: Miss does nothing - 3 misses -> no health changes for any player', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Record initial health for both
      final healthA = ProviderHelpers.getMonsterMashPlayerHealth(tester, playerA.id);
      final healthB = ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id);
      expect(healthA, 20);
      expect(healthB, 20);

      // Throw 3 misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify no health changes
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerA.id), 20);
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, playerB.id), 20);

      // Verify heal/damage = 0 for all darts
      final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
      final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      for (final heal in healAmounts) {
        expect(heal, 0);
      }
      for (final damage in damageAmounts) {
        expect(damage, 0);
      }
    });

    testWidgets('Test 7: Turn advancement - 3 darts then takeout - 3 darts -> shouldPromptTakeout=true, takeout finished -> advances to player 2', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Throw 3 darts
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);

      // Verify shouldPromptTakeout
      final provider = ProviderHelpers.getMonsterMashProvider(tester);
      expect(provider.shouldPromptTakeout, isTrue);

      // Click darts removed
      await clickDartsRemoved(tester);

      // Verify turn advanced to player 2
      final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(player2Id, isNot(equals(player1Id)));

      // Verify darts reset
      final dartsThrown = ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester);
      expect(dartsThrown, 0);
    });

    testWidgets('Test 8: Skip turn with darts thrown - Throw 1 dart, skip -> shouldPromptTakeout=true, after takeout advances to next player', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Throw 1 dart
      await throwMissViaMock(tester);
      expect(ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester), 1);

      // Hide dartboard emulator so skip button is not obscured
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      // Skip turn
      await UITestHelpers.clickSkipTurn(tester, config);

      // Verify shouldPromptTakeout
      final provider = ProviderHelpers.getMonsterMashProvider(tester);
      expect(provider.shouldPromptTakeout, isTrue);

      // Show dartboard emulator for DARTS REMOVED button
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      // Click darts removed
      await clickDartsRemoved(tester);

      // Verify advanced to next player
      final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(player2Id, isNot(equals(player1Id)));
    });

    testWidgets('Test 9: Skip turn without darts (auto-advance) - Skip immediately -> auto-advance to next player', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Hide dartboard emulator so skip button is not obscured
      await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
      await tester.pump();
      await tester.pump();

      // Skip turn without throwing darts
      await UITestHelpers.clickSkipTurn(tester, config);

      // Wait for auto-advance (500ms delay in game screen for 0-dart skip)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();

      // Verify advanced to next player
      final player2Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(player2Id, isNot(equals(player1Id)));
    });

    testWidgets('Test 10: Player elimination - health=10, attack opponent until health=0 -> isEliminated=true', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set low health for faster elimination
      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Attack opponent with triples: 3+3+3 = 9 damage
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Opponent has 1 HP, their turn now
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId), 1);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // First player's turn again - finish off with single
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Verify opponent is eliminated
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, opponentId), isTrue);
      expect(ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId), 0);
    });

    testWidgets('Test 11: Game won - last monster standing - Eliminate opponent -> hasWinner=true, results screen appears', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Winner', config);
      await UITestHelpers.addPlayer(tester, 'Loser', config);

      await UITestHelpers.startGame(tester, config);

      final winner = ProviderHelpers.findPlayerByName(tester, 'Winner')!;
      final loser = ProviderHelpers.findPlayerByName(tester, 'Loser')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == winner.id ? loser.id : winner.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Attack with triples: 3+3+3 = 9 damage
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await throwDartViaMock(tester, opponentTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Opponent has 1 HP, misses 3 darts
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Finish off
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Verify winner
      expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

      // Click darts removed and wait for results screen
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      // Verify results screen appears
      final playAgainButton = config.getPlayAgainButton();
      expect(playAgainButton, findsOneWidget);
    });

    testWidgets('Test 12: Eliminated player skipped in turn order - 3-player game, eliminate p2, verify turn alternates p1/p3 only', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final playerC = ProviderHelpers.findPlayerByName(tester, 'Player C')!;

      // Get current player (player 1) and find player B's target
      final player1Id = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

      // Player 1 attacks player B
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Player B (HP=1) - their turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player C - their turn, just miss
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 1 again - finish off Player B
      await throwDartViaMock(tester, playerBTarget, multiplier: 'single');
      // Player B eliminated but game continues (3-player game, 2 remaining)
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Now turn should skip Player B and go to Player C
      final afterEliminationPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      expect(afterEliminationPlayerId, isNot(equals(playerB.id)));
    });

    testWidgets('Test 13: Hit unassigned number - no effect - Throw at number not assigned to any player -> no heal, no damage', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      final targetA = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerA.id)!;
      final targetB = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

      // Find an unassigned number (not targetA or targetB)
      int unassignedNumber = 1;
      while (unassignedNumber == targetA || unassignedNumber == targetB) {
        unassignedNumber++;
      }

      // Throw at unassigned number
      await throwDartViaMock(tester, unassignedNumber, multiplier: 'single');

      // Verify no effect
      final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
      final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      final targetPlayerIds = ProviderHelpers.getMonsterMashDartThrowTargetPlayerId(tester, currentPlayerId);

      expect(healAmounts.last, 0);
      expect(damageAmounts.last, 0);
      expect(targetPlayerIds.last, isNull);
    });

    testWidgets('Test 14: Hit eliminated opponent number - no effect - Eliminate p2, throw at p2 target -> damageDealt=0', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 10);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      await UITestHelpers.startGame(tester, config);

      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final playerBTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, playerB.id)!;

      // Player 1 attacks Player B to reduce to 1 HP
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await throwDartViaMock(tester, playerBTarget, multiplier: 'triple');
      await clickDartsRemoved(tester);

      // Player B (1 HP) misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player C misses
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Player 1 finishes off Player B
      await throwDartViaMock(tester, playerBTarget, multiplier: 'single');
      expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, playerB.id), isTrue);

      // Now throw at Player B's (eliminated) target
      await throwDartViaMock(tester, playerBTarget, multiplier: 'single');

      // Verify no damage dealt
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final damageAmounts = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageAmounts.last, 0);
    });

    testWidgets('Test 15: Speed play - round counting and game end - Round limit=2, play through -> game ends automatically', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Set high health and speed play with 2 round limit
      await SettingsHelpers.setMonsterMashHealthMax(tester, 50);
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      // Verify round 1
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 1);

      // Play through round 1 (both players throw 3 darts each)
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Should be round 2 now
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 2);

      // Play through round 2
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Round 3
      expect(ProviderHelpers.getMonsterMashCurrentRound(tester), 3);

      // Play through round 3
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Game should end after round limit reached
      expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);
    });

    testWidgets('Test 16: Speed play - winner by health differential - Player 1 attacks, player 2 misses -> winner by health', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
      await SettingsHelpers.toggleMonsterMashSpeedPlay(tester);
      await SettingsHelpers.setMonsterMashRoundLimit(tester, 3);

      await UITestHelpers.addPlayer(tester, 'Attacker', config);
      await UITestHelpers.addPlayer(tester, 'Passive', config);

      await UITestHelpers.startGame(tester, config);

      final attacker = ProviderHelpers.findPlayerByName(tester, 'Attacker')!;
      final passive = ProviderHelpers.findPlayerByName(tester, 'Passive')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == attacker.id ? passive.id : attacker.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Play 3 rounds - player 1 attacks, player 2 misses
      for (int round = 0; round < 3; round++) {
        // Player 1: attack opponent
        await throwDartViaMock(tester, opponentTarget, multiplier: 'single');
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);

        // Player 2: miss everything
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await throwMissViaMock(tester);
        await clickDartsRemoved(tester);
      }

      // Game should be over
      expect(ProviderHelpers.monsterMashHasWinner(tester), isTrue);

      // Winner should be the player with higher health (the attacker)
      final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
      final winners = ProviderHelpers.getMonsterMashWinners(tester, selectedPlayers);
      expect(winners.length, 1);
      expect(winners.first.id, currentPlayerId); // The attacker who dealt damage
    });
  });

  group('Monster Mash - Buff Effect Tests', () {
    setUp(() async {
      await UITestHelpers.resetServerState();
    });

    testWidgets('Test 17: Buff - Blood Moon doubles attack damage - Set activeBuff = bloodMoon, throw single -> verify damage = 2', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Set Blood Moon buff programmatically
      await setActiveBuff(tester, BonusBuff.bloodMoon);

      // Verify UI shows buff indicator via keys
      expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
      expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
      expect(find.textContaining('2x'), findsWidgets);
      expect(find.textContaining('Double damage to any opponent!'), findsOneWidget);

      // Throw single at opponent
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Verify damage is doubled (1 * 2 = 2)
      final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageDealt.last, 2);

      // Throw double at opponent
      await throwDartViaMock(tester, opponentTarget, multiplier: 'double');

      // Verify damage is doubled (2 * 2 = 4)
      final damageDealt2 = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageDealt2.last, 4);

      // Verify total health decrease: 2 + 4 = 6
      final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(opponentHealth, 14); // 20 - 6 = 14
    });

    testWidgets('Test 18: Buff - Ancient Bandages boosts healing to +5 - Set activeBuff = ancientBandages, hit own target -> heal = 5', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Miss 3 darts, advance turn
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await clickDartsRemoved(tester);

      // Opponent attacks first player to reduce health
      final firstPlayerTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, currentPlayerId)!;
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'triple'); // -3
      await clickDartsRemoved(tester);

      // First player health = 11 (20 - 9)
      final healthBefore = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthBefore, 11);

      // Set Ancient Bandages buff
      await setActiveBuff(tester, BonusBuff.ancientBandages);

      // Verify UI shows buff indicator via keys
      expect(find.byKey(MonsterMashGameKeys.buffHealShield), findsOneWidget);
      expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
      expect(find.textContaining('Hit your target number for +5 HP!'), findsOneWidget);

      // Hit own target number (single) -> should heal +5
      await throwDartViaMock(tester, firstPlayerTarget, multiplier: 'single');

      // Verify heal amount = 5
      final healAmounts = ProviderHelpers.getMonsterMashDartThrowHealAmount(tester, currentPlayerId);
      expect(healAmounts.last, 5);

      // Verify health
      final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, currentPlayerId);
      expect(healthAfter, 16); // 11 + 5 = 16
    });

    testWidgets('Test 19: Buff - Shadow Walk blocks all damage - Set activeBuff = shadowWalk, attack opponent -> damage = 0', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 20);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;
      final opponentId = currentPlayerId == playerA.id ? playerB.id : playerA.id;
      final opponentTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, opponentId)!;

      // Set Shadow Walk buff
      await setActiveBuff(tester, BonusBuff.shadowWalk);

      // Verify UI shows buff indicator via keys
      expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
      expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
      expect(find.textContaining('You cannot attack opponents this turn!'), findsOneWidget);

      // Throw single at opponent
      await throwDartViaMock(tester, opponentTarget, multiplier: 'single');

      // Verify damage is 0
      final damageDealt = ProviderHelpers.getMonsterMashDartThrowDamageDealt(tester, currentPlayerId);
      expect(damageDealt.last, 0);

      // Verify opponent health unchanged
      final opponentHealth = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponentId);
      expect(opponentHealth, 20);
    });

    testWidgets('Test 20: Buff - Laboratory Spark bullseye zaps all opponents - Set activeBuff = laboratorySpark, throw bullseye -> all opponents lose 10 HP', (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.setMonsterMashHealthMax(tester, 30);
      await SettingsHelpers.toggleMonsterMashBonusBuffs(tester);

      await UITestHelpers.addPlayer(tester, 'Player A', config);
      await UITestHelpers.addPlayer(tester, 'Player B', config);
      await UITestHelpers.addPlayer(tester, 'Player C', config);

      await UITestHelpers.startGame(tester, config);

      final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A')!;
      final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B')!;
      final playerC = ProviderHelpers.findPlayerByName(tester, 'Player C')!;
      final currentPlayerId = ProviderHelpers.getMonsterMashCurrentPlayerId(tester)!;

      // Set Laboratory Spark buff
      await setActiveBuff(tester, BonusBuff.laboratorySpark);

      // Verify UI shows buff indicator via keys
      expect(find.byKey(MonsterMashGameKeys.buffDamageShield), findsOneWidget);
      expect(find.byKey(MonsterMashGameKeys.buffLabel), findsOneWidget);
      expect(find.textContaining('Hit the bullseye and ALL opponents lose 10 HP!'), findsOneWidget);

      // Record opponent health before
      final opponents = [playerA, playerB, playerC].where((p) => p.id != currentPlayerId).toList();
      final healthBefore = <String, int>{};
      for (final opponent in opponents) {
        healthBefore[opponent.id] = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponent.id);
        expect(healthBefore[opponent.id], 30);
      }

      // Throw bullseye
      await throwBullseyeViaMock(tester);

      // Verify ALL opponents lost 10 HP
      for (final opponent in opponents) {
        final healthAfter = ProviderHelpers.getMonsterMashPlayerHealth(tester, opponent.id);
        expect(healthAfter, 20, reason: 'Opponent ${opponent.name} should have lost 10 HP');
      }
    });
  });
}
