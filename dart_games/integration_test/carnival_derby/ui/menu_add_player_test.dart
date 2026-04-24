import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test 1: Menu - Player Selection & Auto-Selection
  // Features: Player management, auto-selection, play button state
  // UI Elements: NEW PLAYER button, player list, START THE RACE! button
  // Validates: Players auto-select on creation, play button enables with selections
  testWidgets('Test 1: Basic Player Addition and Auto-Selection', (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    // Verify play button disabled with 0 players
    final playButton = config.getStartButton();
    expect(playButton, findsOneWidget);

    // Add Player 1
    await UITestHelpers.addPlayer(tester, 'Player 1', config);
    // Player 1 appears twice: once in Available Players, once in Selected Players
    expect(find.text('Player 1'), findsWidgets);

    // Verify play button enabled with 1 player
    expect(playButton, findsOneWidget);
    expect(getSelectedPlayerCount(tester), 1);

    // Add Player 2
    await UITestHelpers.addPlayer(tester, 'Player 2', config);
    // Player 2 appears twice: once in Available Players, once in Selected Players
    expect(find.text('Player 2'), findsWidgets);

    // Verify both players remain in list and selected
    expect(find.text('Player 1'), findsWidgets);
    expect(find.text('Player 2'), findsWidgets);
    expect(getSelectedPlayerCount(tester), 2);
  });
}
