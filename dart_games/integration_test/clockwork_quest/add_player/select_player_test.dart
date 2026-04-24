import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Added player can be selected',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Selectable', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final player = players.firstWhere((p) => p.name == 'Selectable');

    // Player tile should exist
    final tile = config.getPlayerTile(player.id);
    expect(tile, findsOneWidget);

    // Select the player
    await UITestHelpers.selectPlayers(tester, [player.id], config);

    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(
      playerProvider.selectedPlayers.any((p) => p.id == player.id),
      isTrue,
      reason: 'Player should be selected after tapping',
    );
  });
}
