import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gameplay: podium is visible for each player',
      (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(
      tester,
      config,
      targetScore: 200,
      playerNames: ['Player A', 'Player B'],
    );

    final players = ProviderHelpers.getAllPlayers(tester);
    expect(players.length, 2);

    // All podiums should render
    for (final player in players) {
      expect(ElementFinders.getGladiatorArenaPodium(player.id),
          findsOneWidget,
          reason: 'Podium should be visible for ${player.name}');
    }

    // Goal display should show target
    expect(ElementFinders.getGladiatorArenaGoalDisplay(), findsOneWidget);
  });
}
