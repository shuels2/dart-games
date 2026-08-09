// integration_test/tiki_golf/navigation/_helpers.dart
//
// Delegates to shared helpers for Tiki Golf navigation tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/game_ui_config.dart';
import '../../shared/element_finders.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/navigation_suite.dart';

final config = GameUIConfig.tikiGolf();

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
  List<String>? playerNames,
  int maxStrokes = 3,
  bool mulliganEnabled = false,
}) =>
    GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      playerNames: playerNames,
      maxStrokes: maxStrokes,
      mulliganEnabled: mulliganEnabled,
    );

Future<void> setMaxStrokes(WidgetTester tester, int maxStrokes) =>
    SettingsHelpers.setTikiGolfMaxStrokes(tester, maxStrokes);

Future<void> toggleMulligan(WidgetTester tester) =>
    SettingsHelpers.toggleTikiGolfMulligan(tester);

// ===== GAME-SPECIFIC HELPERS =====

/// Get the current hole's target number from the provider.
int getCurrentHoleTarget(WidgetTester tester) {
  final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
  return ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
}

/// Drive a 2-player solo game to completion (all 9 holes, all birdies).
///
/// Every player hits the hole's target on dart 1. After all 9 holes,
/// hasWinner becomes true and the results screen navigates into view.
Future<void> playGameToCompletion(WidgetTester tester) async {
  final provider = ProviderHelpers.getTikiGolfProvider(tester);

  while (!provider.hasWinner) {
    final target = getCurrentHoleTarget(tester);
    await throwDartViaMock(tester, target);
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  // Wait for results navigation (3s victory delay + animation)
  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPECS =====
//
// Shared bodies live in shared/navigation_suite.dart. Tiki Golf needs
// TWO specs because its hand-written files used different player names and
// settings per scenario; both are reproduced exactly.

/// Default settings, "GoPlayer" names — used by the two home-navigation tests.
final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getTikiGolfBackButton,
  setupAndStart: (tester) => setupAndStartGame(
    tester,
    playerNames: ['GoPlayer1', 'GoPlayer2'],
  ),
  playToVictory: playGameToCompletion,
);

void _verifyStrokesAndMulligan(WidgetTester tester, List<String> playerNames) {
  expect(find.text('5'), findsWidgets,
      reason: 'Max Strokes "5" not showing — settings not preserved');
  final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
  expect(mulliganSwitch, findsOneWidget,
      reason: 'Mulligan switch not found on menu');
  expect(tester.widget<Switch>(mulliganSwitch).value, isTrue,
      reason: 'Mulligan should be ON — settings not preserved');
  for (final name in playerNames) {
    expect(find.text(name), findsWidgets,
        reason: '$name not found in menu after navigating back');
  }
}

/// Max Strokes 5 + Mulligan ON — used by the settings-preservation tests.
/// The two differ only in player names, matching the originals.
final navigationSettingsSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getTikiGolfBackButton,
  setupAndStart: (tester) => setupAndStartGame(
    tester,
    maxStrokes: 5,
    mulliganEnabled: true,
    playerNames: ['SettingsP1', 'SettingsP2'],
  ),
  playToVictory: playGameToCompletion,
  verifySettings: (tester) =>
      _verifyStrokesAndMulligan(tester, ['SettingsP1', 'SettingsP2']),
);

final navigationGameBackSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getTikiGolfBackButton,
  // Backs out of a freshly started game (0 darts thrown).
  reachGameScreen: (tester) async {
    await setupAndStartGame(
      tester,
      maxStrokes: 5,
      mulliganEnabled: true,
      playerNames: ['NavPlayer1', 'NavPlayer2'],
    );
    expect(ElementFinders.getTikiGolfHoleCounter(), findsOneWidget,
        reason: 'Game screen not loaded — hole counter not found');
  },
  verifySettings: (tester) =>
      _verifyStrokesAndMulligan(tester, ['NavPlayer1', 'NavPlayer2']),
);
