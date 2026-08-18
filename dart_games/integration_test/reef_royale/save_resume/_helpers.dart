import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.reefRoyale();
const gameType = 'reef_royale';

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

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwOuterBullViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwOuterBullViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.reefRoyale());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.reefRoyale(),
      GameSaveConfig.reefRoyaleSecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Reef Royale is supplied here.

void _verifyResumedState(WidgetTester tester) {
  // Reef asserts its two on-screen counters as well as provider state.
  expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
  expect(find.byKey(ReefRoyaleGameKeys.coralCounter), findsOneWidget);
  expect(tester.widget<Text>(find.byKey(ReefRoyaleGameKeys.pearlCounter)).data,
      contains('pearls'));
  expect(tester.widget<Text>(find.byKey(ReefRoyaleGameKeys.coralCounter)).data,
      contains('corals'));

  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);
  expect(ProviderHelpers.isReefRoyaleGameActive(tester), true);
}

/// Alice resumes with 1 mark on 20 and 2 darts left; 7 claims wins.
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  await throwDartViaMock(tester, 20, multiplier: 'double'); // claims 20
  await throwDartViaMock(tester, 19, multiplier: 'triple'); // claims 19
  await clickDartsRemoved(tester);

  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  await throwDartViaMock(tester, 18, multiplier: 'triple');
  await throwDartViaMock(tester, 17, multiplier: 'triple');
  await throwDartViaMock(tester, 16, multiplier: 'triple');
  await clickDartsRemoved(tester);

  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await throwMissViaMock(tester);
  await clickDartsRemoved(tester);

  await throwDartViaMock(tester, 15, multiplier: 'triple'); // 6th claim
  await throwBullseyeViaMock(tester); // 2 marks on Bull
  await throwOuterBullViaMock(tester); // 3rd mark — 7th claim, game over

  // Let the takeout prompt and its scheduled callbacks settle first.
  await tester.pump(const Duration(seconds: 4));
  await tester.pump();
  await clickDartsRemoved(tester);
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(ReefRoyaleMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(ReefRoyaleMenuKeys.backButton),
  enabledColor: const Color(0xFFFFF8F0),
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
