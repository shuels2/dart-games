import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Medium difficulty — D18 plants flag in cell [0,1]',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, difficulty: 'Medium',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Verify cell [0,1] (target D18 on medium) is empty before
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), isNull,
        reason: 'Cell [0,1] should be empty before dart');

    // Throw D18 → claims cell [0,1] (Medium: double on 18)
    await throwDartViaMock(tester, 18, multiplier: 'double');

    // Verify cell [0,1] is now claimed by P1
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 1), p1Id,
        reason: 'Cell [0,1] should be claimed by P1 after D18');

    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
        reason: 'P1 should have 1 flag planted');
  });
}
