// integration_test/shared/save_resume_suite.dart
//
// Shared, parameterized bodies for the save/resume scenarios every game
// implements (WS05 §5.3 item 3). Companion to shared/navigation_suite.dart
// and shared/pause_modal_suite.dart.
//
// ─── FILE LAYOUT IS DELIBERATELY UNCHANGED ─────────────────────────────────
// Still ONE `testWidgets` per file, still one file per scenario per game.
// Merging tests into a single `flutter drive` boot (§5.3 item 2) was tried
// before this plan and reverted: tests sharing one app boot dirtied the
// database and app state and failed frequently. One boot per test IS the
// isolation mechanism.
//
// ─── WHY THIS CATEGORY STILL HAD DUPLICATION ───────────────────────────────
// save_resume was already half-templated — SaveResumeHelpers and
// GameSaveConfig exist and the bodies are short. What remained duplicated ten
// times was the CHOREOGRAPHY: navigate → throw → back → save → home → tap card
// → select tile → resume, plus the IconButton-drilling that every
// resume-button test repeats (find the keyed wrapper, descend to the
// IconButton, read onPressed/tooltip/color).
//
// The scenario names also drifted, which is why the runners are named for
// what they assert rather than for any one game's filename. The same scenario
// appears as e.g. `resume_game_loads_screen_test.dart` in seven games and
// `resume_modal_loads_game_test.dart` in three.
//
// ─── THIS FILE MUST EXIST IN BOTH SHARED TREES ─────────────────────────────
// A copy lives at test/shared/save_resume_suite.dart and the two must stay
// byte-identical (CLAUDE.md's shared-helper rule; test/meta/ enforces it).
//
// `flutter drive`'s web compile resolves a UI test's `../../shared/x.dart`
// against test/shared/, NOT integration_test/shared/. A helper present only in
// the integration_test copy fails at compile time with
//     Error when reading 'org-dartlang-app:/shared/<file>.dart': File not found
// while `flutter analyze` and `flutter build web` both resolve it happily.
//
// ─── SCENARIO INVENTORY (the coverage contract) ────────────────────────────
//   SAVE MODAL (4)
//     1 runSaveModalBack0DartsTest      untouched board backs out silently
//     2 runSaveModalBackAfterDartsTest  a thrown dart makes back prompt
//     3 runSaveModalSaveButtonTest      Save persists and returns to menu
//     4 runSaveModalDontSaveTest        Don't Save returns without persisting
//
//   RESUME MODAL (4)
//     5 runResumeModalShowsOnGameTapTest   saved games ⇒ modal on card tap
//     6 runResumeModalStartNewGameTest     Start New Game falls through to menu
//     7 runResumeModalDeleteIndividualTest one tile deleted, the other stays
//     8 runResumeModalDeleteAllTest        delete all ⇒ empty state
//
//   RESUME BUTTON (4)
//     9 runResumeButtonDisabledNoSavesTest  disabled + "No saved games"
//    10 runResumeButtonEnabledAfterSaveTest enabled + "Resume saved game"
//    11 runResumeButtonColorWhenEnabledTest the game's own enabled colour/icon
//    12 runResumeButtonShowsModalTest       tapping it opens the modal
//
//   ROUND TRIP (4)
//     13 runResumeGameLoadsScreenTest        resume restores the game screen
//     14 runResumeResaveOverwritesTest       re-saving overwrites, never dupes
//     15 runResumeButtonEnabledAfterResaveTest button still works afterwards
//     16 runResumeAutoDeletesOnCompletionTest finishing clears the save
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import 'element_finders.dart';
import 'game_ui_config.dart';
import 'pump_sequences.dart';
import 'results_helpers.dart';
import 'ui_test_helpers.dart';

/// Per-game parameters for the save/resume scenarios.
class SaveResumeSpec {
  final GameUIConfig config;

  /// The `gameType` string SaveGameService stores rows under.
  final String gameType;

  /// Opens the menu, adds players, starts a game — leaving a game screen.
  final Future<void> Function(WidgetTester tester) navigateToGameScreen;

  /// Throws exactly one scoring dart without ending the turn, so the board is
  /// dirty and the back arrow raises the Save prompt.
  final Future<void> Function(WidgetTester tester) throwOneDart;

