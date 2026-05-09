import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Gameplay: Skip Turn with 0 darts auto-advances without RemoveDartsModal',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Verify P1 is active with 0 darts thrown
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id);
    expect(provider.getCurrentPlayerDartsThrown(), 0,
        reason: 'P1 should have 0 darts thrown at start');

    // Tap Skip Turn
    final skipButton = ElementFinders.getPiratesGridSkipTurnButton();
    expect(skipButton, findsOneWidget);
    await tester.tap(skipButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Turn should advance to P2 directly (no darts to remove)
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'Skip Turn with 0 darts should advance directly to P2');
  });
}
