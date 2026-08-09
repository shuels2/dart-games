import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/services/mock_scolia_api_service.dart';

import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/navigation_suite.dart';
import '../../shared/ui_test_helpers.dart';

final config = GameUIConfig.clockworkQuest();

// ===== DELEGATES TO SHARED HELPERS =====

MockScoliaApiService? getMockApi(WidgetTester tester) =>
    DartThrowHelpers.getMockApi(tester);

Future<void> throwDartViaMock(WidgetTester tester, int number,
        {String multiplier = 'single'}) =>
    DartThrowHelpers.throwDartViaMock(tester, number, multiplier: multiplier);

Future<void> throwBullseyeViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwBullseyeViaMock(tester);

Future<void> throwMissViaMock(WidgetTester tester) =>
    DartThrowHelpers.throwMissViaMock(tester);

Future<void> clickDartsRemoved(WidgetTester tester) =>
    DartThrowHelpers.clickDartsRemoved(tester);

Future<void> completeTurnWithMisses(WidgetTester tester) =>
    DartThrowHelpers.completeTurnWithMisses(tester);

Future<void> setupAndStartGame(
  WidgetTester tester,
  GameUIConfig config, {
  bool includeBullseye = false,
  List<String>? playerNames,
}) =>
    GameSetupHelpers.setupAndStartClockworkQuest(
      tester,
      config,
      includeBullseye: includeBullseye,
      playerNames: playerNames,
    );

// ===== GAME-SPECIFIC HELPERS =====

Future<void> completeGameToVictory(
  WidgetTester tester, {
  int numOpponents = 1,
  bool includeBullseye = false,
}) async {
  final provider = ProviderHelpers.getClockworkQuestProvider(tester);

  for (int startTarget = 1; startTarget <= 20; startTarget += 3) {
    for (int t = startTarget; t < startTarget + 3 && t <= 20; t++) {
      await throwDartViaMock(tester, t);
    }
    final targetsHit = (startTarget + 2 <= 20) ? 3 : (20 - startTarget + 1);
    for (int i = targetsHit; i < 3; i++) {
      await throwMissViaMock(tester);
    }
    await clickDartsRemoved(tester);

    if (ProviderHelpers.clockworkQuestHasWinner(tester)) break;

    for (int i = 0; i < numOpponents; i++) {
      await completeTurnWithMisses(tester);
    }
  }

  if (includeBullseye && !provider.hasWinner) {
    if (provider.shouldPromptTakeout) {
      await clickDartsRemoved(tester);
      for (int i = 0; i < numOpponents; i++) {
        await completeTurnWithMisses(tester);
      }
    }
    await throwBullseyeViaMock(tester);
    // Remove darts to trigger victory flow after bullseye win
    await clickDartsRemoved(tester);
  }

  await ResultsHelpers.pumpUntilResults(tester, config);
}

// ===== NAVIGATION SUITE SPEC =====
//
// Clockwork has no menu_back_to_home file; the other three scenarios map
// directly onto the shared runners.

void _verifyOptionControls(WidgetTester tester) {
  expect(ElementFinders.getClockworkQuestIncludeBullseyeCheckbox(),
      findsOneWidget);
  expect(ElementFinders.getClockworkQuestSpeedModeCheckbox(), findsOneWidget);
}

Future<void> _reachGameScreen(WidgetTester tester) async {
  await setupAndStartGame(tester, config);
  await completeGameToVictory(tester);
  await ResultsHelpers.pumpUntilResults(tester, config);
  expect(config.getPlayAgainButton(), findsOneWidget);
  await UITestHelpers.clickPlayAgain(tester, config);

  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

final navigationSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getClockworkQuestBackButton,
  setupAndStart: (tester) => setupAndStartGame(tester, config),
  playToVictory: completeGameToVictory,
  reachGameScreen: _reachGameScreen,
  verifySettings: _verifyOptionControls,
);

/// Change Settings additionally asserts the two players survived — checked
/// both through the provider and on screen, as the original did.
final navigationSettingsSpec = NavigationSpec(
  config: config,
  menuBackButton: ElementFinders.getClockworkQuestBackButton,
  setupAndStart: (tester) => setupAndStartGame(tester, config),
  playToVictory: completeGameToVictory,
  verifySettings: (tester) {
    _verifyOptionControls(tester);
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.length, 2);
    expect(find.text('Player A'), findsWidgets);
    expect(find.text('Player B'), findsWidgets);
  },
);
