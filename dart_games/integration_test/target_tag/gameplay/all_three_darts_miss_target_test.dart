import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Dart Highlighting - All Three Darts Miss Target - Validates all three dart indicators show pink borders when all darts miss the target number, D1/D2/D3 all display 0xFFFF007A pink border color, visual feedback correctly indicates failed shield building attempts', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Get current player's target number
    final targetNumber = getCurrentPlayerTargetNumber(tester);

    // Throw all three darts missing the target
    final missNumber = targetNumber == 20 ? 19 : 20;

    await throwDartViaMock(tester, missNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFF007A);

    await throwDartViaMock(tester, missNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFF007A);

    await throwDartViaMock(tester, missNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFFFF007A);

    // All three should be pink
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFFFF007A);
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFFFF007A);
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFFFF007A);
  });
}
