import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Results screen with 3 players shows all in rankings',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob', 'Carol']);
    await completeGameToVictory(tester, numOpponents: 2);

    await UITestHelpers.verifyResultsScreen(tester, config);

    // Rankings list should be visible
    expect(find.byKey(ClockworkQuestResultsKeys.rankingsList), findsOneWidget);

    // All 3 players should appear in rankings
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    for (final playerId in provider.currentGame!.playerIds) {
      expect(
        find.byKey(ClockworkQuestResultsKeys.playerRankTile(playerId)),
        findsOneWidget,
        reason: 'Player $playerId should appear in rankings',
      );
    }
  });
}
