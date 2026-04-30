import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Player tile appears after adding and selecting',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Bubbles', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final bubbles = players.firstWhere((p) => p.name == 'Bubbles');

    await UITestHelpers.selectPlayers(tester, [bubbles.id], config);

    final playerTile = config.getPlayerTile(bubbles.id);
    expect(playerTile, findsOneWidget);
  });
}
