// integration_test/treasure_divide/save_resume/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide save/resume tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:flutter/material.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.treasureDivide();
const gameType = 'treasure_divide';

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
  int numberOfRounds = 9,
  bool quarterItEnabled = false,
  bool customTargetsEnabled = false,
  bool teamMode = false,
  bool manualAssignment = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: numberOfRounds,
      quarterItEnabled: quarterItEnabled,
      customTargetsEnabled: customTargetsEnabled,
      teamMode: teamMode,
      manualAssignment: manualAssignment,
      playerNames: playerNames,
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Treasure Divide is supplied here.
//
// TD's helpers were built on setupAndStartGame rather than the
// navigateToGameScreen / throwOneDart / preSaveGame delegates every other
// game exposes, so those three are defined here in terms of what TD already
// had. numberOfRounds 7 and the Alice/Bob roster match the hand-written
// tests.
//
// `resume_preserves_mid_turn_gold_test.dart` stays hand-written — it asserts
// TD-only in-flight turn state that no other game has.

Future<void> navigateToGameScreen(WidgetTester tester) => setupAndStartGame(
      tester,
      numberOfRounds: 7,
      playerNames: ['Alice', 'Bob'],
    );

/// One dart is enough to make the board dirty. The hand-written save tests
/// threw two; the assertion in every case is only that the board counts as
/// touched, which one dart already satisfies.
Future<void> throwOneDart(WidgetTester tester) =>
    throwDartViaMock(tester, 20);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.treasureDivide());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.treasureDivide(),
      GameSaveConfig.treasureDivideSecond(),
    );

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isTreasureDivideGameActive(tester), true);
}

/// P1 hits the round target three times a turn, P2 misses three times, until
/// a winner exists. Takeout goes through the mock API because TD's
/// DARTS REMOVED button is inert (no dartboardKey is passed to its shell).
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  final provider = ProviderHelpers.getTreasureDivideProvider(tester);
  final p1Id = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);

  int turnCount = 0;
  while (!provider.hasWinner) {
    final currentId = ProviderHelpers.getTreasureDivideCurrentPlayerId(tester);
    final roundIndex =
        ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
    final target =
        ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);

    if (currentId == p1Id) {
      for (var i = 0; i < 3; i++) {
        if (target == -1) {
          await throwDartViaMock(tester, 1, multiplier: 'double');
        } else if (target == -2) {
          await throwDartViaMock(tester, 1, multiplier: 'triple');
        } else {
          await throwDartViaMock(tester, target);
        }
      }
    } else {
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
      await throwMissViaMock(tester);
    }

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    if (provider.shouldPromptTakeout) {
      getMockApi(tester)?.simulateTakeoutFinished();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    turnCount++;
    if (turnCount > 40) break; // Safety bound
  }
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  throwOneDart: throwOneDart,
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(TreasureDivideMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(TreasureDivideMenuKeys.backButton),
  enabledColor: const Color(0xFFFFD700),
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
