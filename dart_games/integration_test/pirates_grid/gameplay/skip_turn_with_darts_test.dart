import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: Skip Turn with 1 dart thrown shows RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];

    // Throw 1 dart for P1
    await throwDartViaMock(tester, 1); // number 1 — no match on Easy grid

    expect(provider.getCurrentPlayerDartsThrown(), 1,
        reason: 'P1 should have 1 dart thrown');

    // Tap Skip Turn
    final skipButton = ElementFinders.getPiratesGridSkipTurnButton();
    expect(skipButton, findsOneWidget);
    await tester.tap(skipButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // RemoveDartsModal should appear (darts were thrown)
    expect(provider.shouldPromptTakeout, isTrue,
        reason: 'Skip turn with dart thrown should trigger takeout prompt');

    // Tap DARTS REMOVED
    await clickDartsRemoved(tester);

    // Turn should advance to P2
    final p2Id = provider.currentGame!.playerIds[1];
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'P2 should be active after Skip Turn takeout');
  });
}
