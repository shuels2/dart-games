import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/save_resume_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/save_resume_helpers.dart';

import 'package:flutter/material.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/widgets/resume_game_button.dart';

import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.piratesGrid();
const gameType = 'pirates_grid';

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

/// Throw one dart at cell [0,0] — uses the cell-target lookup so PG's
/// randomized targets work correctly.
Future<void> throwOneDart(WidgetTester tester) async {
  final t = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
  await DartThrowHelpers.throwDartViaMock(tester, t);
}

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig gameConfig, {
  List<String> playerNames = const ['Alice', 'Bob'],
}) =>
    SaveResumeHelpers.navigateToGameScreen(
      tester,
      gameConfig,
      playerNames: playerNames,
    );

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.piratesGrid());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.piratesGrid(),
      GameSaveConfig.piratesGridSecond(),
    );

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Pirate's Grid is supplied here.
//
// `resume_auto_deletes_on_completion_test.dart` stays HAND-WRITTEN and does
// not use this spec. It cannot: it drives completion through the emulator's
// play-to-complete button rather than a scripted dart sequence, and it needs
// its own ensureVisible-then-tap save flow. See the note in that file.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);

  final provider = ProviderHelpers.getPiratesGridProvider(tester);
  expect(provider.isGameActive, isTrue,
      reason: 'Game should be active after resume');
  final p1Id = provider.currentGame!.playerIds[0];
  expect(provider.currentGame!.getFlagsPlanted(p1Id), 1,
      reason: 'P1 should have 1 flag after resume (state restored)');
  expect(ProviderHelpers.isPiratesGridGameActive(tester), true);
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
  menuBackButton: () => find.byKey(PiratesGridMenuKeys.backButton),
  enabledColor: const Color(0xFFDAA520),
  hiddenWhenNoSaves: true,
  verifyResumedState: _verifyResumedState,
);
