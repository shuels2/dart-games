import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 5: Game - Single Player Quick Win (Normal Mode)
  // Features: Normal mode (no Perfect Finish), instant win by exceeding target
  // UI Elements: Score display, dart display, race track, results screen
  // Validates: Game starts, T20x3=180 wins with target 60, results screen appears
  testWidgets('Test 5: Single Player Quick Win (Normal Mode)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Alice', config);

    // Set target to 60
    await setTargetScore(tester, 60);
    expect(find.textContaining('Target score: 60'), findsOneWidget);

    await startGame(tester);

    // Verify game settings displayed on game screen
    verifyGameSettings(tester, 60, false); // target=60, Perfect Finish OFF

    // Turn 1: T20 = 60 (instant win on first dart)
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 60
    expect(getCurrentPlayerScore(tester), 60);
    verifyCurrentPlayerScoreDisplay(tester, 60, 60); // Current player section
    verifyRaceTrackScore(tester, 60, 60); // Race track lane

    // Verify game has winner immediately after winning dart
    expect(hasWinner(tester), true);

    // Click DARTS REMOVED to advance to results
    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Verify results screen appears
    expect(find.text('Winner!'), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
  });
}
