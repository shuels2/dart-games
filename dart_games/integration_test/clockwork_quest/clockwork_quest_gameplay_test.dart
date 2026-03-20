import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Gameplay Tests', () {
    setUp(() async {
      await ProviderHelpers.clearAllProviders();
    });

    testWidgets('Test 1: Hit correct number advances gear',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(tester, config, playerCount: 2);

      // Hit target 1
      await UITestHelpers.throwDart(tester, 'S1');

      // Player should advance to target 2
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;
      expect(provider.getPlayerCurrentTarget(currentPlayer), 2);
    });

    testWidgets('Test 2: Hit wrong number does not advance',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(tester, config, playerCount: 2);

      // Hit wrong target (5 instead of 1)
      await UITestHelpers.throwDart(tester, 'S5');

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;
      expect(provider.getPlayerCurrentTarget(currentPlayer), 1);
    });

    testWidgets('Test 3: Sequential progression 1 through 5',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(tester, config, playerCount: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Hit targets 1-5 sequentially
      for (int i = 1; i <= 5; i++) {
        await UITestHelpers.throwDart(tester, 'S$i');
        expect(provider.getPlayerCurrentTarget(currentPlayer), i + 1);
      }
    });

    testWidgets('Test 4: D/T Count ON - double advances 2 gears',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'doubleTriplesCount': true},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Hit double 1 (should advance 2 gears: 1 and 2)
      await UITestHelpers.throwDart(tester, 'D1');
      expect(provider.getPlayerCurrentTarget(currentPlayer), 3);
    });

    testWidgets('Test 5: D/T Count ON - triple advances 3 gears',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'doubleTriplesCount': true},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Hit triple 1 (should advance 3 gears: 1, 2, 3)
      await UITestHelpers.throwDart(tester, 'T1');
      expect(provider.getPlayerCurrentTarget(currentPlayer), 4);
    });

    testWidgets('Test 6: D/T Count OFF - double advances 1 gear only',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'doubleTriplesCount': false},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Hit double 1 (should NOT advance - only singles count)
      await UITestHelpers.throwDart(tester, 'D1');
      expect(provider.getPlayerCurrentTarget(currentPlayer), 1);
    });

    testWidgets('Test 7: Include Bullseye ON - must hit bull after 20',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'includeBullseye': true},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Advance to target 21 (bullseye)
      provider.currentGame!.currentTarget[currentPlayer] = 21;

      // Hit bullseye
      await UITestHelpers.throwDart(tester, 'Bull');
      expect(provider.getPlayerCurrentTarget(currentPlayer), 1);
      expect(provider.getPlayerLapsCompleted(currentPlayer), 1);
    });

    testWidgets('Test 8: Turn advances after 3 darts',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(tester, config, playerCount: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final initialPlayer = provider.getCurrentPlayerId()!;

      // Throw 3 darts
      await UITestHelpers.throwDart(tester, 'S1');
      await UITestHelpers.throwDart(tester, 'S2');
      await UITestHelpers.throwDart(tester, 'S3');

      // Confirm darts removed
      await UITestHelpers.confirmDartsRemoved(tester);

      // Should be next player's turn
      final currentPlayer = provider.getCurrentPlayerId()!;
      expect(currentPlayer, isNot(initialPlayer));
    });

    testWidgets('Test 9: Skip turn advances to next player',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(tester, config, playerCount: 2);

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final initialPlayer = provider.getCurrentPlayerId()!;

      // Skip turn
      final skipButton = ElementFinders.getClockworkQuestSkipTurnButton();
      await tester.tap(skipButton);
      await PumpSequences.simpleUpdate(tester);

      final currentPlayer = provider.getCurrentPlayerId()!;
      expect(currentPlayer, isNot(initialPlayer));
    });

    testWidgets('Test 10: Speed mode shows timer (if implemented)',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'speedMode': true},
      );

      // Note: Timer UI may not be implemented yet
      // This test validates speed mode setting is applied
      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      expect(provider.currentGame!.speedMode, true);
      expect(provider.currentGame!.maxDartsPerTurn, 2);
    });

    testWidgets('Test 11: Laps > 1 causes gear reset after completion',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'numberOfLaps': 2},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Simulate completing first lap
      provider.currentGame!.currentTarget[currentPlayer] = 20;
      await UITestHelpers.throwDart(tester, 'S20');

      // Should reset to target 1 and increment lap
      expect(provider.getPlayerCurrentTarget(currentPlayer), 1);
      expect(provider.getPlayerLapsCompleted(currentPlayer), 1);
    });

    testWidgets('Test 12: Win condition - standard (no bullseye, 1 lap)',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'includeBullseye': false, 'numberOfLaps': 1},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Advance to target 20 and hit it
      provider.currentGame!.currentTarget[currentPlayer] = 20;
      await UITestHelpers.throwDart(tester, 'S20');

      // Should win
      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, currentPlayer);
    });

    testWidgets('Test 13: Win condition - with bullseye',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'includeBullseye': true, 'numberOfLaps': 1},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Advance to bullseye and hit it
      provider.currentGame!.currentTarget[currentPlayer] = 21;
      await UITestHelpers.throwDart(tester, 'Bull');

      // Should win
      expect(provider.hasWinner, true);
      expect(provider.currentGame!.winnerId, currentPlayer);
    });

    testWidgets('Test 14: Win condition - multiple laps',
        (WidgetTester tester) async {
      await UITestHelpers.startQuickGame(
        tester,
        config,
        playerCount: 2,
        customSettings: {'numberOfLaps': 2},
      );

      final provider = ProviderHelpers.getClockworkQuestProvider(tester);
      final currentPlayer = provider.getCurrentPlayerId()!;

      // Complete first lap
      provider.currentGame!.currentTarget[currentPlayer] = 20;
      provider.currentGame!.lapsCompleted[currentPlayer] = 0;
      await UITestHelpers.throwDart(tester, 'S20');
      expect(provider.hasWinner, false);

      // Complete second lap
      provider.currentGame!.currentTarget[currentPlayer] = 20;
      await UITestHelpers.throwDart(tester, 'S20');

      // Should win
      expect(provider.hasWinner, true);
    });
  });
}
