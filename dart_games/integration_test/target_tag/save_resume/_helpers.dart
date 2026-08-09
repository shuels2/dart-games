import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

import '../../shared/pump_sequences.dart';

final config = GameUIConfig.targetTag();
const gameType = 'target_tag';

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
    SaveResumeHelpers.preSaveGame(GameSaveConfig.targetTag());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.targetTag(),
      GameSaveConfig.targetTagSecond(),
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> navigateToGameScreenLowShields(WidgetTester tester) async {
  await UITestHelpers.navigateToGameMenu(tester, config);
  await SettingsHelpers.setTargetTagShieldMax(tester, 3);
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);
  await UITestHelpers.startGame(tester, config);
}

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Target Tag is supplied here.

void _verifyResumedState(WidgetTester tester) {
  // The active-player label is a visual check the other games skip.
  final activeNameFinder = find.byKey(TargetTagGameKeys.activePlayerName);
  expect(activeNameFinder, findsOneWidget);
  expect(tester.widget<Text>(activeNameFinder).data, isNotNull);

  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, alice!.id), false);
  expect(ProviderHelpers.isTargetTagPlayerEliminated(tester, bob!.id), false);
  expect(ProviderHelpers.isTargetTagGameActive(tester), true);
}

/// Finishes a RESUMED game at shield_max 3. Alice already threw one dart
/// before the save, so she has two left in the current turn.
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice')!;
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
  final aliceTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, alice.id)!;
  final bobTarget = ProviderHelpers.getTargetTagPlayerTarget(tester, bob.id)!;

  // Alice's 2 remaining darts: triple own target => 3 shields => tagged in.
  await throwDartViaMock(tester, aliceTarget, multiplier: 'triple');
  await throwDartViaMock(tester, 1);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Bob tags in, then misses twice.
  await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
  await throwDartViaMock(tester, 1);
  await throwDartViaMock(tester, 1);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Alice strips Bob's 3 shields.
  await throwDartViaMock(tester, bobTarget);
  await throwDartViaMock(tester, bobTarget);
  await throwDartViaMock(tester, bobTarget);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);
  await PumpSequences.fullRebuild(tester);

  // Bob is at 0 shields — one more hit eliminates him.
  await throwDartViaMock(tester, bobTarget);
  await PumpSequences.simpleUpdate(tester);
  await clickDartsRemoved(tester);
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(TargetTagMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(TargetTagMenuKeys.backButton),
  enabledColor: Colors.white,
  verifyResumedState: _verifyResumedState,
  navigateToQuickGameScreen: navigateToGameScreenLowShields,
  completeResumedGame: _completeResumedGame,
);
