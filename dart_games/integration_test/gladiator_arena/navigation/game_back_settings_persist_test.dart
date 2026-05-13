import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/settings_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Navigation: game back button returns to menu and settings persist',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Change 2 non-default settings
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 350);
    await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);

    // Add 2 players and start game
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Verify game screen
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    // Throw a dart so the SaveGameModal will actually appear on back-button
    // tap. The screen's back-button handler gates the modal on
    // `hasDartsThrown` (see commit 5458414 — "Save modal gated on
    // hasDartsThrown — back button pops directly when no darts have been
    // thrown"). Without this throw, the back button would skip the modal
    // entirely and just call Navigator.pop().
    await DartThrowHelpers.throwDartViaMock(tester, 5);

    // Tap back button (triggers SaveGameModal). The default pump sequence
    // is `simpleUpdate` (2 immediate pumps) which doesn't always let the
    // modal animation finish before the next interaction — `dialogOpen`
    // gives the 500 ms animation window the AlertDialog needs.
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.dialogOpen(tester);
    UITestHelpers.verifySaveGameModal();

    // Don't save — tap Don't Save
    await UITestHelpers.tapDontSaveButton(tester);

    // Should be back on menu
    expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget);

    // Verify target score setting persisted
    final slider =
        tester.widget<Slider>(ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(slider.value.toInt(), 350,
        reason: 'Target score should persist at 350 after returning to menu');
  });
}
