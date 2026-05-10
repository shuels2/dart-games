import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: 8 players (maximum) renders without overflow',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      playerNames: [
        'Player A',
        'Player B',
        'Player C',
        'Player D',
        'Player E',
        'Player F',
        'Player G',
        'Player H',
      ],
    );

    // Game screen should be active
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);

    // All 8 players should be in the provider
    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.length, 8, reason: 'Should have 8 players');

    // All podiums should be visible
    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'Podium for ${player.name} should be visible');
    }
  });
}
