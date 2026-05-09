import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Steal Mode OFF — P1 hitting P2 cell has no effect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy', stealMode: false,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);

    ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
      [p2Id, null, null],
      [null, null, null],
      [null, null, null],
    ]);

    // P1 throws actual target — Steal OFF → cell stays with P2
    await throwDartViaMock(tester, targetNum);

    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), p2Id,
        reason: 'Steal Mode OFF: P1 should not replace P2 flag at cell [0,0]');
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
        reason: 'P1 should have 0 flags — steal was blocked');
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p2Id), 1,
        reason: 'P2 should still have 1 flag');
  });
}
