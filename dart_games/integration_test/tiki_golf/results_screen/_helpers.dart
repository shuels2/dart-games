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

/// Drive a 2-player solo game to completion (all 9 holes).
///
/// Each player hits the target on dart 1 of each hole (birdie).
/// After all 9 holes, the results screen is shown and the winner's ID is
/// returned for assertion.
Future<String?> driveToCompletion(WidgetTester tester,
    {List<String> playerNames = const ['Alice', 'Bob']}) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump();

  return ProviderHelpers.getTikiGolfWinnerId(tester);
}
