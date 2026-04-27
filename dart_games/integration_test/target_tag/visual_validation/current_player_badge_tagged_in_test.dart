import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Current Player Shows Badge When Tagged In - Validates current player is Player 1 with pink border, Player 1 builds shields to max and gets tagged in while still current player, Player 1 tile shows TAGGED IN badge appears immediately, current player pink border remains while also showing tagged in badge, visual state correctly combines current player and tagged in indicators simultaneously', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3 for faster testing
    await setShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Badge 1', config);
    await UITestHelpers.addPlayer(tester, 'Badge 2', config);

    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Verify current player has PINK border, NO badge =====
    verifyPlayerTileBorderColor(tester, 'Badge 1', colorPinkBorder, borderWidthCurrent, shouldExist: true);
    verifyTaggedInBadge(tester, 'Badge 1', shouldExist: false);

    // ===== Step 2: Reach max shields (default is 3) =====
    final targetNumber = getCurrentPlayerTargetNumber(tester);

    // Throw 3 darts hitting own target
    await throwDartViaMock(tester, targetNumber); // Shield 1
    await throwDartViaMock(tester, targetNumber); // Shield 2
    await throwDartViaMock(tester, targetNumber); // Shield 3 - TAGGED IN!

    await PumpSequences.simpleUpdate(tester);

    // ===== Step 3: Verify TAGGED IN badge appears =====
    verifyTaggedInBadge(tester, 'Badge 1', shouldExist: true);

    // ===== Step 4: Verify PINK border STILL present (current player) =====
    verifyPlayerTileBorderColor(tester, 'Badge 1', colorPinkBorder, borderWidthCurrent, shouldExist: true);

    // ===== Step 5: Verify GREEN glow behind pink border =====
    verifyPlayerTileGlow(tester, 'Badge 1', colorGreenGlow, shouldExist: true);

    // ===== Step 6: Advance turn (removes pink border, keeps badge + glow) =====
    await clickDartsRemoved(tester);
    await skipTurn(tester);
    await PumpSequences.fullRebuild(tester);

    // ===== Step 7: Verify badge persists, pink border gone, green glow persists =====
    verifyTaggedInBadge(tester, 'Badge 1', shouldExist: true);
    verifyPlayerTileBorderColor(tester, 'Badge 1', colorPinkBorder, borderWidthCurrent, shouldExist: false);
    verifyPlayerTileGlow(tester, 'Badge 1', colorGreenGlow, shouldExist: true);
  });
}