  /// Writes one saved game straight to the service, bypassing the UI.
  final Future<String> Function() preSaveGame;

  /// Writes two saved games and returns their ids, for the delete scenarios.
  final Future<List<String>> Function() preSaveTwoGames;

  /// The menu's Resume button — the keyed WRAPPER, not the IconButton inside.
  final Finder Function() menuResumeButton;

  /// The menu's back arrow, used to get from the menu to home mid-scenario.
  final Finder Function() menuBackButton;

  /// Asserts a game screen is showing. Defaults to
  /// `config.getSkipTurnButton()`, which every current game exposes.
  final void Function(WidgetTester tester)? verifyOnGameScreen;

  /// The Resume button's colour once enabled. Each game themes it.
  final Color enabledColor;

  /// The Resume button's icon once enabled.
  final IconData enabledIcon;

  /// Asserts the resumed game came back correctly — player list, darts
  /// already thrown, game still active. Wholly game-specific.
  final void Function(WidgetTester tester)? verifyResumedState;

  /// Reaches a game screen configured to finish quickly, for the auto-delete
  /// scenario. Defaults to [navigateToGameScreen].
  final Future<void> Function(WidgetTester tester)? navigateToQuickGameScreen;

  /// Drives the RESUMED game to its results screen. The resumed turn is
  /// already one dart in, so this is not the same as a from-scratch victory
  /// helper and each game supplies its own.
  final Future<void> Function(WidgetTester tester)? completeResumedGame;

  const SaveResumeSpec({
    required this.config,
    required this.gameType,
    required this.navigateToGameScreen,
    required this.throwOneDart,
    required this.preSaveGame,
    required this.preSaveTwoGames,
    required this.menuResumeButton,
    required this.menuBackButton,
    this.verifyOnGameScreen,
    this.enabledColor = const Color(0xFFEEF0F2),
    this.enabledIcon = Icons.history,
    this.verifyResumedState,
    this.navigateToQuickGameScreen,
    this.completeResumedGame,
  });
}

// ─── Shared choreography ────────────────────────────────────────────────────

void _verifyOnMenu(WidgetTester tester, SaveResumeSpec spec) {
  expect(spec.config.getStartButton(), findsOneWidget,
      reason: 'Menu screen not showing — start button not found');
}

void _verifyOnGameScreen(WidgetTester tester, SaveResumeSpec spec) {
  if (spec.verifyOnGameScreen != null) {
    spec.verifyOnGameScreen!(tester);
    return;
  }
  expect(spec.config.getSkipTurnButton(), findsOneWidget,
      reason: 'Game screen not showing — skip-turn button not found');
}

/// The menu's Resume button is a keyed wrapper around an [IconButton]; every
/// assertion about enabled-ness, tooltip and colour reads that inner widget.
IconButton _resumeIconButton(WidgetTester tester, SaveResumeSpec spec) {
  final wrapper = spec.menuResumeButton();
  expect(wrapper, findsOneWidget, reason: 'Resume button not found on menu');
  return tester.widget<IconButton>(
    find.descendant(of: wrapper, matching: find.byType(IconButton)),
  );
}

/// navigate → one dart → back → Save. Ends on the menu with exactly one
/// saved game. This is the opening of most scenarios below.
Future<void> _playAndSave(WidgetTester tester, SaveResumeSpec spec) async {
  await spec.navigateToGameScreen(tester);
  await spec.throwOneDart(tester);
  await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
  await UITestHelpers.tapSaveGameButton(tester);
}

/// Menu → home → tap the game card, landing on the resume modal.
Future<void> _menuToHomeAndBack(WidgetTester tester, SaveResumeSpec spec) async {
  await tester.tap(spec.menuBackButton());
  await PumpSequences.navigation(tester);
  await UITestHelpers.tapGameCard(tester, spec.config);
  await PumpSequences.asyncDataLoad(tester);
}

/// Selects the single saved game and resumes it.
Future<String> _resumeOnlySavedGame(
    WidgetTester tester, SaveResumeSpec spec) async {
  final saved = await SaveGameService().loadSavedGames(spec.gameType);
  expect(saved, hasLength(1), reason: 'Expected exactly one saved game');
  await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
  await UITestHelpers.tapResumeGameButton(tester);
  return saved[0].id;
}

