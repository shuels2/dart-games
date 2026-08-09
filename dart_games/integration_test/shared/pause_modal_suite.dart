// integration_test/shared/pause_modal_suite.dart
//
// Shared, parameterized bodies for the dartboard-paused ("Game Paused")
// scenarios every game implements (WS05 §5.3 item 3 — "template the commodity
// categories"). Companion to shared/navigation_suite.dart.
//
// ─── FILE LAYOUT IS DELIBERATELY UNCHANGED ─────────────────────────────────
// Still ONE `testWidgets` per file, still one file per scenario-group per
// game. Merging tests into a single `flutter drive` boot (§5.3 item 2) was
// tried before this plan and reverted: tests sharing one app boot dirtied the
// database and app state and failed frequently. One boot per test IS the
// isolation mechanism. Boot-count savings come from the runner's reaping, not
// from this file.
//
// What this file removes is DUPLICATED BODIES. The pause category is the most
// uniform in the repo — every game has exactly 7 menu + 8 gameplay + 5 results
// tests, in the same order, asserting the same things — but the bodies were
// hand-written ten times in three drifted spellings:
//
//   gen-A (target_tag, carnival_derby)   guarded `if (f.evaluate().isNotEmpty)`
//                                        taps, no pause-still-visible assert,
//                                        no trailing reconnect.
//   gen-A2 (clockwork_quest, lunar_lander)
//                                        as gen-A but game-specific "still on
//                                        screen" finders (ResultsKeys.winnerName).
//   gen-B (monster_mash, reef_royale, pirates_grid, gladiator_arena,
//          tiki_golf, treasure_divide)
//                                        `warnIfMissed: false` taps, explicit
//                                        pause-visible assert, trailing
//                                        reconnect-and-verify.
//
// gen-B is the canonical form and is what these runners implement: it is a
// strict superset of gen-A's assertions (gen-A never asserted anything gen-B
// omits). Converting a gen-A game therefore ADDS coverage — the pause overlay
// staying visible after a blocked tap, and dismissing on reconnect — of
// behaviour that lives in one shared widget (DartboardPausedModal) which the
// six gen-B games already prove. Everything genuinely per-game (finders,
// setup, victory routes, screen-identity assertions) stays a spec callback.
//
// ─── THIS FILE MUST EXIST IN BOTH SHARED TREES ─────────────────────────────
// A copy lives at test/shared/pause_modal_suite.dart and the two must stay
// byte-identical (CLAUDE.md's shared-helper rule; test/meta/ enforces it).
//
// That is not just tidiness — it is load-bearing. `flutter drive`'s web
// compile resolves a UI test's `../../shared/x.dart` against test/shared/,
// NOT integration_test/shared/. A helper present in only the integration_test
// copy fails at compile time with:
//     Error when reading 'org-dartlang-app:/shared/<file>.dart': File not found
// while `flutter analyze` and `flutter build web` both resolve it happily —
// so this is invisible until a real UI run.
//
// ─── SCENARIO INVENTORY (the coverage contract) ────────────────────────────
// Each runner documents what it asserts. When converting a game, every
// assertion its hand-written file made must appear either in the runner or in
// that game's spec callbacks — never dropped.
//
//   MENU (7)
//     1 runMenuPauseAppearsTest            disconnect → modal → still on menu
//     2 runMenuPauseBlocksBackTest         blocked back tap → still on menu
//     3 runMenuPauseBlocksStartTest        players added, blocked start tap
//     4 runMenuPauseBlocksSettingsTest     blocked settings-control taps
//     5 runMenuPauseBlocksAddPlayerTest    blocked add-player, dialog never opens
//       runMenuPauseCleanDisconnectTest    (gen-A's slot-5 alternative)
//     6 runMenuPauseDismissesTest          reconnect → menu functional again
//     7 runMenuReconnectRestoresBackTest   blocked back, then reconnect → home
//
//   GAMEPLAY (8)
//     1 runGameplayPauseAppearsTest        disconnect → modal → still in game
//     2 runGameplayPauseBlocksBackTest     blocked back tap, no save prompt
//     3 runGameplayPauseBlocksEmulatorTest emulator obscured by the modal
//     4 runGameplayPauseOverRemoveDartsTest  takeout pending → modal on top
//     5 runGameplayPauseOverSaveGameTest   save modal open → modal on top,
//                                          Save blocked
//     6 runGameplayEditScoreAutoClosesTest edit dialog force-closed on drop
//     7 runGameplayPauseDismissesTest      reconnect → darts land again
//     8 runGameplayRemoveDartsSurvivesTest takeout still pending after reconnect
//
//   RESULTS (5)
//     1 runResultsPauseAppearsTest         disconnect → modal → still on results
//     2 runResultsPauseBlocksPlayAgainTest
//     3 runResultsPauseBlocksChangeSettingsTest
//     4 runResultsPauseBlocksBackToMenuTest
//     5 runResultsPauseDismissesTest       reconnect → the game's own tail
import 'package:flutter_test/flutter_test.dart';

