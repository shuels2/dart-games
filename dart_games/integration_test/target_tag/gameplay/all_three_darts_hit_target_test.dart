import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Dart Highlighting - All Three Darts Hit Target - Validates all three dart indicators show green borders when all darts hit the target number, D1/D2/D3 all display 0xFF00FFA3 green border color, visual feedback correctly indicates successful shield building', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Get current player's target number
    final targetNumber = getCurrentPlayerTargetNumber(tester);

    // Throw all three darts hitting the target
    await throwDartViaMock(tester, targetNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFF00FFA3);

    await throwDartViaMock(tester, targetNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFF00FFA3);

    await throwDartViaMock(tester, targetNumber, multiplier: 'single');
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFF00FFA3);

    // All three should be green
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD1Indicator, 0xFF00FFA3);
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD2Indicator, 0xFF00FFA3);
    verifyDartIndicatorColor(tester, TargetTagGameKeys.activePlayerD3Indicator, 0xFF00FFA3);
  });
}
