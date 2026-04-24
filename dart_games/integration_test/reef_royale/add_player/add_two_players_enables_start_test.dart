import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 2: Add two players enables start button',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Nemo', config);
    await UITestHelpers.addPlayer(tester, 'Dory', config);

    // Select both players
    final players = ProviderHelpers.getAllPlayers(tester);
    final nemo = players.firstWhere((p) => p.name == 'Nemo');
    final dory = players.firstWhere((p) => p.name == 'Dory');
    await UITestHelpers.selectPlayers(tester, [nemo.id, dory.id], config);

    final startButton = config.getStartButton();
    await tester.ensureVisible(startButton);
    await tester.pump();
    expect(startButton, findsOneWidget);
  });
}
