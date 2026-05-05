import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 1: Navigation and initial player setup - Navigate from home card to Monster Mash menu, add 2 players via empty-state then normal button', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // Navigate to Monster Mash menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify we are on the Monster Mash menu screen
    expect(find.textContaining('Monster Mash'), findsWidgets);

    // Extra pump to ensure player provider finishes loading
    // (menu body shows loading spinner until players are loaded)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump();

    // Add first player using empty state button
    await UITestHelpers.addPlayer(tester, 'Monster Alpha', config);

    // Verify first player was added
    expect(find.text('Monster Alpha'), findsWidgets);

    // Add second player using normal state button
    await UITestHelpers.addPlayer(tester, 'Monster Beta', config);

    // Verify second player was added
    expect(find.text('Monster Beta'), findsWidgets);

    // Verify both players are in the player provider
    final allPlayers = ProviderHelpers.getAllPlayers(tester);
    final alphaPlayer = ProviderHelpers.findPlayerByName(tester, 'Monster Alpha');
    final betaPlayer = ProviderHelpers.findPlayerByName(tester, 'Monster Beta');
    expect(alphaPlayer, isNotNull);
    expect(betaPlayer, isNotNull);
  });
}
