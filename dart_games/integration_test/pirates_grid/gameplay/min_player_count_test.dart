import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: min player count test.
  // Pirate's Grid requires exactly 2 players (min = max = 2).
  // Verifies UI elements render correctly and a turn cycle completes.
  testWidgets('Gameplay: 2 players (spec minimum) — all UI elements render, turn completes',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    expect(provider.currentGame!.playerIds.length, 2,
        reason: 'Game should have exactly 2 players');

    // Verify mandatory game UI elements
    expect(ElementFinders.getPiratesGridSkipTurnButton(), findsOneWidget,
        reason: 'Skip turn button should be visible');
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar should be visible');

    // Verify grid is present (9 cells)
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        expect(ElementFinders.getPiratesGridGridCell(r, c), findsOneWidget,
            reason: 'Grid cell [$r,$c] should be visible');
      }
    }

    // Complete a turn cycle
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id);

    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P2 should now be active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'P2 should be active after P1 completes turn');
  });
}
