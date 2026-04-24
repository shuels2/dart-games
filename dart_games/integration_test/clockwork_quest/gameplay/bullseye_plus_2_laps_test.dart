import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 28: Bullseye + 2 laps - bull required each lap',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        includeBullseye: true, laps: 2);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.maxTarget, 21);
    expect(provider.currentGame!.numberOfLaps, 2);

    // Complete first lap ending with bull
    provider.currentGame!.currentTarget[playerId] = 21;
    await throwBullseyeViaMock(tester);

    expect(provider.getPlayerLapsCompleted(playerId), 1);
    expect(provider.getPlayerCurrentTarget(playerId), 1);
    expect(provider.hasWinner, isFalse);

    // Complete second lap
    provider.currentGame!.currentTarget[playerId] = 21;
    await throwBullseyeViaMock(tester);

    expect(provider.hasWinner, isTrue);
  });
}
