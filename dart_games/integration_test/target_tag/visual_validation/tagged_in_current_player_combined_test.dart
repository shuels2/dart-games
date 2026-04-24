import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Tagged In + Current Player - Combined Visual - Validates Player 1 gets tagged in on first turn, turn advances to Player 2 (Player 2 becomes current), Player 1 now non-current but tagged in shows green pulsing border only, turn cycles back to Player 1 who is still tagged in, Player 1 tile shows pink border (current) with green glow (tagged in) combined effect, visual hierarchy correctly prioritizes both states when player is both current AND tagged in', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Set shield max to 3 for faster testing
    await setShieldMax(tester, 3);

    await UITestHelpers.addPlayer(tester, 'Combined 1', config);
    await UITestHelpers.addPlayer(tester, 'Combined 2', config);

    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Player 1 reaches tagged in =====
    final targetNumber = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, targetNumber); // Shield 1
    await throwDartViaMock(tester, targetNumber); // Shield 2
    await throwDartViaMock(tester, targetNumber); // Shield 3 - TAGGED IN!

    await PumpSequences.simpleUpdate(tester);

    // ===== Step 2: Verify current + tagged in (pink border + green glow + badge) =====
    verifyTaggedInBadge(tester, 'Combined 1', shouldExist: true);
    verifyPlayerTileBorderColor(tester, 'Combined 1', colorPinkBorder, borderWidthCurrent, shouldExist: true);
    verifyPlayerTileGlow(tester, 'Combined 1', colorGreenGlow, shouldExist: true);

    // ===== Step 3: Advance to Player 2 =====
    await clickDartsRemoved(tester);
    await skipTurn(tester);

    // ===== Step 4: Verify Player 1 non-current but tagged in (green glow + badge, NO pink) =====
    verifyTaggedInBadge(tester, 'Combined 1', shouldExist: true);
    verifyPlayerTileBorderColor(tester, 'Combined 1', colorPinkBorder, borderWidthCurrent, shouldExist: false);
    verifyPlayerTileGlow(tester, 'Combined 1', colorGreenGlow, shouldExist: true);

    // Verify Player 2 is now current (pink border)
    verifyPlayerTileBorderColor(tester, 'Combined 2', colorPinkBorder, borderWidthCurrent, shouldExist: true);

    // ===== Step 5: Cycle back to Player 1 (skip Player 2's turn) =====
    await skipTurn(tester);

    // ===== Step 6: Verify Player 1 current + tagged in again (pink + glow + badge) =====
    verifyTaggedInBadge(tester, 'Combined 1', shouldExist: true);
    verifyPlayerTileBorderColor(tester, 'Combined 1', colorPinkBorder, borderWidthCurrent, shouldExist: true);
    verifyPlayerTileGlow(tester, 'Combined 1', colorGreenGlow, shouldExist: true);

    // ===== Step 7: Verify glow animation cycles (wait and check again) =====
    await PumpSequences.fullRebuild(tester);
    verifyPlayerTileGlow(tester, 'Combined 1', colorGreenGlow, shouldExist: true);
  });
}
