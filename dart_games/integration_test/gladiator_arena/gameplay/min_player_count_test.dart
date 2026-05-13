import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 2 players (minimum) game renders correctly',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Game screen should be active
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    // Both players should be in the provider
    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.length, 2, reason: 'Should have exactly 2 players');

    // Both podiums should be visible
    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'Podium for ${player.name} should be visible');
    }

    // Turn cycle: P1 throws, then P2 throws
    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    await completeTurnWithMisses(tester);

    final p2Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    expect(p2Id, isNot(equals(p1Id)));

    await completeTurnWithMisses(tester);

    // Should rotate back to P1
    final afterP1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;
    expect(afterP1Id, equals(p1Id));
  });
}