import 'element_finders.dart';
import 'game_ui_config.dart';
import 'pause_modal_helpers.dart';
import 'provider_helpers.dart';
import 'pump_sequences.dart';
import 'ui_test_helpers.dart';

/// Per-game parameters for the pause-modal scenarios.
///
/// Only [config] is needed by every runner; the rest are required by the
/// runners that use them, so a game running only the menu group supplies only
/// the menu fields.
class PauseModalSpec {
  final GameUIConfig config;

  // ─── menu ──────────────────────────────────────────────────────────────

  /// The game menu's back arrow.
  final Finder Function()? menuBackButton;

  /// The game's own home-screen card, asserted after the post-reconnect back
  /// tap in scenario 7.
  final Finder Function()? ownGameCard;

  /// Asserts the menu screen is loaded. Defaults to `config.getStartButton()`,
  /// which is correct for every current game; override for a game that
  /// identified its menu by a settings label instead.
  final void Function(WidgetTester tester)? verifyOnMenu;

  /// Settings controls tapped in scenario 4 to prove the overlay swallows
  /// them. Games that exercised two controls list both.
  final List<Finder Function()> menuSettingsControls;

  /// The menu's add-player button (empty-state variant), for scenario 5.
  final Finder Function()? menuAddPlayerButton;

  /// Player names added before the blocked start tap in scenario 3, so the
  /// start button is genuinely enabled and the block is meaningful.
  final List<String> menuStartPlayers;

  /// Asserts the home screen after scenario 7's post-reconnect back tap.
  /// Defaults to asserting [ownGameCard].
  final void Function(WidgetTester tester)? verifyOnHome;

  // ─── gameplay ──────────────────────────────────────────────────────────

  /// Opens the menu, applies settings, adds players, starts the game.
  final Future<void> Function(WidgetTester tester)? startGame;

  /// Asserts a game screen is showing. Defaults to
  /// `config.getGameBackButton()`.
  final void Function(WidgetTester tester)? verifyOnGameScreen;

  /// Throws one scoring dart without ending the turn — enough for
  /// `hasDartsThrown` so the back arrow raises the Save prompt.
  final Future<void> Function(WidgetTester tester)? throwOneDart;

  /// Throws a whole turn so the takeout prompt ("DARTS REMOVED") appears.
  /// Dart counts and hit/miss choices differ per game, so this is the game's.
  final Future<void> Function(WidgetTester tester)? throwTurnToTakeout;

  /// Completes the pending takeout, advancing the turn.
  final Future<void> Function(WidgetTester tester)? finishTakeout;

  /// Opens the Edit Score dialog (the turn must already be complete).
  final Future<void> Function(WidgetTester tester)? openEditScore;

  // ─── results ───────────────────────────────────────────────────────────

  /// Gets from a fresh app all the way to the results screen.
  final Future<void> Function(WidgetTester tester)? reachResults;

  /// Asserts the results screen is showing. Defaults to
  /// `config.getPlayAgainButton()`; games that identified results by the
  /// winner-name key pass that instead.
  final void Function(WidgetTester tester)? verifyOnResults;

  /// The tail of results scenario 5 — each game proved "the buttons work
  /// again" differently (Back to Menu → home card, Play Again → results gone,
  /// Play Again → pause gone), so the whole tail is the game's own.
  final Future<void> Function(WidgetTester tester)? resultsAfterReconnect;

