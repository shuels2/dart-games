// integration_test/tiki_golf/save_resume/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf save/resume tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/save_resume_helpers.dart';

import 'package:dart_games/constants/test_keys.dart';

import '../../shared/save_resume_suite.dart';

final config = GameUIConfig.tikiGolf();
const gameType = 'tiki_golf';

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

Future<void> navigateToGameScreen(WidgetTester tester) =>
    SaveResumeHelpers.navigateToGameScreen(tester, config);

Future<String> preSaveGame() =>
    SaveResumeHelpers.preSaveGame(GameSaveConfig.tikiGolf());

Future<List<String>> preSaveTwoGames() => SaveResumeHelpers.preSaveTwoGames(
      GameSaveConfig.tikiGolf(),
      GameSaveConfig.tikiGolfSecond(),
    );

// One-dart helper that throws the first hole's target on dart 1 (Birdie).
// Use for pre-save setup to advance game state before saving.
Future<void> throwOneDart(WidgetTester tester) async {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
  await throwDartViaMock(tester, target);
}

// ===== SAVE/RESUME SUITE SPEC =====
//
// Shared bodies live in shared/save_resume_suite.dart; everything
// game-specific for Tiki Golf is supplied here.

void _verifyResumedState(WidgetTester tester) {
  final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
  final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
  expect(alice, isNotNull);
  expect(bob, isNotNull);
  expect(ProviderHelpers.isTikiGolfGameActive(tester), true);
  // Alice completed hole 1; Bob has not, so the hole counter has not moved.
  expect(ProviderHelpers.getTikiGolfCurrentHole(tester), 1);
}

/// Birdies every remaining hole until a winner exists.
Future<void> _completeResumedGame(
    WidgetTester tester, String savedGameId) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);
  while (!provider.hasWinner) {
    final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
    final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }
}

final saveResumeSpec = SaveResumeSpec(
  config: config,
  gameType: gameType,
  navigateToGameScreen: navigateToGameScreen,
  // Dart 1 hits the hole's target (Birdie), which ENDS THE TURN and raises
  // the takeout modal — and that modal blocks the game-screen back arrow, so
  // the Save prompt never appears. Every hand-written Tiki save/resume test
  // paired the dart with a clickDartsRemoved for exactly this reason; the
  // shared runner does not, so the pairing lives here.
  throwOneDart: (tester) async {
    await throwOneDart(tester);
    await clickDartsRemoved(tester);
  },
  preSaveGame: preSaveGame,
  preSaveTwoGames: preSaveTwoGames,
  menuResumeButton: () => find.byKey(TikiGolfMenuKeys.resumeGameButton),
  menuBackButton: () => find.byKey(TikiGolfMenuKeys.backButton),
  enabledColor: const Color(0xFFFFF5E1),
  verifyResumedState: _verifyResumedState,
  completeResumedGame: _completeResumedGame,
);
