import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Medium difficulty — D on cell [0,1] target plants flag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Medium', playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Read the actual target assigned to cell [0,1] at runtime
    final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 1);

    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
        reason: 'Cell [0,1] should be empty before dart');

    // Medium requires double or triple — throw a double
    await throwDartViaMock(tester, targetNum, multiplier: 'double');

    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), p1Id,
        reason: 'Cell [0,1] should be claimed by P1 after D on its target');

    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
        reason: 'P1 should have 1 flag planted');
  });
}
