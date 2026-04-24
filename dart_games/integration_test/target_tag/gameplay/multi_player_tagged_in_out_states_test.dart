import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 3: Multi-Player Game with Tagged In/Out States - Validates 3-player game initialization with all players not tagged in initially, first player gets tagged in by reaching max shields (single+double+triple), tagged in badge appears correctly, second player builds partial shields without getting tagged in, turn progression and state transitions work correctly', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 3 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.addPlayer(tester, 'Player C', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Verify all players start NOT tagged in =====
    expect(find.text('TAGGED IN'), findsNothing);
    expect(find.textContaining('Target number:'), findsWidgets);
    expect(find.textContaining('Opponent targets:'), findsNothing);

    // ===== Step 2: Player 1 reaches max shields and gets tagged in =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player1Target, multiplier: 'single');
    await throwDartViaMock(tester, player1Target, multiplier: 'double');
    await throwDartViaMock(tester, player1Target, multiplier: 'triple');

    // Wait for tagged-in state to update and active panel to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();

    // ===== Step 3: Verify tagged in badge appears =====
    expect(find.text('TAGGED IN'), findsWidgets);
    expect(find.textContaining('Opponent targets:'), findsWidgets);
    await clickDartsRemoved(tester);

    // ===== Step 4: Player 2 builds partial shields (does NOT get tagged in) =====
    final player2Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player2Target, multiplier: 'single');
    await throwDartViaMock(tester, player2Target, multiplier: 'double');
    await clickDartsRemoved(tester);

    // Player 2 now has 3 shields (not max), so should NOT be tagged in
    // Verify they still see target number, not opponent targets
    expect(find.textContaining('Target number:'), findsWidgets);
  });
}
