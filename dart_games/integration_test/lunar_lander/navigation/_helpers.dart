import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';

export '../../shared/ui_test_helpers.dart';
export '../../shared/element_finders.dart';
export '../../shared/pump_sequences.dart';

import '../../shared/results_helpers.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/element_finders.dart';

final config = GameUIConfig.lunarLander();

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
  int altitude = 200,
  bool hardLanding = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartLunarLander(
      tester,
      config,
      altitude: altitude,
      hardLanding: hardLanding,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool hardLandingEnabled = false,
}) async {
  final provider = ProviderHelpers.getLunarLanderProvider(tester);

  for (int round = 0; round < 30; round++) {
    if (provider.hasWinner) break;

    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) break;

    final currentAlt = provider.getCurrentAltitude(currentPlayerId);

    if (hardLandingEnabled && currentAlt <= 20) {
      if (currentAlt > 0) {
        await throwDartViaMock(tester, currentAlt);
      }
    } else {
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

  // Trigger the victory flow: when the loop exits with hasWinner=true, the
  // winning dart has not been removed yet, so _handleTakeoutFinished (which
  // calls _handleGameWon → navigates to results) has not fired. Tap DARTS
  // REMOVED to dispatch the takeout_finished event that detects the winner
  // and pushes the results screen.
  await clickDartsRemoved(tester);

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPECS =====

void _verifyAltitudeAndHardLanding(WidgetTester tester) {
  final sliderFinder = ElementFinders.getLunarLanderAltitudeSlider();
  expect(sliderFinder, findsOneWidget);
  expect(tester.widget<Slider>(sliderFinder).value, 300.0,
      reason: 'Altitude should still be 300');

  final switchFinder = ElementFinders.getLunarLanderHardLandingSwitch();
  expect(switchFinder, findsOneWidget);
  expect(tester.widget<Switch>(switchFinder).value, isTrue,
      reason: 'Hard Landing should still be ON');
}

/// Default settings — the two home-navigation tests.
final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getLunarLanderBackButton,
  verifyOnMenu: (tester) =>
      expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget),
  setupAndStart: (tester) => setupAndStartGame(tester, config),
  playToVictory: (tester) => completeGameToVictory(tester),
);

/// Altitude 300 + Hard Landing ON — the two settings-preservation tests.
/// The game-back variant backs straight out of a freshly started game
/// (0 darts thrown, so no Save prompt); Change Settings plays to victory.
final navigationSettingsSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getLunarLanderBackButton,
  verifyOnMenu: (tester) =>
      expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget),
  setupAndStart: (tester) =>
      setupAndStartGame(tester, config, altitude: 300, hardLanding: true),
  playToVictory: (tester) =>
      completeGameToVictory(tester, hardLandingEnabled: true),
  reachGameScreen: (tester) =>
      setupAndStartGame(tester, config, altitude: 300, hardLanding: true),
  verifySettings: (tester) {
    _verifyAltitudeAndHardLanding(tester);
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.length, 2);
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  },
);

/// Game-back asserts only the two settings (no player assertions), matching
/// the original file.
final navigationGameBackSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getLunarLanderBackButton,
  verifyOnMenu: (tester) =>
      expect(ElementFinders.getLunarLanderStartButton(), findsOneWidget),
  reachGameScreen: (tester) =>
      setupAndStartGame(tester, config, altitude: 300, hardLanding: true),
  verifySettings: _verifyAltitudeAndHardLanding,
);
