// integration_test/shared/navigation_suite.dart
//
// Shared, parameterized bodies for the navigation scenarios every game
// implements (WS05 §5.3 item 3 — "template the commodity categories").
//
// ─── FILE LAYOUT IS DELIBERATELY UNCHANGED ─────────────────────────────────
// Still ONE `testWidgets` per file, still one file per scenario per game.
// Merging multiple tests into a single `flutter drive` boot (§5.3 item 2) was
// tried before this plan and reverted: tests sharing one app boot dirtied the
// database and app state and failed frequently. One boot per test IS the
// isolation mechanism. Boot-count savings come from the runner's reaping, not
// from this file.
//
// What this file removes is DUPLICATED BODIES, not boots: the navigation
// choreography (reset → navigate → tap → pump → assert home) was hand-written
// ten times with ten different pump/assert spellings. That choreography is
// where the flake-prone sequencing lives, so standardising it is the point.
// Everything genuinely per-game (setup, victory, settings assertions) stays a
// spec callback.
//
// ─── SCENARIO INVENTORY (the coverage contract) ────────────────────────────
// Each runner below documents exactly what it asserts. When converting a game
// to this suite, every assertion its old hand-written file made must appear
// either in the runner or in that game's spec callbacks — never dropped.
//
//   runMenuBackToHomeTest
//     menu loaded (optional per-game check) → tap menu back → home screen
//     shows the three canonical game cards (+ the game's own card if given).
//
//   runChangeSettingsBackToHomeTest
//     setup+start → play to victory → results shows Play Again → tap Change
//     Settings → menu loaded → tap menu back → home shows the three cards.
//
//   runChangeSettingsPreservesSettingsTest
//     setup+start → play to victory → results shows Play Again → tap Change
//     Settings → menu loaded → spec's verifySettings runs (slider values,
//     switch states, player names — whatever that game asserted before).
//
//   runGameBackSettingsPersistTest
//     spec's reachGameScreen (each game's own route to a backable game
//     screen) → tap game back → optionally assert+dismiss the Save modal →
//     menu loaded → spec's verifySettings runs.
import 'package:flutter_test/flutter_test.dart';

import 'element_finders.dart';
import 'game_ui_config.dart';
import 'pump_sequences.dart';
import 'results_helpers.dart';
import 'ui_test_helpers.dart';

/// Per-game parameters for the navigation scenarios.
///
/// Only [config] and [menuBackButton] are needed by every runner; the rest are
/// required by the runners that use them, so a game that only runs a subset
/// supplies only that subset.
class NavigationSpec {
  final GameUIConfig config;

  /// The game menu's back arrow.
  final Finder Function() menuBackButton;

  /// The game's own home-screen card, asserted alongside the canonical three
  /// when supplied. Only some games asserted this; pass null to match a game
  /// that did not.
  final Finder Function()? ownGameCard;

  /// Asserts the menu screen is loaded. Defaults to `config.getStartButton()`,
  /// which is correct for every current game; override for a game whose start
  /// button is conditional.
  final void Function(WidgetTester tester)? verifyOnMenu;

  /// Opens the menu, applies this game's settings, adds players, starts.
  final Future<void> Function(WidgetTester tester)? setupAndStart;

  /// Drives a started game to the results screen. Implementations vary a lot
  /// (dart patterns, round counts, provider polling), so this is wholly the
  /// game's own.
  final Future<void> Function(WidgetTester tester)? playToVictory;

  /// Gets from a fresh app to a game screen the back button can be tapped on.
  /// Three shapes exist across the roster — start-then-back, complete-then-
  /// Play-Again-then-back, and start-throw-then-back — so each game supplies
  /// its own.
  final Future<void> Function(WidgetTester tester)? reachGameScreen;

  /// Asserts this game's settings (and players, where the old test did)
  /// survived onto the menu.
  final void Function(WidgetTester tester)? verifySettings;

  /// True for games whose game-back test asserted the Save modal appears
  /// before dismissing it. When false the modal is dismissed if present and
  /// ignored if not — matching the games that guarded defensively.
  final bool expectSaveModalOnGameBack;

  const NavigationSpec({
    required this.config,
    required this.menuBackButton,
    this.ownGameCard,
    this.verifyOnMenu,
    this.setupAndStart,
    this.playToVictory,
    this.reachGameScreen,
    this.verifySettings,
    this.expectSaveModalOnGameBack = false,
  });
}

// ─── Shared choreography ────────────────────────────────────────────────────

