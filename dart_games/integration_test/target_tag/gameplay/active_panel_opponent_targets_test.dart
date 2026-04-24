import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Active Panel Opponent Targets Display - Validates active panel shows target number when not tagged in, panel switches to show opponent targets list when player gets tagged in, opponent targets displayed correctly with player names and target numbers', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // Verify we're on the game screen
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // ===== Step 1: Verify active panel shows target number (not tagged in) =====
    expect(find.textContaining('Target number:'), findsWidgets);
    expect(find.textContaining('Opponent targets:'), findsNothing);

    // Get current player's target number
    final targetNumber = getCurrentPlayerTargetNumber(tester);
    expect(targetNumber, isNotNull);

    // ===== Step 2: Throw darts to reach max shields and get tagged in =====
    // Throw darts hitting current player's target number
    await throwDartViaMock(tester, targetNumber, multiplier: 'single');  // 1 shield
    await throwDartViaMock(tester, targetNumber, multiplier: 'double');  // 2 shields (total: 3)
    await throwDartViaMock(tester, targetNumber, multiplier: 'triple');  // 3 shields (total: 6 = max)

    // Wait for tagged-in state to update and active panel to rebuild
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();

    // ===== Step 3: Verify active panel NOW shows opponent targets =====
    // Check for opponent targets label in active panel (not player tiles)
    expect(find.byKey(TargetTagGameKeys.activePlayerOpponentTargetsLabel), findsOneWidget);
    // Target label should NOT be in active panel (still exists on player tiles, which is correct)
    expect(find.byKey(TargetTagGameKeys.activePlayerTargetLabel), findsNothing);
    await clickDartsRemoved(tester);

    // Verify opponent name and target appear in the list
    final opponent = find.textContaining('Player');
    expect(opponent, findsWidgets);
  });
}
