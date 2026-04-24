import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 33: 4-player game - turn cycles through all 4 players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['P1', 'P2', 'P3', 'P4']);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerIds = provider.currentGame!.playerIds;

    // Verify P1 is active
    expect(provider.getCurrentPlayerId(), playerIds[0]);

    // P1 turn: 3 misses
    await completeTurnWithMisses(tester);
    expect(provider.getCurrentPlayerId(), playerIds[1]);

    // P2 turn: 3 misses
    await completeTurnWithMisses(tester);
    expect(provider.getCurrentPlayerId(), playerIds[2]);

    // P3 turn: 3 misses
    await completeTurnWithMisses(tester);
    expect(provider.getCurrentPlayerId(), playerIds[3]);

    // P4 turn: 3 misses -- back to P1
    await completeTurnWithMisses(tester);
    expect(provider.getCurrentPlayerId(), playerIds[0]);
  });
}