void _verifyOnMenu(WidgetTester tester, NavigationSpec spec) {
  if (spec.verifyOnMenu != null) {
    spec.verifyOnMenu!(tester);
    return;
  }
  expect(spec.config.getStartButton(), findsOneWidget,
      reason: 'Menu screen not loaded — start button not found');
}

/// Asserts the home screen is showing. Multiple game cards is the signal that
/// distinguishes home from the dartboard-registration screen, which is why
/// every game asserted three of them.
void _verifyOnHome(WidgetTester tester, NavigationSpec spec) {
  expect(ElementFinders.getCarnivalDerbyCard(), findsOneWidget,
      reason: 'Carnival Derby card missing — not on the home screen');
  expect(ElementFinders.getTargetTagCard(), findsOneWidget,
      reason: 'Target Tag card missing — not on the home screen');
  expect(ElementFinders.getMonsterMashCard(), findsOneWidget,
      reason: 'Monster Mash card missing — not on the home screen');
  if (spec.ownGameCard != null) {
    expect(spec.ownGameCard!(), findsOneWidget,
        reason: "This game's own card missing — not on the home screen");
  }
}

Future<void> _tapMenuBackToHome(WidgetTester tester, NavigationSpec spec) async {
  final backButton = spec.menuBackButton();
  expect(backButton, findsOneWidget,
      reason: 'Menu back button not found');
  await tester.tap(backButton);
  await PumpSequences.navigation(tester);
}

Future<void> _playToResults(WidgetTester tester, NavigationSpec spec) async {
  await spec.playToVictory!(tester);
  await ResultsHelpers.pumpUntilResults(tester, spec.config);
  expect(spec.config.getPlayAgainButton(), findsOneWidget,
      reason: 'Results screen not loaded — Play Again button not found');
}

// ─── Scenario runners ───────────────────────────────────────────────────────

/// Menu back arrow returns to the home screen.
///
/// [verifyMenuFirst] asserts the menu is loaded before tapping back. It is
/// opt-in rather than automatic: only some games asserted it here, and a game
/// whose start button is gated on having players would fail an assertion its
/// old test never made. Games that did assert it pass true.
void runMenuBackToHomeTest(NavigationSpec spec,
    {String? description, bool verifyMenuFirst = false}) {
  testWidgets(description ?? 'Menu back button returns to home screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, spec.config);

    if (verifyMenuFirst) _verifyOnMenu(tester, spec);
    await _tapMenuBackToHome(tester, spec);
    _verifyOnHome(tester, spec);
  });
}

/// Change Settings on the results screen lands on the menu, and the menu's
/// back arrow still reaches home from there.
void runChangeSettingsBackToHomeTest(NavigationSpec spec, {String? description}) {
  testWidgets(
      description ?? 'Results change settings then menu back returns to home',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.setupAndStart!(tester);
    await _playToResults(tester, spec);

    await UITestHelpers.clickChangeSettings(tester, spec.config);
    _verifyOnMenu(tester, spec);

    await _tapMenuBackToHome(tester, spec);
    _verifyOnHome(tester, spec);
  });
}

/// Change Settings carries the finished game's settings and players back onto
/// the menu.
void runChangeSettingsPreservesSettingsTest(NavigationSpec spec,
    {String? description}) {
  testWidgets(
      description ??
          'Change Settings preserves settings and players after victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.setupAndStart!(tester);
    await _playToResults(tester, spec);

    await UITestHelpers.clickChangeSettings(tester, spec.config);
    _verifyOnMenu(tester, spec);

    spec.verifySettings!(tester);
  });
}

/// The game screen's back arrow returns to the menu with settings intact.
void runGameBackSettingsPersistTest(NavigationSpec spec, {String? description}) {
  testWidgets(
      description ?? 'Game back button returns to menu with settings preserved',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.reachGameScreen!(tester);

    await UITestHelpers.tapGameScreenBackButton(tester, spec.config);

    // Games that have thrown a dart get the Save prompt; games backing out of
    // an untouched board do not. Assert it only where the old test did.
    if (spec.expectSaveModalOnGameBack) {
      await PumpSequences.dialogOpen(tester);
      UITestHelpers.verifySaveGameModal();
      await UITestHelpers.tapDontSaveButton(tester);
    } else {
      final dontSave = ElementFinders.getSaveGameModalDontSaveButton();
      if (dontSave.evaluate().isNotEmpty) {
        await tester.tap(dontSave);
      }
    }
    await PumpSequences.navigation(tester);

    _verifyOnMenu(tester, spec);
    spec.verifySettings!(tester);
  });
}
