import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 32: 3-player game - opponent tiles visible for both opponents',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob', 'Carol']);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerIds = provider.currentGame!.playerIds;
    final currentPlayerId = provider.getCurrentPlayerId()!;

    // Both non-active players should show as opponent tiles
    final opponents = playerIds.where((id) => id != currentPlayerId).toList();
    expect(opponents.length, 2);

    for (final opponentId in opponents) {
      expect(
        find.byKey(ClockworkQuestGameKeys.playerTile(opponentId)),
        findsOneWidget,
        reason: 'Opponent tile for $opponentId should be visible',
      );
    }
  });
}
