import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Edit score removes claim if marks drop below threshold',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Claim target 20 with triple, then 2 misses
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Verify claimed
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // Open edit score and change triple 20 to miss
    await EditScoreHelpers.openEditScore(tester, config);
    await EditScoreHelpers.setDart1(tester, 'Miss');
    await EditScoreHelpers.updateScore(tester);

    // Claim should be removed since marks dropped to 0
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isFalse);
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);
  });
}
