import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Eliminated Player Visual State - Validates Player 1 hits triple to get tagged in instantly, Player 1 hits Player 2 target once to eliminate (hit at 0 shields), Player 2 tile shows TAGGED OUT badge when eliminated, eliminated player tile has greyed out appearance (reduced opacity or desaturated colors), eliminated player no longer shows current player border (skipped in turn rotation), eliminated player remains visible in UI but clearly marked as out of game', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3 for faster testing
    await setShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Eliminated 1', config);
    await UITestHelpers.addPlayer(tester, 'Eliminated 2', config);
    await UITestHelpers.addPlayer(tester, 'Eliminated 3', config);


    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Get target numbers for both players =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    // Skip to Player 2's turn to get their target
    await skipTurn(tester);
    final player2Target = getCurrentPlayerTargetNumber(tester);

    // Skip to Player 3's turn
    await skipTurn(tester);

    // Skip back to Player 1's turn
    await skipTurn(tester);

    // ===== Step 2: Player 1 eliminates Player 2 in ONE turn =====
    // D1: Hit triple of own target (tagged in instantly)
    await throwDartViaMock(tester, player1Target, multiplier: 'triple'); // 3 shields = TAGGED IN!
    await PumpSequences.simpleUpdate(tester);

    // D2: Hit opponent's target (eliminate immediately - same turn!)
    await throwDartViaMock(tester, player2Target); // Hit at 0 shields = ELIMINATED
    await PumpSequences.simpleUpdate(tester);

    // D3: Fill turn with miss
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);

    await clickDartsRemoved(tester); // Moves to player 3

    // ===== Step 4: Verify Player 2 ELIMINATED =====

    // TAGGED OUT badge
    verifyTaggedOutBadge(tester, 'Eliminated 2', shouldExist: true);

    // Opacity 0.4
    verifyPlayerTileOpacity(tester, 'Eliminated 2', opacityEliminated);

    // No green glow
    verifyPlayerTileGlow(tester, 'Eliminated 2', colorGreenGlow, shouldExist: false);

    // ===== Step 5: Verify Player 2 no longer gets current player border =====
    // Skip turn should cycle back to Player 1 from Player 3
    await skipTurn(tester);

    // Player 1 should be current (pink border)
    verifyPlayerTileBorderColor(tester, 'Eliminated 1', colorPinkBorder, borderWidthCurrent, shouldExist: true);

    // Player 2 should NOT be current (no pink border)
    verifyPlayerTileBorderColor(tester, 'Eliminated 2', colorPinkBorder, borderWidthCurrent, shouldExist: false);

    // ===== Step 6: Verify Player 2 remains visible (not hidden) =====
    expect(find.text('Eliminated 2'), findsOneWidget);
  });
}
