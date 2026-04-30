import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: D1/D2/D3 Highlighting - Solo Mode Not Tagged In - Validates dart highlighting colors when player is not tagged in, D1 hits own target shows green border (0xFF00FFA3), D2 misses own target shows pink border (0xFFFF007A), D3 hits own target with double multiplier shows green border, all three dart indicators display correct border colors based on hit/miss', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Get current player's target number
    final targetNumber = getCurrentPlayerTargetNumber(tester);

    // ===== Test D1: Hit own target (should be green) =====
    await throwDartViaMock(tester, targetNumber, multiplier: 'single');

    // Verify D1 has green border (0xFF00FFA3)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFF00FFA3);

    // ===== Test D2: Miss own target (should be pink) =====
    // Throw a different number (not the target)
    final missNumber = targetNumber == 20 ? 19 : 20;
    await throwDartViaMock(tester, missNumber, multiplier: 'single');

    // Verify D2 has pink border (0xFFFF007A)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFF007A);

    // ===== Test D3: Hit own target with double (should be green) =====
    await throwDartViaMock(tester, targetNumber, multiplier: 'double');

    // Verify D3 has green border (0xFF00FFA3)
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFF00FFA3);
  });
}
