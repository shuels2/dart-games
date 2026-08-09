import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';
export '../../shared/provider_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

import 'package:dart_games/widgets/resume_game_button.dart';

final config = GameUIConfig.gladiatorArena();
const gameType = 'gladiator_arena';

// ===== DELEGATES TO SHARED HELPERS =====

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> throwOneDart(WidgetTester tester) =>
    DartThrowHelpers.throwDartViaMock(tester, 20);

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
    SaveResumeHelpers.preSaveGame(GameSaveConfig.gladiatorArena());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.gladiatorArena(),
      GameSaveConfig.gladiatorArenaSecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Gladiator Arena is supplied here.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isGladiatorArenaGameActive(tester), true);
  expect(ProviderHelpers.getGladiatorArenaCurrentPlayerDartsThrown(tester), 1);
}

Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
  for (int r = 0; r < 30; r++) {
    if (provider.hasWinner) break;
    for (int d = 0; d < 3; d++) {
      if (provider.hasWinner || provider.shouldPromptTakeout) break;
      await throwDartViaMock(tester, 20);
    }
    if (provider.hasWinner) break;
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;
      await completeTurnWithMisses(tester);
    }
  }
  if (provider.hasWinner) {
    await clickDartsRemoved(tester);
  }
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  // No key on the button, and it is hidden rather than disabled with no saves.
  menuResumeButton: () => find.byType(ResumeGameButton),
  menuBackButton: () => find.byKey(GladiatorArenaMenuKeys.backButton),
  // Gladiator's colour test never asserted a colour — only enabled + icon.
  enabledColor: null,
  hiddenWhenNoSaves: true,
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
