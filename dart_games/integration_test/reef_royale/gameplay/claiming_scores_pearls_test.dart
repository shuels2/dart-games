import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 8: Claiming scores pearls on subsequent hits',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Claim target 20 with triple
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
        isTrue);

    // Hit target 20 again for pearls
    await throwDartViaMock(tester, 20);
    expect(ProviderHelpers.getReefRoyalePlayerPearls(tester, playerId),
        greaterThan(0));
  });
}
