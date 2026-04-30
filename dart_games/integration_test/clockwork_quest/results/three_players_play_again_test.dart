import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Results screen with 3 players - Play Again works',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob', 'Carol']);
    await completeGameToVictory(tester, numOpponents: 2);

    await UITestHelpers.clickPlayAgain(tester, config);

    // Should be back on game screen with all 3 players
    expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    expect(provider.currentGame!.playerIds.length, 3);
  });
}
