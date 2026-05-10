import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: skip turn with partial darts scores thrown darts',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final currentPlayerId =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Throw 1 dart (S20 = 20 pts)
    await throwDartViaMock(tester, 20);

    // Tap Skip Turn with 1 dart thrown
    final skipButton = ElementFinders.getGladiatorArenaSkipTurnButton();
    await tester.tap(skipButton);
    await tester.pump(const Duration(seconds: 4)); // allow simulateTakeoutStarted
    await tester.pump();

    // Click DARTS REMOVED
    await clickDartsRemoved(tester);

    // Score should include the 1 thrown dart = 20
    final score = ProviderHelpers.getGladiatorArenaPlayerScore(
        tester, currentPlayerId);
    expect(score, 20,
        reason: 'Score should reflect the 1 dart thrown before skip');
  });
}
