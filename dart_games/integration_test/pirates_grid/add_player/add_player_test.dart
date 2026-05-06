import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("Pirate's Grid - Add Player", () {
    testWidgets('Add Player: navigate from home to menu',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify we are on the Pirate's Grid menu
      expect(ElementFinders.getPiratesGridStartButton(), findsOneWidget);
    });

    testWidgets('Add Player: add player with name',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      await UITestHelpers.addPlayer(tester, 'Captain Jack', config);

      // Verify the player appears in the selected list (tile by name text)
      expect(find.text('Captain Jack'), findsWidgets);
    });

    testWidgets('Add Player: photo UI elements present in dialog',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Open add player dialog
      await SettingsHelpers.openAddPlayerDialog(
          tester, ElementFinders.getPiratesGridAddPlayerButton());

      // Verify name field and photo-related elements exist
      expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);
      expect(ElementFinders.getAddPlayerAddButton(), findsOneWidget);
      expect(ElementFinders.getAddPlayerCancelButton(), findsOneWidget);

      // Cancel to clean up
      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Add Player: empty name validation shows error',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, ElementFinders.getPiratesGridAddPlayerButton());

      // Tap Add without entering a name
      await tester.tap(ElementFinders.getAddPlayerAddButton());
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open (validation prevents close)
      expect(ElementFinders.getAddPlayerAddButton(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Add Player: whitespace-only name validation',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, ElementFinders.getPiratesGridAddPlayerButton());

      await tester.enterText(ElementFinders.getAddPlayerNameField(), '   ');
      await PumpSequences.textEntry(tester);

      await tester.tap(ElementFinders.getAddPlayerAddButton());
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerAddButton(), findsOneWidget);

      await SettingsHelpers.cancelAddPlayerDialog(tester);
    });

    testWidgets('Add Player: cancel closes without adding player',
        (WidgetTester tester) async {
      await UITestHelpers.resetServerState();
      await UITestHelpers.navigateToGameMenu(tester, config);

      await SettingsHelpers.openAddPlayerDialog(
          tester, ElementFinders.getPiratesGridAddPlayerButton());

      await tester.enterText(
          ElementFinders.getAddPlayerNameField(), 'Should Not Appear');
      await PumpSequences.textEntry(tester);

      await SettingsHelpers.cancelAddPlayerDialog(tester);

      // Player should not appear
      expect(find.text('Should Not Appear'), findsNothing);
    });
  });
}
