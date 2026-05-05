import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 22: Results - Results Screen Display & Content
  // Features: Results screen layout, winner announcement, action buttons
  // UI Elements: Winner title, avatar, score, standings table, Play Again/Change Settings/Home buttons
  // Validates: Results screen layout with winner announcement, action buttons (Play Again, Change Settings, Back to Menu), winner name displayed. Note: Does NOT validate confetti animation or victory music plays - only verifies visual elements present
  testWidgets('Test 22: Results Screen Content', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Winner', config);

    await setTargetScore(tester, 180);

    await startGame(tester);

    // Quick win
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple'); // 180

    expect(hasWinner(tester), true);

    await clickDartsRemoved(tester);

    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Verify results screen elements
    expect(find.text('Winner!'), findsOneWidget);
    expect(find.text('Winner'), findsWidgets);
    expect(find.text('Play Again'), findsOneWidget);
    expect(find.text('Change game players and settings'), findsOneWidget);
    expect(find.text('Select a different game'), findsOneWidget);
    expect(find.text('Final Standings'), findsOneWidget);
  });
}
