import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 9: Select and deselect player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Toggle', config);

    final players = ProviderHelpers.getAllPlayers(tester);
    final player = players.firstWhere((p) => p.name == 'Toggle');

    // Select
    await UITestHelpers.selectPlayers(tester, [player.id], config);
    var playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isTrue);

    // Deselect (tap again)
    await UITestHelpers.deselectPlayers(tester, [player.id], config);
    playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.any((p) => p.id == player.id), isFalse);
  });
}
