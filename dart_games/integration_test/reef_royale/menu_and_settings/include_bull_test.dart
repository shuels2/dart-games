// End-to-end UI test for the Reef Royale "Include Bull" option.
//
// Three behaviors verified in a single testWidgets so the surrounding
// navigation/state stays consistent and the test fits comfortably under
// the parallel-runner 600s budget:
//
//   1. Toggle dependency on Random Reefs — Include Bull is disabled
//      (onChanged == null) while Random Reefs is OFF and becomes enabled
//      the moment Random Reefs is toggled ON. Toggling Random Reefs
//      back OFF re-disables Include Bull.
//   2. Game playable to completion — with Random Reefs ON and Include
//      Bull ON, the auto-play strategy can drive the game to a winner
//      and the results screen appears.
//   3. Change Settings persistence — tapping Change Settings on the
//      results screen returns to the menu with BOTH Random Reefs and
//      Include Bull still ON (the change-settings round-trip preserves
//      the new toggle value via initialIncludeBull).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/settings_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Include Bull toggle: dependency on Random Reefs, playable to '
      'completion, and persists across Change Settings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── (1) Toggle dependency ────────────────────────────────────────
    // Include Bull must be present in the tree from first render so
    // its state can be observed without first toggling Random Reefs.
    final includeBullFinder = ElementFinders.getReefRoyaleIncludeBullSwitch();
    expect(includeBullFinder, findsOneWidget,
        reason: 'Include Bull switch must be on the menu at all times');

    // Random Reefs is OFF by default — the Include Bull switch is rendered
    // with onChanged == null, which is the Flutter convention for disabled.
    Switch includeBullSwitch = tester.widget<Switch>(includeBullFinder);
    expect(includeBullSwitch.onChanged, isNull,
        reason: 'Include Bull must be disabled when Random Reefs is OFF');

    // Toggle Random Reefs ON → Include Bull becomes enabled.
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    await tester.pump();
    includeBullSwitch = tester.widget<Switch>(includeBullFinder);
    expect(includeBullSwitch.onChanged, isNotNull,
        reason: 'Include Bull must be enabled when Random Reefs is ON');

    // Toggle Random Reefs OFF → Include Bull re-disables.
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    await tester.pump();
    includeBullSwitch = tester.widget<Switch>(includeBullFinder);
    expect(includeBullSwitch.onChanged, isNull,
        reason: 'Include Bull must re-disable when Random Reefs goes OFF');

    // Final config for the rest of the test: Random Reefs ON, Include
    // Bull ON.
    await SettingsHelpers.toggleReefRoyaleRandomReefs(tester);
    await tester.pump();
    await SettingsHelpers.toggleReefRoyaleIncludeBull(tester);
    await tester.pump();

    final rrSwitch =
        tester.widget<Switch>(ElementFinders.getReefRoyaleRandomReefsSwitch());
    expect(rrSwitch.value, isTrue);
    includeBullSwitch = tester.widget<Switch>(includeBullFinder);
    expect(includeBullSwitch.value, isTrue);

    // ── (2) Playable to completion ───────────────────────────────────
    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);
    await UITestHelpers.startGame(tester, config);

    // Verify the started game reflects both toggles. Include Bull on +
    // Random Reefs on means Bull (25) MUST be in the active target list.
    final providerGame =
        ProviderHelpers.getReefRoyaleProvider(tester).currentGame!;
    expect(providerGame.includeBull, isTrue);
    expect(providerGame.randomReefs, isTrue);
    expect(providerGame.activeTargets.contains(25), isTrue,
        reason: 'Bull (25) must be in the target list when Include Bull '
            'is ON and Random Reefs is ON');

    await PlayToCompleteHelpers.tapPlayToComplete(tester);
    final provider = ProviderHelpers.getReefRoyaleProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 800,
    );
    expect(provider.hasWinner, isTrue,
        reason: 'auto-play should drive the game to a winner');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'results screen should be reached');

    // ── (3) Change Settings persistence ──────────────────────────────
    await ResultsHelpers.clickChangeSettings(tester, config);

    // Back on the menu — both toggles must still be ON.
    final rrAfter = tester.widget<Switch>(
        ElementFinders.getReefRoyaleRandomReefsSwitch());
    expect(rrAfter.value, isTrue,
        reason: 'Random Reefs must persist across Change Settings');

    final ibAfter = tester.widget<Switch>(
        ElementFinders.getReefRoyaleIncludeBullSwitch());
    expect(ibAfter.value, isTrue,
        reason: 'Include Bull must persist across Change Settings');
    expect(ibAfter.onChanged, isNotNull,
        reason: 'Include Bull stays enabled because Random Reefs is still ON');
  });
}