  const PauseModalSpec({
    required this.config,
    this.menuBackButton,
    this.ownGameCard,
    this.verifyOnMenu,
    this.menuSettingsControls = const [],
    this.menuAddPlayerButton,
    this.menuStartPlayers = const ['Player A', 'Player B'],
    this.verifyOnHome,
    this.startGame,
    this.verifyOnGameScreen,
    this.throwOneDart,
    this.throwTurnToTakeout,
    this.finishTakeout,
    this.openEditScore,
    this.reachResults,
    this.verifyOnResults,
    this.resultsAfterReconnect,
  });
}

// ─── Shared choreography ────────────────────────────────────────────────────

void _verifyOnMenu(WidgetTester tester, PauseModalSpec spec) {
  if (spec.verifyOnMenu != null) {
    spec.verifyOnMenu!(tester);
    return;
  }
  expect(spec.config.getStartButton(), findsOneWidget,
      reason: 'Menu screen not showing — start button not found');
}

void _verifyOnGameScreen(WidgetTester tester, PauseModalSpec spec) {
  if (spec.verifyOnGameScreen != null) {
    spec.verifyOnGameScreen!(tester);
    return;
  }
  expect(spec.config.getGameBackButton(), findsOneWidget,
      reason: 'Game screen not showing — game back button not found');
}

void _verifyOnResults(WidgetTester tester, PauseModalSpec spec) {
  if (spec.verifyOnResults != null) {
    spec.verifyOnResults!(tester);
    return;
  }
  expect(spec.config.getPlayAgainButton(), findsOneWidget,
      reason: 'Results screen not showing — Play Again button not found');
}

void _verifyOnHome(WidgetTester tester, PauseModalSpec spec) {
  if (spec.verifyOnHome != null) {
    spec.verifyOnHome!(tester);
    return;
  }
  expect(spec.ownGameCard!(), findsOneWidget,
      reason: "This game's own card missing — not on the home screen");
}

/// Taps a widget the pause overlay is expected to swallow.
///
/// `warnIfMissed: false` is the point: the target is on screen but covered, so
/// the hit test lands on the overlay. Without the flag every one of these taps
/// prints a spurious "finder found a widget but no gesture was received"
/// warning — which is exactly the outcome being asserted.
Future<void> _tapBlocked(WidgetTester tester, Finder finder) async {
  await tester.tap(finder, warnIfMissed: false);
  await PumpSequences.simpleUpdate(tester);
}

/// Disconnects and pumps long enough for post-frame dialog teardown to run.
///
/// The Edit Score dialog is closed from a post-frame callback, so the plain
/// `simulateDisconnectAndVerify` pump is not enough to observe it gone.
Future<void> _disconnectAndSettleDialogs(WidgetTester tester) async {
  ProviderHelpers.simulateDartboardDisconnection(tester);
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

// ─── Menu scenarios ─────────────────────────────────────────────────────────

/// Disconnecting on the menu raises the pause modal without leaving the menu.
void runMenuPauseAppearsTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause modal appears on menu screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    _verifyOnMenu(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows the menu's AppBar back arrow.
void runMenuPauseBlocksBackTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause blocks AppBar back button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, spec.menuBackButton!());

    PauseModalHelpers.verifyPauseModalVisible(tester);
    _verifyOnMenu(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows the start button even with players added.
void runMenuPauseBlocksStartTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause blocks start game button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    // Players first, so the start button is genuinely enabled and the block
    // being asserted is the overlay's rather than the empty-roster guard's.
    for (final name in spec.menuStartPlayers) {
      await UITestHelpers.addPlayer(tester, name, spec.config);
    }

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, spec.config.getStartButton());

    PauseModalHelpers.verifyPauseModalVisible(tester);
    _verifyOnMenu(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows the menu's settings controls.
void runMenuPauseBlocksSettingsTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause blocks settings controls',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    for (final control in spec.menuSettingsControls) {
      await _tapBlocked(tester, control());
      PauseModalHelpers.verifyPauseModalVisible(tester);
    }

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows the add-player button — the dialog never opens.
void runMenuPauseBlocksAddPlayerTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause blocks add player button on menu',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, spec.menuAddPlayerButton!());

    PauseModalHelpers.verifyPauseModalVisible(tester);
    expect(ElementFinders.getAddPlayerNameField(), findsNothing,
        reason: 'Add Player dialog opened despite the pause overlay');

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// Disconnect then reconnect on an untouched menu leaves it clean.
///
/// This is the slot-5 scenario for the games that never had an add-player
/// variant. It is deliberately kept rather than replaced: those games' menus
/// use a different add-player entry point, and swapping the scenario would
/// assert something the game never asserted.
void runMenuPauseCleanDisconnectTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause modal on clean menu disconnect works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
    _verifyOnMenu(tester, spec);
  });
}

