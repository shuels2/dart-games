import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

import 'package:dart_games/widgets/resume_game_button.dart';

final config = GameUIConfig.lunarLander();
const gameType = 'lunar_lander';

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> throwOneDart(WidgetTester tester) =>
    DartThrowHelpers.throwDartViaMock(tester, 20); // First dart for Lunar Lander

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
    SaveResumeHelpers.preSaveGame(GameSaveConfig.lunarLander());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.lunarLander(),
      GameSaveConfig.lunarLanderSecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Lunar Lander is supplied here.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isLunarLanderGameActive(tester), true);
  expect(ProviderHelpers.getLunarLanderCurrentPlayerDartsThrown(tester), 1);
}

Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  // The provider must be tracking the row it was resumed from, otherwise
  // completion has nothing to auto-delete.
  expect(ProviderHelpers.getLunarLanderProvider(tester).resumedSavedGameId,
      savedGameId,
      reason: 'Resumed game should track the saved game ID');

  for (int i = 0; i < 30; i++) {
    if (!ProviderHelpers.isLunarLanderGameActive(tester)) break;
    if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
    if (ProviderHelpers.getLunarLanderProvider(tester).shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (ProviderHelpers.lunarLanderHasWinner(tester)) break;
      await completeTurnWithMisses(tester);
    }
  }

  // The winning dart has not been taken out yet; this dispatches
  // takeout_finished, which chains into the victory + auto-delete flow.
  await clickDartsRemoved(tester);
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  // Lunar's ResumeGameButton carries no key, so it is found by type — and it
  // is hidden entirely (not disabled) when nothing is saved.
  menuResumeButton: () => find.byType(ResumeGameButton),
  menuBackButton: () => find.byKey(LunarLanderMenuKeys.backButton),
  enabledColor: const Color(0xFFFAFDF6),
  hiddenWhenNoSaves: true,
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
