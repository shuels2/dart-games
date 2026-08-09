import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.carnivalDerby();
const gameType = 'carnival_derby';

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
    SaveResumeHelpers.preSaveGame(GameSaveConfig.carnivalDerby());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.carnivalDerby(),
      GameSaveConfig.carnivalDerbySecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Carnival Derby is supplied here.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  // The single S20 thrown before saving must come back as 20 points.
  expect(ProviderHelpers.getCarnivalDerbyPlayerScore(tester, alice!.id), 20);
  expect(ProviderHelpers.getCarnivalDerbyPlayerScore(tester, bob!.id), 0);
  expect(ProviderHelpers.getCarnivalDerbyCurrentPlayerId(tester), alice.id);
  expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), true);
}

/// Alice resumes on 20 points with 2 darts left; target is 150.
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  await throwDartViaMock(tester, 20, multiplier: 'triple'); // 80
  await throwDartViaMock(tester, 20, multiplier: 'triple'); // 140
  await clickDartsRemoved(tester);

  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  await throwDartViaMock(tester, 20); // 160 >= 150 — wins
  await clickDartsRemoved(tester);
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(CarnivalDerbyMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(CarnivalDerbyMenuKeys.backButton),
  enabledColor: const Color(0xFFF1FAEE),
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
