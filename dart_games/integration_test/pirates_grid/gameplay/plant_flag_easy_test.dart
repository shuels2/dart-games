import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Easy difficulty — hitting cell [0,0] target plants flag',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy', playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Read the actual target assigned to cell [0,0] at runtime
    final targetNum = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);

    // Verify cell [0,0] is empty before
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), isNull,
        reason: 'Cell [0,0] should be empty before dart');

    // Throw single on the actual target number (Easy: any hit matches)
    await throwDartViaMock(tester, targetNum);

    // Verify cell [0,0] is now claimed by P1
    expect(ProviderHelpers.getPiratesGridCellClaimedBy(tester, 0, 0), p1Id,
        reason: 'Cell [0,0] should be claimed by P1 after hitting its target');

    // Flags counter should be 1
    expect(ProviderHelpers.getPiratesGridFlagsPlanted(tester, p1Id), 1,
        reason: 'P1 should have 1 flag planted');
  });
}
