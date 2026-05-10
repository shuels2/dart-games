import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: score updates after dart throws', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final currentPlayerId =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    final initialScore = ProviderHelpers.getGladiatorArenaPlayerScore(
        tester, currentPlayerId);
    expect(initialScore, 0, reason: 'Score should start at 0');

    // Throw S20 = 20 points
    await throwDartViaMock(tester, 20);

    // Score won't update until turn ends (after 3 darts / skip)
    // After 1 dart, darts thrown count should be 1
    expect(
        ProviderHelpers.getGladiatorArenaCurrentPlayerDartsThrown(tester),
        1);

    // Throw 2 more misses to complete the turn
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Score should now be 20
    final updatedScore = ProviderHelpers.getGladiatorArenaPlayerScore(
        tester, currentPlayerId);
    expect(updatedScore, 20,
        reason: 'Score should be 20 after S20 + Miss + Miss');
  });
}
