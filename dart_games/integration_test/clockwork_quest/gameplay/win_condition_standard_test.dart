import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 11: Win condition - standard (no bullseye, 1 lap)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    // Set player near end
    provider.currentGame!.currentTarget[playerId] = 20;

    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    expect(provider.hasWinner, isTrue);
    expect(provider.currentGame!.winnerId, playerId);
  });
}
