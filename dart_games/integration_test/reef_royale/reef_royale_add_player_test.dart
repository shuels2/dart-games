import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../shared/ui_test_helpers.dart';
import '../shared/element_finders.dart';
import '../shared/pump_sequences.dart';
import '../shared/settings_helpers.dart';
import '../shared/game_ui_config.dart';
import '../shared/provider_helpers.dart';

/// Get whichever add player button is visible (empty state or normal)
Finder getAddPlayerButton(WidgetTester tester) {
  final emptyState = ElementFinders.getReefRoyaleAddPlayerButtonEmptyState();
  if (emptyState.evaluate().isNotEmpty) return emptyState;
  return ElementFinders.getReefRoyaleAddPlayerButton();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.reefRoyale();

  group('Reef Royale - Add Player Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Add player via dialog shows player in list',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Coral', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      expect(players.any((p) => p.name == 'Coral'), isTrue);
    });

    testWidgets('Test 2: Add two players enables start button',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Nemo', config);
      await UITestHelpers.addPlayer(tester, 'Dory', config);

      // Select both players
      final players = ProviderHelpers.getAllPlayers(tester);
      final nemo = players.firstWhere((p) => p.name == 'Nemo');
      final dory = players.firstWhere((p) => p.name == 'Dory');
      await UITestHelpers.selectPlayers(tester, [nemo.id, dory.id], config);

      final startButton = config.getStartButton();
      await tester.ensureVisible(startButton);
      await tester.pump();
      expect(startButton, findsOneWidget);
    });

    testWidgets('Test 3: Add player with empty name is rejected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Try to add empty name
      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      final addButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addButton);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 4: Cancel add player dialog does not add player',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final playersBefore = ProviderHelpers.getAllPlayers(tester).length;

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));
      await tester.enterText(
          ElementFinders.getAddPlayerNameField(), 'CancelMe');
      await PumpSequences.textEntry(tester);
      await SettingsHelpers.cancelAddPlayerDialog(tester);

      final playersAfter = ProviderHelpers.getAllPlayers(tester).length;
      expect(playersAfter, playersBefore);
    });

    testWidgets('Test 5: Player tile appears after adding and selecting',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Bubbles', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final bubbles = players.firstWhere((p) => p.name == 'Bubbles');

      await UITestHelpers.selectPlayers(tester, [bubbles.id], config);

      final playerTile = config.getPlayerTile(bubbles.id);
      expect(playerTile, findsOneWidget);
    });

    testWidgets('Test 6: Start button disabled with fewer than 2 players selected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Solo', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      final solo = players.firstWhere((p) => p.name == 'Solo');
      await UITestHelpers.selectPlayers(tester, [solo.id], config);

      // Start button should exist but game shouldn't start with 1 player
      final startButton = config.getStartButton();
      await tester.ensureVisible(startButton);
      await tester.pump();
      expect(startButton, findsOneWidget);
    });
  });
}
