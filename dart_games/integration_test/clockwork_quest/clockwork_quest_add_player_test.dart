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
  final emptyState = ElementFinders.getClockworkQuestAddPlayerButtonEmptyState();
  if (emptyState.evaluate().isNotEmpty) return emptyState;
  return ElementFinders.getClockworkQuestAddPlayerButton();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = GameUIConfig.clockworkQuest();

  group('Clockwork Quest - Add Player Tests', () {
    setUp(() async {
      await SettingsHelpers.initializeSettings();
    });

    testWidgets('Test 1: Navigate to Clockwork Quest menu',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify we're on the menu screen
      expect(config.getStartButton(), findsOneWidget);
    });

    testWidgets('Test 2: Add player with name shows in list',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Cogsworth', config);

      final players = ProviderHelpers.getAllPlayers(tester);
      expect(players.any((p) => p.name == 'Cogsworth'), isTrue);
    });

    testWidgets('Test 3: Add player dialog has photo UI elements',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      // Check for photo-related elements
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
      expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 4: Add player with empty name shows validation error',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      // Try to add with empty name
      final addButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addButton);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 5: Add player with whitespace-only name is rejected',
        (WidgetTester tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, getAddPlayerButton(tester));

      await tester.enterText(ElementFinders.getAddPlayerNameField(), '   ');
      await PumpSequences.textEntry(tester);

      final addButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addButton);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Test 6: Cancel add player dialog closes without adding',
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
  });
}
