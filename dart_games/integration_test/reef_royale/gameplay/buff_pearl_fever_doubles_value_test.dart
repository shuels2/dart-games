import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/models/reef_royale_game.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 23: Buff Pearl Fever doubles pearl value',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, bonusBuffs: true);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Claim target 20 with triple
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // P2 misses
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Activate Pearl Fever before P1's next turn
    ProviderHelpers.setReefRoyaleActiveBuff(tester, ReefBuff.pearlFever);

    // P1 scores on claimed 20 -> 20 * 2 = 40 pearls
    await throwDartViaMock(tester, 20);

    expect(
        ProviderHelpers.getReefRoyalePlayerPearls(tester, playerId), 40);
  });
}
