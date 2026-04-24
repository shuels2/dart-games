import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 7: Change Settings preserves players from game',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickChangeSettings(tester, config);

    // Players should be pre-selected (2 players)
    final playerProvider = ProviderHelpers.getPlayerProvider(tester);
    expect(playerProvider.selectedPlayers.length, 2);
  });
}
