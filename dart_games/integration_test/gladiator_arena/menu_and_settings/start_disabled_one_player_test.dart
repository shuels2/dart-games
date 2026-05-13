import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit): peer game Clockwork Quest has this
/// menu-level guard and Gladiator Arena was missing it. Verifies the Start
/// button is disabled with only 1 player selected (Gladiator Arena requires
/// at least 2 players, enforced by the provider, but the menu must also
/// surface this by leaving the Start button disabled).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: Start button disabled with 1 player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Solo', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final solo = players.firstWhere((p) => p.name == 'Solo');
    await UITestHelpers.selectPlayers(tester, [solo.id], config);

    final startButton = tester.widget<ElevatedButton>(
      config.getStartButton(),
    );
    expect(startButton.onPressed, isNull,
        reason: 'Start button should be disabled with 1 player');
  });
}
