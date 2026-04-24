import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 5: Opponent summary bar updates after scoring',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Claim target 20 and score
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now it's P2's turn - verify P1 appears in opponent tiles
    // The player tile for P1 should exist showing their stats
    expect(find.byKey(ReefRoyaleGameKeys.playerTile(playerId)),
        findsOneWidget);
  });
}
