import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Edit score recalculates marks correctly',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Throw 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();

    // All marks should be 0
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 0);

    // Open edit score dialog
    await EditScoreHelpers.openEditScore(tester, config);

    // Change dart 1 from Miss to Triple 20 (should add 3 marks = claim target 20)
    await EditScoreHelpers.setDart1(tester, 'T20');

    // Save
    await EditScoreHelpers.updateScore(tester);

    // Target 20 should now have 3 marks (claimed)
    expect(
        ProviderHelpers.getReefRoyalePlayerMarks(tester, playerId, 20), 3);
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20), isTrue);
  });
}
