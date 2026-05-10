import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: turn advances to next player after 3 darts',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Complete P1's turn with misses
    await completeTurnWithMisses(tester);

    // Should now be P2's turn
    final p2Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    expect(p2Id, isNot(equals(p1Id)),
        reason: 'Turn should advance to second player');
  });
}
