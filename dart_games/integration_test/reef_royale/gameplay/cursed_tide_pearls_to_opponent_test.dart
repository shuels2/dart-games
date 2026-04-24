import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 21: Cursed Tide mode shows badge and pearls go to opponent',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, cursedTide: true);

    // Verify cursed badge is visible
    expect(find.byKey(ReefRoyaleGameKeys.cursedBadge), findsOneWidget);

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

    // P1 scores on claimed 20 -> in Cursed Tide, pearls go to opponent
    await throwDartViaMock(tester, 20);

    // P1 should have 0 pearls, opponent gets them
    expect(
        ProviderHelpers.getReefRoyalePlayerPearls(tester, playerId), 0);
  });
}
