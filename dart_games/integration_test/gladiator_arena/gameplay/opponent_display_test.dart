import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 3-player game shows all opponents\' podiums',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      playerNames: ['Player A', 'Player B', 'Player C'],
    );

    // All 3 players' podiums should be visible
    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.length, 3);

    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'Podium for ${player.name} should be visible');
    }

    // After P1's turn, P2 and P3 should still render
    await completeTurnWithMisses(tester);

    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'All podiums still visible after P1\'s turn');
    }
  });
}
