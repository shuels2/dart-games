import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: D1/D2/D3 Highlighting - Tagged In Mode Attack - Validates dart highlighting when player is tagged in and attacking opponents, D1 hits opponent target shows green border (successful attack), D2 misses all opponent targets shows pink border (failed attack), D3 hits different opponent target shows green border, dart indicators correctly show attack hit/miss status', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 3 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // ===== Step 1: Get tagged in first =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player1Target, multiplier: 'single');
    await throwDartViaMock(tester, player1Target, multiplier: 'double');
    await throwDartViaMock(tester, player1Target, multiplier: 'triple');

    // Wait for tagged-in state to update and active panel to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();

    // Verify tagged in
    expect(find.text('TAGGED IN'), findsWidgets);
    expect(find.textContaining('Opponent targets:'), findsWidgets);
    await clickDartsRemoved(tester);

    // ===== Step 2: Get opponent target numbers from provider =====
    // Player A is tagged in, so get Player B and Player C target numbers
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    final selectedPlayers = playerProvider.selectedPlayers;

    // Find Player B and C IDs
    final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
    final playerC = selectedPlayers.firstWhere((p) => p.name == 'Player C');

    final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);
    final playerCTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerC.id);

    expect(playerBTarget, isNotNull);
    expect(playerCTarget, isNotNull);

    // Player B gets 3 shields
    await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
    await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
    await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
    await clickDartsRemoved(tester);

    // Player C gets 3 shields
    await throwDartViaMock(tester, playerCTarget!, multiplier: 'single');
    await throwDartViaMock(tester, playerCTarget!, multiplier: 'single');
    await throwDartViaMock(tester, playerCTarget!, multiplier: 'single');
    await clickDartsRemoved(tester);

    // ===== Step 3: Player 1 attack opponent targets and verify highlighting =====
    // D1: Hit Player B's target (should be gold)
    await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFFD700);

    // D2: Miss all opponent targets (should be pink)
    // Throw a number that's neither Player B nor Player C target
    int missNumber = 1;
    while (missNumber == playerBTarget || missNumber == playerCTarget) {
      missNumber++;
    }
    await throwDartViaMock(tester, missNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFF007A);

    // D3: Hit Player C's target (should be gold)
    await throwDartViaMock(tester, playerCTarget!, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFFFFD700);
  });
}
