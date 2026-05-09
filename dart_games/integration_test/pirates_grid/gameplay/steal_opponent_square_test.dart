import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Steal Mode ON — P1 hitting P2 cell replaces flag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy', stealMode: true,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Read actual target for cell [0,0] before setting state
    final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);

    // Programmatically claim cell [0,0] for P2
    ProviderHelpers.setPiratesGridGameState(tester, claimedBy: [
      [p2Id, null, null],
      [null, null, null],
      [null, null, null],
    ]);

    // P1 throws the actual target for [0,0] — should steal it (Steal Mode ON)
    await throwDartViaMock(tester, targetNum);

    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), p1Id,
        reason: 'Steal Mode ON: P1 should replace P2 flag at cell [0,0]');
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
        reason: 'P1 should have 1 flag after stealing');
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p2Id), 0,
        reason: 'P2 should have 0 flags after being stolen from');
  });
}
