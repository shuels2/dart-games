import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Play Again returns to game screen with same players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    await UITestHelpers.clickPlayAgain(tester, config);

    // Should be back on game screen with game active
    expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);

    // Should have same 2 players
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    expect(provider.currentGame!.playerIds.length, 2);
  });
}
