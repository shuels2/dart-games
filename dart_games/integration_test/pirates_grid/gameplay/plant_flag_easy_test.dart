import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Easy difficulty — S20 plants flag in cell [0,0]',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, difficulty: 'Easy',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Verify cell [0,0] is empty before
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
        reason: 'Cell [0,0] should be empty before dart');

    // Throw S20 → claims cell [0,0] (Easy: any hit on 20)
    await throwDartViaMock(tester, 20);

    // Verify cell [0,0] is now claimed by P1
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), p1Id,
        reason: 'Cell [0,0] should be claimed by P1 after S20');

    // Flags counter should be 1
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
        reason: 'P1 should have 1 flag planted');
  });
}
