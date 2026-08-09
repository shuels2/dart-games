// integration_test/tiki_golf/play_to_complete/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf play-to-complete tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/play_to_complete_suite.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';

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
  int maxStrokes = 3,
  bool mulliganEnabled = false,
  bool teamMode = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
      teamMode: teamMode,
      playerNames: playerNames,
    );

// ===== TIKI GOLF-SPECIFIC HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Drive a 2-player solo game to completion (all 9 holes, all birdies).
///
/// Every player hits the hole's target on dart 1. After all 9 holes,
/// hasWinner becomes true and the results screen navigates into view.
Future<void> playGameToCompletion(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation (3s victory delay + animation)
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();
}

// ===== PLAY TO COMPLETE SUITE SPEC =====
//
// Shared bodies live in shared/play_to_complete_suite.dart; everything
// specific to Tiki Golf is supplied here. Only the two commodity scenarios
// (default settings, mid-game pickup) use it — the per-option tests in this
// folder stay hand-written.

final playToCompleteSpec = PlayToCompleteSpec(
  config: config,
  setupAndStart: (tester) =>
      GameSetupHelpers.setupAndStartTikiGolf(tester, config),
  hasWinner: (tester) => ProviderHelpers.getTikiGolfProvider(tester).hasWinner,
  // A single miss: a hit would sink the hole and end the turn, which is the
  // opposite of the mid-turn state this scenario wants.
  midGameDarts: (tester) async {
    await DartThrowHelpers.throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
  },
);
