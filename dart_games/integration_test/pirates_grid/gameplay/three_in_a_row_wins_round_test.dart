import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Bo1 — P1 row 0 (S20+S18+S16) wins match → results screen',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        difficulty: 'Easy',
        bestOf: '1',
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // P1: throw S20, S18, S16 → row 0 (indices [0,0], [0,1], [0,2])
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 18);
    await throwDartViaMock(tester, 16);

    // P1 should now have won the round (and match on Bo1)
    expect(ProviderHelpers.piratesGridHasWinner(tester), isTrue,
        reason: 'P1 wins with row 0 (3-in-a-row)');
    expect(ProviderHelpers.getPiratesGridMatchWinnerId(tester), p1Id,
        reason: 'P1 should be match winner');

    // Tap DARTS REMOVED → should navigate to results
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    // Results screen: play again button should be visible
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should show after P1 wins Bo1');
  });
}
