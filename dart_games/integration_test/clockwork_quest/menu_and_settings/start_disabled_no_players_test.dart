import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Start button disabled with no players',
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
