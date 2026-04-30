import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 12: Complete Solo Mode Game to Victory - Validates complete game flow from start to victory screen, 2-player solo mode game starts correctly, Player 1 builds shields to max and gets tagged in, Player 2 builds partial shields, Player 1 attacks Player 2 target repeatedly until elimination, victory screen appears after opponent elimination, winner displayed correctly on victory screen', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    // Start game
    await UITestHelpers.startGame(tester, config);

    // ===== Step 1: Player 1 gets tagged in =====
    final player1Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player1Target, multiplier: 'single');
    await throwDartViaMock(tester, player1Target, multiplier: 'double');
    await throwDartViaMock(tester, player1Target, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // ===== Step 2: Player 2 builds partial shields =====
    final player2Target = getCurrentPlayerTargetNumber(tester);

    await throwDartViaMock(tester, player2Target, multiplier: 'single');
    await throwDartViaMock(tester, player2Target, multiplier: 'single');
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // ===== Step 3: Player 1 attacks Player 2 until elimination =====
    // Get Player B data
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    final selectedPlayers = playerProvider.selectedPlayers;
    final playerB = selectedPlayers.firstWhere((p) => p.name == 'Player B');
    final playerBTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, playerB.id);

    // Attack Player B repeatedly (max shields is 6, Player B has 3)
    // Need to remove 3 shields
    for (int i = 0; i < 3; i++) {
      await throwDartViaMock(tester, playerBTarget!, multiplier: 'single');
    }
    await clickDartsRemoved(tester);


    // ===== Step 4: Verify victory screen appears =====
    // Wait for game ending logic, stats updates, and navigation to results screen
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Wait for navigation to results screen
    await tester.pump(); // Build results screen
    await tester.pump(); // Layout results screen
    await tester.pump(); // Paint results screen

    // Check if we're on results screen
    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget);

    // Verify winner is displayed
    expect(find.textContaining('Player A'), findsWidgets);
  });
}
