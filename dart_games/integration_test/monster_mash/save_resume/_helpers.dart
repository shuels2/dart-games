import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';
import '../../shared/save_resume_suite.dart';
import '../../shared/provider_helpers.dart';
import 'package:dart_games/constants/test_keys.dart';

final config = GameUIConfig.monsterMash();
const gameType = 'monster_mash';

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

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.monsterMash());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.monsterMash(),
      GameSaveConfig.monsterMashSecond(),
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> navigateToGameScreenLowHealth(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setMonsterMashHealthMax(tester, 10);
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);
  await UITestHelpers.startGame(tester, config);
}

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Monster Mash is supplied here.

/// Finishes a RESUMED game. The resumed turn already has one dart on it, so
/// Alice has two left — this is not the same shape as a from-scratch victory
/// helper. Health Max is 10 (set by [navigateToGameScreenLowHealth]).
Future<void> _completeResumedGame(WidgetTester tester) async {
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
  final bobTarget = ProviderHelpers.getMonsterMashPlayerTarget(tester, bob.id)!;

  // Alice's remaining 2 darts: 2 triples = 6 damage.
  await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
  await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
  await clickDartsRemoved(tester);

  // Bob misses his whole turn.
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  // Alice finishes Bob off: triple + single = 4 more damage.
  await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
  await throwDartViaMock(tester, bobTarget);
  await clickDartsRemoved(tester);
}

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, alice!.id), false,
      reason: 'Alice came back eliminated');
  expect(ProviderHelpers.isMonsterMashPlayerEliminated(tester, bob!.id), false,
      reason: 'Bob came back eliminated');
  expect(ProviderHelpers.getMonsterMashCurrentPlayerDartsThrown(tester), 1,
      reason: 'The dart thrown before saving did not survive the resume');
  expect(ProviderHelpers.isMonsterMashGameActive(tester), true);
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(MonsterMashMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(MonsterMashMenuKeys.backButton),
  verifyResumedState: _verifyResumedState,
  navigateToQuickGameScreen: navigateToGameScreenLowHealth,
  completeResumedGame: _completeResumedGame,
);
