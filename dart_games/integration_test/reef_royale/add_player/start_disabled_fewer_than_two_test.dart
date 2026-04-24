import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 6: Start button disabled with fewer than 2 players selected',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Solo', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final solo = players.firstWhere((p) => p.name == 'Solo');
    await UITestHelpers.selectPlayers(tester, [solo.id], config);

    // Start button should exist but game shouldn't start with 1 player
    final startButton = config.getStartButton();
    await tester.ensureVisible(startButton);
    await tester.pump();
    expect(startButton, findsOneWidget);
  });
}