/// After reconnecting, the menu is interactive again.
void runMenuPauseDismissesTest(PauseModalSpec spec,
    {String? description,
    String playerName = 'Player A',
    void Function(WidgetTester tester)? verifyAfter}) {
  testWidgets(description ?? 'Pause dismisses and menu still works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Adding a player is the cheapest proof the menu accepts input again.
    await UITestHelpers.addPlayer(tester, playerName, spec.config);

    if (verifyAfter != null) {
      verifyAfter(tester);
    } else {
      _verifyOnMenu(tester, spec);
    }
  });
}

/// The back arrow is blocked while paused and works once reconnected.
void runMenuReconnectRestoresBackTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(
      description ?? 'Pause blocks then reconnect back button works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    final backButton = spec.menuBackButton!();
    await _tapBlocked(tester, backButton);

    PauseModalHelpers.verifyPauseModalVisible(tester);
    _verifyOnMenu(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    await tester.tap(backButton);
    await PumpSequences.navigation(tester);

    _verifyOnHome(tester, spec);
  });
}

// ─── Gameplay scenarios ─────────────────────────────────────────────────────

/// Disconnecting mid-game raises the pause modal without leaving the game.
///
/// [throwDartFirst] reproduces the games whose original test threw a dart to
/// confirm gameplay was live before pulling the board.
void runGameplayPauseAppearsTest(PauseModalSpec spec,
    {String? description, bool throwDartFirst = false}) {
  testWidgets(description ?? 'Pause modal appears during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    if (throwDartFirst) await spec.throwOneDart!(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    _verifyOnGameScreen(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows the game screen's back arrow — no Save prompt.
void runGameplayPauseBlocksBackTest(PauseModalSpec spec,
    {String? description, bool throwDartFirst = false}) {
  testWidgets(description ?? 'Pause blocks AppBar back button during gameplay',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    // With a dart thrown, an unblocked back tap WOULD raise the Save prompt —
    // which makes its absence below the sharper assertion.
    if (throwDartFirst) await spec.throwOneDart!(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, spec.config.getGameBackButton());

    PauseModalHelpers.verifyPauseModalVisible(tester);
    _verifyOnGameScreen(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay covers the dartboard emulator.
void runGameplayPauseBlocksEmulatorTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(description ?? 'Pause blocks dartboard emulator',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    // The emulator section re-renders without its controls while the board is
    // down, so the modal being on top IS the assertion.
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause modal paints over a pending RemoveDartsModal.
void runGameplayPauseOverRemoveDartsTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(description ?? 'Pause over RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    await spec.throwTurnToTakeout!(tester);
    expect(find.text('DARTS REMOVED'), findsOneWidget,
        reason: 'Takeout prompt not showing — turn did not end');

    // Not tapping DARTS REMOVED here: when the board drops, the emulator
    // section re-renders without that button, so the visual blocker is the
    // meaningful assertion.
    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
  });
}

/// The pause modal paints over an open SaveGameModal and blocks its Save.
void runGameplayPauseOverSaveGameTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(description ?? 'Pause over SaveGameModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    // A dart makes the board dirty, so back raises the Save prompt.
    await spec.throwOneDart!(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);
    UITestHelpers.verifySaveGameModal();

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, ElementFinders.getSaveGameModalSaveButton());
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // Dismiss the save modal so the app is left in a clean state.
    await UITestHelpers.tapDontSaveButton(tester);
  });
}

/// Losing the board force-closes an open Edit Score dialog.
void runGameplayEditScoreAutoClosesTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(description ?? 'EditScoreDialog auto-closes on disconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    // Edit Score only appears once a turn is complete.
    await spec.throwTurnToTakeout!(tester);
    await spec.openEditScore!(tester);
    expect(ElementFinders.getEditScoreSaveButton(), findsOneWidget,
        reason: 'Edit Score dialog did not open');

    await _disconnectAndSettleDialogs(tester);

    expect(ElementFinders.getEditScoreSaveButton(), findsNothing,
        reason: 'Edit Score dialog survived the disconnect');
    PauseModalHelpers.verifyPauseModalVisible(tester);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// Reconnecting resumes gameplay — darts register again.
void runGameplayPauseDismissesTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause dismisses on reconnect game continues',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    await spec.throwOneDart!(tester);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    // The board accepting another dart is the proof gameplay resumed.
    await spec.throwOneDart!(tester);

    _verifyOnGameScreen(tester, spec);
  });
}

