import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 13: Start button enabled with 2 players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Gear1', config);
    await UITestHelpers.addPlayer(tester, 'Gear2', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final p1 = players.firstWhere((p) => p.name == 'Gear1');
    final p2 = players.firstWhere((p) => p.name == 'Gear2');
    await UITestHelpers.selectPlayers(tester, [p1.id, p2.id], config);

    final startButton = tester.widget<ElevatedButton>(
      config.getStartButton(),
    );
    expect(startButton.onPressed, isNotNull,
        reason: 'Start button should be enabled with 2 players');
  });
}
