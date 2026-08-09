// integration_test/tiki_golf/pause_modal/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf pause-modal (dartboard paused) tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/results_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/pause_modal_helpers.dart';
export '../../shared/provider_helpers.dart';
export '../../shared/edit_score_helpers.dart';
export '../../shared/element_finders.dart';

import '../../shared/element_finders.dart';
import '../../shared/pause_modal_suite.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.tikiGolf();

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

Future<void> setupAndStartGame(
  WidgetTester tester, {
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      playerNames: playerNames,
    );

Future<void> openEditScore(WidgetTester tester, GameUIConfig cfg) =>
    EditScoreHelpers.openEditScore(tester, cfg);

void simulateDartboardDisconnection(WidgetTester tester) =>
    ProviderHelpers.simulateDartboardDisconnection(tester);

void simulateDartboardReconnection(WidgetTester tester) =>
    ProviderHelpers.simulateDartboardReconnection(tester);

// ===== TIKI GOLF-SPECIFIC HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Drive a 2-player solo game to completion (all 9 holes, birdie every hole).
///
/// After all 9 holes, results screen is shown.
Future<void> completeGameToVictory(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results screen navigation
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== PAUSE MODAL SUITE SPEC =====
//
// Shared bodies live in shared/pause_modal_suite.dart; everything
// game-specific for Tiki Golf is supplied here. Tiki throws misses rather
// than scoring darts: a hit sinks the hole and ends the turn immediately,
// which would skip past the states these tests need to observe.

final pauseModalSpec = PauseModalSpec(
  config: config,
  menuBackButton: ElementFinders.getTikiGolfBackButton,
  ownGameCard: ElementFinders.getTikiGolfCard,
  // Tiki exercised two controls, so both are tapped.
  menuSettingsControls: [
    ElementFinders.getTikiGolfMaxStrokesDropdown,
    ElementFinders.getTikiGolfMulliganSwitch,
  ],
  menuAddPlayerButton: ElementFinders.getTikiGolfAddPlayerButtonEmptyState,
  startGame: (tester) => setupAndStartGame(tester),
  throwOneDart: throwMissViaMock,
  throwTurnToTakeout: (tester) async {
    // maxStrokes (3) misses ends the turn without sinking the hole.
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await PumpSequences.simpleUpdate(tester);
  },
  verifyEmulatorBlocked: (tester) => expect(
      find.text('DARTS REMOVED'), findsNothing,
      reason: 'Emulator takeout control still reachable while paused'),
  finishTakeout: clickDartsRemoved,
  openEditScore: (tester) => openEditScore(tester, config),
  reachResults: (tester) async {
    await setupAndStartGame(tester, playerNames: ['Player A', 'Player B']);
    await completeGameToVictory(tester);
  },
  resultsAfterReconnect: (tester) async {
    await UITestHelpers.clickBackToMenu(tester, config);
    expect(ElementFinders.getTikiGolfCard(), findsOneWidget,
        reason: 'Back to Menu did not work after reconnect');
  },
);
