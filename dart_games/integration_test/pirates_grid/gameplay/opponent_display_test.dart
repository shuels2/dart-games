import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // MANDATORY: opponent display test.
  // In a 2-player game, after P1 completes turn (DARTS REMOVED),
  // verify P2 becomes the active player with correct display:
  // - P2 avatar shows as active (glow)
  // - P1 avatar shows as inactive
  // - Dart indicators reset to P2's turn
  testWidgets('Gameplay: opponent display — after P1 turn, P2 becomes active player',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    final p1Id = provider.currentGame!.playerIds[0];
    final p2Id = provider.currentGame!.playerIds[1];

    // Verify P1 is currently active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p1Id,
        reason: 'P1 should be active at start');

    // Active player avatar key should be present
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar (P1) should be visible');

    // Dart indicators should be at 0 for current player
    expect(provider.getCurrentPlayerDartsThrown(), 0,
        reason: 'P1 darts thrown should be 0 at start');

    // P1 completes turn with 3 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now P2 should be active
    expect(ProviderHelpers.getPiratesGridCurrentPlayerId(tester), p2Id,
        reason: 'P2 should be active after P1 completes turn');

    // Active avatar key should still be present (now for P2)
    expect(ElementFinders.getPiratesGridPlayerAvatarActive(), findsOneWidget,
        reason: 'Active player avatar (now P2) should be visible');

    // P2 dart indicator should show 0 darts (fresh turn)
    expect(provider.getCurrentPlayerDartsThrown(), 0,
        reason: 'P2 darts thrown should be 0 at start of their turn');

    // P2 name should be displayed
    expect(find.text('Player B'), findsWidgets,
        reason: 'P2 (Player B) name should be displayed');
  });
}
