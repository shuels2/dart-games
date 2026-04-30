import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 2: Menu - Maximum Player Limit Enforcement
  // Features: 8-player maximum limit, player selection overflow handling
  // UI Elements: Player selection checkboxes, player list
  // Validates: Only 8 players can be selected, 9th+ players cannot be auto-selected
  testWidgets('Test 2: Max Player Enforcement (8 Players)', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    // Add 10 players
    for (int i = 1; i <= 10; i++) {
      await UITestHelpers.addPlayer(tester, 'Player $i', config);
    }

    // Verify all 10 players exist in list
    expect(getPlayerCount(tester), greaterThanOrEqualTo(10));

    // Only first 8 should be auto-selected
    expect(getSelectedPlayerCount(tester), 8);

    // 9th and 10th players should not be auto-selected
    // (Cannot manually select more than 8)

    // Start game with first 8 players selected
    final playButton = config.getStartButton();
    expect(playButton, findsOneWidget);

    await tester.ensureVisible(playButton);
    await tester.pump();
    await tester.tap(playButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Verify game starts
    expect(find.text('Carnival Derby Race'), findsOneWidget);
  });
}
