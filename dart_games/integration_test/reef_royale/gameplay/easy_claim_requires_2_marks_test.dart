import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Easy claim requires only 2 marks',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, easyClaim: true);

    final playerId =
        ProviderHelpers.getReefRoyaleCurrentPlayerId(tester)!;

    // Double should claim with easy claim (2 marks needed)
    await throwDartViaMock(tester, 20, multiplier: 'double');

    expect(
        ProviderHelpers.reefRoyaleHasPlayerClaimed(tester, playerId, 20),
        isTrue);
  });
}
