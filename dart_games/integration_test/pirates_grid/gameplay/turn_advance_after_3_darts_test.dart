import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: After 3 darts + DARTS REMOVED, turn advances to P2',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Verify P1 is active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason: 'P1 should be active at start');

    // Throw 3 misses for P1
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // RemoveDartsModal should appear
    expect(provider.shouldPromptTakeout, isTrue,
        reason: 'Should prompt takeout after 3 darts');

    // Click DARTS REMOVED
    await clickDartsRemoved(tester);

    // P2 should now be active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'P2 should be active after P1 completes turn');
  });
}
