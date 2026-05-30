// integration_test/tiki_golf/results_screen/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf results-screen tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';

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

/// Hit the current hole's target on the first dart (Birdie), then takeout.
Future<void> throwBirdieAndTakeout(WidgetTester tester) async {
  final target = getCurrentHoleTarget(tester);
  await throwDartViaMock(tester, target);
  await clickDartsRemoved(tester);
}

/// Drive a 2-player solo game to completion with an OUTRIGHT winner.
///
/// Player 1 hits the target on dart 1 every hole (birdie = 1 stroke). All
/// other players miss once then hit on dart 2 (par = 2 strokes). After 9
/// holes, player 1 has a strictly lower total and is the sole winner.
///
/// Use [driveToTie] when you need a tied results screen instead.
Future<String?> driveToCompletion(WidgetTester tester,
    {List<String> playerNames = const ['Alice', 'Bob']}) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  final firstPlayerId = provider.currentGame?.playerIds.first;

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    final activeId = provider.currentGame?.activePlayerId;

    if (activeId == firstPlayerId) {
      // Birdie on dart 1
      await throwDartViaMock(tester, target);
    } else {
      // Par on dart 2 (miss then hit)
      await throwMissViaMock(tester);
      await throwDartViaMock(tester, target);
    }
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation
  await ResultsHelpers.pumpUntilResults(tester, config);

  return ProviderHelpers.getTikiGolfWinnerId(tester);
}

/// Drive a solo game to completion where ALL players tie at the same total.
///
/// Every player hits the target on dart 1 of every hole (everybody birdies),
/// producing identical totals (9 strokes each). After 9 holes the results
/// screen displays a tied-winners card.
Future<void> driveToTie(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation
  await ResultsHelpers.pumpUntilResults(tester, config);
}
