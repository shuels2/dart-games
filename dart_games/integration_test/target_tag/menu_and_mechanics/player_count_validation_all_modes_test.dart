import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Test 2: Player Count Validation - All Modes - Validates solo mode starts with 2 players successfully, team mode enabled and starts with 3+ players, adding 15 total players with only first 10 auto-selected, attempting to manually select 11th player is rejected (max 10), play button remains enabled with exactly 10 selected, game starts successfully with 10 players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    // Add 2 players for solo mode
    await UITestHelpers.addPlayer(tester, 'Solo1', config);
    await UITestHelpers.addPlayer(tester, 'Solo2', config);
    expect(find.text('(2/10 selected)'), findsOneWidget);

    // Start game in solo mode
    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Return to menu
    final backFinder = find.byKey(TargetTagGameKeys.backButton);
    await tester.tap(backFinder);
    await PumpSequences.navigation(tester);

    // Handle Save Game Modal
    final dontSaveButton = find.byKey(SaveGameModalKeys.dontSaveButton);
    if (dontSaveButton.evaluate().isNotEmpty) {
      await tester.tap(dontSaveButton);
      await PumpSequences.dialogClose(tester);
    }

    // Handle Resume Game Modal
    final startNewButton = find.byKey(ResumeGameModalKeys.startNewGameButton);
    if (startNewButton.evaluate().isNotEmpty) {
      await tester.tap(startNewButton);
      await PumpSequences.dialogClose(tester);
    }

    // Enable team mode
    await SettingsHelpers.toggleTargetTagTeamMode(tester);

    // Add one more player (total 3 for team mode)
    await UITestHelpers.addPlayer(tester, 'Team1', config);
    expect(find.text('(3/10 selected)'), findsOneWidget);

    // Start game in team mode with 3 players
    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);

    // Return to menu again
    final backFinder2 = find.byKey(TargetTagGameKeys.backButton);
    await tester.tap(backFinder2);
    await PumpSequences.navigation(tester);

    // Handle Save Game Modal
    final dontSaveButton2 = find.byKey(SaveGameModalKeys.dontSaveButton);
    if (dontSaveButton2.evaluate().isNotEmpty) {
      await tester.tap(dontSaveButton2);
      await PumpSequences.dialogClose(tester);
    }

    // Handle Resume Game Modal
    final startNewButton2 = find.byKey(ResumeGameModalKeys.startNewGameButton);
    if (startNewButton2.evaluate().isNotEmpty) {
      await tester.tap(startNewButton2);
      await PumpSequences.dialogClose(tester);
    }

    // Add 12 more players (15 total, but max 10 can be selected)
    for (int i = 4; i <= 15; i++) {
      await UITestHelpers.addPlayer(tester, 'Player$i', config);
      await tester.pump();
    }

    // Wait for ListView to render all players
    await PumpSequences.asyncDataLoad(tester);

    // Verify only 10 players auto-selected
    expect(find.text('(10/10 selected)'), findsOneWidget);
    final selectedPlayers = ProviderHelpers.getSelectedPlayers(tester);
    expect(selectedPlayers.length, 10);

    // Try to manually select 11th player (should be rejected)
    final player11 = ProviderHelpers.findPlayerByName(tester, 'Player11');
    expect(player11, isNotNull);
    final player11Tile = config.getPlayerTile(player11!.id);

    await tester.ensureVisible(player11Tile);
    await tester.pump();
    await tester.tap(player11Tile);
    await PumpSequences.simpleUpdate(tester);

    // Verify still only 10 selected (11th was rejected)
    expect(find.text('(10/10 selected)'), findsOneWidget);
    final stillTenSelected = ProviderHelpers.getSelectedPlayers(tester);
    expect(stillTenSelected.length, 10);

    // Verify play button enabled with 10 players
    final startButton = config.getStartButton();
    expect(startButton, findsOneWidget);

    // Start game with 10 players
    await UITestHelpers.startGame(tester, config);
    expect(find.text('Target Tag Game On!'), findsOneWidget);
  });
}
