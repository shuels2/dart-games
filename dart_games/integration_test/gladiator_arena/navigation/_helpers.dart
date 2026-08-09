import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/ui_test_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';

import '../../shared/results_helpers.dart';

final config = GameUIConfig.gladiatorArena();

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

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  int targetScore = 200,
  bool doubleFinishEnabled = true,
  bool shieldRoundEnabled = false,
  bool speedPlayEnabled = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: targetScore,
      doubleFinishEnabled: doubleFinishEnabled,
      shieldRoundEnabled: shieldRoundEnabled,
      speedPlayEnabled: speedPlayEnabled,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
}) async {
  final provider = ProviderHelpers.getGladiatorArenaProvider(tester);

  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;
    final currentPlayerId = provider.currentPlayerId;
    if (currentPlayerId == null) break;

    for (int d = 0; d < 3; d++) {
      if (provider.hasWinner || provider.shouldPromptTakeout) break;
      await throwDartViaMock(tester, 20);
    }

    if (provider.hasWinner) break;

    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      if (provider.hasWinner) break;
      for (int i = 0; i < numOpponents; i++) {
        if (provider.hasWinner) break;
        await completeTurnWithMisses(tester);
      }
    }
  }

  if (provider.hasWinner) {
    await clickDartsRemoved(tester);
  }

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====
//
// Gladiator only uses two of the four shared runners:
//   * menu_back_to_home and change_settings_back_to_home are BOTH plain
//     menu → back → home checks here (the latter never plays a game), so
//     both call runMenuBackToHomeTest.
//   * game_back_settings_persist throws a dart first, so it is the one game
//     that ASSERTS the Save modal appears (expectSaveModalOnGameBack).
//   * change_settings_preserves_settings stays hand-written: it asserts the
//     OPPOSITE of the other games — that a home round-trip RESETS settings to
//     defaults — which is a deliberate policy test, not this template.

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getGladiatorArenaBackButton,
  ownGameCard: ElementFinders.getGladiatorArenaCard,
  verifyOnMenu: (tester) =>
      expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget),
  reachGameScreen: (tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.setGladiatorArenaTargetScore(tester, 350);
    await SettingsHelpers.toggleGladiatorArenaShieldRound(tester);
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);
    await DartThrowHelpers.throwDartViaMock(tester, 5);
  },
  expectSaveModalOnGameBack: true,
  verifySettings: (tester) {
    final slider = tester
        .widget<Slider>(ElementFinders.getGladiatorArenaTargetScoreSlider());
    expect(slider.value.toInt(), 350,
        reason: 'Target score should still be 350 after back from game');
  },
);
