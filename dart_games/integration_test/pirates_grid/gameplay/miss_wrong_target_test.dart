import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Easy — unmatched dart target has no effect',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, difficulty: 'Easy',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Throw S1 — not a target on Easy grid (grid uses 20/18/16/19/17/15/14/12/10)
    await throwDartViaMock(tester, 1);

    // No flags should be planted
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 0,
        reason: 'S1 should not match any grid cell on Easy — no flag planted');

    // All cells should remain empty
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, r, c), isNull,
            reason: 'Cell [$r,$c] should be empty after unmatched dart');
      }
    }
  });
}
