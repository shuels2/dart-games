import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies that the LAUNCH button is disabled with 0 or 1 players, becomes
  // enabled with >= 2 players, and goes back to disabled if a player is
  // removed below the minimum.
  //
  // The button is wrapped in `Opacity(opacity: canStart ? 1.0 : 0.5, ...)` so
  // we read the Opacity ancestor to assert disabled/enabled. We also assert
  // ElevatedButton.onPressed mirrors that state (null when disabled).
  testWidgets('Menu: LAUNCH button enabled state tracks selected player count',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    Opacity launchOpacity() {
      final opacityFinder = find.ancestor(
        of: find.byKey(LunarLanderMenuKeys.startGameButton),
        matching: find.byType(Opacity),
      );
      return tester.widget<Opacity>(opacityFinder.first);
    }

    ElevatedButton launchButton() {
      return tester.widget<ElevatedButton>(
        find.byKey(LunarLanderMenuKeys.startGameButton),
      );
    }

    // 0 players: disabled
    expect(launchOpacity().opacity, 0.5,
        reason: 'LAUNCH button should be at 0.5 opacity with 0 players');
    expect(launchButton().onPressed, isNull,
        reason: 'LAUNCH button onPressed should be null with 0 players');

    // Add 1 player: still disabled
    await UITestHelpers.addPlayer(tester, 'Astro Alice', config);
    expect(launchOpacity().opacity, 0.5,
        reason: 'LAUNCH button should remain disabled with only 1 player');
    expect(launchButton().onPressed, isNull,
        reason: 'LAUNCH button onPressed should be null with 1 player');

    // Add 2nd player: enabled
    await UITestHelpers.addPlayer(tester, 'Bob Beta', config);
    expect(launchOpacity().opacity, 1.0,
        reason: 'LAUNCH button should be at full opacity with 2 players');
    expect(launchButton().onPressed, isNotNull,
        reason: 'LAUNCH button onPressed should be wired with 2 players');

    // Remove a player back to 1 -> disabled again
    final players = ProviderHelpers.getAllPlayers(tester);
    final alice = players.firstWhere((p) => p.name == 'Astro Alice');
    final removeButton =
        find.byKey(LunarLanderMenuKeys.removePlayerButton(alice.id));
    expect(removeButton, findsOneWidget,
        reason: 'Remove player button should be available for selected player');

    await tester.tap(removeButton);
    await PumpSequences.simpleUpdate(tester);

    expect(launchOpacity().opacity, 0.5,
        reason: 'LAUNCH button should be disabled after removing back to 1 player');
    expect(launchButton().onPressed, isNull,
        reason: 'LAUNCH button onPressed should be null after removing back to 1 player');
  });
}
