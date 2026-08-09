import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/element_finders.dart';
import '../../shared/pause_modal_helpers.dart';
import '../../shared/pause_modal_suite.dart';

final config = GameUIConfig.clockworkQuest();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartClockworkQuest(
      tester,
      config,
      includeBullseye: includeBullseye,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester) =>
    EditScoreHelpers.openEditScore(tester, config);

Future<void> updateScore(WidgetTester tester) =>
    EditScoreHelpers.updateScore(tester);

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool includeBullseye = false,
}) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);

  for (int target = 1; target <= 20; target++) {
    await throwDartViaMock(tester, target);

    if (target % 3 == 0 && target < 20) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
  }

  if (includeBullseye && !provider.hasWinner) {
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
    await DartThrowHelpers.throwBullseyeViaMock(tester);
  }

  // Remove darts to trigger victory flow (standardized: DARTS REMOVED before results)
  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Clockwork Quest is supplied here.
//
// Slot 4 is named "Pause blocks settings controls" but its hand-written body
// only ever tapped the Add Player button. Both controls are listed below so
// the test now covers what its name claims WITHOUT dropping the add-player
// tap it actually made.

/// Clockwork's Edit Score button only appears on a turn AFTER the first, so
/// this finishes the pending takeout and plays a second turn before opening
/// the dialog — exactly what the hand-written test did.
Future<void> _openEditScoreOnSecondTurn(WidgetTester tester) async {
  await clickDartsRemoved(tester);
  await throwDartViaMock(tester, 4);
  await throwDartViaMock(tester, 5);
  await throwDartViaMock(tester, 6);
  await openEditScore(tester);
}

final pauseModalSpec = PauseModalSpec(
  config: config,
  // Clockwork's menu back arrow is found by tooltip, not by key.
  menuBackButton: () => find.byTooltip('Back'),
  ownGameCard: ElementFinders.getClockworkQuestCard,
  verifyOnMenu: (tester) =>
      expect(find.text('CLOCKWORK QUEST GAME SETUP'), findsWidgets,
          reason: 'Menu screen not showing — setup heading not found'),
  menuSettingsControls: [
    ElementFinders.getClockworkQuestNumberOfLapsDropdown,
    ElementFinders.getClockworkQuestAddPlayerButtonEmptyState,
  ],
  startGame: (tester) => setupAndStartGame(tester, config),
  throwOneDart: (tester) => throwDartViaMock(tester, 1),
  throwAnotherDart: (tester) => throwDartViaMock(tester, 2),
  throwTurnToTakeout: (tester) async {
    // Clockwork advances 1 → 2 → 3, which fills the turn.
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 2);
    await throwDartViaMock(tester, 3);
  },
  verifyNoSavePrompt: (tester) => expect(find.text('Save Game?'), findsNothing,
      reason: 'Save prompt appeared despite the pause overlay'),
  finishTakeout: clickDartsRemoved,
  openEditScore: _openEditScoreOnSecondTurn,
  reachResults: (tester) async {
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);
  },
  verifyOnResults: (tester) => expect(
      find.byKey(ClockworkQuestResultsKeys.winnerName), findsOneWidget,
      reason: 'Results screen not showing — winner name not found'),
  resultsAfterReconnect: (tester) async {
    await tester.tap(config.getPlayAgainButton());
    await PumpSequences.navigation(tester);
    PauseModalHelpers.verifyPauseModalNotVisible(tester);
  },
);
