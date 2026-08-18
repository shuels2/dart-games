import 'package:flutter/material.dart';
// integration_test/treasure_divide/navigation/_helpers.dart
//
// Delegates to shared helpers for Treasure Divide navigation tests.
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

final config = GameUIConfig.treasureDivide();

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
}) =>
    GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      playerNames: playerNames,
    );

// ===== NAVIGATION SUITE SPEC =====
//
// Only menu_back_to_home and game_back_settings_persist use the shared
// runners. The two change-settings files stay hand-written on purpose: they
// carry deliberately INLINED game-completion helpers (documented in-file as
// matching the screenshot-test safe pattern), and hoisting those into this
// file to satisfy the suite would break that pattern for no coverage gain.

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getTreasureDivideBackButton,
  verifyOnMenu: (tester) => expect(
      ElementFinders.getTreasureDivideStartButton(), findsOneWidget,
      reason: 'SET SAIL! button not found — menu did not load'),
  // Rounds = 7 + Quarter It ON, two players, then straight back out.
  reachGameScreen: (tester) async {
    await UITestHelpers.navigateToGameMenu(tester, config);
    await SettingsHelpers.selectTreasureDivideRounds(tester, 7);
    await SettingsHelpers.toggleTreasureDivideQuarterIt(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await UITestHelpers.addPlayer(tester, 'NavPirate1', config);
    await UITestHelpers.addPlayer(tester, 'NavPirate2', config);
    await UITestHelpers.startGame(tester, config);
    expect(ElementFinders.getTreasureDivideGameBackButton(), findsOneWidget,
        reason: 'Game screen not loaded — back button not found');
  },
  verifySettings: (tester) {
    expect(find.text('7'), findsWidgets,
        reason: 'Rounds "7" not showing — settings not preserved');
    final quarterIt = ElementFinders.getTreasureDivideQuarterItSwitch();
    expect(quarterIt, findsOneWidget,
        reason: 'Quarter It switch not found on menu');
    expect(tester.widget<Switch>(quarterIt).value, isTrue,
        reason: 'Quarter It should be ON — settings not preserved');
    expect(find.text('NavPirate1'), findsWidgets,
        reason: 'NavPirate1 not found — players not preserved');
    expect(find.text('NavPirate2'), findsWidgets,
        reason: 'NavPirate2 not found — players not preserved');
  },
);
