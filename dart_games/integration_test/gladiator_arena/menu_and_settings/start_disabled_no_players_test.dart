import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

/// Gap-coverage test (cross-game audit): peer game Clockwork Quest has this
/// menu-level guard and Gladiator Arena was missing it. Verifies the Start
/// button is disabled when zero players are selected.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: Start button disabled with no players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    final startButton = tester.widget<ElevatedButton>(
      config.getStartButton(),
    );
    expect(startButton.onPressed, isNull,
        reason: 'Start button should be disabled with 0 players');
  });
}
