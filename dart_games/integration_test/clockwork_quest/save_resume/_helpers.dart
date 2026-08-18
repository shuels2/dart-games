import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.clockworkQuest();
const gameType = 'clockwork_quest';

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> throwOneDart(WidgetTester tester) =>
    DartThrowHelpers.throwDartViaMock(tester, 1);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.clockworkQuest());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.clockworkQuest(),
      GameSaveConfig.clockworkQuestSecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Clockwork Quest is supplied here.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.getClockworkQuestCurrentPlayerDartsThrown(tester), 1);
  expect(ProviderHelpers.isClockworkQuestGameActive(tester), true);
}

/// Alice resumes having advanced 1 -> 2 with 2 darts left; reaching 20 wins.
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  await throwDartViaMock(tester, 2);
  await throwDartViaMock(tester, 3);
  await clickDartsRemoved(tester);
  await completeTurnWithMisses(tester);

  for (int startTarget = 4; startTarget <= 20; startTarget += 3) {
    for (int t = startTarget; t < startTarget + 3 && t <= 20; t++) {
      await throwDartViaMock(tester, t);
    }
    // Pad the turn with misses when fewer than 3 targets remain.
    final targetsHit = (startTarget + 2 <= 20) ? 3 : (20 - startTarget + 1);
    for (int i = targetsHit; i < 3; i++) {
      await throwMissViaMock(tester);
    }
    await clickDartsRemoved(tester);

    if (ProviderHelpers.clockworkQuestHasWinner(tester)) break;
    await completeTurnWithMisses(tester);
  }
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(ClockworkQuestMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(ClockworkQuestMenuKeys.backButton),
  enabledColor: const Color(0xFFF5F0E8),
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
