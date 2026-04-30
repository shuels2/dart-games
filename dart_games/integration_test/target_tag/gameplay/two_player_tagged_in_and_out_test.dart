import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Two Player Game with Tagged In and Tagged Out - Validates 2-player game initialization, neither player tagged in initially, target numbers displayed correctly, Player 1 reaches max shields and gets tagged in (single+double+triple), tagged in badge appears for Player 1, active panel switches to show opponent targets list, Player 1 remains tagged in after turn ends', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Verify game started
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Verify initial state - neither player tagged in =====
    expect(find.text('TAGGED IN'), findsNothing);
    expect(find.textContaining('Target number:'), findsWidgets);

    // ===== Step 2: Player 1 reaches max shields =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player1Target, multiplier: 'single');
    await throwDartViaMock(tester, player1Target, multiplier: 'double');
    await throwDartViaMock(tester, player1Target, multiplier: 'triple');

    // Wait for tagged-in state to update and active panel to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();

    // ===== Step 3: Verify Player 1 is now tagged in =====
    expect(find.text('TAGGED IN'), findsWidgets);
    expect(find.textContaining('Opponent targets:'), findsWidgets);
    await clickDartsRemoved(tester);

    // ===== Step 4: Verify Player 1 REMAINS tagged in on next turn =====
    // Note: Player 1's turn ended when they removed darts, now it's Player 2's turn
    // But Player 1 should still have TAGGED IN badge visible on their player tile
    expect(find.text('TAGGED IN'), findsWidgets);
  });
}
