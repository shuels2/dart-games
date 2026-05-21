// Regression test for the "save-and-back auto-pops Resume modal" bug.
//
// Flow: enter Tiki Golf menu (no saves yet) -> start game -> throw a
// dart -> hit back -> Save Game modal appears -> tap Save -> game
// screen pops back to the menu.
//
// Correct behavior: the user lands on the Tiki Golf MENU with the
// Resume Game button now enabled (because a save exists), but the
// Resume Game MODAL must NOT auto-pop. The user just chose to save
// and exit; immediately surfacing the resume modal would interrupt
// that intent. Auto-popup is reserved for the INITIAL menu entry
// from the home screen — see resume_modal_shows_on_game_tap_test.
//
// Source rule: skills/game.build/SKILL.md AR-X (save-and-back resume
// modal suppression) — `_checkForSavedGames()` must only refresh the
// `_hasSavedGames` button state; `_showResumeModal` is set INLINE in
// initState, never inside `_checkForSavedGames()`.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'save-and-back returns to menu without auto-popping Resume modal',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await clickDartsRemoved(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    await UITestHelpers.tapSaveGameButton(tester);

    // Back on the menu — Start (TEE OFF!) button should be visible.
    expect(config.getStartButton(), findsOneWidget,
        reason: 'Should be back on the Tiki Golf menu after save');

    // The Resume Game MODAL must NOT auto-pop. This is the regression
    // guard: previously `_checkForSavedGames()` (called by the
    // Navigator.push.then callback after the game popped) would set
    // `_showResumeModal = true`, opening the modal on top of the
    // menu. The fix moves the auto-popup logic inline into initState
    // so it only runs on the initial entry, never on return.
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing,
        reason:
            'Resume Game modal must NOT auto-pop after save-and-back — '
            'auto-popup is initial-entry-only');
  });
}
