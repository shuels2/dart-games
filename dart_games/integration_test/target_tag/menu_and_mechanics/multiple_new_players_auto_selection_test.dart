import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 1: Multiple New Players Auto-Selection - Validates adding Player 1 auto-selects them, player count shows (1/10 selected), adding Player 2 auto-selects them, player count shows (2/10 selected), both players remain selected and visible in player list',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    print('=== DEBUG TEST 1 START ===');
    print('About to navigate to game menu...');

    // Navigate to Target Tag menu
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Verify initial state: no players selected
    expect(find.text('(0/10 selected)'), findsOneWidget);

    // Add Player 1
    await UITestHelpers.addPlayer(tester, 'Player 1', config);
    await PumpSequences.asyncDataLoad(tester); // Wait for ListView to render

    // Verify Player 1 auto-selected
    expect(find.text('(1/10 selected)'), findsOneWidget);
    final player1 = ProviderHelpers.findPlayerByName(tester, 'Player 1');
    expect(player1, isNotNull);
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 1);
    expect(selectedPlayers.any((p) => p.id == player1!.id), isTrue);

    // Add Player 2
    await UITestHelpers.addPlayer(tester, 'Player 2', config);
    await PumpSequences.asyncDataLoad(tester); // Wait for ListView to render

    // Verify Player 2 auto-selected
    expect(find.text('(2/10 selected)'), findsOneWidget);
    final player2 = ProviderHelpers.findPlayerByName(tester, 'Player 2');
    expect(player2, isNotNull);
    final selectedAfterAdd2 = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedAfterAdd2.length, 2);
    expect(selectedAfterAdd2.any((p) => p.id == player1!.id), isTrue);
    expect(selectedAfterAdd2.any((p) => p.id == player2!.id), isTrue);

    // Verify both players visible in list
    final player1Tile = config.getPlayerTile(player1!.id);
    final player2Tile = config.getPlayerTile(player2!.id);

    await tester.ensureVisible(player1Tile);
    await tester.pump();
    expect(player1Tile, findsOneWidget);
    await tester.ensureVisible(player2Tile);
    await tester.pump();
    expect(player2Tile, findsOneWidget);
  });
}
