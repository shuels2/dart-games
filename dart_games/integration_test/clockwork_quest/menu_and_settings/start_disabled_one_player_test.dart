import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 12: Start button disabled with 1 player',
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
