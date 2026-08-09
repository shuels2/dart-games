// integration_test/shared/play_to_complete_suite.dart
//
// Shared, parameterized bodies for the two play-to-complete scenarios every
// game implements (WS05 §5.3 item 3 — the plan scopes this category to
// "play_to_complete-default"). Companion to shared/navigation_suite.dart,
// shared/pause_modal_suite.dart and shared/save_resume_suite.dart.
//
// ─── SCOPE: ONLY THE TWO COMMODITY SCENARIOS ───────────────────────────────
// play_to_complete holds 51 files, but only two exist in every game:
//   default_settings_test.dart  and  mid_game_test.dart
// The other 31 are per-game OPTION variants — bestof3, hard_landing_on,
// quarter_it_on, shield_round, mulligan_on, easy_claim, and so on. Those are
// each game's own option matrix, they assert game-specific settings effects,
// and they are deliberately NOT templated. Only the two commodity scenarios
// route through this file.
//
// ─── FILE LAYOUT IS DELIBERATELY UNCHANGED ─────────────────────────────────
// Still ONE `testWidgets` per file. Merging tests into a single
// `flutter drive` boot (§5.3 item 2) was tried before this plan and reverted:
// tests sharing one app boot dirtied the database and app state and failed
// frequently. One boot per test IS the isolation mechanism.
//
// ─── THIS FILE MUST EXIST IN BOTH SHARED TREES ─────────────────────────────
// A copy lives at test/shared/play_to_complete_suite.dart and the two must
// stay byte-identical (CLAUDE.md's shared-helper rule; test/meta/ enforces
// it). `flutter drive`'s web compile resolves a UI test's `../../shared/x.dart`
// against test/shared/, NOT integration_test/shared/ — a suite present only in
// the integration_test copy fails at compile time with
//     Error when reading 'org-dartlang-app:/shared/<file>.dart': File not found
// while `flutter analyze` and `flutter build web` both resolve it happily.
//
// ─── SCENARIO INVENTORY (the coverage contract) ────────────────────────────
//   1 runPlayToCompleteDefaultTest
//       set up with this game's default options → tap Play to Complete →
//       poll until the provider reports a winner → results screen is showing.
//
//   2 runPlayToCompleteMidGameTest
//       set up → throw this game's manual darts by hand → (optionally assert
//       the game is NOT already won) → tap Play to Complete → poll → results.
//       The point is that auto-play can pick up a board that is already
//       part-way through a turn, not only a pristine one.
import 'package:flutter_test/flutter_test.dart';

import 'game_ui_config.dart';
import 'play_to_complete_helpers.dart';
import 'ui_test_helpers.dart';

/// Per-game parameters for the play-to-complete scenarios.
class PlayToCompleteSpec {
  final GameUIConfig config;

  /// Opens the menu, applies this game's DEFAULT options, adds players and
  /// starts — leaving a game screen with the emulator available.
  final Future<void> Function(WidgetTester tester) setupAndStart;

  /// Setup for the mid-game scenario when it differs from [setupAndStart].
  /// Monster Mash lowers Health Max first so the hand-thrown darts land on a
  /// board that can still finish quickly. Defaults to [setupAndStart].
  final Future<void> Function(WidgetTester tester)? setupAndStartMidGame;

  /// Reads this game's provider and reports whether a winner exists. This is
  /// the completion condition auto-play is polled against.
  final bool Function(WidgetTester tester) hasWinner;

  /// Throws the manual darts the mid-game scenario starts from. Each game
  /// throws different numbers (its own targets, or misses where a hit would
  /// end the turn), so this is wholly the game's own.
  final Future<void> Function(WidgetTester tester)? midGameDarts;

  /// Poll budget handed to [PlayToCompleteHelpers.waitForGameCompletion].
  /// This is an upper bound on polling, not a delay, so a game that needs
  /// longer raises it. The helper's own default is 500.
  final int maxIterations;

  /// True for the games whose mid-game test asserted the hand-thrown darts
  /// had NOT already won the game before auto-play was handed the board.
  final bool verifyNotWonBeforeAutoPlay;

  const PlayToCompleteSpec({
    required this.config,
    required this.setupAndStart,
    required this.hasWinner,
    this.setupAndStartMidGame,
    this.midGameDarts,
    this.maxIterations = 500,
    this.verifyNotWonBeforeAutoPlay = false,
  });
}

// ─── Shared choreography ────────────────────────────────────────────────────

/// Hands the board to auto-play, waits for a winner, and asserts the game
/// actually finished and landed on the results screen.
Future<void> _autoPlayToResults(
    WidgetTester tester, PlayToCompleteSpec spec) async {
  await PlayToCompleteHelpers.tapPlayToComplete(tester);

  await PlayToCompleteHelpers.waitForGameCompletion(
    tester,
    isComplete: () => spec.hasWinner(tester),
    maxIterations: spec.maxIterations,
  );

  expect(spec.hasWinner(tester), isTrue,
      reason: 'Play to Complete did not finish the game');
  expect(spec.config.getPlayAgainButton(), findsOneWidget,
      reason: 'Results screen not showing after auto-play completed the game');
}

// ─── Scenario runners ───────────────────────────────────────────────────────

/// Auto-play finishes a game started with this game's default options.
void runPlayToCompleteDefaultTest(PlayToCompleteSpec spec,
    {String? description}) {
  testWidgets(description ?? 'Play to Complete with default settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await spec.setupAndStart(tester);

    await _autoPlayToResults(tester, spec);
  });
}

/// Auto-play picks up a board that already has darts thrown by hand.
void runPlayToCompleteMidGameTest(PlayToCompleteSpec spec,
    {String? description}) {
  testWidgets(description ?? 'Play to Complete mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await (spec.setupAndStartMidGame ?? spec.setupAndStart)(tester);

    await spec.midGameDarts!(tester);

    // Only asserted where the hand-written test asserted it: the manual darts
    // must not have ended the game, or auto-play would have nothing to pick up
    // and the scenario would silently degrade into the default one.
    if (spec.verifyNotWonBeforeAutoPlay) {
      expect(spec.hasWinner(tester), isFalse,
          reason: 'Manual darts already won the game — nothing left to resume');
    }

    await _autoPlayToResults(tester, spec);
  });
}