/// Home → pre-save → tap the game card, landing on the resume modal without
/// ever touching the game screen.
Future<void> _preSaveThenOpenModal(
    WidgetTester tester, SaveResumeSpec spec) async {
  await UITestHelpers.navigateToHomeScreen(tester);
  await spec.preSaveGame();
  await UITestHelpers.tapGameCard(tester, spec.config);
  await PumpSequences.asyncDataLoad(tester);
}

// ─── Save modal ─────────────────────────────────────────────────────────────

/// Backing out of an untouched board navigates away with no prompt.
void runSaveModalBack0DartsTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(
      description ?? 'back button with 0 darts navigates without save modal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.navigateToGameScreen(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
    await PumpSequences.navigation(tester);

    expect(ElementFinders.getSaveGameModalOverlay(), findsNothing,
        reason: 'Save prompt appeared for a board with no darts thrown');
    _verifyOnMenu(tester, spec);
  });
}

/// One thrown dart makes the back arrow raise the Save prompt.
void runSaveModalBackAfterDartsTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'back button after darts thrown shows save modal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.navigateToGameScreen(tester);
    await spec.throwOneDart(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);

    UITestHelpers.verifySaveGameModal();

    // Dismiss so this test leaves no widget-tree state behind: lingering
    // provider listeners and post-frame callbacks would otherwise fire
    // against the NEXT test's freshly-reset server and corrupt it.
    await UITestHelpers.tapDontSaveButton(tester);
  });
}

/// Save persists the game and returns to the menu.
void runSaveModalSaveButtonTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'Save button saves game and navigates back',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    _verifyOnMenu(tester, spec);
    expect(await SaveGameService().hasSavedGames(spec.gameType), true,
        reason: 'Save button did not persist the game');
  });
}

/// Don't Save returns to the menu without persisting anything.
void runSaveModalDontSaveTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? "Don't Save navigates back without saving",
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.navigateToGameScreen(tester);
    await spec.throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);

    await UITestHelpers.tapDontSaveButton(tester);

    _verifyOnMenu(tester, spec);
    expect(await SaveGameService().hasSavedGames(spec.gameType), false,
        reason: "Don't Save persisted the game anyway");
  });
}

// ─── Resume modal ───────────────────────────────────────────────────────────

/// Tapping the home card with saved games present opens the resume modal.
void runResumeModalShowsOnGameTapTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(description ?? 'tapping game with saved games shows resume modal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _preSaveThenOpenModal(tester, spec);

    UITestHelpers.verifyResumeGameModal();
  });
}

/// Start New Game dismisses the modal and falls through to the menu.
void runResumeModalStartNewGameTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'Start New Game dismisses modal and shows menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _preSaveThenOpenModal(tester, spec);

    await UITestHelpers.tapStartNewGameButton(tester);

    _verifyOnMenu(tester, spec);
  });
}

/// Deleting one saved game leaves the other alone.
void runResumeModalDeleteIndividualTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(description ?? 'delete individual saved game removes it',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    final ids = await spec.preSaveTwoGames();
    await UITestHelpers.tapGameCard(tester, spec.config);
    await PumpSequences.asyncDataLoad(tester);

    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]),
        findsOneWidget);
    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
        findsOneWidget);

    await UITestHelpers.deleteSavedGameTile(tester, ids[0]);

    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[0]), findsNothing,
        reason: 'Deleted tile is still showing');
    expect(ElementFinders.getResumeGameModalSavedGameTile(ids[1]),
        findsOneWidget,
        reason: 'Deleting one saved game removed the other too');
  });
}

/// Deleting every saved game leaves the modal in its empty state.
void runResumeModalDeleteAllTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'delete all saved games shows empty state',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await spec.preSaveTwoGames();
    await UITestHelpers.tapGameCard(tester, spec.config);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.deleteAllSavedGames(tester);

    expect(ElementFinders.getResumeGameModalEmptyState(), findsOneWidget,
        reason: 'Resume modal did not fall back to its empty state');
  });
}

// ─── Resume button ──────────────────────────────────────────────────────────

