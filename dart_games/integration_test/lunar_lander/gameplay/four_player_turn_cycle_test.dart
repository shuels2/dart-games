import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Verifies that a 4-player game cycles turns correctly P1 -> P2 -> P3 -> P4 -> P1
  // and each player makes progress (altitude decreases) after their turn.
  testWidgets('Gameplay: 4-player turn cycle — turns advance through all 4 and back to P1',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, playerNames: [
      'P1',
      'P2',
      'P3',
      'P4',
    ]);

    final provider = ProviderHelpers.getLunarLanderProvider(tester);
    final playerIds = provider.currentGame!.playerIds;
    expect(playerIds.length, 4);

    final startingAlt = ProviderHelpers.getLunarLanderStartingAltitude(tester);

    // P1 active
    expect(provider.getCurrentPlayerId(), playerIds[0]);

    // P1 turn: throw 3 scoring darts so altitude decreases
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);
    expect(provider.getCurrentPlayerId(), playerIds[1],
        reason: 'After P1 turn, P2 should be active');

    // P2 turn
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);
    expect(provider.getCurrentPlayerId(), playerIds[2],
        reason: 'After P2 turn, P3 should be active');

    // P3 turn
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);
    expect(provider.getCurrentPlayerId(), playerIds[3],
        reason: 'After P3 turn, P4 should be active');

    // P4 turn
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await throwDartViaMock(tester, 5);
    await clickDartsRemoved(tester);
    expect(provider.getCurrentPlayerId(), playerIds[0],
        reason: 'After P4 turn, turn should cycle back to P1');

    // After full cycle, every player should have made progress (altitude < starting).
    for (final id in playerIds) {
      expect(getAltitude(tester, id), lessThan(startingAlt),
          reason: 'Player $id should have descended below starting altitude');
    }
  });
}
