import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';

import '../../shared/results_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/element_finders.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/pause_modal_helpers.dart';

final config = GameUIConfig.lunarLander();

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
  int altitude = 200,
  bool hardLanding = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: altitude,
      hardLanding: hardLanding,
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
  bool hardLandingEnabled = false,
}) async {
  final provider = ProviderHelpers.getLunarLanderProvider(tester);

  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final currentAlt = provider.getCurrentAltitude(currentPlayerId);

    if (hardLandingEnabled && currentAlt <= 20) {
      if (currentAlt > 0) {
        await throwDartViaMock(tester, currentAlt);
      }
    } else {
      await throwDartViaMock(tester, 20);
    }

    if (provider.hasWinner) break;

    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;

      for (int i = 0; i < numOpponents; i++) {
        if (provider.hasWinner) break;
        await completeTurnWithMisses(tester);
      }
    }
  }

  // Trigger the victory flow: when the loop exits with hasWinner=true, the
  // winning dart has not been removed yet, so _handleTakeoutFinished (which
  // calls _handleGameWon → navigates to results) has not fired. Tap DARTS
  // REMOVED to dispatch the takeout_finished event that detects the winner
  // and pushes the results screen.
  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Lunar Lander is supplied here.
//
// As with Clockwork, slot 4 is named "Pause blocks settings controls" but its
// hand-written body only tapped Add Player. Both controls are listed so the
// name is honoured without dropping the tap the test actually made.

/// Lunar's Edit Score button belongs to a completed turn, so this finishes
/// the pending takeout and plays a second turn first — matching the
/// hand-written test.
Future<void> _openEditScoreOnSecondTurn(WidgetTester tester) async {
  await clickDartsRemoved(tester);
  await throwDartViaMock(tester, 5);
  await throwDartViaMock(tester, 5);
  await throwDartViaMock(tester, 5);
  await openEditScore(tester);
}

final pauseModalSpec = PauseModalSpec(
  config: config,
  // Lunar's menu back arrow is found by tooltip, not by key.
  menuBackButton: () => find.byTooltip('Back'),
  ownGameCard: ElementFinders.getLunarLanderCard,
  verifyOnMenu: (tester) =>
      expect(find.text('LUNAR LANDER GAME SETUP'), findsWidgets,
          reason: 'Menu screen not showing — setup heading not found'),
  menuSettingsControls: [
    ElementFinders.getLunarLanderAltitudeSlider,
    ElementFinders.getLunarLanderAddPlayerButtonEmptyState,
  ],
  startGame: (tester) => setupAndStartGame(tester, config),
  throwOneDart: (tester) => throwDartViaMock(tester, 20),
  throwTurnToTakeout: (tester) async {
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
  },
  verifyNoSavePrompt: (tester) => expect(find.text('Save Game?'), findsNothing,
      reason: 'Save prompt appeared despite the pause overlay'),
  finishTakeout: clickDartsRemoved,
  openEditScore: _openEditScoreOnSecondTurn,
  reachResults: (tester) async {
    await setupAndStartGame(tester, config, altitude: 100);
    await completeGameToVictory(tester);
  },
  verifyOnResults: (tester) => expect(
      find.byKey(LunarLanderResultsKeys.winnerName), findsOneWidget,
      reason: 'Results screen not showing — winner name not found'),
  resultsAfterReconnect: (tester) async {
    await tester.tap(config.getPlayAgainButton());
    await PumpSequences.navigation(tester);
    PauseModalHelpers.verifyPauseModalNotVisible(tester);
  },
);