/// With nothing saved the Resume button is present but inert.
void runResumeButtonDisabledNoSavesTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(description ?? 'button is disabled when no saved games exist',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    final button = _resumeIconButton(tester, spec);
    expect(button.onPressed, isNull,
        reason: 'Resume button is tappable with no saved games');
    expect(button.tooltip, 'No saved games');
  });
}

/// Saving a game enables the Resume button.
void runResumeButtonEnabledAfterSaveTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(description ?? 'button becomes enabled after saving a game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    final button = _resumeIconButton(tester, spec);
    expect(button.onPressed, isNotNull,
        reason: 'Resume button still inert after a save');
    expect(button.tooltip, 'Resume saved game');
  });
}

/// The enabled Resume button carries this game's colour and icon.
void runResumeButtonColorWhenEnabledTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(description ?? 'button is visible with correct color when enabled',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    final button = _resumeIconButton(tester, spec);
    expect(button.color, spec.enabledColor);
    expect((button.icon as Icon).icon, spec.enabledIcon);
  });
}

/// Tapping the enabled Resume button opens the resume modal.
void runResumeButtonShowsModalTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'clicking button shows resume modal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    await tester.tap(spec.menuResumeButton());
    await PumpSequences.asyncDataLoad(tester);

    UITestHelpers.verifyResumeGameModal();
  });
}

// ─── Round trip ─────────────────────────────────────────────────────────────

/// The full round trip: play, save, leave, come back, resume.
void runResumeGameLoadsScreenTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(description ?? 'Resume Game loads game screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);
    await _menuToHomeAndBack(tester, spec);
    await _resumeOnlySavedGame(tester, spec);

    _verifyOnGameScreen(tester, spec);
    spec.verifyResumedState?.call(tester);
  });
}

/// Saving a resumed game overwrites its row instead of adding another.
void runResumeResaveOverwritesTest(SaveResumeSpec spec, {String? description}) {
  testWidgets(
      description ?? 'resumed game re-save overwrites instead of duplicating',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    var saved = await SaveGameService().loadSavedGames(spec.gameType);
    expect(saved, hasLength(1));
    final originalId = saved[0].id;

    await _menuToHomeAndBack(tester, spec);
    await _resumeOnlySavedGame(tester, spec);

    // Dirty the resumed board and save again.
    await spec.throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
    await UITestHelpers.tapSaveGameButton(tester);

    saved = await SaveGameService().loadSavedGames(spec.gameType);
    expect(saved, hasLength(1),
        reason: 'Re-saving a resumed game created a second row');
    expect(saved[0].id, originalId,
        reason: 'Re-save replaced the row instead of updating it');
  });
}

/// After a resume-and-re-save round trip the menu's Resume button still works.
void runResumeButtonEnabledAfterResaveTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(
      description ?? 'button stays hidden when modal is not shown after resume',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await _playAndSave(tester, spec);

    // Reach the resume modal via the button rather than the home card.
    await tester.tap(spec.menuResumeButton());
    await PumpSequences.asyncDataLoad(tester);
    await _resumeOnlySavedGame(tester, spec);
    _verifyOnGameScreen(tester, spec);

    await spec.throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
    await UITestHelpers.tapSaveGameButton(tester);

    _verifyOnMenu(tester, spec);
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing,
        reason: 'Resume modal auto-opened after returning to the menu');
    expect(_resumeIconButton(tester, spec).onPressed, isNotNull,
        reason: 'Resume button went inert after the round trip');
  });
}

/// Finishing a resumed game deletes its save.
void runResumeAutoDeletesOnCompletionTest(SaveResumeSpec spec,
    {String? description}) {
  testWidgets(
      description ?? 'resumed game auto-deletes saved game on completion',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await (spec.navigateToQuickGameScreen ?? spec.navigateToGameScreen)(tester);
    await spec.throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
    await UITestHelpers.tapSaveGameButton(tester);

    await _menuToHomeAndBack(tester, spec);
    await _resumeOnlySavedGame(tester, spec);

    await spec.completeResumedGame!(tester);
    await ResultsHelpers.pumpUntilResults(tester, spec.config);
    expect(spec.config.getPlayAgainButton(), findsOneWidget,
        reason: 'Resumed game did not reach the results screen');

    expect(await SaveGameService().loadSavedGames(spec.gameType), isEmpty,
        reason: 'Finishing the game did not clear its saved row');
  });
}
