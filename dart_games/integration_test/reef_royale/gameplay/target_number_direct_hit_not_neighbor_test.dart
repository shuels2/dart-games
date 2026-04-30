import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 30: Target number only counts as direct hit, not also as neighbor',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, neighborNumbers: true);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Standard targets: 20, 19, 18, 17, 16, 15, Bull
    // 18 is physically adjacent to 1 and 4 on the dartboard
    // But hitting 18 should only be a direct hit on 18, never a neighbor of anything

    // Hit target 18 directly
    await throwDartViaMock(tester, 18);

    // Should add marks to 18 only
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 18), 1);

    // Should NOT add marks to any other target as a neighbor
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 19), 0);
    expect(ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 17), 0);

    // Target count should be 1 (single direct hit, not multi-target)
    final provider = ProviderHelpers.getReefRoyaleProvider(tester);
    final targetCount = provider.getDartThrowTargetCount(playerId);
    expect(targetCount[0], 1);
  });
}