/// A pending takeout survives the pause — pausing obscures, it does not cancel.
void runGameplayRemoveDartsSurvivesTest(PauseModalSpec spec,
    {String? description}) {
  testWidgets(description ?? 'RemoveDartsModal still visible after reconnect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.startGame!(tester);

    await spec.throwTurnToTakeout!(tester);
    expect(find.text('DARTS REMOVED'), findsOneWidget,
        reason: 'Takeout prompt not showing — turn did not end');

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    expect(find.text('DARTS REMOVED'), findsOneWidget,
        reason: 'Takeout prompt was lost across the pause');

    // Complete the takeout so the game is left able to continue.
    await spec.finishTakeout!(tester);
    _verifyOnGameScreen(tester, spec);
  });
}

// ─── Results scenarios ──────────────────────────────────────────────────────

/// Disconnecting on the results screen raises the pause modal.
void runResultsPauseAppearsTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause modal appears on results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.reachResults!(tester);
    _verifyOnResults(tester, spec);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    _verifyOnResults(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// Shared body for the three "pause blocks a results button" scenarios.
void _runResultsBlockedButtonTest(
  PauseModalSpec spec,
  String defaultDescription,
  Finder Function(PauseModalSpec spec) button, {
  String? description,
}) {
  testWidgets(description ?? defaultDescription, (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.reachResults!(tester);
    _verifyOnResults(tester, spec);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);

    await _tapBlocked(tester, button(spec));

    PauseModalHelpers.verifyPauseModalVisible(tester);
    _verifyOnResults(tester, spec);

    await PauseModalHelpers.simulateReconnectAndVerify(tester);
  });
}

/// The pause overlay swallows Play Again.
void runResultsPauseBlocksPlayAgainTest(PauseModalSpec spec,
        {String? description}) =>
    _runResultsBlockedButtonTest(
      spec,
      'Pause blocks Play Again button',
      (s) => s.config.getPlayAgainButton(),
      description: description,
    );

/// The pause overlay swallows Change Settings.
void runResultsPauseBlocksChangeSettingsTest(PauseModalSpec spec,
        {String? description}) =>
    _runResultsBlockedButtonTest(
      spec,
      'Pause blocks Change Settings button',
      (s) => s.config.getChangeSettingsButton(),
      description: description,
    );

/// The pause overlay swallows Back to Menu.
void runResultsPauseBlocksBackToMenuTest(PauseModalSpec spec,
        {String? description}) =>
    _runResultsBlockedButtonTest(
      spec,
      'Pause blocks Back to Menu button',
      (s) => s.config.getBackToMenuButton(),
      description: description,
    );

/// Reconnecting restores the results screen's actions.
void runResultsPauseDismissesTest(PauseModalSpec spec, {String? description}) {
  testWidgets(description ?? 'Pause dismisses and buttons work',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.reachResults!(tester);
    _verifyOnResults(tester, spec);

    await PauseModalHelpers.simulateDisconnectAndVerify(tester);
    await PauseModalHelpers.simulateReconnectAndVerify(tester);

    await spec.resultsAfterReconnect!(tester);
  });
}
