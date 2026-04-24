import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 4: Rankings list shows all players',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);
    await completeGameToVictory(tester);

    expect(find.byKey(ClockworkQuestResultsKeys.rankingsList), findsOneWidget);

    // Both players should appear in rankings
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
